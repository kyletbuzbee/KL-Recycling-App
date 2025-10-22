import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kl_recycling_app/firebase_options.dart';
import 'package:kl_recycling_app/config/theme.dart';
import 'package:kl_recycling_app/config/constants.dart';
import 'package:kl_recycling_app/providers/camera_provider.dart';
import 'package:kl_recycling_app/services/firebase_service.dart';
import 'package:kl_recycling_app/models/photo_estimate.dart' as models;
import 'package:kl_recycling_app/providers/gamification_provider.dart';
import 'package:kl_recycling_app/screens/services/services_screen.dart';
import 'package:kl_recycling_app/screens/home_screen.dart';
import 'package:kl_recycling_app/screens/locations_screen.dart';
import 'package:kl_recycling_app/screens/contact_screen.dart';
import 'package:kl_recycling_app/screens/educational_screen.dart';
import 'package:kl_recycling_app/screens/gamification_screen.dart';
import 'package:kl_recycling_app/screens/notification_settings_screen.dart';
import 'package:kl_recycling_app/services/notification_service.dart';
import 'package:kl_recycling_app/widgets/common/image_placement_guide.dart';

// Platform-specific imports
import 'package:package_info_plus/package_info_plus.dart';

// Platform type enumeration
enum PlatformVariant {
  mobile,
  wear,
  tv,
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize other Firebase services
  await FirebaseService.initialize();

  // Initialize notification service
  await NotificationService.initialize();

  // Log app open event
  FirebaseService.logAppOpen();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
      ],
      child: const KLRecyclingApp(),
    ),
  );
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  late CameraProvider _cameraProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraProvider.disposeCamera();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    _cameraProvider = context.read<CameraProvider>();
    await _cameraProvider.initializeCamera();
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraProvider.controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _takePhoto() async {
    try {
      final imagePath = await _cameraProvider.takePicture();
      if (!mounted || imagePath == null) return;

      // Navigate to photo preview
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoPreviewScreen(imagePath: imagePath),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = context.watch<CameraProvider>();

    if (!cameraProvider.isInitialized || cameraProvider.controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Photo Estimate'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Estimate'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () {
              // Toggle camera - would implement if needed
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(cameraProvider.controller!),

          // Framing overlay
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            margin: const EdgeInsets.all(20),
          ),

          // Instructions
          const Positioned(
            top: 20,
            left: 20,
            child: SizedBox(
              width: 200,
              child: Text(
                'Position scrap metal in the frame for instant pricing estimate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Capture button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.large(
                  onPressed: _takePhoto,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.camera, size: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoPreviewScreen extends StatefulWidget {
  final String imagePath;

  const PhotoPreviewScreen({super.key, required this.imagePath});

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  models.MaterialType _selectedMaterial = models.MaterialType.unknown;
  double _estimatedWeight = 0.0;
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cameraProvider = context.read<CameraProvider>();
    final estimatedPrice = cameraProvider.calculateEstimatePrice(_selectedMaterial, _estimatedWeight);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Estimate'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveEstimate,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Photo display
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(widget.imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Form
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What material is this?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Material type buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _materialButton(models.MaterialType.steel, 'Steel'),
                      _materialButton(models.MaterialType.aluminum, 'Aluminum'),
                      _materialButton(models.MaterialType.copper, 'Copper'),
                      _materialButton(models.MaterialType.brass, 'Brass'),
                      _materialButton(models.MaterialType.unknown, 'Other'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Estimated weight input
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Estimated Weight (lbs)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _estimatedWeight = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),

                  const SizedBox(height: 8),

                  // Price estimate display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Value:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${estimatedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  const Spacer(),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveEstimate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Estimate'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _materialButton(models.MaterialType type, String label) {
    final isSelected = _selectedMaterial == type;

    return OutlinedButton(
      onPressed: () => setState(() => _selectedMaterial = type),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : null,
        foregroundColor: isSelected ? Colors.white : AppColors.primary,
        side: BorderSide(
          color: AppColors.primary,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }

  Future<void> _saveEstimate() async {
    try {
      final cameraProvider = context.read<CameraProvider>();

      // Get current location
      final position = await cameraProvider.getCurrentLocation();

      final photoEstimate = models.PhotoEstimate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: widget.imagePath,
        materialType: _selectedMaterial,
        estimatedWeight: _estimatedWeight,
        notes: _notesController.text,
        timestamp: DateTime.now(),
        latitude: position?.latitude,
        longitude: position?.longitude,
        estimatedValue: cameraProvider.calculateEstimatePrice(_selectedMaterial, _estimatedWeight),
      );

      cameraProvider.addEstimate(photoEstimate);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estimate saved successfully!')),
      );

      Navigator.pop(context); // Go back to camera
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving estimate: $e')),
      );
    }
  }
}

class KLRecyclingApp extends StatefulWidget {
  const KLRecyclingApp({super.key});

  @override
  State<KLRecyclingApp> createState() => _KLRecyclingAppState();
}

class _KLRecyclingAppState extends State<KLRecyclingApp> {
  PlatformVariant? _platformVariant;

  @override
  void initState() {
    super.initState();
    _initializePlatformDetection();
  }

  Future<void> _initializePlatformDetection() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final packageName = packageInfo.packageName;

    PlatformVariant variant;
    if (packageName.contains('wear')) {
      variant = PlatformVariant.wear;
    } else if (packageName.contains('tv')) {
      variant = PlatformVariant.tv;
    } else {
      variant = PlatformVariant.mobile;
    }

    setState(() {
      _platformVariant = variant;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_platformVariant == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    switch (_platformVariant!) {
      case PlatformVariant.mobile:
        return const MobileRecyclingApp();
      case PlatformVariant.wear:
        return const WearRecyclingApp();
      case PlatformVariant.tv:
        return const TvRecyclingApp();
    }
  }
}

// Mobile app - full featured
class MobileRecyclingApp extends StatefulWidget {
  const MobileRecyclingApp({super.key});

  @override
  State<MobileRecyclingApp> createState() => _MobileRecyclingAppState();
}

class _MobileRecyclingAppState extends State<MobileRecyclingApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CameraScreen(),
    const ServicesScreen(),
    const EducationalScreen(),
    const GamificationScreen(),
    // const LocationsScreen(),
    // const ContactScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'Camera',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              activeIcon: Icon(Icons.build),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Impact',
            ),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Wear-specific home screen - simplified for watch display
class WearHomeScreen extends StatelessWidget {
  const WearHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KL Recycling'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        toolbarHeight: 40,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Quick action buttons for wear
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WearActionButton(
                    icon: Icons.local_shipping,
                    label: 'Container Quote',
                    onTap: () => _navigateToServices(context),
                  ),
                  const SizedBox(height: 16),
                  WearActionButton(
                    icon: Icons.recycling,
                    label: 'Scrap Pickup',
                    onTap: () => _navigateToScrapPickup(context),
                  ),
                  const SizedBox(height: 16),
                  WearActionButton(
                    icon: Icons.phone,
                    label: 'Call Us',
                    onTap: () => _callBusiness(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToServices(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Container quote available - check mobile app')),
    );
  }

  void _navigateToScrapPickup(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scrap pickup available - check mobile app')),
    );
  }

  void _callBusiness(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call ${AppConstants.phoneNumber}')),
    );
  }
}

// Simplified button for wear OS
class WearActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const WearActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Wear OS app - simplified for watches
class WearRecyclingApp extends StatelessWidget {
  const WearRecyclingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${AppConstants.appName} - Wear',
      theme: AppTheme.lightTheme,
      home: const WearHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Android TV app - focusable navigation
class TvRecyclingApp extends StatefulWidget {
  const TvRecyclingApp({super.key});

  @override
  State<TvRecyclingApp> createState() => _TvRecyclingAppState();
}

class _TvRecyclingAppState extends State<TvRecyclingApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ServicesScreen(),
    const LocationsScreen(),
    const ContactScreen(),
  ]; // Exclude camera for TV

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${AppConstants.appName} - TV',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              activeIcon: Icon(Icons.build),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'Locations',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.phone_outlined),
              activeIcon: Icon(Icons.phone),
              label: 'Contact',
            ),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

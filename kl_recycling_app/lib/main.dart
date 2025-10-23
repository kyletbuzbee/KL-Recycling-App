import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:kl_recycling_app/config/theme.dart';
import 'package:kl_recycling_app/config/constants.dart';
import 'package:kl_recycling_app/providers/camera_provider.dart';
import 'package:kl_recycling_app/providers/business_customer_provider.dart';
import 'package:kl_recycling_app/models/photo_estimate.dart' as models;
import 'package:kl_recycling_app/providers/gamification_provider.dart';
import 'package:kl_recycling_app/screens/services/services_screen.dart';
import 'package:kl_recycling_app/screens/home_screen.dart';
import 'package:kl_recycling_app/screens/locations_screen.dart';
import 'package:kl_recycling_app/screens/contact_screen.dart';
import 'package:kl_recycling_app/screens/educational_screen.dart';
import 'package:kl_recycling_app/screens/gamification_screen.dart';
import 'package:kl_recycling_app/screens/business_customer_management_screen.dart';
import 'package:kl_recycling_app/services/notification_service.dart';
import 'package:kl_recycling_app/services/ai/weight_prediction_service.dart' as ai_service;
import 'package:kl_recycling_app/widgets/common/custom_card.dart';
import 'package:kl_recycling_app/widgets/common/photo_guidance_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Skip Firebase initialization for now to prevent crashes
  print('Firebase initialization skipped for testing');

  // Initialize notification service (non-Firebase)
  try {
    await NotificationService.initialize();
    print('Notification service initialized');
  } catch (e) {
    print('Notification service initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => BusinessCustomerProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
      ],
      child: const KLRecyclingApp(),
    ),
  );
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.showTutorial = false});

  final bool showTutorial;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  late CameraProvider _cameraProvider;
  models.PhotoQuality _currentQuality = models.PhotoQuality.fair;
  List<String> _currentTips = [];
  bool _showTutorial = false;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _checkFirstTimeUser();
    _simulatePhotoAnalysis();
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
    if (!mounted) return;

    // Only dispose on inactive, let resumed state handle reinitialization
    if (state == AppLifecycleState.inactive) {
      _cameraProvider.disposeCamera();
    }
  }

  @override
  void didUpdateWidget(CameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize if needed when widget updates
    if (_cameraProvider.controller == null || !_cameraProvider.isInitialized) {
      _initializeCamera();
    }
  }

  Future<void> _checkFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isFirstTime = prefs.getBool('camera_tutorial_shown') ?? true;
      if (_isFirstTime && mounted) {
        setState(() {
          _showTutorial = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking first-time user: $e');
    }
  }

  void _simulatePhotoAnalysis() {
    // Simulate dynamic photo quality analysis
    // In a real implementation, this would analyze the camera feed
    _currentTips = [
      'Consider moving closer to fill the frame with metal',
      'Ensure good lighting for better AI accuracy',
      'Avoid complex backgrounds for optimal results',
    ];
    setState(() {});
  }

  void _dismissTutorial() {
    setState(() {
      _showTutorial = false;
      _isFirstTime = false;
    });
    // Mark as shown
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('camera_tutorial_shown', true);
    });
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

  Widget _buildCameraPreview(CameraController controller) {
    try {
      // Check if controller is properly initialized
      if (!controller.value.isInitialized) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Text(
              'Camera initializing...',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }

      return CameraPreview(controller);
    } catch (e) {
      debugPrint('Camera preview error: $e');
      return Container(
        color: Colors.black45,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off,
                color: Colors.white,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Camera preview\nunavailable',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
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
          // Safe CameraPreview with error handling
          SizedBox.expand(
            child: _buildCameraPreview(cameraProvider.controller!),
          ),

          // Framing overlay with better design
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(20),
          ),

          // Add dash pattern to framing guide
          Positioned.fill(
            child: CustomPaint(
              painter: DashedBorderPainter(),
            ),
          ),

          // Photo Guidance Overlay - only show dismissible tutorial
          if (_showTutorial)
            Positioned.fill(
              child: PhotoGuidanceOverlay(
                currentQuality: _currentQuality,
                currentTips: _currentTips,
                showTutorial: _showTutorial,
                isProcessing: false,
                onDismiss: _dismissTutorial,
              ),
            ),

          // Enhanced capture button with better positioning
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dismissible tutorial overlay
          if (_showTutorial)
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissTutorial,
                child: const SizedBox.expand(),
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

  late ai_service.EnhancedWeightPredictionService _aiService;
  ai_service.WeightPredictionResult? _aiPrediction;
  bool _isAnalyzing = false;
  bool _serviceInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAIService();
  }

  @override
  void dispose() {
    if (_serviceInitialized) {
      _aiService.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeAIService() async {
    try {
      _aiService = ai_service.EnhancedWeightPredictionService();
      await _aiService.initialize();
      _serviceInitialized = true;

      // Now run analysis
      await _analyzeImageAI();
    } catch (e) {
      debugPrint('AI service initialization failed: $e');
      // Continue with manual estimation only
      setState(() {
        _serviceInitialized = false;
      });
    }
  }

  Future<void> _analyzeImageAI() async {
    if (_selectedMaterial == models.MaterialType.unknown || !_serviceInitialized) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _aiService.predictWeightFromImage(
        imagePath: widget.imagePath,
        materialType: _selectedMaterial,
        manualEstimate: _estimatedWeight > 0 ? _estimatedWeight : null,
      );

      if (mounted) {
        setState(() {
          _aiPrediction = result;
          _isAnalyzing = false;

          // Auto-suggest AI weight if user hasn't entered anything
          if (_estimatedWeight == 0.0 && result.estimatedWeight > 0) {
            _estimatedWeight = result.estimatedWeight;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI analysis failed: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _onMaterialChanged(models.MaterialType material) {
    setState(() {
      _selectedMaterial = material;
      // Clear previous AI result when material changes
      _aiPrediction = null;
    });
    // Re-analyze with new material
    _analyzeImageAI();
  }

  @override
  Widget build(BuildContext context) {
    final isMaterialSelected = _selectedMaterial != models.MaterialType.unknown;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Weight Estimation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: isMaterialSelected && _estimatedWeight > 0 ? _saveEstimate : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: (isMaterialSelected && _estimatedWeight > 0)
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Photo display with ML indicators
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(File(widget.imagePath)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // ML processing indicator
                  if (_isAnalyzing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Analyzing metal weight...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // AI result indicator
                  if (_aiPrediction != null && !_isAnalyzing)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                        color: _aiPrediction!.confidenceColor.withValues(alpha: 1.0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_aiPrediction!.confidenceDescription} Confidence',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // AI Results Card
            if (_aiPrediction != null && !_isAnalyzing)
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomCard(
                  padding: const EdgeInsets.all(20),
                  variant: CardVariant.filled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.science,
                            color: _aiPrediction!.confidenceColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Weight Analysis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _aiPrediction!.confidenceColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_aiPrediction!.estimatedWeight.toStringAsFixed(1)} lbs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _aiPrediction!.confidenceColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Estimated weight based on enhanced AI analysis with TensorFlow Lite',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // AI Factors
                      if (_aiPrediction!.factors.isNotEmpty) ...[
                        const Text(
                          'How it was calculated:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._aiPrediction!.factors.take(3).map((factor) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 8, right: 12),
                                decoration: BoxDecoration(
                                  color: _aiPrediction!.confidenceColor,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  factor,
                                  style: const TextStyle(fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 12),
                      ],
                      // Suggestions
                      if (_aiPrediction!.suggestions.isNotEmpty &&
                          _aiPrediction!.suggestions.first != 'Photo analysis looks good - weight estimate should be reliable') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _aiPrediction!.suggestions.first,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Manual Entry Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Material & Manual Estimate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isMaterialSelected ? AppColors.primary : Colors.grey,
                    ),
                  ),
                  if (!isMaterialSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Select a material to enable AI analysis',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
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
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Manual weight input
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _estimatedWeight > 0 ? _estimatedWeight.toStringAsFixed(1) : '',
                          decoration: InputDecoration(
                            labelText: _aiPrediction != null
                              ? 'Override AI Weight (lbs)'
                              : 'Enter Weight (lbs)',
                            border: const OutlineInputBorder(),
                            hintText: _aiPrediction != null
                              ? '${_aiPrediction!.estimatedWeight.toStringAsFixed(1)}'
                              : null,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _estimatedWeight = double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                      ),
                      if (_aiPrediction != null)
                        IconButton(
                          icon: const Icon(Icons.restore),
                          tooltip: 'Use AI estimate',
                          onPressed: () {
                            setState(() {
                              _estimatedWeight = _aiPrediction!.estimatedWeight;
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Any special details about this material',
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 32),

                  // Confidence indicator and submit
                  if (_aiPrediction != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _aiPrediction!.confidenceColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _aiPrediction!.confidenceScore >= 0.6 ? Icons.check_circle : Icons.warning,
                            color: _aiPrediction!.confidenceColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_aiPrediction!.confidenceDescription} confidence estimate - $_estimatedWeight lbs',
                              style: TextStyle(
                                color: _aiPrediction!.confidenceColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else if (isMaterialSelected && !_isAnalyzing) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Select material type above to enable AI weight analysis',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (isMaterialSelected && _estimatedWeight > 0) ? _saveEstimate : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isMaterialSelected && _estimatedWeight > 0
                          ? AppColors.primary
                          : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _aiPrediction != null ? 'Save AI-Verified Estimate' : 'Save Estimate',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _materialButton(models.MaterialType type, String label) {
    final isSelected = _selectedMaterial == type;

    return OutlinedButton(
      onPressed: () => _onMaterialChanged(type),
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
        estimatedValue: null,
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
    const BusinessCustomerManagementScreen(),
    const LocationsScreen(),
    const EducationalScreen(),
    const GamificationScreen(),
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
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Auto-switch based on system preference
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
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'Locations',
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
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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

// Custom painter for dashed border guide
class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashLength = 8.0;
    const gapLength = 4.0;
    final borderRect = Rect.fromLTRB(20, 20, size.width - 20, size.height - 20);

    _drawDashedRect(canvas, borderRect, dashLength, gapLength, paint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, double dashLength, double gapLength, Paint paint) {
    final width = rect.width;
    final height = rect.height;

    // Draw dashed lines for top, right, bottom, left
    _drawDashedLine(canvas, Offset(rect.left, rect.top), Offset(rect.right, rect.top), dashLength, gapLength, paint);
    _drawDashedLine(canvas, Offset(rect.right, rect.top), Offset(rect.right, rect.bottom), dashLength, gapLength, paint);
    _drawDashedLine(canvas, Offset(rect.right, rect.bottom), Offset(rect.left, rect.bottom), dashLength, gapLength, paint);
    _drawDashedLine(canvas, Offset(rect.left, rect.bottom), Offset(rect.left, rect.top), dashLength, gapLength, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, double dashLength, double gapLength, Paint paint) {
    final path = Path();
    final distance = (end - start).distance;
    final direction = (end - start) / distance;

    double currentDistance = 0;
    bool drawDash = true;

    while (currentDistance < distance) {
      final segmentLength = drawDash ? dashLength : gapLength;
      final endDistance = currentDistance + segmentLength;

      if (endDistance > distance) {
        final remainingDistance = distance - currentDistance;
        final endPoint = start + direction * remainingDistance;

        if (drawDash) {
          path.moveTo(start.dx, start.dy);
          path.lineTo(endPoint.dx, endPoint.dy);
        }
        break;
      }

      final segmentEnd = start + direction * endDistance;

      if (drawDash) {
        path.moveTo(start.dx, start.dy);
        path.lineTo(segmentEnd.dx, segmentEnd.dy);
      }

      start = segmentEnd;
      currentDistance = endDistance;
      drawDash = !drawDash;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Wear-specific home screen - simplified for watches
class WearRecyclingApp extends StatelessWidget {
  const WearRecyclingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${AppConstants.appName} - Wear',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
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

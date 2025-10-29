import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kl_recycling_app/firebase_options.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/core/constants.dart';

import 'package:kl_recycling_app/features/camera/logic/camera_provider.dart';
import 'package:kl_recycling_app/features/business_customer/logic/business_customer_provider.dart';
import 'package:kl_recycling_app/features/gamification/logic/gamification_provider.dart';
import 'package:kl_recycling_app/features/services/view/services/services_screen.dart';
import 'package:kl_recycling_app/features/home/view/home_screen.dart';
import 'package:kl_recycling_app/features/camera/view/camera_screen.dart';
import 'package:kl_recycling_app/features/locations/view/locations_screen.dart';
import 'package:kl_recycling_app/features/contact/view/contact_screen.dart';
import 'package:kl_recycling_app/features/educational/view/educational_screen.dart';
import 'package:kl_recycling_app/features/gamification/view/gamification_screen.dart';
import 'package:kl_recycling_app/features/admin/view/admin/admin_auth_screen.dart';
import 'package:kl_recycling_app/features/loyalty/logic/loyalty_provider.dart';
import 'package:kl_recycling_app/core/providers/theme_provider.dart';
import 'package:kl_recycling_app/features/challenges/logic/challenges_provider.dart';
import 'package:kl_recycling_app/features/notifications/logic/notification_service.dart';
import 'package:kl_recycling_app/core/services/ai/weight_prediction_service.dart' as ai_service;
import 'package:kl_recycling_app/features/loyalty/logic/loyalty_service.dart';
import 'package:kl_recycling_app/core/services/firebase_service.dart';
import 'package:kl_recycling_app/constants/app_icons.dart';
import 'package:kl_recycling_app/core/widgets/common/app_icon_tile.dart';
import 'package:kl_recycling_app/core/widgets/error_boundary.dart';
import 'package:kl_recycling_app/core/services/crash_reporting_service.dart';
import 'package:kl_recycling_app/core/services/analytics_service.dart';

// Platform-specific imports
import 'package:package_info_plus/package_info_plus.dart';

// Platform type enumeration
enum PlatformVariant {
  mobile,
  wear,
  tv,
}

void main() {
  runZonedGuarded(() async {
    FlutterError.onError = (errorDetails) {
      FlutterError.presentError(errorDetails);
      debugPrint('Flutter Error: ${errorDetails.exception}\n${errorDetails.stack}');
    };

    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables first
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('Environment variables loaded successfully');
    } catch (e) {
      debugPrint('Failed to load environment variables: $e');
    }

    // Initialize Firebase first
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      // Continue with limited functionality in demo mode
    }

    // Initialize operational readiness services - skip crash reporting for now to avoid crashes
    try {
      // Skip crash reporting initialization during app startup to avoid recursion
      AnalyticsService.initialize();
      debugPrint('Operational services initialized (skipping crash reporting)');
    } catch (e) {
      debugPrint('Failed to initialize operational services: $e');
    }

    // Initialize notification service (non-Firebase first)
    try {
      await NotificationService.initialize();
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Notification service initialization failed: $e');
    }

    // Initialize services after Firebase is ready
    final firebaseService = FirebaseService();
    final loyaltyService = LoyaltyService(firebaseService);

    final themeProvider = ThemeProvider();

    // Listen to loyalty tier changes and update theme
    LoyaltyEventService.tierChangeStream.listen((event) {
      themeProvider.updateFromLoyaltyTier(event.currentPoints);
    });

    // Simple error boundary without complex crash reporting
    runApp(
      AppErrorBoundary(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CameraProvider()),
            ChangeNotifierProvider(create: (_) => BusinessCustomerProvider()),
            ChangeNotifierProvider(create: (_) => GamificationProvider()),
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider(create: (_) => ChallengesProvider()),
            ChangeNotifierProvider(
              create: (context) => LoyaltyProvider(loyaltyService),
            ),
          ],
          child: const KLRecyclingApp(),
        ),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('Uncaught async error: $error\n$stackTrace');
  });
}





class KLRecyclingApp extends StatefulWidget {
  const KLRecyclingApp({super.key});

  @override
  State<KLRecyclingApp> createState() => _KLRecyclingAppState();
}

class _KLRecyclingAppState extends State<KLRecyclingApp> {
  PlatformVariant _platformVariant = PlatformVariant.mobile; // Default to mobile

  @override
  void initState() {
    super.initState();
    // Async platform detection - don't block UI
    _initializePlatformDetection();
  }

  Future<void> _initializePlatformDetection() async {
    try {
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

      if (mounted) {  // Only update if widget is still mounted
        setState(() {
          _platformVariant = variant;
        });
      }
    } catch (e) {
      debugPrint('Platform detection failed, using mobile default: $e');
      // Keep mobile as default
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always return an app based on current variant
    switch (_platformVariant) {
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
      home: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.onSurfaceSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: AppIconTile(
                assetPath: AppIcons.homeDashboard,
                semanticLabel: 'Home dashboard',
                width: 24,
                height: 24,
              ),
              activeIcon: AppIconTile(
                assetPath: AppIcons.homeDashboard,
                semanticLabel: 'Home dashboard',
                width: 24,
                height: 24,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: AppIconTile(
                assetPath: AppIcons.cameraEstimate,
                semanticLabel: 'Camera photo estimate',
                width: 24,
                height: 24,
              ),
              activeIcon: AppIconTile(
                assetPath: AppIcons.cameraEstimate,
                semanticLabel: 'Camera photo estimate',
                width: 24,
                height: 24,
              ),
              label: 'Camera',
            ),
            BottomNavigationBarItem(
              icon: AppIconTile(
                assetPath: AppIcons.servicesBuild,
                semanticLabel: 'Construction services',
                width: 24,
                height: 24,
              ),
              activeIcon: AppIconTile(
                assetPath: AppIcons.servicesBuild,
                semanticLabel: 'Construction services',
                width: 24,
                height: 24,
              ),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: AppIconTile(
                assetPath: AppIcons.locationPinService,
                semanticLabel: 'Service locations',
                width: 24,
                height: 24,
              ),
              activeIcon: AppIconTile(
                assetPath: AppIcons.locationPinService,
                semanticLabel: 'Service locations',
                width: 24,
                height: 24,
              ),
              label: 'Locations',
            ),
            BottomNavigationBarItem(
              icon: AppIconTile(
                assetPath: AppIcons.educationSchool,
                semanticLabel: 'Educational resources',
                width: 24,
                height: 24,
              ),
              activeIcon: AppIconTile(
                assetPath: AppIcons.educationSchool,
                semanticLabel: 'Educational resources',
                width: 24,
                height: 24,
              ),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: AppIconTile(
                assetPath: AppIcons.impactSustainability,
                semanticLabel: 'Sustainability impact',
                width: 24,
                height: 24,
              ),
              activeIcon: AppIconTile(
                assetPath: AppIcons.impactSustainability,
                semanticLabel: 'Sustainability impact',
                width: 24,
                height: 24,
              ),
              label: 'Impact',
            ),
          ],
        ),
      ),
      routes: {
        '/admin': (context) => const AdminAuthScreen(),
        '/admin/dashboard': (context) => const AdminAuthScreen(), // Consider if this duplicate is needed
        // Hidden route for emergency admin access (debug builds only)
        if (kDebugMode) '/superadmin': (context) => const AdminAuthScreen(),
      },
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
                    assetPath: 'assets/icons/container_roll_off.png',
                    label: 'Container Quote',
                    onTap: () => _navigateToServices(context),
                  ),
                  const SizedBox(height: 16),
                  WearActionButton(
                    assetPath: 'assets/icons/metal_steel_fragments.png',
                    label: 'Scrap Pickup',
                    onTap: () => _navigateToScrapPickup(context),
                  ),
                  const SizedBox(height: 16),
                  WearActionButton(
                    assetPath: 'assets/icons/contact_phone.png',
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
  final IconData? icon;
  final String? assetPath;
  final String label;
  final VoidCallback onTap;

  const WearActionButton({
    this.icon,
    this.assetPath,
    required this.label,
    required this.onTap,
    super.key,
  }) : assert(icon != null || assetPath != null, 'Either icon or assetPath must be provided');

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
            assetPath != null
                ? AppIconTile(
                    assetPath: assetPath!,
                    semanticLabel: 'Icon for ${label.toLowerCase()}',
                    width: 24,
                    height: 24,
                    color: AppColors.primary,
                  )
                : Icon(icon, color: AppColors.primary, size: 24),
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



// Wear-specific home screen - simplified for watches
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.onSurfaceSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: AppIconTile(
                assetPath: AppIcons.homeDashboard,
                semanticLabel: 'Home dashboard',
                width: 24,
                height: 24,
              ),
              activeIcon: AppIconTile(
                assetPath: AppIcons.homeDashboard,
                semanticLabel: 'Home dashboard',
                width: 24,
                height: 24,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: AppIconTile(
                assetPath: AppIcons.servicesBuild,
                semanticLabel: 'Construction services',
                width: 24,
                height: 24,
              ),
              activeIcon: AppIconTile(
                assetPath: AppIcons.servicesBuild,
                semanticLabel: 'Construction services',
                width: 24,
                height: 24,
              ),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: AppIconTile(
                assetPath: AppIcons.locationPinService,
                semanticLabel: 'Service locations',
                width: 24,
                height: 24,
              ),
              activeIcon: AppIconTile(
                assetPath: AppIcons.locationPinService,
                semanticLabel: 'Service locations',
                width: 24,
                height: 24,
              ),
              label: 'Locations',
            ),
            BottomNavigationBarItem(
              icon: AppIconTile(
                assetPath: AppIcons.contactPhone,
                semanticLabel: 'Contact information',
                width: 24,
                height: 24,
              ),
              activeIcon: AppIconTile(
                assetPath: AppIcons.contactPhone,
                semanticLabel: 'Contact information',
                width: 24,
                height: 24,
              ),
              label: 'Contact',
            ),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

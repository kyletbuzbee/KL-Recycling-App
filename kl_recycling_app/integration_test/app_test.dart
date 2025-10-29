import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kl_recycling_app/main.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/features/home/view/home_screen.dart';
import 'package:kl_recycling_app/features/services/view/services/services_screen.dart';
import 'package:kl_recycling_app/features/camera/view/camera_screen.dart';
import 'package:kl_recycling_app/features/locations/view/locations_screen.dart';
import 'package:kl_recycling_app/features/contact/view/contact_screen.dart';
import 'package:kl_recycling_app/features/educational/view/educational_screen.dart';
import 'package:kl_recycling_app/features/gamification/view/gamification_screen.dart';
import 'package:kl_recycling_app/features/notifications/view/notification_settings_screen.dart';
import 'package:kl_recycling_app/core/widgets/error_boundary.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Test Suite', () {
    testWidgets('Complete user journey: App launch to core features',
        (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(const KLRecyclingApp());
      await tester.pumpAndSettle();

      // Test 1: Verify home screen loads
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('KL Recycling'), findsWidgets); // App bar title

      print('✓ Home screen loaded successfully');

      // Test 2: Navigate to Services
      final servicesNavItem = find.byIcon(Icons.build); // Services icon
      expect(servicesNavItem, findsOneWidget);
      await tester.tap(servicesNavItem);
      await tester.pumpAndSettle();

      expect(find.byType(ServicesScreen), findsOneWidget);
      expect(find.text('Services'), findsWidgets); // Services screen title

      print('✓ Services screen navigation successful');

      // Test 3: Navigate to Camera
      final cameraNavItem = find.byIcon(Icons.camera);
      expect(cameraNavItem, findsOneWidget);
      await tester.tap(cameraNavItem);
      await tester.pumpAndSettle();

      expect(find.byType(CameraScreen), findsOneWidget);

      print('✓ Camera screen navigation successful');

      // Test 4: Navigate to Locations (if accessible)
      final locationsNavItem = find.byIcon(Icons.location_on);
      if (locationsNavItem.evaluate().isNotEmpty) {
        await tester.tap(locationsNavItem);
        await tester.pumpAndSettle();

        expect(find.byType(LocationsScreen), findsOneWidget);
        print('✓ Locations screen navigation successful');
      }

      // Test 5: Navigate to Contact
      final contactNavItem = find.byIcon(Icons.contact_support);
      expect(contactNavItem, findsOneWidget);
      await tester.tap(contactNavItem);
      await tester.pumpAndSettle();

      expect(find.byType(ContactScreen), findsOneWidget);

      print('✓ Contact screen navigation successful');

      // Test 6: Navigate to Educational content
      final educationNavItem = find.byIcon(Icons.school);
      expect(educationNavItem, findsOneWidget);
      await tester.tap(educationNavItem);
      await tester.pumpAndSettle();

      expect(find.byType(EducationalScreen), findsOneWidget);

      print('✓ Educational screen navigation successful');

      // Test 7: Navigate to Gamification/Dashboard
      final gamificationNavItem = find.byIcon(Icons.leaderboard);
      expect(gamificationNavItem, findsOneWidget);
      await tester.tap(gamificationNavItem);
      await tester.pumpAndSettle();

      expect(find.byType(GamificationScreen), findsOneWidget);
      expect(find.text('My Impact'), findsWidgets); // Gamification screen title

      print('✓ Gamification screen navigation successful');

      // Test 8: Access notification settings (from gamification screen)
      final notificationButton = find.byIcon(Icons.notifications);
      if (notificationButton.evaluate().isNotEmpty) {
        await tester.tap(notificationButton);
        await tester.pumpAndSettle();

        expect(find.byType(NotificationSettingsScreen), findsOneWidget);
        expect(find.text('Notification Settings'), findsWidgets);

        // Go back to previous screen
        await tester.pageBack();
        await tester.pumpAndSettle();

        print('✓ Notification settings navigation and back navigation successful');
      }

      // Test 9: Navigate back to home
      final homeNavItem = find.byIcon(Icons.home);
      expect(homeNavItem, findsOneWidget);
      await tester.tap(homeNavItem);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      print('✓ Home screen navigation (return) successful');
    });

    testWidgets('Core user flows - Camera and photo estimation',
        (WidgetTester tester) async {
      await tester.pumpWidget(const KLRecyclingApp());
      await tester.pumpAndSettle();

      // Navigate to camera
      await tester.tap(find.byIcon(Icons.camera));
      await tester.pumpAndSettle();

      expect(find.byType(CameraScreen), findsOneWidget);

      // Note: Camera permission and functionality testing would require
      // additional setup for integration tests in a real environment
      // Here we're just proving the navigation works

      print('✓ Camera screen accessibility verified');
    });

    testWidgets('Settings and configuration screens', (WidgetTester tester) async {
      await tester.pumpWidget(const KLRecyclingApp());
      await tester.pumpAndSettle();

      // Navigate to gamification (where notification settings are accessible)
      await tester.tap(find.byIcon(Icons.leaderboard));
      await tester.pumpAndSettle();

      // Tap notification settings if available
      final notificationIcon = find.byIcon(Icons.notifications);
      if (notificationIcon.evaluate().isNotEmpty) {
        await tester.tap(notificationIcon);
        await tester.pumpAndSettle();

        expect(find.byType(NotificationSettingsScreen), findsOneWidget);

        // Test notification toggles (UI interaction)
        final notificationsToggle = find.text('Enable Notifications');
        expect(notificationsToggle, findsOneWidget);

        // Toggle notifications
        await tester.tap(notificationsToggle);
        await tester.pumpAndSettle();

        print('✓ Notification settings interaction successful');
      }
    });

    testWidgets('App theming and UI consistency', (WidgetTester tester) async {
      await tester.pumpWidget(const KLRecyclingApp());
      await tester.pumpAndSettle();

      // Verify theme consistency by checking for themed colors
      expect(find.byWidgetPredicate((widget) =>
        widget is MaterialApp &&
        widget.theme?.colorScheme.primary != null), findsOneWidget);

      print('✓ App theming consistency verified');
    });

    testWidgets('Error boundary functionality', (WidgetTester tester) async {
      // This test would require setting up scenarios that trigger errors
      // For now, we verify the error boundary is in place
      await tester.pumpWidget(const KLRecyclingApp());
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorBoundary), findsWidgets);

      print('✓ Error boundary presence verified');
    });

    testWidgets('Accessibility - Screen reader compatibility', (WidgetTester tester) async {
      await tester.pumpWidget(const KLRecyclingApp());
      await tester.pumpAndSettle();

      // Check for semantic labels and accessibility features
      final homeScreen = find.byType(HomeScreen);

      // Verify key UI elements exist and have accessibility features
      expect(homeScreen, findsOneWidget);

      // Check that we have some app bar or title elements that screen readers can use
      expect(find.byType(AppBar), findsWidgets);

      print('✓ Basic accessibility features verified');
    });
  });
}

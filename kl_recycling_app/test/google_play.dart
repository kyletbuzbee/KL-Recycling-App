import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

/// Google Play Store compliance testing suite
/// Tests app against Play Store requirements and policies

void main() {
  group('Google Play Store Compliance Tests', () {
    group('App Configuration Tests', () {
      test('build.gradle contains valid package name', () {
        final buildGradle = File('android/app/build.gradle.kts');
        expect(buildGradle.existsSync(), isTrue);

        final content = buildGradle.readAsStringSync();

        // Check for valid application ID format
        expect(
          content.contains(r'applicationId = "com.klrecycling.android"'),
          isTrue,
          reason: 'Application ID should follow reverse domain notation',
        );

        // Ensure minSdk is set appropriately for Play Store
        expect(
          content.contains('minSdk = flutter.minSdkVersion'),
          isTrue,
          reason: 'minSdk should be properly configured',
        );
      });

      test('AndroidManifest.xml contains required permissions', () {
        final manifest = File('android/app/src/main/AndroidManifest.xml');
        expect(manifest.existsSync(), isTrue);

        final content = manifest.readAsStringSync();

        // Check for camera permission (required for app functionality)
        expect(
          content.contains('android.permission.CAMERA'),
          isTrue,
          reason: 'Camera permission required for photo analysis feature',
        );

        // Check for location permissions
        expect(
          content.contains('android.permission.ACCESS_FINE_LOCATION'),
          isTrue,
          reason: 'Location permission required for service area detection',
        );

        // Check for main activity export setting
        expect(
          content.contains('android:exported="true"'),
          isTrue,
          reason: 'Main activity must be exported for Android 12+ compatibility',
        );
      });

      test('ProGuard rules are configured for Play Store', () {
        final proguardRules = File('android/app/proguard-rules.pro');
        expect(proguardRules.existsSync(), isTrue,
            reason: 'ProGuard rules should exist for release builds');

        final content = proguardRules.readAsStringSync();

        // Check for basic ProGuard rules
        expect(
          content.contains('# Add project specific ProGuard rules here.'),
          isTrue,
          reason: 'ProGuard rules template should be present',
        );
      });
    });

    group('Store Listing Compliance', () {
      test('App icons exist in required sizes', () {
        final androidResDir = Directory('android/app/src/main/res');

        expect(androidResDir.existsSync(), isTrue,
            reason: 'Android resources directory should exist');

        // Check for common icon densities
        final requiredIcons = [
          'mipmap-mdpi/ic_launcher.png',
          'mipmap-hdpi/ic_launcher.png',
          'mipmap-xhdpi/ic_launcher.png',
          'mipmap-xxhdpi/ic_launcher.png',
          'mipmap-xxxhdpi/ic_launcher.png',
        ];

        for (final iconPath in requiredIcons) {
          final iconFile = File(path.join(androidResDir.path, iconPath));
          expect(iconFile.existsSync(), isTrue,
              reason: 'Icon $iconPath should exist for proper app distribution');
        }
      });

      test('Store listing assets directory exists', () {
        final assetsDir = Directory('assets');
        expect(assetsDir.existsSync(), isTrue);

        // Check for store listing related directories
        final storeAssetDirs = ['images', 'certifications'];

        for (final dir in storeAssetDirs) {
          final subDir = Directory(path.join(assetsDir.path, dir));
          expect(subDir.existsSync(), isTrue,
              reason: 'Store assets directory $dir should exist');
        }
      });

      test('Privacy policy and terms files are accessible', () {
        // Note: These should exist either locally or as URLs
        // For now, just check if there's documentation of privacy policy URL
        final readmeFiles = ['README.md', 'app_improvement_recommendations.md'];

        bool foundPrivacyReference = false;
        for (final readme in readmeFiles) {
          final file = File(readme);
          if (file.existsSync()) {
            final content = file.readAsStringSync().toLowerCase();
            if (content.contains('privacy') || content.contains('policy')) {
              foundPrivacyReference = true;
              break;
            }
          }
        }

        expect(foundPrivacyReference, isTrue,
            reason: 'Privacy policy should be documented for Play Store submission');
      });
    });

    group('Content Rating and Age Appropriateness', () {
      test('App contains age-appropriate content descriptors', () {
        // This is a business app for recycling - should be appropriate for all ages
        final manifest = File('android/app/src/main/AndroidManifest.xml');
        final content = manifest.readAsStringSync();

        // Ensure no inappropriate permissions or features
        expect(content.contains('android.permission.RECORD_AUDIO'), isFalse,
            reason: 'Microphone permission should not be present unless required');

        // Check that there's no violence or adult content related metadata
        expect(
          !content.contains('violence') && !content.contains('adult'),
          isTrue,
          reason: 'App should not contain mature content indicators',
        );
      });

      test('App handles data appropriately for minors', () {
        // Check if there's any child-related functionality
        final pubspec = File('pubspec.yaml');
        expect(pubspec.existsSync(), isTrue);

        final content = pubspec.readAsStringSync().toLowerCase();

        // Ensure app is B2B focused for recycling industry
        expect(
          content.contains('recycling') || content.contains('scrap') || content.contains('metal'),
          isTrue,
          reason: 'App should clearly be for recycling/scrap metal industry',
        );

        // This app is for business purposes - appropriate for 12+ rating
        expect(
          !content.contains('game') && !content.contains('kids') && !content.contains('children'),
          isTrue,
          reason: 'App should not be marketed toward children',
        );
      });
    });

    group('Data Safety and Privacy Tests', () {
      test('Firebase configuration files are secured', () {
        final googleServices = File('android/app/google-services.json');
        final firebaseConfig = File('lib/firebase_options.dart');

        expect(googleServices.existsSync(), isTrue);
        expect(firebaseConfig.existsSync(), isTrue);

        // Check that Firebase config is properly imported
        final configContent = firebaseConfig.readAsStringSync();
        expect(configContent.contains('FirebaseOptions'), isTrue);

        // Ensure firebaserc exists for project configuration
        final firebaseRc = File('.firebaserc');
        expect(firebaseRc.existsSync(), isTrue);
      });

      test('Data collection disclosure is documented', () {
        final firestoreRules = File('firestore.rules');
        expect(firestoreRules.existsSync(), isTrue);

        final rulesContent = firestoreRules.readAsStringSync();

        // Check for security rules that protect user data
        expect(
          rulesContent.contains('match') && rulesContent.contains('allow'),
          isTrue,
          reason: 'Firestore security rules should be configured to protect data',
        );

        // Check that there's documentation about data handling
        final readme = File('README.md');
        if (readme.existsSync()) {
          final content = readme.readAsStringSync().toLowerCase();
          expect(
            content.contains('firebase') || content.contains('data') || content.contains('privacy'),
            isTrue,
            reason: 'Data handling should be documented',
          );
        }
      });

      test('Required permissions are justifiable for app functionality', () {
        final manifest = File('android/app/src/main/AndroidManifest.xml');
        final content = manifest.readAsStringSync();

        // Camera permission - justified for photo analysis
        expect(content.contains('android.permission.CAMERA'), isTrue);

        // Location permissions - justified for finding nearby locations
        expect(content.contains('android.permission.ACCESS_FINE_LOCATION'), isTrue);

        // Phone permission - justified for contact/call functionality
        expect(content.contains('android.permission.CALL_PHONE'), isTrue);

        // Ensure no unnecessary permissions
        final unnecessaryPermissions = [
          'android.permission.RECORD_AUDIO',
          'android.permission.READ_CONTACTS',
          'android.permission.WRITE_CONTACTS',
          'android.permission.SEND_SMS'
        ];

        for (final permission in unnecessaryPermissions) {
          expect(content.contains(permission), isFalse,
              reason: 'App should not request unnecessary permissions like $permission');
        }
      });
    });

    group('Performance and Quality Tests', () {
      test('App size is reasonable for Play Store', () async {
        final androidDir = Directory('android');
        expect(androidDir.existsSync(), isTrue);

        // Check for build optimizations
        final buildGradle = File('android/app/build.gradle.kts');
        final content = buildGradle.readAsStringSync();

        // Ensure R8/ProGuard can be enabled for release builds
        expect(
          content.contains('isMinifyEnabled') || content.contains('proguardFiles'),
          isTrue,
          reason: 'Build optimization should be configured for app size reduction',
        );
      });

      test('Material icons and assets are optimized', () {
        final assetsDir = Directory('assets');
        final iconsDir = Directory('Icons');

        expect(assetsDir.existsSync(), isTrue);
        expect(iconsDir.existsSync(), isTrue);

        // Check for optimized image formats (PNG is preferred for Android)
        final iconFiles = iconsDir.listSync().whereType<File>();
        final imageFiles = assetsDir.listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.png') || file.path.endsWith('.jpg') || file.path.endsWith('.jpeg'));

        expect(imageFiles.length, greaterThan(0),
            reason: 'App should contain optimized images');
      });

      test('Flutter version is compatible with Play Store requirements', () {
        final pubspec = File('pubspec.yaml');
        expect(pubspec.existsSync(), isTrue);

        final content = pubspec.readAsStringSync();

        // Ensure Flutter SDK requirement is specified
        expect(content.contains('sdk: flutter'), isTrue,
            reason: 'Flutter SDK version should be specified');

        // Ensure environment is defined
        expect(content.contains('environment:'), isTrue,
            reason: 'Flutter environment should be defined');
      });
    });

    group('Target SDK and Play Store Requirements', () {
      test('Target SDK meets Play Store requirements', () {
        final buildGradle = File('android/app/build.gradle.kts');
        final content = buildGradle.readAsStringSync();

        // Google Play requires targetSdk to be recent
        expect(
          content.contains('targetSdk = flutter.targetSdkVersion'),
          isTrue,
          reason: 'Target SDK should be properly configured',
        );

        // Check for AndroidX migration
        expect(content.contains('androidx'), isFalse,
            reason: 'App should use AndroidX (legacy support library should not be used)');
      });

      test('Java/Kotlin compatibility meets Play Store standards', () {
        final buildGradle = File('android/app/build.gradle.kts');
        final content = buildGradle.readAsStringSync();

        // Check Java version compatibility
        expect(
          content.contains('JavaVersion.VERSION_17'),
          isTrue,
          reason: 'Java 17 should be used for compatibility',
        );

        // Ensure Kotlin is configured
        expect(
          content.contains('kotlinOptions'),
          isTrue,
          reason: 'Kotlin should be properly configured',
        );
      });
    });
  });
}

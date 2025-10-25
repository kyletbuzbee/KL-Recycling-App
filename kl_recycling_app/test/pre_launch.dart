import 'dart:io';
import 'package:flutter_test/flutter_test.dart' as flutter_test;

/// Pre-Launch Testing Suite for Play Store Submission
/// Comprehensive testing to ensure app meets all Play Store requirements

class PreLaunchTester {
  static const List<String> requiredPermissions = [
    'android.permission.CAMERA',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.CALL_PHONE',
  ];

  static const List<String> restrictedPermissions = [
    'android.permission.RECORD_AUDIO',
    'android.permission.READ_CONTACTS',
    'android.permission.WRITE_CONTACTS',
    'android.permission.SEND_SMS',
    'android.permission.READ_SMS',
    'android.permission.RECEIVE_SMS',
  ];

  /// Check if all required files exist for Play Store submission
  static Future<Map<String, bool>> checkRequiredFiles() async {
    final results = <String, bool>{};

    // Android build files
    results['build.gradle (app)'] = File('android/app/build.gradle.kts').existsSync();
    results['build.gradle (project)'] = File('android/build.gradle.kts').existsSync();
    results['AndroidManifest.xml'] = File('android/app/src/main/AndroidManifest.xml').existsSync();
    results['ProGuard rules'] = File('android/app/proguard-rules.pro').existsSync();

    // Flutter assets
    results['pubspec.yaml'] = File('pubspec.yaml').existsSync();
    results['firebase_options.dart'] = File('lib/firebase_options.dart').existsSync();
    results['google-services.json (android)'] = File('android/app/google-services.json').existsSync();

    // Store listing assets would be checked in separate tests
    results['README.md'] = File('README.md').existsSync();
    results['Privacy policy documentation'] = _hasPrivacyPolicyDocumentation();

    return results;
  }

  /// Validate AndroidManifest.xml for Play Store compliance
  static Future<Map<String, dynamic>> validateManifest() async {
    final manifestFile = File('android/app/src/main/AndroidManifest.xml');
    final issues = <String>[];
    final warnings = <String>[];

    if (!manifestFile.existsSync()) {
      issues.add('AndroidManifest.xml does not exist');
      return {
        'valid': false,
        'issues': issues,
        'warnings': warnings,
        'permissions': [],
      };
    }

    final content = manifestFile.readAsStringSync();

    // Check for main activity export setting
    if (!content.contains('android:exported="true"')) {
      issues.add('Main activity must be exported for Android 12+ compatibility');
    }

    // Check required permissions
    for (final permission in requiredPermissions) {
      if (!content.contains(permission)) {
        issues.add('Missing required permission: $permission');
      }
    }

    // Check for restricted/unnecessary permissions
    for (final permission in restrictedPermissions) {
      if (content.contains(permission)) {
        warnings.add('Potentially unnecessary permission: $permission');
      }
    }

    // Check for proper intent filters
    if (!content.contains('android.intent.action.MAIN')) {
      issues.add('Missing MAIN intent filter');
    }

    if (!content.contains('android.intent.category.LAUNCHER')) {
      issues.add('Missing LAUNCHER intent filter');
    }

    // Extract all permissions for reporting
    final permissions = RegExp(r'android:name="android\.permission\.([^"]+)"')
        .allMatches(content)
        .map((match) => match.group(1)!)
        .toList();

    return {
      'valid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'permissions': permissions,
    };
  }

  /// Check build configuration for Play Store requirements
  static Future<Map<String, dynamic>> validateBuildConfig() async {
    final buildFile = File('android/app/build.gradle.kts');
    final issues = <String>[];
    final warnings = <String>[];

    if (!buildFile.existsSync()) {
      issues.add('build.gradle.kts does not exist');
      return {
        'valid': false,
        'issues': issues,
        'warnings': warnings,
        'minSdkVersion': null,
        'targetSdkVersion': null,
      };
    }

    final content = buildFile.readAsStringSync();

    // Check for application ID
    if (!content.contains('com.klrecycling.android')) {
      issues.add('Application ID does not match expected package name');
    }

    // Check for version configuration
    if (!content.contains('flutter.versionCode')) {
      warnings.add('Using default versionCode instead of flutter.versionCode');
    }

    if (!content.contains('flutter.versionName')) {
      warnings.add('Using default versionName instead of flutter.versionName');
    }

    // Check for signing configuration
    if (content.contains('signingConfigs.getByName("debug")')) {
      issues.add('Using debug signing config for release - must use proper signing config');
    }

    // Check for ProGuard/R8
    if (content.contains('isMinifyEnabled = false')) {
      warnings.add('Minification disabled - consider enabling for release builds');
    }

    // Check for build optimization
    if (content.contains('isShrinkResources = false')) {
      warnings.add('Resource shrinking disabled - consider enabling for release builds');
    }

    return {
      'valid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'minSdkVersion': _extractFlutterSdkVersion(content, 'minSdk'),
      'targetSdkVersion': _extractFlutterSdkVersion(content, 'targetSdk'),
    };
  }

  /// Validate Flutter configuration
  static Future<Map<String, dynamic>> validateFlutterConfig() async {
    final pubspecFile = File('pubspec.yaml');
    final issues = <String>[];
    final warnings = <String>[];

    if (!pubspecFile.existsSync()) {
      issues.add('pubspec.yaml does not exist');
      return {
        'valid': false,
        'issues': issues,
        'warnings': warnings,
        'flutterVersion': null,
        'dependencies': [],
      };
    }

    final content = pubspecFile.readAsStringSync();

    // Check Flutter SDK constraint
    if (!content.contains('sdk: flutter')) {
      issues.add('Flutter SDK constraint not specified');
    }

    // Check for required dependencies
    final requiredDeps = ['flutter', 'firebase_core'];
    for (final dep in requiredDeps) {
      if (!content.contains('$dep:')) {
        issues.add('Missing required dependency: $dep');
      }
    }

    // Extract SDK version constraint
    final sdkMatch = RegExp(r'sdk:\s*^3\.(\d+)\.(\d+)').firstMatch(content);
    String? flutterVersion;
    if (sdkMatch != null) {
      flutterVersion = '3.${sdkMatch.group(1)}.${sdkMatch.group(2)}';
    }

    return {
      'valid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'flutterVersion': flutterVersion,
      'dependencies': _extractDependencies(content),
    };
  }

  /// Generate pre-launch report
  static Future<String> generateReport() async {
    final buffer = StringBuffer();
    buffer.writeln('# 🎯 Play Store Pre-Launch Report\n');
    buffer.writeln('Generated on: ${DateTime.now()}\n');

    // File checks
    buffer.writeln('## 📁 File Existence Check');
    final files = await checkRequiredFiles();
    for (final entry in files.entries) {
      final status = entry.value ? '✅' : '❌';
      buffer.writeln('$status ${entry.key}');
    }
    buffer.writeln();

    // Manifest validation
    buffer.writeln('## 📱 Android Manifest Validation');
    final manifestResult = await validateManifest();
    _writeValidationResults(buffer, manifestResult);
    if (manifestResult['permissions'] != null) {
      buffer.writeln('**Permissions declared:**');
      for (final permission in manifestResult['permissions'] as List<String>) {
        buffer.writeln('- android.permission.$permission');
      }
      buffer.writeln();
    }

    // Build configuration
    buffer.writeln('## 🔧 Build Configuration Validation');
    final buildResult = await validateBuildConfig();
    _writeValidationResults(buffer, buildResult);
    buffer.writeln();

    // Flutter configuration
    buffer.writeln('## 🎯 Flutter Configuration Validation');
    final flutterResult = await validateFlutterConfig();
    _writeValidationResults(buffer, flutterResult);
    buffer.writeln();

    // Overall assessment
    final allValid = [
      manifestResult['valid'] as bool,
      buildResult['valid'] as bool,
      flutterResult['valid'] as bool,
      !files.containsValue(false),
    ].every((valid) => valid);

    buffer.writeln('## 🎯 Overall Assessment');
    if (allValid) {
      buffer.writeln('✅ **READY FOR PLAY STORE SUBMISSION**');
      buffer.writeln('All critical requirements have been validated.');
    } else {
      buffer.writeln('❌ **ISSUES FOUND**');
      buffer.writeln('Address the issues above before Play Store submission.');
    }

    return buffer.toString();
  }

  static bool _hasPrivacyPolicyDocumentation() {
    final readmeFiles = ['README.md', 'PRIVACY_POLICY.md', 'privacy_policy.md'];
    for (final file in readmeFiles) {
      if (File(file).existsSync()) {
        final content = File(file).readAsStringSync().toLowerCase();
        if (content.contains('privacy') && content.contains('policy')) {
          return true;
        }
      }
    }
    return false;
  }

  static String? _extractFlutterSdkVersion(String content, String sdkType) {
    final pattern = RegExp('$sdkType = flutter\\.$sdkType');
    return pattern.hasMatch(content) ? 'flutter.$sdkType' : null;
  }

  static List<String> _extractDependencies(String content) {
    final deps = <String>[];
    final lines = content.split('\n');
    bool inDependencies = false;

    for (final line in lines) {
      if (line.trim().startsWith('dependencies:')) {
        inDependencies = true;
        continue;
      }
      if (inDependencies && line.trim().startsWith('dev_dependencies:')) {
        break;
      }
      if (inDependencies && line.contains(': ')) {
        final dep = line.trim().split(':').first;
        if (dep.isNotEmpty && !dep.startsWith('#')) {
          deps.add(dep);
        }
      }
    }

    return deps;
  }

  static void _writeValidationResults(StringBuffer buffer, Map<String, dynamic> result) {
    if (result['issues'] != null && (result['issues'] as List).isNotEmpty) {
      buffer.writeln('**Issues:**');
      for (final issue in result['issues'] as List<String>) {
        buffer.writeln('🚫 $issue');
      }
    }

    if (result['warnings'] != null && (result['warnings'] as List).isNotEmpty) {
      buffer.writeln('**Warnings:**');
      for (final warning in result['warnings'] as List<String>) {
        buffer.writeln('⚠️ $warning');
      }
    }

    if ((result['issues'] as List).isEmpty && (result['warnings'] as List).isEmpty) {
      buffer.writeln('✅ No issues found');
    }
    buffer.writeln();
  }
}

void main() {
  flutter_test.group('Play Store Pre-Launch Testing', () {
    flutter_test.test('All required files exist', () async {
      final files = await PreLaunchTester.checkRequiredFiles();

      for (final entry in files.entries) {
        flutter_test.expect(entry.value, flutter_test.isTrue,
            reason: '${entry.key} is required for Play Store submission');
      }
    });

    flutter_test.test('AndroidManifest.xml meets Play Store requirements', () async {
      final result = await PreLaunchTester.validateManifest();

      flutter_test.expect(result['valid'], flutter_test.isTrue,
          reason: 'AndroidManifest.xml must be compliant for Play Store');
    });

    flutter_test.test('Build configuration is valid for Play Store', () async {
      final result = await PreLaunchTester.validateBuildConfig();

      flutter_test.expect(result['valid'], flutter_test.isTrue,
          reason: 'Build configuration must be valid for Play Store submission');
    });

    flutter_test.test('Flutter configuration is complete', () async {
      final result = await PreLaunchTester.validateFlutterConfig();

      flutter_test.expect(result['valid'], flutter_test.isTrue,
          reason: 'Flutter configuration must be complete for Play Store');
    });

    flutter_test.test('Can generate pre-launch report', () async {
      final report = await PreLaunchTester.generateReport();

      flutter_test.expect(report, flutter_test.isNotEmpty,
          reason: 'Should be able to generate pre-launch report');

      flutter_test.expect(report.contains('# 🎯 Play Store Pre-Launch Report'),
          flutter_test.isTrue, reason: 'Report should have proper header');

      flutter_test.expect(report.contains('Overall Assessment'),
          flutter_test.isTrue, reason: 'Report should include overall assessment');
    });

    flutter_test.test('Required permissions are justified', () async {
      final manifestResult = await PreLaunchTester.validateManifest();
      final permissions = manifestResult['permissions'] as List<String>;

      // Camera permission - justified for photo analysis
      flutter_test.expect(permissions.contains('CAMERA'), flutter_test.isTrue,
          reason: 'Camera permission required for ML analysis feature');

      // Location permissions - justified for finding nearby locations
      flutter_test.expect(permissions.any((p) => p.contains('LOCATION')), flutter_test.isTrue,
          reason: 'Location permission required for location-based services');

      // Phone permission - justified for contact functionality
      flutter_test.expect(permissions.contains('CALL_PHONE'), flutter_test.isTrue,
          reason: 'Phone permission required for contact functionality');
    });

    flutter_test.test('No unnecessary permissions are declared', () async {
      final manifestResult = await PreLaunchTester.validateManifest();
      final permissions = manifestResult['permissions'] as List<String>;

      // Check that no restricted permissions are present
      final restrictedFound = permissions.any((permission) =>
          PreLaunchTester.restrictedPermissions.any((restricted) =>
              restricted.endsWith(permission)));

      flutter_test.expect(restrictedFound, flutter_test.isFalse,
          reason: 'No unnecessary or restricted permissions should be declared');
    });
  });
}

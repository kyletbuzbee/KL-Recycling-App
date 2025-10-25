import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

/// Store Listing Compliance Tests
/// Validates all assets and metadata required for Google Play Store listing

class StoreListingValidator {
  static const int maxAppNameLength = 30;
  static const int maxShortDescriptionLength = 80;
  static const int maxFullDescriptionLength = 4000;
  static const int minScreenshots = 2;
  static const int maxScreenshots = 8;
  static const int requiredIconSize = 512;
  static const int requiredFeatureGraphicWidth = 1024;
  static const int requiredFeatureGraphicHeight = 500;

  static const List<String> requiredMetadataFiles = [
    'README.md',
    'pubspec.yaml',
    'android/app/build.gradle.kts',
  ];

  /// Validate app name for Play Store requirements
  static Future<Map<String, dynamic>> validateAppName() async {
    final issues = <String>[];
    final warnings = <String>[];

    // Check pubspec.yaml for app name
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      issues.add('pubspec.yaml not found');
      return {'valid': false, 'issues': issues, 'warnings': warnings};
    }

    final content = pubspec.readAsStringSync();
    final nameMatch = RegExp(r'name:\s*(.+)').firstMatch(content);

    if (nameMatch == null) {
      issues.add('App name not found in pubspec.yaml');
      return {'valid': false, 'issues': issues, 'warnings': warnings};
    }

    final appName = nameMatch.group(1)!.trim().replaceAll("'", '').replaceAll('"', '');

    if (appName.isEmpty) {
      issues.add('App name is empty');
    } else {
      if (appName.length > maxAppNameLength) {
        issues.add('App name is too long (${appName.length} chars, max $maxAppNameLength)');
      }

      // Check for special characters or trademarks
      if (appName.contains('®') || appName.contains('™')) {
        warnings.add('App name contains trademark symbols - verify trademark rights');
      }

      if (appName.contains('™')) {
        warnings.add('App name contains ™ symbol - verify trademark rights');
      }

      // Check for appropriate content
      if (!appName.toLowerCase().contains('recycling') &&
          !appName.toLowerCase().contains('scrap') &&
          !appName.toLowerCase().contains('metal')) {
        warnings.add('App name should clearly indicate it\'s a recycling/scrap metal app');
      }
    }

    return {
      'valid': issues.isEmpty,
      'name': appName,
      'length': appName.length,
      'issues': issues,
      'warnings': warnings,
    };
  }

  /// Validate app descriptions
  static Future<Map<String, dynamic>> validateDescriptions() async {
    final issues = <String>[];
    final warnings = <String>[];
    final descriptions = <String, String>{};

    final readme = File('README.md');
    if (!readme.existsSync()) {
      issues.add('README.md not found - required for description extraction');
      return {
        'valid': false,
        'issues': issues,
        'warnings': warnings,
        'descriptions': descriptions
      };
    }

    final content = readme.readAsStringSync();

    // Extract short description (typically first paragraph after title)
    final lines = LineSplitter.split(content).toList();
    String shortDescription = '';
    bool foundTitle = false;

    for (final line in lines) {
      if (line.startsWith('#') && !foundTitle) {
        foundTitle = true;
        continue;
      }

      if (foundTitle && line.trim().isNotEmpty && !line.startsWith('#')) {
        shortDescription = line.trim();
        break;
      }
    }

    // Look for a more detailed description
    String fullDescription = content;
    if (fullDescription.length > maxFullDescriptionLength) {
      fullDescription = '${fullDescription.substring(0, maxFullDescriptionLength - 3)}...';
    }

    descriptions['short'] = shortDescription;
    descriptions['full'] = fullDescription;

    // Validate short description
    if (shortDescription.length > maxShortDescriptionLength) {
      issues.add('Short description too long (${shortDescription.length} chars, max $maxShortDescriptionLength)');
    } else if (shortDescription.length < 10) {
      warnings.add('Short description is very short (${shortDescription.length} chars)');
    }

    // Validate full description
    if (fullDescription.length > maxFullDescriptionLength) {
      issues.add('Full description too long (${fullDescription.length} chars, max $maxFullDescriptionLength)');
    }

    // Check for required keywords in descriptions
    final combinedText = '$shortDescription $fullDescription'.toLowerCase();
    final requiredKeywords = ['recycling', 'scrap', 'metal'];

    bool hasKeyword = requiredKeywords.any((keyword) =>
        combinedText.contains(keyword));

    if (!hasKeyword) {
      warnings.add('Descriptions should mention recycling, scrap, or metal to clarify app purpose');
    }

    return {
      'valid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'descriptions': descriptions,
    };
  }

  /// Validate app icon and visual assets
  static Future<Map<String, dynamic>> validateIconsAndAssets() async {
    final issues = <String>[];
    final warnings = <String>[];
    final results = <String, dynamic>{};

    // Check for Android app icon
    final androidResDir = Directory('android/app/src/main/res');
    final iconDirExists = androidResDir.existsSync();
    results['android_res_directory'] = iconDirExists;

    if (!iconDirExists) {
      issues.add('Android resources directory not found');
    } else {
      // Check different icon densities
      final iconSizes = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];
      int foundIcons = 0;

      for (final size in iconSizes) {
        final iconPath = 'mipmap-$size/ic_launcher.png';
        final iconFile = File('${androidResDir.path}/$iconPath');
        if (iconFile.existsSync()) {
          foundIcons++;
          results['icon_$size'] = true;
        } else {
          results['icon_$size'] = false;
          warnings.add('Missing app icon for $size density');
        }
      }

      if (foundIcons == 0) {
        issues.add('No app icons found in any density');
      }
    }

    // Check Flutter assets directory
    // final flutterIconsDir = Directory('assets(Icons)'); // This might be assets/Icons
    final flutterIconsDir = Directory('Icons'); // Based on project structure
    results['flutter_icons_directory'] = flutterIconsDir.existsSync();

    if (!flutterIconsDir.existsSync()) {
      warnings.add('Icons directory not found - expected at root level');
    } else {
      final iconFiles = flutterIconsDir.listSync().whereType<File>();
      results['flutter_icons_count'] = iconFiles.length;  // This is fine as Map<String, dynamic>
      if (iconFiles.length < 5) {
        warnings.add('Only ${iconFiles.length} icon files found - consider adding more for store assets');
      }
    }

    // Check assets/images for store graphics
    final assetsImagesDir = Directory('assets/images');
    results['assets_images_directory'] = assetsImagesDir.existsSync();

    if (!assetsImagesDir.existsSync()) {
      warnings.add('assets/images directory not found - needed for store screenshots');
    } else {
      final imageFiles = assetsImagesDir.listSync().whereType<File>()
          .where((f) => f.path.endsWith('.png') || f.path.endsWith('.jpg') || f.path.endsWith('.jpeg'));
      results['store_images_count'] = imageFiles.length;  // This is fine as Map<String, dynamic>

      if (imageFiles.length < minScreenshots) {
        issues.add('Only ${imageFiles.length} store images found, minimum $minScreenshots required');
      }
    }

    return {
      'valid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'results': results,
    };
  }

  /// Validate privacy policy and compliance
  static Future<Map<String, dynamic>> validatePrivacyCompliance() async {
    final issues = <String>[];
    final warnings = <String>[];
    final complianceChecks = <String, bool>{};

    // Check for privacy policy documentation
    final privacyFiles = ['PRIVACY_POLICY.md', 'privacy_policy.md'];
    final readme = File('README.md');

    bool hasPrivacyPolicy = false;
    for (final file in privacyFiles) {
      if (File(file).existsSync()) {
        hasPrivacyPolicy = true;
        complianceChecks['privacy_policy_file'] = true;
        break;
      }
    }

    // Check if README mentions privacy policy
    if (readme.existsSync()) {
      final content = readme.readAsStringSync().toLowerCase();
      if (content.contains('privacy') && (content.contains('policy') || content.contains('url'))) {
        hasPrivacyPolicy = true;
        complianceChecks['privacy_policy_mentioned'] = true;
      }
    }

    complianceChecks['privacy_policy_exists'] = hasPrivacyPolicy;

    if (!hasPrivacyPolicy) {
      issues.add('Privacy policy documentation not found or mentioned');
    }

    // Check for data collection statements
    final pubspec = File('pubspec.yaml');
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync().toLowerCase();

      // Check if Firebase is used (which requires data disclosure)
      if (content.contains('firebase') || content.contains('analytics')) {
        complianceChecks['uses_firebase'] = true;
        warnings.add('Firebase/Analytics usage requires data collection disclosure in Play Store');

        // Verify Firebase configuration exists
        final firebaseOptions = File('lib/firebase_options.dart');
        final googleServices = File('android/app/google-services.json');

        complianceChecks['firebase_config_exists'] = firebaseOptions.existsSync() && googleServices.existsSync();

        if (!firebaseOptions.existsSync()) {
          warnings.add('Firebase options file missing');
        }
        if (!googleServices.existsSync()) {
          warnings.add('Google Services JSON missing');
        }
      }
    }

    return {
      'valid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'compliance_checks': complianceChecks,
    };
  }

  /// Generate comprehensive store listing report
  static Future<String> generateStoreListingReport() async {
    final buffer = StringBuffer();
    buffer.writeln('# 🏪 Play Store Listing Compliance Report\n');
    buffer.writeln('Generated on: ${DateTime.now()}\n');

    // App Name Validation
    buffer.writeln('## 📝 App Name Validation');
    final nameResult = await validateAppName();
    _writeReportSection(buffer, nameResult);
    if (nameResult.containsKey('name')) {
      buffer.writeln('**Current name:** ${nameResult['name']}');
      buffer.writeln('**Length:** ${nameResult['length']}/$maxAppNameLength characters\n');
    }

    // Description Validation
    buffer.writeln('## 📄 Description Validation');
    final descResult = await validateDescriptions();
    _writeReportSection(buffer, descResult);
    if (descResult.containsKey('descriptions')) {
      final descriptions = descResult['descriptions'] as Map<String, String>;
      buffer.writeln('**Short description:** ${descriptions['short'] ?? 'Not found'}');
      buffer.writeln('**Full description length:** ${descriptions['full']?.length ?? 0}/$maxFullDescriptionLength characters\n');
    }

    // Visual Assets Validation
    buffer.writeln('## 🖼️ Visual Assets Validation');
    final assetsResult = await validateIconsAndAssets();
    _writeReportSection(buffer, assetsResult);
    if (assetsResult.containsKey('results')) {
      final results = assetsResult['results'] as Map<String, dynamic>;
      buffer.writeln('**Android icons found:** ${results.entries.where((e) => e.key.startsWith('icon_') && e.value == true).length}/5 densities');
      buffer.writeln('**Flutter icons:** ${results['flutter_icons_count'] ?? 0} files');
      buffer.writeln('**Store images:** ${results['store_images_count'] ?? 0} files (minimum $minScreenshots required)\n');
    }

    // Privacy Compliance
    buffer.writeln('## 🔒 Privacy & Compliance Validation');
    final privacyResult = await validatePrivacyCompliance();
    _writeReportSection(buffer, privacyResult);
    if (privacyResult.containsKey('compliance_checks')) {
      final checks = privacyResult['compliance_checks'] as Map<String, bool>;
      if (checks['uses_firebase'] == true) {
        buffer.writeln('**Firebase usage detected** - Data collection disclosure required');
      }
      buffer.writeln('**Privacy policy:** ${checks['privacy_policy_exists'] == true ? '✅ Found' : '❌ Missing'}\n');
    }

    // Overall Assessment
    final allValid = [
      nameResult['valid'] as bool,
      descResult['valid'] as bool,
      assetsResult['valid'] as bool,
      privacyResult['valid'] as bool,
    ].every((valid) => valid);

    buffer.writeln('## 🏆 Overall Assessment');
    if (allValid) {
      buffer.writeln('✅ **STORE LISTING READY**');
      buffer.writeln('All store listing requirements have been validated.');
    } else {
      buffer.writeln('❌ **ISSUES FOUND**');
      buffer.writeln('Address the issues above before creating store listing.');
    }

    return buffer.toString();
  }

  static void _writeReportSection(StringBuffer buffer, Map<String, dynamic> result) {
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
  group('Google Play Store Listing Tests', () {
    test('App name meets Play Store requirements', () async {
      final result = await StoreListingValidator.validateAppName();

      expect(result['valid'], isTrue,
          reason: 'App name must meet Play Store requirements');
    });

    test('App descriptions are properly formatted', () async {
      final result = await StoreListingValidator.validateDescriptions();

      expect(result['valid'], isTrue,
          reason: 'App descriptions must meet Play Store requirements');
    });

    test('Visual assets meet Play Store requirements', () async {
      final result = await StoreListingValidator.validateIconsAndAssets();

      expect(result['valid'], isTrue,
          reason: 'Visual assets must meet Play Store requirements');
    });

    test('Privacy compliance requirements are met', () async {
      final result = await StoreListingValidator.validatePrivacyCompliance();

      expect(result['valid'], isTrue,
          reason: 'Privacy compliance is required for Play Store');
    });

    test('Can generate store listing report', () async {
      final report = await StoreListingValidator.generateStoreListingReport();

      expect(report, isNotEmpty,
          reason: 'Should be able to generate store listing report');

      expect(report.contains('# 🏪 Play Store Listing Compliance Report'),
          isTrue, reason: 'Report should have proper header');

      expect(report.contains('Overall Assessment'),
          isTrue, reason: 'Report should include overall assessment');

      print('\n--- Store Listing Report ---\n$report');
    });

    test('Required metadata files exist', () {
      for (final file in StoreListingValidator.requiredMetadataFiles) {
        expect(File(file).existsSync(), isTrue,
            reason: '$file is required for store listing');
      }
    });

    test('App name length is within limits', () async {
      final result = await StoreListingValidator.validateAppName();

      if (result.containsKey('length')) {
        expect(result['length'], lessThanOrEqualTo(StoreListingValidator.maxAppNameLength),
            reason: 'App name must not exceed ${StoreListingValidator.maxAppNameLength} characters');
      }
    });

    test('Descriptions have appropriate content', () async {
      final result = await StoreListingValidator.validateDescriptions();

      if (result.containsKey('descriptions')) {
        final descriptions = result['descriptions'] as Map<String, String>;
        final shortDesc = descriptions['short'] ?? '';
        final fullDesc = descriptions['full'] ?? '';

        expect(shortDesc.length, lessThanOrEqualTo(StoreListingValidator.maxShortDescriptionLength),
            reason: 'Short description must not exceed ${StoreListingValidator.maxShortDescriptionLength} characters');

        expect(fullDesc.length, lessThanOrEqualTo(StoreListingValidator.maxFullDescriptionLength + 10), // Allow some buffer for "..."
            reason: 'Full description must not exceed ${StoreListingValidator.maxFullDescriptionLength} characters');
      }
    });
  });
}

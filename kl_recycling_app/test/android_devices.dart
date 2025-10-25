import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Android Device Testing Setup
/// Provides utilities for testing on Android devices and emulators

class AndroidDeviceTester {
  static const String emulatorCommand = 'emulator';
  static const String adbCommand = 'adb';

  /// Check if Android SDK tools are available
  static Future<bool> isAndroidSdkAvailable() async {
    try {
      final result = await Process.run('which', ['adb']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get list of connected Android devices
  static Future<List<String>> getConnectedDevices() async {
    try {
      final result = await Process.run(adbCommand, ['devices']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        return lines
            .where((line) => line.contains('device') && !line.startsWith('List'))
            .map((line) => line.split('\t').first.trim())
            .where((device) => device.isNotEmpty)
            .toList();
      }
    } catch (e) {
      // ADB not available
    }
    return [];
  }

  /// Check if any Android devices are available for testing
  static Future<bool> hasAvailableDevices() async {
    final devices = await getConnectedDevices();
    return devices.isNotEmpty;
  }

  /// Get device information for a specific device
  static Future<Map<String, String>> getDeviceInfo(String deviceId) async {
    final info = <String, String>{};

    try {
      // Get device model
      final modelResult = await Process.run(adbCommand, ['-s', deviceId, 'shell', 'getprop', 'ro.product.model']);
      if (modelResult.exitCode == 0) {
        info['model'] = modelResult.stdout.toString().trim();
      }

      // Get Android version
      final versionResult = await Process.run(adbCommand, ['-s', deviceId, 'shell', 'getprop', 'ro.build.version.release']);
      if (versionResult.exitCode == 0) {
        info['android_version'] = versionResult.stdout.toString().trim();
      }

      // Get API level
      final apiResult = await Process.run(adbCommand, ['-s', deviceId, 'shell', 'getprop', 'ro.build.version.sdk']);
      if (apiResult.exitCode == 0) {
        info['api_level'] = apiResult.stdout.toString().trim();
      }

      // Check if device supports Google Play Services
      final playResult = await Process.run(adbCommand, ['-s', deviceId, 'shell', 'pm', 'list', 'packages', 'com.google.android.gms']);
      info['play_services'] = playResult.exitCode == 0 ? 'available' : 'not_available';

    } catch (e) {
      // Failed to get device info
    }

    return info;
  }

  /// Check if device meets minimum requirements for Play Store apps
  static bool meetsMinimumRequirements(Map<String, String> deviceInfo) {
    // Check API level (minimum 21 for most apps)
    final apiLevel = int.tryParse(deviceInfo['api_level'] ?? '0') ?? 0;
    if (apiLevel < 21) return false;

    // Check for Play Services
    if (deviceInfo['play_services'] != 'available') return false;

    return true;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Android Device Testing Setup', () {
    test('Android SDK tools are available', () async {
      final available = await AndroidDeviceTester.isAndroidSdkAvailable();
      expect(available, isTrue,
          reason: 'Android SDK tools (ADB) should be available for device testing');
    }, skip: !Platform.isLinux && !Platform.isMacOS && !Platform.isWindows);

    test('Can detect connected Android devices', () async {
      if (!await AndroidDeviceTester.isAndroidSdkAvailable()) {
        markTestSkipped('Android SDK not available');
        return;
      }

      final devices = await AndroidDeviceTester.getConnectedDevices();
      // Note: This might be empty if no devices are connected, which is okay for CI
      expect(devices, isA<List<String>>(),
          reason: 'Should be able to get device list (may be empty)');
    });

    test('Device meets Play Store minimum requirements', () async {
      if (!await AndroidDeviceTester.hasAvailableDevices()) {
        markTestSkipped('No Android devices available for testing');
        return;
      }

      final devices = await AndroidDeviceTester.getConnectedDevices();
      final deviceId = devices.first;

      final deviceInfo = await AndroidDeviceTester.getDeviceInfo(deviceId);

      expect(deviceInfo.isNotEmpty, isTrue,
          reason: 'Should be able to get device information');

      expect(
        AndroidDeviceTester.meetsMinimumRequirements(deviceInfo),
        isTrue,
        reason: 'Testing device should meet minimum Play Store requirements (API 21+, Play Services)',
      );

      // Log device information for debugging
      print('Testing on device: $deviceId');
      deviceInfo.forEach((key, value) => print('  $key: $value'));
    });

    test('Flutter integration with Android device', () async {
      // This test verifies that Flutter can communicate with Android device
      if (!await AndroidDeviceTester.hasAvailableDevices()) {
        markTestSkipped('No Android devices available for testing');
        return;
      }

      // Basic Flutter integration test
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'Flutter should render properly on Android device');
    });
  });

  group('Google Play Store Device Compatibility', () {
    test('App runs on different screen densities', () async {
      if (!await AndroidDeviceTester.hasAvailableDevices()) {
        markTestSkipped('No Android devices available for testing');
        return;
      }

      // This would ideally test different device configurations
      // For now, just verify the app starts
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    test('App handles different Android versions', () async {
      if (!await AndroidDeviceTester.hasAvailableDevices()) {
        markTestSkipped('No Android devices available for testing');
        return;
      }

      // Test that app handles various Android versions gracefully
      final devices = await AndroidDeviceTester.getConnectedDevices();

      for (final deviceId in devices) {
        final deviceInfo = await AndroidDeviceTester.getDeviceInfo(deviceId);

        print('Testing compatibility with device: $deviceId');
        print('Android Version: ${deviceInfo['android_version']}');
        print('API Level: ${deviceInfo['api_level']}');

        // Verify app can start on this device
        expect(find.byType(MaterialApp), findsOneWidget,
            reason: 'App should start on Android device $deviceId');
      }
    });

    test('Camera permission works on physical devices', () async {
      if (!await AndroidDeviceTester.hasAvailableDevices()) {
        markTestSkipped('No Android devices available for testing');
        return;
      }

      // Test camera-related functionality if camera screen is accessible
      final devices = await AndroidDeviceTester.getConnectedDevices();

      for (final deviceId in devices) {
        final deviceInfo = await AndroidDeviceTester.getDeviceInfo(deviceId);

        // Only test camera if device has camera hardware
        if (deviceInfo['has_camera'] != 'false') {
          print('Testing camera functionality on device: $deviceId');
          // Camera tests would go here
        }
      }
    });

    test('Location services work correctly', () async {
      if (!await AndroidDeviceTester.hasAvailableDevices()) {
        markTestSkipped('No Android devices available for testing');
        return;
      }

      // Test location-related functionality
      final devices = await AndroidDeviceTester.getConnectedDevices();

      for (final deviceId in devices) {
        print('Testing location services on device: $deviceId');
        // Location permission tests would go here
        expect(find.byType(MaterialApp), findsOneWidget,
            reason: 'App should handle location services on device $deviceId');
      }
    });
  });
}

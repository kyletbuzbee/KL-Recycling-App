import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Try to load from environment variables first
    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];

    // Check if we have valid configuration (not placeholder values)
    if (apiKey != null && apiKey.isNotEmpty &&
        !apiKey.contains('-') && !apiKey.startsWith('YOUR_') &&
        projectId != null && projectId.isNotEmpty && !projectId.startsWith('YOUR_')) {

      // Real Firebase configuration
      return FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
        iosBundleId: null,
      );
    } else {
      // Demo/offline fallback configuration
      debugPrint('Using demo Firebase configuration - app will work offline');
      return const FirebaseOptions(
        apiKey: 'demo-api-key-for-offline-mode',
        appId: '1:1234567890:android:demo1234567890abcdef',
        messagingSenderId: '123456789012',
        projectId: 'demo-recycling-app',
        storageBucket: 'demo-recycling-app.appspot.com',
        measurementId: null,
        iosBundleId: null,
      );
    }
  }
}

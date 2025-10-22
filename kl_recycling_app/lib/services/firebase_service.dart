import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static FirebaseAnalytics? _analytics;
  static FirebaseMessaging? _messaging;
  static FirebaseStorage? _storage;

  // Getters for Firebase services
  static FirebaseAnalytics get analytics {
    _analytics ??= FirebaseAnalytics.instance;
    return _analytics!;
  }

  static FirebaseMessaging get messaging {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }

  static FirebaseStorage get storage {
    _storage ??= FirebaseStorage.instance;
    return _storage!;
  }

  // Initialize all Firebase services
  static Future<void> initialize() async {
    // Firebase Core is already initialized in main.dart

    try {
      // Initialize Analytics
      _analytics = FirebaseAnalytics.instance;
      debugPrint('Firebase Analytics initialized');

      // Initialize Messaging
      _messaging = FirebaseMessaging.instance;

      // Request permission for notifications (iOS only)
      if (!kIsWeb) {
        await _messaging?.requestPermission();
      }

      // Get FCM token
      String? token = await _messaging?.getToken();
      debugPrint('FCM Token: $token');

      // Initialize Storage
      _storage = FirebaseStorage.instance;
      debugPrint('Firebase Storage initialized');

    } catch (e) {
      debugPrint('Error initializing Firebase services: $e');
    }
  }

  // Analytics methods
  static void logEvent(String name, [Map<String, Object>? parameters]) {
    _analytics?.logEvent(name: name, parameters: parameters);
  }

  static void logScreenView(String screenName) {
    _analytics?.logScreenView(screenName: screenName);
  }

  static void logAppOpen() {
    _analytics?.logAppOpen();
  }

  // Storage methods
  static Future<String?> uploadImage(String filePath, String fileName) async {
    try {
      final ref = _storage!.ref().child('images/$fileName');
      final uploadTask = ref.putFile(File(filePath));
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  static Future<void> deleteImage(String url) async {
    try {
      final ref = _storage!.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }
}

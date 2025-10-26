import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static FirebaseAnalytics? _analytics;
  static FirebaseMessaging? _messaging;
  static FirebaseStorage? _storage;
  static FirebaseFirestore? _firestore;

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

  static FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
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

  // Firestore methods
  Future<Map<String, dynamic>?> getDocument(String collection, String documentId) async {
    try {
      final doc = await firestore.collection(collection).doc(documentId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Error getting document: $e');
      return null;
    }
  }

  Future<void> setDocument(String collection, String documentId, Map<String, dynamic> data) async {
    try {
      await firestore.collection(collection).doc(documentId).set(data);
    } catch (e) {
      debugPrint('Error setting document: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    try {
      final snapshot = await firestore.collection(collection).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting collection: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> queryCollection(String collection, String field, dynamic value) async {
    try {
      final snapshot = await firestore.collection(collection).where(field, isEqualTo: value).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error querying collection: $e');
      return [];
    }
  }
}

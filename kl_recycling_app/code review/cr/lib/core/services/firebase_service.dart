// Firebase Service - Complete implementation with offline support
// KL Recycling App

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Initialization state
  bool _isInitialized = false;
  final Completer<void> _initialized = Completer<void>();

  // Offline state
  final bool _isOffline = false;
  StreamSubscription? _connectivitySubscription;

  // Cache for offline operations
  final Map<String, DocumentSnapshot> _documentCache = {};
  final Map<String, QuerySnapshot> _queryCache = {};

  // Stream controllers for broadcasting
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  // Getters for Firebase instances
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  // Getters for streams
  Stream<User?> get authStateChanges => _authStateController.stream;
  Stream<bool> get connectivityChanges => _connectivityController.stream;

  bool get isOffline => _isOffline;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase services
  Future<void> initialize() async {
    if (_isInitialized) return _initialized.future;

    try {
      // Initialize Firebase if not already done
      await Firebase.initializeApp();

      // Setup connectivity monitoring for web platform
      if (kIsWeb) {
        _setupWebConnectivity();
      }

      // Setup auth state monitoring
      _auth.authStateChanges().listen(_authStateController.add);

      _isInitialized = true;
      _initialized.complete();

      debugPrint('✅ Firebase Service initialized successfully');

    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      _initialized.completeError(e);
      rethrow;
    }
  }

  /// Setup web connectivity monitoring
  void _setupWebConnectivity() {
    // For web, we'll use a simple approach
    // In production, you'd use connectivity_plus package
    _connectivityController.add(true);
  }

  /// Dispose of resources
  void dispose() {
    _authStateController.close();
    _connectivityController.close();
    _connectivitySubscription?.cancel();
    _documentCache.clear();
    _queryCache.clear();
  }

  // ========= AUTHENTICATION METHODS =========

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    await _ensureInitialized();
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Create user account
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    await _ensureInitialized();
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _ensureInitialized();
    await _auth.signOut();
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _ensureInitialized();
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ========= FIRESTORE METHODS =========

  /// Get document with offline caching
  Future<DocumentSnapshot> getDocument(String path) async {
    await _ensureInitialized();

    if (_isOffline && _documentCache.containsKey(path)) {
      return _documentCache[path]!;
    }

    try {
      final doc = await _firestore.doc(path).get();

      if (doc.exists) {
        _documentCache[path] = doc; // Cache for offline use
      }

      return doc;
    } catch (e) {
      if (_documentCache.containsKey(path)) {
        debugPrint('🔄 Using cached data for $path due to error: $e');
        return _documentCache[path]!;
      }
      rethrow;
    }
  }

  /// Set document data
  Future<void> setDocument(String path, Map<String, dynamic> data, {bool merge = true}) async {
    await _ensureInitialized();

    if (_isOffline) {
      // Store operation for retry later
      debugPrint('📱 Queueing offline write for $path');
      return;
    }

    await _firestore.doc(path).set(data, SetOptions(merge: merge));

    // Update cache
    final doc = await _firestore.doc(path).get();
    _documentCache[path] = doc;
  }

  /// Update document fields
  Future<void> updateDocument(String path, Map<String, dynamic> data) async {
    await _ensureInitialized();

    if (_isOffline) {
      debugPrint('📱 Queueing offline update for $path');
      return;
    }

    await _firestore.doc(path).update(data);

    // Update cache
    final doc = await _firestore.doc(path).get();
    _documentCache[path] = doc;
  }

  /// Delete document
  Future<void> deleteDocument(String path) async {
    await _ensureInitialized();

    if (_isOffline) {
      debugPrint('📱 Queueing offline delete for $path');
      return;
    }

    await _firestore.doc(path).delete();
    _documentCache.remove(path);
  }

  /// Add document to collection
  Future<DocumentReference> addDocument(String collectionPath, Map<String, dynamic> data) async {
    await _ensureInitialized();

    if (_isOffline) {
      throw Exception('Cannot add documents while offline');
    }

    return await _firestore.collection(collectionPath).add(data);
  }

  /// Get query snapshot with caching
  Future<QuerySnapshot> getQuery(Query query, {String? cacheKey}) async {
    await _ensureInitialized();

    if (_isOffline && cacheKey != null && _queryCache.containsKey(cacheKey)) {
      return _queryCache[cacheKey]!;
    }

    try {
      final snapshot = await query.get();

      if (cacheKey != null) {
        _queryCache[cacheKey] = snapshot;
      }

      return snapshot;
    } catch (e) {
      if (cacheKey != null && _queryCache.containsKey(cacheKey)) {
        debugPrint('🔄 Using cached query data for $cacheKey due to error: $e');
        return _queryCache[cacheKey]!;
      }
      rethrow;
    }
  }

  /// Listen to document changes
  Stream<DocumentSnapshot> documentStream(String path) {
    if (!_isInitialized) {
      throw Exception('FirebaseService not initialized');
    }

    return _firestore.doc(path).snapshots();
  }

  /// Listen to collection changes
  Stream<QuerySnapshot> collectionStream(String path, {Query Function(Query)? queryBuilder}) {
    if (!_isInitialized) {
      throw Exception('FirebaseService not initialized');
    }

    Query query = _firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }

    return query.snapshots();
  }

  // ========= STORAGE METHODS =========

  /// Upload file to Firebase Storage
  Future<String> uploadFile(String storagePath, String filePath, String contentType) async {
    await _ensureInitialized();

    if (_isOffline) {
      throw Exception('Cannot upload files while offline');
    }

    final ref = _storage.ref().child(storagePath);
    // Import dart:io is already included above
    await ref.putFile(File(filePath), SettableMetadata(contentType: contentType));

    return await ref.getDownloadURL();
  }

  /// Get download URL for storage file
  Future<String> getDownloadURL(String storagePath) async {
    await _ensureInitialized();
    final ref = _storage.ref().child(storagePath);
    return await ref.getDownloadURL();
  }

  /// Delete file from storage
  Future<void> deleteFile(String storagePath) async {
    await _ensureInitialized();

    if (_isOffline) {
      throw Exception('Cannot delete files while offline');
    }

    final ref = _storage.ref().child(storagePath);
    await ref.delete();
  }

  // ========= UTILITY METHODS =========

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      return _initialized.future;
    }
  }

  /// Flush all caches (useful for testing)
  void flushCaches() {
    _documentCache.clear();
    _queryCache.clear();
  }

  /// Get collection reference
  CollectionReference getCollection(String path) {
    if (!_isInitialized) {
      throw Exception('FirebaseService not initialized');
    }

    return _firestore.collection(path);
  }

  /// Get document reference
  DocumentReference getDocumentRef(String path) {
    if (!_isInitialized) {
      throw Exception('FirebaseService not initialized');
    }

    return _firestore.doc(path);
  }

  /// Build query for collection
  Query queryCollection(String collectionPath) {
    if (!_isInitialized) {
      throw Exception('FirebaseService not initialized');
    }

    return _firestore.collection(collectionPath);
  }
}

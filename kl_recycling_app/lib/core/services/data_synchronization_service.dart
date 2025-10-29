import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kl_recycling_app/core/services/firebase_service.dart';


/// Data Synchronization service for offline/online sync and real-time updates
class DataSynchronizationService {
  static const String _pendingOperationsKey = 'pending_operations';
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';

  final FirebaseService _firebaseService;
  final SharedPreferences _prefs;

  /// Stream controllers for real-time updates
  final StreamController<Map<String, dynamic>> _realtimeUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _connectionCheckTimer;

  /// Pending operations queue
  final List<Map<String, dynamic>> _pendingOperations = [];

  DataSynchronizationService(
    this._firebaseService,
    this._prefs,
  );

  /// Initialize synchronization service
  Future<void> initialize() async {
    await _loadPendingOperations();
    await _startRealtimeListeners();
    await _syncOnStartup();
    _startConnectionCheckTimer();
  }

  /// Get real-time updates stream
  Stream<Map<String, dynamic>> get realtimeUpdates => _realtimeUpdatesController.stream;

  /// Basic connectivity check using HTTP request
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Start real-time Firestore listeners
  Future<void> _startRealtimeListeners() async {
    // Listen to collection updates
    _firebaseService.firestore
        .collection('collections')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            _realtimeUpdatesController.add({
              'type': 'collection',
              'changeType': change.type.toString(),
              'data': change.doc.data(),
              'docId': change.doc.id,
            });
          }
        });

    // Listen to challenges updates
    _firebaseService.firestore
        .collection('challenges')
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            _realtimeUpdatesController.add({
              'type': 'challenge',
              'changeType': change.type.toString(),
              'data': change.doc.data(),
              'docId': change.doc.id,
            });
          }
        });

    // Listen to loyalty program updates
    _firebaseService.firestore
        .collection('loyalty_programs')
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            _realtimeUpdatesController.add({
              'type': 'loyalty',
              'changeType': change.type.toString(),
              'data': change.doc.data(),
              'docId': change.doc.id,
            });
          }
        });

    // Listen to driver locations (for real-time tracking)
    _firebaseService.firestore
        .collection('driver_locations')
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            _realtimeUpdatesController.add({
              'type': 'driver_location',
              'changeType': change.type.toString(),
              'data': change.doc.data(),
              'docId': change.doc.id,
            });
          }
        });
  }

  /// Sync on app startup
  Future<void> _syncOnStartup() async {
    final isConnected = await _checkConnectivity();
    if (isConnected) {
      await _performFullSync();
    }
  }

  /// Perform full data synchronization
  Future<void> _performFullSync() async {
    try {
      // Sync collection history
      await _syncCollectionHistory();

      // Sync user profile and stats
      await _syncUserProfile();

      // Sync challenge progress
      await _syncChallenges();

      // Sync loyalty program data
      await _syncLoyaltyProgram();

      // Update last sync timestamp
      await _prefs.setString(_lastSyncTimestampKey, DateTime.now().toIso8601String());

    } catch (e) {
      print('Full sync failed: $e');
      // Don't throw error - sync failures shouldn't crash the app
    }
  }

  /// Sync collection history data
  Future<void> _syncCollectionHistory() async {
    final lastSyncStr = _prefs.getString(_lastSyncTimestampKey);
    final lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : DateTime.now().subtract(const Duration(days: 7));

    final collections = await _firebaseService.firestore
        .collection('collections')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(lastSync))
        .orderBy('timestamp', descending: true)
        .get();

    for (final doc in collections.docs) {
      final data = doc.data();
      // Cache locally for offline access
      await _storeOfflineData('collections', data, doc.id);
    }
  }

  /// Sync user profile and statistics
  Future<void> _syncUserProfile() async {
    final userProfile = await _firebaseService.firestore
        .collection('user_profiles')
        .doc('current_user') // In real app, this would be dynamic user ID
        .get();

    if (userProfile.exists) {
      await _storeOfflineData('user_profile', userProfile.data()!, userProfile.id);
    }

    // Sync gamification stats
    final gamificationStats = await _firebaseService.firestore
        .collection('gamification_stats')
        .doc('current_user')
        .get();

    if (gamificationStats.exists) {
      await _storeOfflineData('gamification_stats', gamificationStats.data()!, gamificationStats.id);
    }
  }

  /// Sync challenge progress
  Future<void> _syncChallenges() async {
    final challenges = await _firebaseService.firestore
        .collection('challenges')
        .get();

    for (final doc in challenges.docs) {
      await _storeOfflineData('challenges', doc.data(), doc.id);
    }

    // Sync user challenge progress
    final userChallenges = await _firebaseService.firestore
        .collection('user_challenges')
        .doc('current_user')
        .get();

    if (userChallenges.exists) {
      await _storeOfflineData('user_challenges', userChallenges.data()!, userChallenges.id);
    }
  }

  /// Sync loyalty program data
  Future<void> _syncLoyaltyProgram() async {
    final loyaltyProgram = await _firebaseService.firestore
        .collection('loyalty_programs')
        .doc('default') // Could be multiple programs
        .get();

    if (loyaltyProgram.exists) {
      await _storeOfflineData('loyalty_programs', loyaltyProgram.data()!, loyaltyProgram.id);
    }

    // Sync user loyalty status
    final userLoyalty = await _firebaseService.firestore
        .collection('user_loyalty')
        .doc('current_user')
        .get();

    if (userLoyalty.exists) {
      await _storeOfflineData('user_loyalty', userLoyalty.data()!, userLoyalty.id);
    }
  }

  /// Queue operation for offline execution
  Future<void> queueOperation(String operationType, Map<String, dynamic> data) async {
    final operation = {
      'id': 'op_${DateTime.now().millisecondsSinceEpoch}_${_pendingOperations.length}',
      'type': operationType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    };

    _pendingOperations.add(operation);
    await _savePendingOperations();

    // Try to sync immediately if online
    final isConnected = await _checkConnectivity();
    if (isConnected) {
      await _syncPendingOperations();
    }
  }

  /// Sync pending operations when connection is restored
  Future<void> _syncPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    final operationsToProcess = List<Map<String, dynamic>>.from(_pendingOperations);

    for (final operation in operationsToProcess) {
      try {
        await _executePendingOperation(operation);
        _pendingOperations.remove(operation);
      } catch (e) {
        print('Failed to sync operation ${operation['id']}: $e');

        // Increment retry count and potentially remove if max retries exceeded
        operation['retryCount'] = (operation['retryCount'] ?? 0) + 1;
        if (operation['retryCount'] >= 3) {
          _pendingOperations.remove(operation);
        }
      }
    }

    await _savePendingOperations();
  }

  /// Execute a pending operation
  Future<void> _executePendingOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    final data = operation['data'] as Map<String, dynamic>;

    switch (type) {
      case 'collection_submit':
        await _firebaseService.firestore.collection('collections').add(data);
        break;

      case 'challenge_complete':
        await _firebaseService.firestore.collection('user_challenges').doc('current_user').update(data);
        break;

      case 'loyalty_update':
        await _firebaseService.firestore.collection('user_loyalty').doc('current_user').update(data);
        break;

      case 'driver_location_update':
        await _firebaseService.firestore.collection('driver_locations').doc('current_driver').set(data);
        break;

      default:
        throw Exception('Unknown operation type: $type');
    }
  }

  /// Store data locally for offline access
  Future<void> _storeOfflineData(String key, Map<String, dynamic> data, String docId) async {
    final cacheKey = '${key}_$docId';
    final cacheJson = jsonEncode({
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _prefs.setString(cacheKey, cacheJson);
  }

  /// Retrieve cached data
  Future<Map<String, dynamic>?> getCachedData(String key, String docId) async {
    final cacheKey = '${key}_$docId';
    final cachedJson = _prefs.getString(cacheKey);
    if (cachedJson == null) return null;

    try {
      final cached = jsonDecode(cachedJson) as Map<String, dynamic>;
      return cached['data'] as Map<String, dynamic>;
    } catch (e) {
      print('Failed to decode cached data: $e');
      return null;
    }
  }

  /// Load pending operations from storage
  Future<void> _loadPendingOperations() async {
    final operationsJson = _prefs.getString(_pendingOperationsKey);
    if (operationsJson != null) {
      try {
        final operations = jsonDecode(operationsJson) as List<dynamic>;
        _pendingOperations.clear();
        _pendingOperations.addAll(operations.map((op) => op as Map<String, dynamic>));
      } catch (e) {
        print('Failed to load pending operations: $e');
      }
    }
  }

  /// Save pending operations to storage
  Future<void> _savePendingOperations() async {
    final operationsJson = jsonEncode(_pendingOperations);
    await _prefs.setString(_pendingOperationsKey, operationsJson);
  }

  /// Manual sync trigger
  Future<bool> manualSync() async {
    try {
      await _performFullSync();
      await _syncPendingOperations();
      return true;
    } catch (e) {
      print('Manual sync failed: $e');
      return false;
    }
  }

  /// Start periodic connection check timer
  void _startConnectionCheckTimer() {
    _connectionCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final isConnected = await _checkConnectivity();
      if (isConnected && _pendingOperations.isNotEmpty) {
        await _syncPendingOperations();
      }
    });
  }

  /// Get sync status information
  Map<String, dynamic> getSyncStatus() {
    return {
      'pendingOperationsCount': _pendingOperations.length,
      'lastSyncTimestamp': _prefs.getString(_lastSyncTimestampKey),
    };
  }

  /// Dispose resources
  void dispose() {
    _connectionCheckTimer?.cancel();
    _realtimeUpdatesController.close();
  }
}

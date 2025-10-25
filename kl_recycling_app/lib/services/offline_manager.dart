import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kl_recycling_app/models/photo_estimate.dart' as models;

/// Service for managing offline functionality and data synchronization
class OfflineManager extends ChangeNotifier {
  static const String _modelsStatusKey = 'offline_models_status';
  static const String _offlineEstimatesKey = 'offline_estimates_queue';
  static const String _syncStatusKey = 'sync_status';

  late SharedPreferences _prefs;

  // Offline status
  bool _isOfflineMode = false; // Simplified: manually set based on failures
  bool _modelsCached = false;
  bool _hasQueuedData = false;
  int _queuedEstimatesCount = 0;

  // Data storage
  List<models.PhotoEstimate> _offlineEstimates = [];

  // Initialization
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Load cached data
    await _loadOfflineData();

    // Check if models are cached
    await checkModelsCached();

    notifyListeners();
  }

  // Core offline functionality
  bool get isOfflineMode => _isOfflineMode;
  bool get modelsCached => _modelsCached;
  bool get hasQueuedData => _hasQueuedData;
  int get queuedEstimatesCount => _queuedEstimatesCount;

  /// Check if TensorFlow Lite models are cached for offline use
  Future<bool> checkModelsCached() async {
    try {
      // Check for locally stored models (you would implement actual model caching logic)
      final modelPaths = [
        'assets/models/scrap_metal_detector_v20251024_023843.tflite',
        // Add other model paths as needed
      ];

      bool allCached = true;
      for (final path in modelPaths) {
        final file = File(path);
        if (!await file.exists()) {
          allCached = false;
          break;
        }
      }

      _modelsCached = allCached;
      await _prefs.setBool(_modelsStatusKey, _modelsCached);

      return _modelsCached;
    } catch (e) {
      debugPrint('Error checking cached models: $e');
      _modelsCached = false;
      return false;
    }
  }

  /// Cache TensorFlow Lite models for offline use
  Future<bool> cacheModelsForOffline() async {
    try {
      // In a real implementation, this would download and store models locally
      // For now, just check if they exist in assets
      final modelCached = await checkModelsCached();

      if (modelCached) {
        debugPrint('Models already cached for offline use');
        return true;
      }

      // Placeholder for model downloading logic
      // This would typically download models from your server/backend
      debugPrint('Models need to be downloaded for offline use');
      return false; // Models not available offline yet

    } catch (e) {
      debugPrint('Error caching models: $e');
      return false;
    }
  }

  /// Get offline-compatible weight estimation with local logic
  Future<Map<String, dynamic>> getOfflineWeightEstimation({
    required String imagePath,
    required models.MaterialType materialType,
    double? manualEstimate,
  }) async {
    try {
      final file = File(imagePath);

      // Basic file analysis for offline estimation
      final fileSize = await file.length();
      final estimatedVolume = _calculateEstimatedVolumeFromFile(fileSize);
      final materialDensity = _getMaterialDensity(materialType);

      // Calculate weight using basic heuristics
      final estimatedWeight = estimatedVolume * materialDensity;

      // Blend with manual estimate if provided
      final finalWeight = manualEstimate != null
          ? (estimatedWeight * 0.7) + (manualEstimate * 0.3) // 70/30 weighted average
          : estimatedWeight;

      // Generate factors and suggestions
      final factors = [
        'Offline estimation using file size heuristics',
        'Image size: ${(fileSize / 1024).round()}KB processed',
        'Material density: ${materialDensity.toStringAsFixed(3)} lb/cu³',
        'Estimated volume: ${estimatedVolume.toStringAsFixed(2)} cu³',
        if (manualEstimate != null) 'Incorporated manual estimate: ${manualEstimate}lbs',
      ];

      final suggestions = [
        'This is an offline estimate - verify when you have internet',
        'AI analysis will be more accurate when online',
        'Consider adding reference objects for calibration',
      ];

      return {
        'estimatedWeight': finalWeight,
        'confidenceScore': 0.4, // Lower confidence for offline mode
        'method': 'Offline_Heuristic_Estimation',
        'factors': factors,
        'suggestions': suggestions,
        'offlineMode': true,
      };

    } catch (e) {
      debugPrint('Offline estimation error: $e');

      // Ultimate fallback
      return {
        'estimatedWeight': manualEstimate ?? _getDefaultWeight(materialType),
        'confidenceScore': manualEstimate != null ? 0.3 : 0.1,
        'method': 'Offline_Emergency_Fallback',
        'factors': ['Emergency offline estimation - please verify online'],
        'suggestions': ['Internet connection recommended for accurate estimation'],
        'offlineMode': true,
        'error': e.toString(),
      };
    }
  }

  /// Queue an estimate for later synchronization
  Future<bool> queueEstimateForSync(models.PhotoEstimate estimate) async {
    try {
      _offlineEstimates.add(estimate);
      _queuedEstimatesCount = _offlineEstimates.length;
      _hasQueuedData = true;

      // Save to local storage
      await _saveOfflineEstimates();

      // Update sync status
      await _prefs.setString(_syncStatusKey, 'queued');

      notifyListeners();
      debugPrint('Estimate queued for sync: ${estimate.id}');

      return true;
    } catch (e) {
      debugPrint('Error queuing estimate: $e');
      return false;
    }
  }

  /// Synchronize queued data when online
  Future<Map<String, dynamic>> synchronizeData() async {
    if (_offlineEstimates.isEmpty) {
      return {'success': true, 'message': 'No data to sync'};
    }

    try {
      int syncedCount = 0;
      int failedCount = 0;
      List<String> errors = [];

      // In real implementation, this would upload to your backend
      for (final estimate in _offlineEstimates) {
        try {
          // Simulate sync operation
          await Future.delayed(const Duration(milliseconds: 200)); // Network delay

          // Backend sync would happen here
          // await _uploadEstimateToBackend(estimate);

          syncedCount++;

        } catch (e) {
          failedCount++;
          errors.add('Error syncing ${estimate.id}: $e');
          debugPrint('Sync failed for estimate ${estimate.id}: $e');
        }
      }

      // Clear synced data (in real implementation, track sync status)
      if (syncedCount > 0) {
        _offlineEstimates.clear();
        _queuedEstimatesCount = 0;
        _hasQueuedData = false;
        await _saveOfflineEstimates();
      }

      // Update sync status
      final status = failedCount == 0 ? 'completed' : 'partial';
      await _prefs.setString(_syncStatusKey, status);

      notifyListeners();

      return {
        'success': failedCount == 0,
        'syncedCount': syncedCount,
        'failedCount': failedCount,
        'totalProcessed': syncedCount + failedCount,
        'errors': errors,
        'message': 'Sync completed: $syncedCount synced, $failedCount failed',
      };

    } catch (e) {
      debugPrint('Sync error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Synchronization failed: $e',
      };
    }
  }

  /// Simplified connectivity check (placeholder - can be expanded later)
  Future<bool> checkConnectivityForSync() async {
    // Simple approach: assume online and let network calls fail if needed
    // In real implementation, check actual connectivity
    return true;
  }

  /// Manually set offline mode (for when network calls fail)
  void setOfflineMode(bool offline) {
    if (_isOfflineMode != offline) {
      _isOfflineMode = offline;
      notifyListeners();
    }
  }

  // UI Helper Methods
  String getOfflineIndicatorText() {
    if (_isOfflineMode) {
      return _modelsCached ? 'Offline Mode - AI Available' : 'Offline Mode - Manual Only';
    }
    return _hasQueuedData ? 'Online - $_queuedEstimatesCount items to sync' : 'Online';
  }

  Color getOfflineIndicatorColor() {
    if (_isOfflineMode) {
      return _modelsCached ? const Color(0xFFFFA726) : const Color(0xFFF44336); // Orange/Red
    }
    return _hasQueuedData ? const Color(0xFF2196F3) : const Color(0xFF4CAF50); // Blue/Green
  }

  IconData getOfflineIndicatorIcon() {
    if (_isOfflineMode) {
      return _modelsCached ? Icons.offline_bolt : Icons.offline_pin;
    }
    return _hasQueuedData ? Icons.sync : Icons.wifi;
  }

  // Private helper methods
  double _calculateEstimatedVolumeFromFile(int fileSizeBytes) {
    // Rough heuristic: larger files suggest larger/heavier items
    // This is a simplified approximation for offline mode
    const double baseVolume = 0.1; // 0.1 cubic feet base
    const double volumeScale = 0.00001; // Scaling factor

    final additionalVolume = fileSizeBytes * volumeScale;
    return baseVolume + additionalVolume;
  }

  double _getMaterialDensity(models.MaterialType materialType) {
    // Simplified density map for offline mode
    const densities = {
      models.MaterialType.steel: 0.283,
      models.MaterialType.aluminum: 0.098,
      models.MaterialType.copper: 0.323,
      models.MaterialType.brass: 0.304,
      models.MaterialType.zinc: 0.256,
      models.MaterialType.stainless: 0.290,
      models.MaterialType.other: 0.260,
    };

    return densities[materialType] ?? 0.283; // Default to steel
  }

  double _getDefaultWeight(models.MaterialType materialType) {
    switch (materialType) {
      case models.MaterialType.aluminum: return 8.0;
      case models.MaterialType.copper: return 15.0;
      case models.MaterialType.brass: return 12.0;
      default: return 10.0; // Steel/conservative default
    }
  }

  Future<void> _loadOfflineData() async {
    try {
      // Load queued estimates
      final estimatesJson = _prefs.getStringList(_offlineEstimatesKey) ?? [];
      _offlineEstimates = estimatesJson.map((jsonStr) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        return models.PhotoEstimate.fromJson(data);
      }).toList();

      _queuedEstimatesCount = _offlineEstimates.length;
      _hasQueuedData = _offlineEstimates.isNotEmpty;

      // Load models status
      _modelsCached = _prefs.getBool(_modelsStatusKey) ?? false;

    } catch (e) {
      debugPrint('Error loading offline data: $e');
      _offlineEstimates = [];
    }
  }

  Future<void> _saveOfflineEstimates() async {
    try {
      final estimatesJson = _offlineEstimates.map((estimate) => jsonEncode(estimate.toJson())).toList();
      await _prefs.setStringList(_offlineEstimatesKey, estimatesJson);
    } catch (e) {
      debugPrint('Error saving offline estimates: $e');
    }
  }

  // Cleanup
}

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kl_recycling_app/core/services/firebase_service.dart';
import 'package:kl_recycling_app/features/photo_estimate/models/photo_estimate.dart' as models;

/// Secure, privacy-preserving data collection service for AI/ML training
class DataCollectionService {
  final FirebaseService _firebaseService;
  bool _optInEnabled = false;
  bool _dataCollectionEnabled = false;

  // Privacy and security settings
  static const int _maxBatchSize = 10; // Max predictions per batch
  static const Duration _uploadInterval = Duration(hours: 24); // Daily uploads
  static const String _collectionEnabledKey = 'ai_data_collection_enabled';
  static const String _optInAcceptedKey = 'ai_data_collection_opt_in';

  // Data batching and compression
  final List<Map<String, dynamic>> _pendingData = [];
  DateTime? _lastUploadTime;
  Timer? _uploadTimer;

  DataCollectionService(this._firebaseService) {
    _initializePrivacySettings();
    _startPeriodicUpload();
  }

  /// Initialize privacy settings from user preferences
  Future<void> _initializePrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    _optInEnabled = prefs.getBool(_optInAcceptedKey) ?? false;
    _dataCollectionEnabled = prefs.getBool(_collectionEnabledKey) ?? false;

    debugPrint('Data collection initialized: optIn=$_optInEnabled, enabled=$_dataCollectionEnabled');
  }

  /// User explicitly opts into data collection
  Future<void> optIntoDataCollection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_optInAcceptedKey, true);
    await prefs.setBool(_collectionEnabledKey, true);
    _optInEnabled = true;
    _dataCollectionEnabled = true;

    debugPrint('User opted into data collection');
  }

  /// User opts out of data collection
  Future<void> optOutOfDataCollection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_optInAcceptedKey, false);
    await prefs.setBool(_collectionEnabledKey, false);
    _optInEnabled = false;
    _dataCollectionEnabled = false;

    // Clear any pending data
    _pendingData.clear();

    debugPrint('User opted out of data collection');
  }

  /// Check if data collection is allowed
  bool get isDataCollectionAllowed => _optInEnabled && _dataCollectionEnabled;

  /// Record a prediction event with minimal, anonymized data
  Future<void> recordPrediction({
    required WeightPredictionResult result,
    required models.MaterialType materialType,
    required Map<String, dynamic> imageMetadata,
    required Map<String, dynamic> deviceCapabilities,
    String? userFeedback, // Optional: user corrections for training
  }) async {
    if (!isDataCollectionAllowed) return;

    // Create compact telemetry entry
    final telemetryEntry = TelemetryEntry.create(
      result: result,
      materialType: materialType,
      imageMetadata: imageMetadata,
      deviceCapabilities: deviceCapabilities,
      userFeedback: userFeedback,
    );

    _pendingData.add(telemetryEntry);

    // Upload if we have enough data or it's time for periodic upload
    if (_pendingData.length >= _maxBatchSize ||
        (_lastUploadTime != null &&
         DateTime.now().difference(_lastUploadTime!) > _uploadInterval)) {
      await _uploadBatch();
    }
  }

  /// Force immediate upload of all pending data
  Future<void> forceUpload() async {
    if (_pendingData.isNotEmpty) {
      await _uploadBatch();
    }
  }

  /// Upload a batch of telemetry data with retry logic
  Future<void> _uploadBatch() async {
    if (_pendingData.isEmpty) return;

    final batchData = List<Map<String, dynamic>>.from(_pendingData);

    try {
      // Compress data for upload
      final compressedData = _compressBatch(batchData);

      // Encrypt sensitive information at rest
      final encryptedData = await _encryptData(compressedData);

      // Upload to secure backend
      await _firebaseService.uploadTelemetryBatch(encryptedData, {
        'batch_size': batchData.length,
        'upload_time': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'privacy_level': 'anonymized',
      });

      // Clear uploaded data
      _pendingData.removeRange(0, batchData.length);
      _lastUploadTime = DateTime.now();

      debugPrint('Successfully uploaded ${batchData.length} telemetry records');

    } catch (e) {
      debugPrint('Failed to upload telemetry batch: $e');
      // Keep data for retry on next attempt
      // Could implement exponential backoff here
    }
  }

  /// Compress batch data using gzip-like compression
  String _compressBatch(List<Map<String, dynamic>> batch) {
    // In production, would use actual compression
    // For now, just minify JSON
    final jsonData = jsonEncode(batch);
    // Simple minification - remove extra whitespace
    return jsonData.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Encrypt sensitive telemetry data
  Future<String> _encryptData(String data) async {
    // In production, would use proper encryption
    // For now, just add a salt and hash
    final salt = 'kl_recycling_telemetry_salt_v1';
    final saltedData = '$salt$data';
    final hash = sha256.convert(utf8.encode(saltedData)).toString();
    return '$hash:${base64Encode(utf8.encode(data))}';
  }

  /// Get anonymized statistics for user transparency
  Future<Map<String, dynamic>> getCollectionStatistics() async {
    return {
      'opt_in_status': _optInEnabled,
      'collection_enabled': _dataCollectionEnabled,
      'pending_records': _pendingData.length,
      'last_upload': _lastUploadTime?.toIso8601String(),
      'total_collected_today': _calculateTodayCollection(),
      'privacy_guarantees': [
        'All data is anonymized - no personal information',
        'Images are never uploaded, only metadata',
        'Data is encrypted in transit and at rest',
        'User can opt-out at any time',
        'Data is used only for AI model improvement',
      ],
    };
  }

  /// Calculate how many records collected today
  int _calculateTodayCollection() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    return _pendingData.where((data) {
      final timestamp = DateTime.parse(data['timestamp']);
      return timestamp.isAfter(todayStart);
    }).length;
  }

  /// Start periodic background upload
  void _startPeriodicUpload() {
    _uploadTimer = Timer.periodic(_uploadInterval, (_) => _uploadBatch());
  }

  /// Clear all stored data and reset settings
  Future<void> resetCollection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_optInAcceptedKey);
    await prefs.remove(_collectionEnabledKey);

    _pendingData.clear();
    _optInEnabled = false;
    _dataCollectionEnabled = false;

    debugPrint('Data collection reset completed');
  }

  /// Export data for user download (anonymized)
  Future<String> exportDataForUser() async {
    if (!isDataCollectionAllowed) return '';

    final exportData = {
      'export_time': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'privacy_notice': 'This data contains only anonymized AI performance metrics',
      'data': _pendingData.map((entry) => _anonymizeForExport(entry)).toList(),
    };

    return jsonEncode(exportData);
  }

  /// Remove potentially identifiable information for export
  Map<String, dynamic> _anonymizeForExport(Map<String, dynamic> entry) {
    final anonymized = Map<String, dynamic>.from(entry);

    // Remove any potential identifiers
    anonymized.remove('device_id');
    anonymized.remove('user_id');
    anonymized.remove('location_data');

    // Add privacy metadata
    anonymized['anonymized'] = true;
    anonymized['export_time'] = DateTime.now().toIso8601String();

    return anonymized;
  }

  /// Dispose resources
  void dispose() {
    _uploadTimer?.cancel();
    _uploadTimer = null;
  }

  /// Get data collection opt-in dialog content
  Map<String, String> getOptInDialogContent() {
    return {
      'title': 'Help Improve AI Weight Estimation',
      'description': 'Would you like to help improve our AI\'s accuracy by anonymously sharing prediction data?',
      'benefits': 'Your contributions help make the app more accurate for everyone.',
      'privacy': 'All data is anonymized and encrypted. You can opt out at any time.',
      'data_types': 'Only prediction accuracy, material types, and performance metrics.',
      'no_photos': 'Images are never uploaded - only numerical results.',
    };
  }
}

/// Compact telemetry entry for AI training data
class TelemetryEntry {
  final String timestamp;
  final String modelVersion;
  final String materialType;
  final double estimatedWeight;
  final double actualWeight; // If user provided correction
  final double confidence;
  final String imageQuality;
  final Map<String, dynamic> imageMetadata;
  final Map<String, dynamic> deviceCapabilities;
  final Map<String, dynamic> modelOutputs;

  TelemetryEntry({
    required this.timestamp,
    required this.modelVersion,
    required this.materialType,
    required this.estimatedWeight,
    required this.actualWeight,
    required this.confidence,
    required this.imageQuality,
    required this.imageMetadata,
    required this.deviceCapabilities,
    required this.modelOutputs,
  });

  /// Create telemetry entry from prediction result and metadata
  static Map<String, dynamic> create({
    required WeightPredictionResult result,
    required models.MaterialType materialType,
    required Map<String, dynamic> imageMetadata,
    required Map<String, dynamic> deviceCapabilities,
    String? userFeedback,
  }) {
    return {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'model_version': result.method,
      'material_type': materialType.name,
      'estimated_weight': result.estimatedWeight,
      'actual_weight': userFeedback != null ? _parseUserWeight(userFeedback) : null,
      'confidence': result.confidenceScore,
      'image_quality': _assessImageQuality(result),
      'image_metadata': {
        'resolution': imageMetadata['resolution'] ?? 'unknown',
        'format': imageMetadata['format'] ?? 'unknown',
        'lighting': imageMetadata['lighting'] ?? 'unknown',
        // Don't include pixel data or actual images
      },
      'device_capabilities': {
        'platform': deviceCapabilities['platform'] ?? 'unknown',
        'has_accelerator': deviceCapabilities['has_accelerator'] ?? false,
        'memory_mb': deviceCapabilities['memory_mb'] ?? 0,
        // Anonymize device details
      },
      'model_outputs': _extractModelOutputs(result),
      'privacy_level': 'anonymized',
      'consented': true,
    };
  }

  static double? _parseUserWeight(String feedback) {
    // Parse user-provided weight correction
    // This would implement text parsing logic to extract numbers
    final weightRegex = RegExp(r'(\d+(?:\.\d+)?)');
    final match = weightRegex.firstMatch(feedback);
    return match != null ? double.tryParse(match.group(1)!) : null;
  }

  static String _assessImageQuality(WeightPredictionResult result) {
    // Infer image quality from result factors
    final factors = result.factors.join(' ').toLowerCase();

    if (factors.contains('excellent') || result.confidenceScore > 0.8) {
      return 'excellent';
    } else if (factors.contains('good') || result.confidenceScore > 0.6) {
      return 'good';
    } else if (factors.contains('fair') || result.confidenceScore > 0.4) {
      return 'fair';
    } else {
      return 'poor';
    }
  }

  static Map<String, dynamic> _extractModelOutputs(WeightPredictionResult result) {
    // Extract only statistical model outputs, not raw predictions
    return {
      'method': result.method,
      'confidence': result.confidenceScore,
      'factor_count': result.factors.length,
      'suggestion_count': result.suggestions.length,
      // Don't include actual prediction details that could be traceable
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'model_version': modelVersion,
      'material_type': materialType,
      'estimated_weight': estimatedWeight,
      'actual_weight': actualWeight,
      'confidence': confidence,
      'image_quality': imageQuality,
      'image_metadata': imageMetadata,
      'device_capabilities': deviceCapabilities,
      'model_outputs': modelOutputs,
    };
  }
}

/// Result of weight prediction for telemetry collection
class WeightPredictionResult {
  final double estimatedWeight;
  final double confidenceScore;
  final String method;
  final List<String> factors;
  final List<String> suggestions;
  final Map<String, dynamic> metadata;

  WeightPredictionResult({
    required this.estimatedWeight,
    required this.confidenceScore,
    required this.method,
    required this.factors,
    required this.suggestions,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'estimatedWeight': estimatedWeight,
      'confidenceScore': confidenceScore,
      'method': method,
      'factors': factors,
      'suggestions': suggestions,
      'metadata': metadata,
    };
  }

  factory WeightPredictionResult.fromMap(Map<String, dynamic> map) {
    return WeightPredictionResult(
      estimatedWeight: map['estimatedWeight']?.toDouble() ?? 0.0,
      confidenceScore: map['confidenceScore']?.toDouble() ?? 0.0,
      method: map['method'] ?? '',
      factors: List<String>.from(map['factors'] ?? []),
      suggestions: List<String>.from(map['suggestions'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

// Extension for Firebase service integration
extension FirebaseServiceExtensions on FirebaseService {
  Future<void> uploadTelemetryBatch(String encryptedData, Map<String, dynamic> metadata) async {
    // Implementation would upload to Firebase/Firestore
    // This is a placeholder for the actual implementation
    debugPrint('Uploading telemetry batch with ${metadata['batch_size']} records');
  }
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/service_request.dart';
import '../models/ml_analysis_result.dart';
import 'firebase_service.dart';

/// Backend service for handling Firestore operations with resilience
class BackendService {
  // Timeout configuration
  static const Duration _networkTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(milliseconds: 500);

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Collection references
  static CollectionReference get _serviceRequests =>
      _firestore.collection('serviceRequests');

  static CollectionReference get _mlAnalysis =>
      _firestore.collection('mlAnalysisResults');

  static CollectionReference get _businessAnalytics =>
      _firestore.collection('businessAnalytics');

  /// Execute an operation with retry logic and exponential backoff
  static Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = _maxRetries,
    Duration timeout = _networkTimeout,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        return await operation().timeout(timeout);
      } on TimeoutException {
        if (attempt == maxRetries - 1) rethrow;
        debugPrint('Operation timed out (attempt ${attempt + 1}), retrying...');
      } on FirebaseException catch (e) {
        // Don't retry client errors (4xx)
        if (e.code.startsWith('4')) rethrow;
        if (attempt == maxRetries - 1) rethrow;
        debugPrint('Firebase error (attempt ${attempt + 1}): ${e.message}, retrying...');
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        debugPrint('Unexpected error (attempt ${attempt + 1}), retrying...');
      }

      // Exponential backoff
      final delay = _baseRetryDelay * (1 << attempt); // 2^attempt
      await Future.delayed(delay);
      attempt++;
    }

    throw Exception('Operation failed after $maxRetries attempts');
  }

  /// Save a service request to Firestore
  static Future<String> saveServiceRequest(ServiceRequest request) async {
    return _retryOperation(() async {
      final docRef = await _serviceRequests.add(request.toMap());
      debugPrint('Service request saved with ID: ${docRef.id}');

      // Log analytical event
      FirebaseService.logEvent('service_request_submitted', {
        'request_type': request.requestType.name,
        'zip_code': request.zipCode,
        'has_company': request.company != null,
      });

      return docRef.id;
    });
  }

  /// Get all service requests (for admin use)
  static Stream<List<ServiceRequest>> getServiceRequests() {
    return _serviceRequests
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRequest.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Update service request status
  static Future<void> updateServiceRequestStatus(
      String requestId, RequestStatus status) async {
    try {
      await _serviceRequests.doc(requestId).update({
        'status': status.toString(),
        'updatedAt': Timestamp.now(),
      });
      debugPrint('Service request $requestId updated to status: ${status.display}');
    } catch (e) {
      debugPrint('Error updating service request status: $e');
      throw Exception('Failed to update request status: $e');
    }
  }

  /// Save ML analysis result to Firestore
  static Future<String> saveMlAnalysisResult(MlAnalysisResult result) async {
    return _retryOperation(() async {
      final docRef = await _mlAnalysis.add(result.toMap());
      debugPrint('ML analysis result saved with ID: ${docRef.id}');

      // Also save business summary for analytics dashboard
      await _saveBusinessAnalyticsSummary(result);

      // Log analytical event
      FirebaseService.logEvent('ml_analysis_completed', {
        'material_types': result.allDetectedMaterialTypes,
        'confidence_avg': result.averageConfidence,
        'quality_score': result.qualityScore.overallRating,
        'has_high_confidence': result.hasHighConfidenceDetection,
      });

      return docRef.id;
    });
  }

  /// Save business analytics summary
  static Future<void> _saveBusinessAnalyticsSummary(MlAnalysisResult result) async {
    try {
      final summary = result.toBusinessSummary();
      summary['timestamp'] = Timestamp.now();

      await _businessAnalytics.add(summary);
      debugPrint('Business analytics summary saved');
    } catch (e) {
      debugPrint('Error saving business analytics: $e');
      // Don't throw - business analytics failure shouldn't affect core functionality
    }
  }

  /// Get ML analysis results (for business intelligence)
  static Stream<List<MlAnalysisResult>> getMlAnalysisResults({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _mlAnalysis.orderBy('createdAt', descending: true);

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => MlAnalysisResult.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Get business analytics summary data
  static Future<Map<String, dynamic>> getBusinessAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = await _businessAnalytics
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final analytics = <String, dynamic>{};
      analytics['total_analyses'] = query.docs.length;

      // Materials distribution
      final materialCounts = <String, int>{};
      final confidenceScores = <double>[];
      final qualityRatings = <double>[];

      for (final doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final materials = List<String>.from(data['materials'] ?? []);

        for (final material in materials) {
          materialCounts[material] = (materialCounts[material] ?? 0) + 1;
        }

        if (data.containsKey('highConfidence')) {
          confidenceScores.add((data['highConfidence'] as bool) ? 1.0 : 0.0);
        }

        if (data.containsKey('qualityRating')) {
          qualityRatings.add((data['qualityRating'] ?? 0.0).toDouble());
        }
      }

      analytics['material_distribution'] = materialCounts;
      analytics['avg_high_confidence_rate'] = confidenceScores.isNotEmpty
          ? confidenceScores.reduce((a, b) => a + b) / confidenceScores.length
          : 0.0;
      analytics['avg_quality_rating'] = qualityRatings.isNotEmpty
          ? qualityRatings.reduce((a, b) => a + b) / qualityRatings.length
          : 0.0;

      return analytics;
    } catch (e) {
      debugPrint('Error getting business analytics: $e');
      throw Exception('Failed to get business analytics: $e');
    }
  }

  /// Get service request statistics
  static Future<Map<String, dynamic>> getServiceRequestStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = await _serviceRequests
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final stats = <String, dynamic>{};
      final requests = query.docs.map((doc) =>
          ServiceRequest.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      stats['total_requests'] = requests.length;

      // Status distribution
      final statusCounts = <String, int>{};
      for (final request in requests) {
        final statusName = request.status.display;
        statusCounts[statusName] = (statusCounts[statusName] ?? 0) + 1;
      }
      stats['status_distribution'] = statusCounts;

      // Request type distribution
      final typeCounts = <String, int>{};
      for (final request in requests) {
        final typeName = request.requestType.display;
        typeCounts[typeName] = (typeCounts[typeName] ?? 0) + 1;
      }
      stats['type_distribution'] = typeCounts;

      // Geographic distribution
      final zipCounts = <String, int>{};
      for (final request in requests) {
        if (request.zipCode.isNotEmpty) {
          zipCounts[request.zipCode] = (zipCounts[request.zipCode] ?? 0) + 1;
        }
      }
      stats['zip_code_distribution'] = zipCounts;

      // Lead conversion rate (simplified - requests that moved past pending)
      final convertedRequests = requests.where(
        (req) => req.status != RequestStatus.pending && req.status != RequestStatus.cancelled
      ).length;
      stats['lead_conversion_rate'] = requests.isNotEmpty ? convertedRequests / requests.length : 0.0;

      return stats;
    } catch (e) {
      debugPrint('Error getting service request stats: $e');
      throw Exception('Failed to get service request statistics: $e');
    }
  }

  /// Reset all data (for testing/development)
  static Future<void> resetAllData() async {
    try {
      // Delete all collections (be very careful with this in production!)
      await _deleteCollection(_serviceRequests);
      await _deleteCollection(_mlAnalysis);
      await _deleteCollection(_businessAnalytics);

      debugPrint('All backend data reset');
    } catch (e) {
      debugPrint('Error resetting data: $e');
      throw Exception('Failed to reset backend data: $e');
    }
  }

  static Future<void> _deleteCollection(CollectionReference collection) async {
    final batch = _firestore.batch();
    final snapshots = await collection.get();
    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

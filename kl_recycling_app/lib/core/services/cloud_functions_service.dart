import 'package:cloud_functions/cloud_functions.dart';

/// Cloud Functions service for handling automated business logic
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CloudFunctionsService();

  /// Handles appointment completion business logic
  Future<Map<String, dynamic>> onAppointmentComplete(String appointmentId, Map<String, dynamic> appointmentData) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('onAppointmentComplete');
      final HttpsCallableResult<Map<String, dynamic>> result = await callable.call(<String, dynamic>{
        'appointmentId': appointmentId,
        'appointmentData': appointmentData,
      });

      return result.data;
    } catch (e) {
      throw Exception('Failed to process appointment completion: $e');
    }
  }

  /// Handles referral usage business logic
  Future<Map<String, dynamic>> onReferralUsed(String referralCode, String referringUserId, String newUserId) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('onReferralUsed');
      final HttpsCallableResult<Map<String, dynamic>> result = await callable.call(<String, dynamic>{
        'referralCode': referralCode,
        'referringUserId': referringUserId,
        'newUserId': newUserId,
      });

      return result.data;
    } catch (e) {
      throw Exception('Failed to process referral: $e');
    }
  }

  /// Checks and upgrades user loyalty tier if eligible
  Future<Map<String, dynamic>> checkTierUpgrade(String userId, int currentPoints) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('checkTierUpgrade');
      final HttpsCallableResult<Map<String, dynamic>> result = await callable.call(<String, dynamic>{
        'userId': userId,
        'currentPoints': currentPoints,
      });

      return result.data;
    } catch (e) {
      throw Exception('Failed to check tier upgrade: $e');
    }
  }

  /// Processes scrap metal weight estimates with automated quality checks
  Future<Map<String, dynamic>> processWeightEstimate(Map<String, dynamic> estimateData, String userId) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('processWeightEstimate');
      final HttpsCallableResult<Map<String, dynamic>> result = await callable.call(<String, dynamic>{
        'estimateData': estimateData,
        'userId': userId,
      });

      return result.data;
    } catch (e) {
      throw Exception('Failed to process weight estimate: $e');
    }
  }

  /// Generates automated business reports
  Future<Map<String, dynamic>> generateBusinessReport(String reportType, Map<String, dynamic> filters) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('generateBusinessReport');
      final HttpsCallableResult<Map<String, dynamic>> result = await callable.call(<String, dynamic>{
        'reportType': reportType,
        'filters': filters,
      });

      return result.data;
    } catch (e) {
      throw Exception('Failed to generate business report: $e');
    }
  }

  /// Validates photo estimates against business rules
  Future<Map<String, dynamic>> validatePhotoEstimate(String imageUrl, Map<String, dynamic> metadata) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('validatePhotoEstimate');
      final HttpsCallableResult<Map<String, dynamic>> result = await callable.call(<String, dynamic>{
        'imageUrl': imageUrl,
        'metadata': metadata,
      });

      return result.data;
    } catch (e) {
      throw Exception('Failed to validate photo estimate: $e');
    }
  }

  /// Processes bulk material submissions for businesses
  Future<Map<String, dynamic>> processBulkSubmission(Map<String, dynamic> bulkData, String businessId) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('processBulkSubmission');
      final HttpsCallableResult<Map<String, dynamic>> result = await callable.call(<String, dynamic>{
        'bulkData': bulkData,
        'businessId': businessId,
      });

      return result.data;
    } catch (e) {
      throw Exception('Failed to process bulk submission: $e');
    }
  }

  /// Triggers emergency response protocols
  Future<bool> triggerEmergencyProtocol(String protocolType, Map<String, dynamic> emergencyData) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('triggerEmergencyProtocol');
      final HttpsCallableResult<Map<String, dynamic>> result = await callable.call(<String, dynamic>{
        'protocolType': protocolType,
        'emergencyData': emergencyData,
      });

      return result.data['success'] ?? false;
    } catch (e) {
      throw Exception('Failed to trigger emergency protocol: $e');
    }
  }
}

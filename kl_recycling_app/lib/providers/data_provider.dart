import 'package:flutter/material.dart';
import '../models/service_request.dart';
import '../models/ml_analysis_result.dart';
import '../services/backend_service.dart';

/// Provider for backend data operations (service requests and ML analysis)
class DataProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<ServiceRequest> _serviceRequests = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ServiceRequest> get serviceRequests => _serviceRequests;

  /// Clear any error messages
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Save service request to backend
  Future<bool> saveServiceRequest(ServiceRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await BackendService.saveServiceRequest(request);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save service request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Save ML analysis result to backend
  Future<bool> saveMlAnalysisResult(MlAnalysisResult result) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await BackendService.saveMlAnalysisResult(result);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save ML analysis result: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load service requests (for admin dashboard)
  void loadServiceRequests() {
    _isLoading = true;
    notifyListeners();

    BackendService.getServiceRequests().listen(
      (requests) {
        _serviceRequests = requests;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load service requests: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Update service request status
  Future<bool> updateServiceRequestStatus(String requestId, RequestStatus status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await BackendService.updateServiceRequestStatus(requestId, status);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update request status: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get business analytics data
  Future<Map<String, dynamic>?> getBusinessAnalytics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final analytics = await BackendService.getBusinessAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
      return analytics;
    } catch (e) {
      _errorMessage = 'Failed to get business analytics: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get service request statistics
  Future<Map<String, dynamic>?> getServiceRequestStats(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final stats = await BackendService.getServiceRequestStats(
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
      return stats;
    } catch (e) {
      _errorMessage = 'Failed to get service request statistics: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Reset loading and error states
  void resetState() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AuthService _authProvider;
  final AdminService _adminService;

  bool _isLoading = false;
  String? _error;

  AdminProvider(AuthService authProvider)
      : _authProvider = authProvider,
        _adminService = AdminService(authProvider);

  bool get isAdmin => _adminService.isAdmin;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Service Requests Management
  Future<List<dynamic>> getServiceRequests({
    String? status,
    String? serviceType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    if (!isAdmin) {
      _error = 'Access denied: Admin permissions required';
      notifyListeners();
      return [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final requests = await _adminService.getServiceRequests(
        status: status,
        serviceType: serviceType,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      _isLoading = false;
      notifyListeners();
      return requests;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<bool> updateServiceRequest(String requestId, String status, {String? notes}) async {
    if (!isAdmin) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.updateServiceRequestStatus(requestId, status, notes: notes);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignTechnician(String requestId, String technicianId, {String? notes}) async {
    if (!isAdmin) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.assignTechnician(requestId, technicianId, notes: notes);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // User Management
  Future<List<dynamic>> getUsers({
    bool? isAdminFilter,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    if (!isAdmin) {
      _error = 'Access denied: Admin permissions required';
      notifyListeners();
      return [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final users = await _adminService.getUsers(
        isAdmin: isAdminFilter,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      _isLoading = false;
      notifyListeners();
      return users;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<bool> updateUserPermissions(String userId, bool isAdmin) async {
    if (!isAdmin) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.updateUserPermissions(userId, isAdmin: isAdmin);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ML Analytics
  Future<List<dynamic>> getMlAnalysisResults({
    DateTime? startDate,
    DateTime? endDate,
    String? method,
    bool? isAccurate,
    int limit = 1000,
  }) async {
    if (!isAdmin) return [];

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _adminService.getMlAnalysisResults(
        startDate: startDate,
        endDate: endDate,
        method: method,
        isAccurate: isAccurate,
        limit: limit,
      );

      _isLoading = false;
      notifyListeners();
      return results;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<Map<String, dynamic>> getMlPerformanceStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!isAdmin) return {};

    try {
      return await _adminService.getMlPerformanceStats(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }

  // Dashboard Analytics
  Future<Map<String, dynamic>> getDashboardAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!isAdmin) {
      _error = 'Access denied: Admin permissions required';
      notifyListeners();
      return {};
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final analytics = await _adminService.getDashboardAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      _isLoading = false;
      notifyListeners();
      return analytics;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }

  // Export Data
  Future<Map<String, dynamic>> exportData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!isAdmin) return {};

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final exportedData = await _adminService.exportData(
        startDate: startDate,
        endDate: endDate,
      );

      _isLoading = false;
      notifyListeners();
      return exportedData;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }

  // Account Management
  Future<bool> deleteServiceRequest(String requestId) async {
    if (!isAdmin) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.deleteServiceRequest(requestId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUserAccount(String userId) async {
    if (!isAdmin) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.deleteUserAccount(userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mock data creation (for development)
  Future<bool> createSampleData() async {
    if (!isAdmin) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.createSampleData();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

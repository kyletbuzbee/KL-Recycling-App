import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_request.dart';
import '../models/ml_analysis_result.dart';
import '../models/user.dart' as app_user;
import 'auth_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  AdminService(this._authService);

  /// Check if current user is admin
  bool get isAdmin => _authService.currentUser != null && _getUserProfle()?.isAdmin == true;

  /// Get user profile from auth service
  app_user.User? _getUserProfle() {
    return null; // TODO: Implement when AuthProvider is integrated
  }

  /// Service Requests Management
  Future<List<ServiceRequest>> getServiceRequests({
    String? status,
    String? serviceType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('serviceRequests');

      // Apply filters
      if (status != null) query = query.where('status', isEqualTo: status);
      if (serviceType != null) query = query.where('serviceType', isEqualTo: serviceType);

      // Date filters
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Order by newest first
      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => ServiceRequest.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch service requests: $e');
    }
  }

  /// Update service request status
  Future<void> updateServiceRequestStatus(String requestId, String status, {String? notes}) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (notes != null) 'adminNotes': notes,
      };

      await _firestore.collection('serviceRequests').doc(requestId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update service request: $e');
    }
  }

  /// Assign technician to service request
  Future<void> assignTechnician(String requestId, String technicianId, {String? notes}) async {
    try {
      await _firestore.collection('serviceRequests').doc(requestId).update({
        'assignedTo': technicianId,
        'status': 'assigned',
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (notes != null) 'assignmentNotes': notes,
      });
    } catch (e) {
      throw Exception('Failed to assign technician: $e');
    }
  }

  /// Users Management
  Future<List<app_user.User>> getUsers({
    bool? isAdmin,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('users');

      if (isAdmin != null) query = query.where('isAdmin', isEqualTo: isAdmin);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => app_user.User.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Update user permissions
  Future<void> updateUserPermissions(String userId, {required bool isAdmin}) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user permissions: $e');
    }
  }

  /// ML Analytics
  Future<List<MlAnalysisResult>> getMlAnalysisResults({
    DateTime? startDate,
    DateTime? endDate,
    String? method,
    bool? isAccurate,
    int limit = 1000,
  }) async {
    try {
      Query query = _firestore.collection('mlAnalysisResults');

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      if (method != null) query = query.where('method', isEqualTo: method);
      if (isAccurate != null) query = query.where('isAccurate', isEqualTo: isAccurate);

      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => MlAnalysisResult.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch ML analysis results: $e');
    }
  }

  /// Get ML performance statistics
  Future<Map<String, dynamic>> getMlPerformanceStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final mlResults = await getMlAnalysisResults(
        startDate: startDate,
        endDate: endDate,
        limit: 10000, // Large limit for stats
      );

      final totalAnalyses = mlResults.length;
      final accurateAnalyses = mlResults.where((result) => result.isAccurate ?? false).length;
      final accuracyRate = totalAnalyses > 0 ? accurateAnalyses / totalAnalyses : 0.0;

      // Group by method
      final methodStats = <String, Map<String, dynamic>>{};
      for (final result in mlResults) {
        final method = result.method ?? 'Unknown';
        methodStats[method] ??= {'total': 0, 'accurate': 0};
        methodStats[method]!['total'] += 1;
        if (result.isAccurate ?? false) {
          methodStats[method]!['accurate'] += 1;
        }
      }

      // Calculate method accuracy rates
      final methodAccuracy = <String, double>{};
      methodStats.forEach((method, stats) {
        final total = stats['total'] as int;
        final accurate = stats['accurate'] as int;
        methodAccuracy[method] = total > 0 ? accurate / total : 0.0;
      });

      return {
        'totalAnalyses': totalAnalyses,
        'accurateAnalyses': accurateAnalyses,
        'accuracyRate': accuracyRate,
        'methodStats': methodStats,
        'methodAccuracy': methodAccuracy,
      };
    } catch (e) {
      throw Exception('Failed to fetch ML performance stats: $e');
    }
  }

  /// Analytics Dashboard Data
  Future<Map<String, dynamic>> getDashboardAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get service requests stats
      final serviceRequests = await getServiceRequests(
        startDate: startDate,
        endDate: endDate,
        limit: 10000,
      );

      // Status breakdown
      final statusCounts = <String, int>{};
      for (final request in serviceRequests) {
        final statusString = request.status.toString();
        statusCounts[statusString] = (statusCounts[statusString] ?? 0) + 1;
      }

      // Service type breakdown
      final serviceTypeCounts = <String, int>{};
      for (final request in serviceRequests) {
        final serviceTypeString = _getServiceType(request);
        serviceTypeCounts[serviceTypeString] = (serviceTypeCounts[serviceTypeString] ?? 0) + 1;
      }

      // Revenue calculations (assuming standard rates)
      final revenueMap = {
        'container_rental': 50.0, // $50/month per container
        'scrap_pickup': 100.0, // $100 per pickup
        'equipment_rental': 200.0, // $200/day
        'consultation': 150.0, // $150/hour
      };

      double totalRevenue = 0;
      for (final request in serviceRequests) {
        final rate = revenueMap[_getServiceType(request)] ?? 0.0;
        totalRevenue += rate;
      }

      // Get user stats
      final users = await getUsers(startDate: startDate, endDate: endDate, limit: 10000);
      final totalUsers = users.length;
      final newUsers = users.where((user) => user.createdAt.isAfter(
        startDate ?? DateTime.now().subtract(const Duration(days: 30))
      )).length;

      // Get ML stats
      final mlStats = await getMlPerformanceStats(startDate: startDate, endDate: endDate);

      return {
        'totalServiceRequests': serviceRequests.length,
        'serviceRequestsByStatus': statusCounts,
        'serviceRequestsByType': serviceTypeCounts,
        'totalRevenue': totalRevenue,
        'totalUsers': totalUsers,
        'newUsers': newUsers,
        'mlPerformance': mlStats,
        'dateRange': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard analytics: $e');
    }
  }

  /// Export data for reporting
  Future<Map<String, dynamic>> exportData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final analytics = await getDashboardAnalytics(startDate: startDate, endDate: endDate);

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'analytics': analytics,
        'exportSource': 'KL Recycling Admin Dashboard',
      };
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Delete service request (admin only)
  Future<void> deleteServiceRequest(String requestId) async {
    try {
      await _firestore.collection('serviceRequests').doc(requestId).delete();
    } catch (e) {
      throw Exception('Failed to delete service request: $e');
    }
  }

  /// Delete user account (admin only)
  Future<void> deleteUserAccount(String userId) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // TODO: Delete user from Firebase Auth (requires admin SDK)
      // For now, just mark as deleted in Firestore
      await _firestore.collection('deletedUsers').add({
        'userId': userId,
        'deletedBy': _authService.currentUser?.uid ?? 'admin',
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete user account: $e');
    }
  }

  /// Helper method to get service type from request
  String _getServiceType(ServiceRequest request) {
    final serviceTypeMap = {
      'containerQuote': 'container_rental',
      'scrapPickup': 'scrap_pickup',
      'rollOffService': 'equipment_rental',
      'emergencyService': 'consultation',
      'wasteRemoval': 'equipment_rental',
      'generalInquiry': 'consultation',
    };
    return serviceTypeMap[request.requestType.toString()] ?? 'consultation';
  }

  /// Create sample data for testing (development only)
  Future<void> createSampleData() async {
    // This method should only be used in development
    // TODO: Implement sample data creation
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Endpoints service for external integrations and third-party access
class ApiEndpointsService {
  static const String _baseUrl = 'https://us-central1-KL-Recycling-App.cloudfunctions.net';

  ApiEndpointsService();

  /// Collection Recycler Stats API
  Future<Map<String, dynamic>> getCollectionStats({
    String? businessId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (businessId != null) queryParams['businessId'] = businessId;
      if (userId != null) queryParams['userId'] = userId;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final uri = Uri.parse('$_baseUrl/getCollectionStats').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch collection stats: $e');
    }
  }

  /// Weight Prediction API for external clients
  Future<Map<String, dynamic>> predictWeight(String imageUrl, Map<String, dynamic> metadata) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predictWeight'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imageUrl': imageUrl,
          'metadata': metadata,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to predict weight: $e');
    }
  }

  /// Business Analytics API
  Future<Map<String, dynamic>> getBusinessAnalytics(String businessId, {
    String? timeframe = 'monthly',
    bool includePredictions = false,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/getBusinessAnalytics').replace(queryParameters: {
        'businessId': businessId,
        'timeframe': timeframe,
        'includePredictions': includePredictions.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch business analytics: $e');
    }
  }

  /// Sustainability Metrics API
  Future<Map<String, dynamic>> getSustainabilityMetrics({
    String? region,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (region != null) queryParams['region'] = region;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final uri = Uri.parse('$_baseUrl/getSustainabilityMetrics').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch sustainability metrics: $e');
    }
  }

  /// Driver Location and Route Optimization API
  Future<Map<String, dynamic>> optimizeRoutes(List<Map<String, dynamic>> pickupLocations, String driverId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/optimizeRoutes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'locations': pickupLocations,
          'driverId': driverId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to optimize routes: $e');
    }
  }

  /// Inventory Management API
  Future<Map<String, dynamic>> checkInventoryAvailability(List<String> materialTypes, String businessId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/checkInventory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'materialTypes': materialTypes,
          'businessId': businessId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to check inventory: $e');
    }
  }

  /// Emergency Response API
  Future<Map<String, dynamic>> createEmergencyPickup(Map<String, dynamic> emergencyData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/createEmergencyPickup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ...emergencyData,
          'timestamp': DateTime.now().toIso8601String(),
          'urgent': true,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create emergency pickup: $e');
    }
  }

  /// Health Check API
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('System health check failed: $e');
    }
  }

  /// Webhook Integration for Third-Party Apps
  Future<Map<String, dynamic>> registerWebhook(String endpointUrl, List<String> events) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/registerWebhook'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'endpointUrl': endpointUrl,
          'events': events,
          'secretKey': await _generateWebhookSecret(),
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to register webhook: $e');
    }
  }

  /// Batch Operations API
  Future<Map<String, dynamic>> processBatchOperation(String operationType, List<Map<String, dynamic>> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/batchOperation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'operationType': operationType,
          'data': data,
          'batchId': 'batch_${DateTime.now().millisecondsSinceEpoch}',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Batch operation failed: $e');
    }
  }

  /// Generate webhook secret for authentication
  Future<String> _generateWebhookSecret() async {
    // In production, this would generate a cryptographically secure secret
    // For demo purposes, using timestamp-based approach
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'wh_$timestamp';
  }

  /// Refresh authentication token (if needed for API access)
  Future<String?> refreshApiToken(String? currentToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/refreshToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': currentToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['token'] as String?;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Token refresh failed: $e');
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kl_recycling_app/models/photo_estimate.dart' as models;

/// Enhanced Analytics Service for K&L Recycling Business Intelligence
class AnalyticsService extends ChangeNotifier {
  static const String _analyticsDataKey = 'analytics_data';
  static const String _customerProfilesKey = 'customer_profiles';

  late SharedPreferences _prefs;

  // Analytics data storage
  final List<AnalyticsEvent> _events = [];
  final Map<String, CustomerProfile> _customerProfiles = {};
  final Map<String, TrendData> _trends = {};

  // Real-time metrics
  AnalyticsMetrics _currentMetrics = AnalyticsMetrics.empty();

  // Initialization
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAnalyticsData();
    await _loadCustomerProfiles();
    await _calculateCurrentMetrics();
    notifyListeners();
  }

  // Core functionality
  AnalyticsMetrics get currentMetrics => _currentMetrics;
  Map<String, CustomerProfile> get customerProfiles => Map.from(_customerProfiles);
  Map<String, TrendData> get trends => Map.from(_trends);

  /// Track customer interaction event
  Future<void> trackEvent(AnalyticsEvent event) async {
    _events.add(event);
    await _processEvent(event);
    await _saveAnalyticsData();

    // Update real-time metrics
    await _calculateCurrentMetrics();
    notifyListeners();
  }

  /// Process photo estimate for customer analytics
  Future<void> trackPhotoEstimate(models.PhotoEstimate estimate, {String? customerId}) async {
    // Generate or use customer ID
    final effectiveCustomerId = customerId ?? _generateCustomerId(estimate);

    // Create analytics event
    final event = AnalyticsEvent(
      id: estimate.id,
      eventType: 'photo_estimate_submitted',
      customerId: effectiveCustomerId,
      timestamp: estimate.timestamp,
      data: {
        'material_type': estimate.materialType.name,
        'estimated_weight': estimate.estimatedWeight,
        'location': {
          'latitude': estimate.latitude,
          'longitude': estimate.longitude,
        },
        'facility_preference': _determineFacilityPreference(estimate),
        'value_estimate': estimate.estimatedValue,
      },
    );

    await trackEvent(event);
  }

  /// Get customer lifetime value
  double getCustomerLifetimeValue(String customerId) {
    final profile = _customerProfiles[customerId];
    if (profile == null) return 0.0;

    return profile.totalValue + profile.estimatedLifetimeValue;
  }

  /// Get customer loyalty tier
  CustomerTier getCustomerTier(String customerId) {
    final lifetimeValue = getCustomerLifetimeValue(customerId);

    if (lifetimeValue >= 10000) return CustomerTier.platinum;
    if (lifetimeValue >= 5000) return CustomerTier.gold;
    if (lifetimeValue >= 2000) return CustomerTier.silver;
    return CustomerTier.bronze;
  }

  /// Get material type preferences by customer
  Map<String, double> getCustomerMaterialPreferences(String customerId) {
    final profile = _customerProfiles[customerId];
    if (profile == null) return {};

    final totalEstimates = profile.photoEstimateCount.toDouble();
    if (totalEstimates == 0) return {};

    return Map.fromEntries(
      profile.materialBreakdown.entries.map(
        (entry) => MapEntry(entry.key, entry.value / totalEstimates),
      ),
    );
  }

  /// Get top customers by lifetime value
  List<CustomerProfile> getTopCustomers({int limit = 10}) {
    return _customerProfiles.values.toList()
      ..sort((a, b) => getCustomerLifetimeValue(b.id).compareTo(getCustomerLifetimeValue(a.id)))
      ..take(limit);
  }

  /// Get material trends over time
  Map<String, List<TrendPoint>> getMaterialTrends({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    // Group estimates by material and date
    Map<String, Map<DateTime, double>> materialDailyTotals = {};

    for (final event in _events.where((e) =>
      e.eventType == 'photo_estimate_submitted' &&
      e.timestamp.isAfter(cutoffDate)
    )) {
      final materialType = event.data?['material_type'] as String?;
      if (materialType == null) continue;

      final date = DateTime(event.timestamp.year, event.timestamp.month, event.timestamp.day);
      final weight = event.data?['estimated_weight'] as double? ?? 0.0;

      materialDailyTotals.putIfAbsent(materialType, () => {});
      materialDailyTotals[materialType]![date] = (materialDailyTotals[materialType]![date] ?? 0) + weight;
    }

    // Convert to trend points
    return materialDailyTotals.map((material, dailyData) {
      final trendPoints = dailyData.entries.map((entry) => TrendPoint(
        date: entry.key,
        value: entry.value,
      )).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return MapEntry(material, trendPoints);
    });
  }

  /// Get busy times for appointment scheduling
  List<BusyTimeSlot> getBusyTimeSlots(int daysAhead) {
    final slots = <BusyTimeSlot>[];

    // Analyze appointment patterns from events
    for (int day = 0; day < daysAhead; day++) {
      final date = DateTime.now().add(Duration(days: day));
      final dayEvents = _events.where((e) =>
        e.timestamp.year == date.year &&
        e.timestamp.month == date.month &&
        e.timestamp.day == date.day
      );

      // Group by hour
      final hourlyCounts = <int, int>{};
      for (final event in dayEvents) {
        final hour = event.timestamp.hour;
        hourlyCounts[hour] = (hourlyCounts[hour] ?? 0) + 1;
      }

      // Create busy slots
      for (final entry in hourlyCounts.entries) {
        final utilization = entry.value / 10.0; // Assume 10 slots per hour max
        slots.add(BusyTimeSlot(
          date: date,
          hour: entry.key,
          utilizationPercentage: (utilization * 100).clamp(0, 100),
        ));
      }
    }

    return slots;
  }

  /// Export analytics data for business reporting
  Future<Map<String, dynamic>> exportAnalyticsData() async {
    return {
      'metrics': _currentMetrics.toJson(),
      'customer_profiles': _customerProfiles.map((k, v) => MapEntry(k, v.toJson())),
      'trends': _trends.map((k, v) => MapEntry(k, v.toJson())),
      'events_count': _events.length,
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Private helper methods
  Future<void> _processEvent(AnalyticsEvent event) async {
    // Update customer profile
    _updateCustomerProfile(event);

    // Update trends
    _updateTrends(event);
  }

  void _updateCustomerProfile(AnalyticsEvent event) {
    final customerId = event.customerId;
    final profile = _customerProfiles.putIfAbsent(customerId, () => CustomerProfile(id: customerId));

    if (event.eventType == 'photo_estimate_submitted') {
      profile.photoEstimateCount++;
      profile.lastActivity = event.timestamp;

      // Update first activity if not set
      profile.firstActivity ??= event.timestamp;

      // Update material breakdown
      final materialType = event.data?['material_type'] as String?;
      if (materialType != null) {
        profile.materialBreakdown[materialType] = (profile.materialBreakdown[materialType] ?? 0) + 1;
      }

      // Update location preferences
      final latitude = event.data?['location']?['latitude'] as double?;
      final longitude = event.data?['location']?['longitude'] as double?;
      if (latitude != null && longitude != null) {
        profile.preferredLocations.add(LocationData(latitude: latitude, longitude: longitude));
      }

      // Calculate estimated lifetime value
      profile.totalValue = profile.photoEstimateCount * 50.0; // Rough estimate
      profile.estimatedLifetimeValue = profile.totalValue * 1.5; // Conservative projection
    }
  }

  void _updateTrends(AnalyticsEvent event) {
    if (event.eventType == 'photo_estimate_submitted') {
      final materialType = event.data?['material_type'] as String?;
      final weight = event.data?['estimated_weight'] as double?;
      final value = event.data?['value_estimate'] as double?;

      if (materialType != null) {
        final trend = _trends.putIfAbsent(materialType, () => TrendData(
          metric: materialType,
          unit: 'lbs',
          points: [],
        ));

        // Add data point for this day
        final dateKey = DateTime(event.timestamp.year, event.timestamp.month, event.timestamp.day);
        final existingPoint = trend.points.where((p) => p.date == dateKey).firstOrNull;

        if (existingPoint != null) {
          existingPoint.value += weight ?? 0.0;
        } else {
          trend.points.add(TrendPoint(date: dateKey, value: weight ?? 0.0));
        }
      }
    }
  }

  Future<void> _calculateCurrentMetrics() async {
    // Calculate metrics from events and profiles
    final totalEstimates = _events.where((e) => e.eventType == 'photo_estimate_submitted').length;
    final totalCustomers = _customerProfiles.length;
    final totalValue = _customerProfiles.values.fold(0.0, (sum, profile) => sum + profile.totalValue);

    // Material distribution
    final materialCounts = <String, int>{};
    for (final event in _events.where((e) => e.eventType == 'photo_estimate_submitted')) {
      final materialType = event.data?['material_type'] as String?;
      if (materialType != null) {
        materialCounts[materialType] = (materialCounts[materialType] ?? 0) + 1;
      }
    }

    _currentMetrics = AnalyticsMetrics(
      totalPhotoEstimates: totalEstimates,
      totalCustomers: totalCustomers,
      totalEstimatedValue: totalValue,
      materialDistribution: materialCounts,
      averageValuePerEstimate: totalEstimates > 0 ? totalValue / totalEstimates : 0.0,
      topMaterial: materialCounts.entries.isNotEmpty
        ? materialCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null,
    );
  }

  String _generateCustomerId(models.PhotoEstimate estimate) {
    // Generate deterministic customer ID based on device/location patterns
    // In real implementation, this would use device ID or user authentication
    final hash = estimate.latitude?.toString() ?? estimate.longitude?.toString() ?? 'anonymous';
    return 'cust_${hash.hashCode.abs()}';
  }

  String? _determineFacilityPreference(models.PhotoEstimate estimate) {
    // Determine closest facility based on coordinates
    // This is a placeholder - real implementation would calculate actual distances
    if (estimate.latitude != null && estimate.longitude != null) {
      return 'nearest_facility_based_on_coords';
    }
    return null;
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final jsonData = _prefs.getStringList(_analyticsDataKey) ?? [];
      for (final jsonStr in jsonData) {
        final eventData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final event = AnalyticsEvent.fromJson(eventData);
        _events.add(event);
      }
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
    }
  }

  Future<void> _loadCustomerProfiles() async {
    try {
      final jsonData = _prefs.getString(_customerProfilesKey);
      if (jsonData != null) {
        final data = jsonDecode(jsonData) as Map<String, dynamic>;
        for (final entry in data.entries) {
          final profile = CustomerProfile.fromJson(entry.value as Map<String, dynamic>);
          _customerProfiles[entry.key] = profile;
        }
      }
    } catch (e) {
      debugPrint('Error loading customer profiles: $e');
    }
  }

  Future<void> _saveAnalyticsData() async {
    try {
      // Keep only last 1000 events to prevent storage bloat
      if (_events.length > 1000) {
        _events.removeRange(0, _events.length - 1000);
      }

      final jsonData = _events.map((event) => jsonEncode(event.toJson())).toList();
      await _prefs.setStringList(_analyticsDataKey, jsonData);

      // Save customer profiles
      final profileData = _customerProfiles.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs.setString(_customerProfilesKey, jsonEncode(profileData));

    } catch (e) {
      debugPrint('Error saving analytics data: $e');
    }
  }
}

// Supporting data models
class AnalyticsEvent {
  final String id;
  final String eventType;
  final String customerId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  AnalyticsEvent({
    required this.id,
    required this.eventType,
    required this.customerId,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventType': eventType,
    'customerId': customerId,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
    id: json['id'],
    eventType: json['eventType'],
    customerId: json['customerId'],
    timestamp: DateTime.parse(json['timestamp']),
    data: json['data'],
  );
}

class AnalyticsMetrics {
  final int totalPhotoEstimates;
  final int totalCustomers;
  final double totalEstimatedValue;
  final Map<String, int> materialDistribution;
  final double averageValuePerEstimate;
  final String? topMaterial;

  AnalyticsMetrics({
    required this.totalPhotoEstimates,
    required this.totalCustomers,
    required this.totalEstimatedValue,
    required this.materialDistribution,
    required this.averageValuePerEstimate,
    this.topMaterial,
  });

  factory AnalyticsMetrics.empty() => AnalyticsMetrics(
    totalPhotoEstimates: 0,
    totalCustomers: 0,
    totalEstimatedValue: 0.0,
    materialDistribution: {},
    averageValuePerEstimate: 0.0,
    topMaterial: null,
  );

  Map<String, dynamic> toJson() => {
    'totalPhotoEstimates': totalPhotoEstimates,
    'totalCustomers': totalCustomers,
    'totalEstimatedValue': totalEstimatedValue,
    'materialDistribution': materialDistribution,
    'averageValuePerEstimate': averageValuePerEstimate,
    'topMaterial': topMaterial,
  };
}

enum CustomerTier {
  bronze,
  silver,
  gold,
  platinum,
}

extension CustomerTierExtension on CustomerTier {
  String get displayName {
    switch (this) {
      case CustomerTier.bronze: return 'Bronze';
      case CustomerTier.silver: return 'Silver';
      case CustomerTier.gold: return 'Gold';
      case CustomerTier.platinum: return 'Platinum';
    }
  }

  Color get color {
    switch (this) {
      case CustomerTier.bronze: return const Color(0xFFCD7F32);
      case CustomerTier.silver: return const Color(0xFFC0C0C0);
      case CustomerTier.gold: return const Color(0xFFFFD700);
      case CustomerTier.platinum: return const Color(0xFFE5E4E2);
    }
  }

  double get minValue {
    switch (this) {
      case CustomerTier.bronze: return 0;
      case CustomerTier.silver: return 2000;
      case CustomerTier.gold: return 5000;
      case CustomerTier.platinum: return 10000;
    }
  }
}

class CustomerProfile {
  final String id;
  int photoEstimateCount;
  DateTime? firstActivity;
  DateTime? lastActivity;
  Map<String, int> materialBreakdown;
  List<LocationData> preferredLocations;
  double totalValue;
  double estimatedLifetimeValue;

  CustomerProfile({
    required this.id,
    this.photoEstimateCount = 0,
    this.firstActivity,
    this.lastActivity,
    Map<String, int>? materialBreakdown,
    List<LocationData>? preferredLocations,
    this.totalValue = 0.0,
    this.estimatedLifetimeValue = 0.0,
  }) :
    materialBreakdown = materialBreakdown ?? {},
    preferredLocations = preferredLocations ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'photoEstimateCount': photoEstimateCount,
    'firstActivity': firstActivity?.toIso8601String(),
    'lastActivity': lastActivity?.toIso8601String(),
    'materialBreakdown': materialBreakdown,
    'preferredLocations': preferredLocations.map((loc) => {'lat': loc.latitude, 'lon': loc.longitude}).toList(),
    'totalValue': totalValue,
    'estimatedLifetimeValue': estimatedLifetimeValue,
  };

  factory CustomerProfile.fromJson(Map<String, dynamic> json) => CustomerProfile(
    id: json['id'],
    photoEstimateCount: json['photoEstimateCount'] ?? 0,
    firstActivity: json['firstActivity'] != null ? DateTime.parse(json['firstActivity']) : null,
    lastActivity: json['lastActivity'] != null ? DateTime.parse(json['lastActivity']) : null,
    materialBreakdown: Map<String, int>.from(json['materialBreakdown'] ?? {}),
    preferredLocations: (json['preferredLocations'] as List<dynamic>? ?? [])
      .map((loc) => LocationData(latitude: loc['lat'], longitude: loc['lon']))
      .toList(),
    totalValue: json['totalValue'] ?? 0.0,
    estimatedLifetimeValue: json['estimatedLifetimeValue'] ?? 0.0,
  );

  Duration? get customerAge {
    if (firstActivity == null) return null;
    return DateTime.now().difference(firstActivity!);
  }

  double get estimatedMonthlyValue {
    if (customerAge == null || customerAge!.inDays < 30) return totalValue;
    final months = customerAge!.inDays / 30.0;
    return totalValue / months;
  }
}

class LocationData {
  final double latitude;
  final double longitude;

  LocationData({required this.latitude, required this.longitude});
}

class TrendPoint {
  final DateTime date;
  double value;

  TrendPoint({required this.date, required this.value});
}

class TrendData {
  final String metric;
  final String unit;
  final List<TrendPoint> points;

  TrendData({
    required this.metric,
    required this.unit,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
    'metric': metric,
    'unit': unit,
    'points': points.map((p) => {'date': p.date.toIso8601String(), 'value': p.value}).toList(),
  };
}

class BusyTimeSlot {
  final DateTime date;
  final int hour;
  final double utilizationPercentage;

  BusyTimeSlot({
    required this.date,
    required this.hour,
    required this.utilizationPercentage,
  });
}

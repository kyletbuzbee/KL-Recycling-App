import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kl_recycling_app/models/enhanced_analytics.dart';
import 'package:kl_recycling_app/services/analytics_service.dart';

/// Enhanced analytics service with business intelligence capabilities
/// Generates revenue, facility, customer, and operational analytics
class EnhancedAnalyticsService extends ChangeNotifier {
  static const String _revenueDataKey = 'revenue_data';
  static const String _facilityMetricsKey = 'facility_metrics';
  static const String _customerAnalyticsKey = 'customer_analytics';
  static const String _materialAnalyticsKey = 'material_analytics';
  static const String _recommendationsKey = 'recommendations';
  static const String _preferencesKey = 'dashboard_preferences';

  late SharedPreferences _prefs;

  // Data stores
  final List<RevenueData> _revenueData = [];
  final List<FacilityMetrics> _facilityMetrics = [];
  final List<CustomerAnalytics> _customerAnalytics = [];
  final List<MaterialAnalytics> _materialAnalytics = [];
  final List<BusinessRecommendation> _recommendations = [];

  late AnalyticsService _baseAnalyticsService;

  // Dashboard preferences
  DashboardPreferences _preferences = DashboardPreferences(
    visibleMetrics: ['revenue', 'appointments', 'utilization', 'customers'],
    timeRangeSettings: {'revenue': 'last30Days', 'appointments': 'last30Days'},
    chartTypes: {'revenue': ['line'], 'utilization': ['bar']},
    alertsEnabled: {'low_utilization': true, 'high_demand': true},
    thresholds: {'low_utilization': 50.0, 'high_demand': 80.0},
  );

  // Initialization
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Initialize with sample data for demonstration
    await _initializeSampleData();

    // Load existing data
    await _loadAllData();

    // Generate initial recommendations
    await _generateRecommendations();

    notifyListeners();
  }

  void setAnalyticsService(AnalyticsService service) {
    _baseAnalyticsService = service;
  }

  // Public getters
  List<RevenueData> get revenueData => List.from(_revenueData);
  List<FacilityMetrics> get facilityMetrics => List.from(_facilityMetrics);
  List<CustomerAnalytics> get customerAnalytics => List.from(_customerAnalytics);
  List<MaterialAnalytics> get materialAnalytics => List.from(_materialAnalytics);
  List<BusinessRecommendation> get recommendations => List.from(_recommendations);
  DashboardPreferences get preferences => _preferences;

  /// Generate revenue analytics from appointment and estimate data
  Future<void> generateRevenueAnalytics(TimeRange timeRange) async {
    final dateRange = timeRange.getDateRange();
    final startDate = dateRange[0];
    final endDate = dateRange[1];

    List<RevenueData> newRevenueData = [];

    // Group by week for weekly analytics
    DateTime current = startDate;
    while (current.isBefore(endDate)) {
      DateTime weekEnd = current.add(const Duration(days: 7));
      if (weekEnd.isAfter(endDate)) weekEnd = endDate;

      // Calculate revenue for this week
      double totalRevenue = 0.0;
      double totalCost = 0.0;
      Map<String, double> materialRevenue = {};
      Map<String, int> appointmentTypeCount = {};
      int appointmentCount = 0;

      // In a real implementation, this would come from appointment completion records
      // For demo, we'll generate realistic sample data
      totalRevenue = (Random().nextDouble() * 50000) + 25000; // $25K-$75K
      totalCost = totalRevenue * 0.35; // 35% cost of goods
      appointmentCount = Random().nextInt(50) + 20; // 20-70 appointments

      // Material distribution
      materialRevenue = {
        'steel': totalRevenue * 0.45,
        'aluminum': totalRevenue * 0.25,
        'copper': totalRevenue * 0.20,
        'brass': totalRevenue * 0.10,
      };

      appointmentTypeCount = {
        'materialPickup': (appointmentCount * 0.7).round(),
        'containerDelivery': (appointmentCount * 0.2).round(),
        'bulkMaterial': (appointmentCount * 0.1).round(),
      };

      newRevenueData.add(RevenueData(
        date: current,
        totalRevenue: totalRevenue,
        totalCost: totalCost,
        netProfit: totalRevenue - totalCost,
        appointmentCount: appointmentCount,
        materialRevenue: materialRevenue,
        appointmentTypeCount: appointmentTypeCount,
        averageRevenuePerAppointment: totalRevenue / appointmentCount,
      ));

      current = weekEnd;
    }

    _revenueData.clear();
    _revenueData.addAll(newRevenueData);
    await _saveRevenueData();

    await _generateRevenueRecommendations();
    notifyListeners();
  }

  /// Generate facility utilization metrics
  Future<void> generateFacilityMetrics(TimeRange timeRange) async {
    final facilities = ['facility_main']; // In real implementation, get from appointment service
    final dateRange = timeRange.getDateRange();

    List<FacilityMetrics> newMetrics = [];

    for (final facilityId in facilities) {
      DateTime current = dateRange[0];
      while (current.isBefore(dateRange[1])) {
        // Generate realistic utilization data
        final utilization = (Random().nextDouble() * 40) + 60; // 60-100%
        final totalAppointments = (utilization / 100 * 8).round(); // Max 8 appointments per day
        final completedAppointments = (totalAppointments * 0.85).round();
        final cancelledAppointments = totalAppointments - completedAppointments;
        final revenue = Random().nextDouble() * 8000 + 2000; // $2K-$10K per day

        newMetrics.add(FacilityMetrics(
          facilityId: facilityId,
          date: current,
          utilizationPercentage: utilization,
          totalAppointments: totalAppointments,
          completedAppointments: completedAppointments,
          cancelledAppointments: cancelledAppointments,
          averageAppointmentTime: 45.0 + Random().nextDouble() * 30, // 45-75 minutes
          revenue: revenue,
          appointmentTypeDistribution: {
            'materialPickup': (totalAppointments * 0.6).round(),
            'containerDelivery': (totalAppointments * 0.3).round(),
            'bulkMaterial': (totalAppointments * 0.1).round(),
          },
          equipmentUtilization: {
            'truck1': Random().nextDouble() * 40 + 60,
            'scale1': Random().nextDouble() * 20 + 80,
            'forklift1': Random().nextDouble() * 30 + 50,
          },
          peakHour: Random().nextInt(4) + 10, // 10 AM - 2 PM
          peakDayOfWeek: Random().nextInt(5) + 1, // Monday-Friday
          customerSatisfactionScore: 4.0 + Random().nextDouble(), // 4.0-5.0
        ));

        current = current.add(const Duration(days: 1));
      }
    }

    _facilityMetrics.clear();
    _facilityMetrics.addAll(newMetrics);
    await _saveFacilityMetrics();

    await _generateFacilityRecommendations();
    notifyListeners();
  }

  /// Generate customer analytics data
  Future<void> generateCustomerAnalytics(TimeRange timeRange) async {
    final totalCustomers = 1250 + Random().nextInt(250); // 1250-1500 customers
    final newCustomers = (totalCustomers * 0.15).round(); // 15% new customers
    final returningCustomers = totalCustomers - newCustomers;

    _customerAnalytics.clear();
    _customerAnalytics.add(CustomerAnalytics(
      period: timeRange.getDateRange()[0],
      newCustomers: newCustomers,
      returningCustomers: returningCustomers,
      totalCustomers: totalCustomers,
      retentionRate: 78.0 + Random().nextDouble() * 10, // 78-88%
      customerTierDistribution: {
        'bronze': (totalCustomers * 0.5).round(),
        'silver': (totalCustomers * 0.3).round(),
        'gold': (totalCustomers * 0.15).round(),
        'platinum': (totalCustomers * 0.05).round(),
      },
      customerLifetimeValue: {
        'bronze': 450.0,
        'silver': 1200.0,
        'gold': 2800.0,
        'platinum': 6500.0,
      },
      preferredMaterialTypes: {
        'steel': (totalCustomers * 0.45).round(),
        'aluminum': (totalCustomers * 0.30).round(),
        'copper': (totalCustomers * 0.20).round(),
        'brass': (totalCustomers * 0.05).round(),
      },
      preferredAppointmentTypes: {
        'materialPickup': (totalCustomers * 0.8).round(),
        'containerDelivery': (totalCustomers * 0.15).round(),
        'consultation': (totalCustomers * 0.05).round(),
      },
      averageAppointmentFrequency: 1.2 + Random().nextDouble() * 0.8, // 1.2-2.0 appointments/month
      geographicDistribution: {
        'Tyler': (totalCustomers * 0.4).round(),
        'Longview': (totalCustomers * 0.2).round(),
        'Kilgore': (totalCustomers * 0.15).round(),
        'Gladewater': (totalCustomers * 0.1).round(),
        'Mineola': (totalCustomers * 0.15).round(),
      },
      customerSatisfactionByTier: {
        'bronze': 3.8 + Random().nextDouble() * 0.4,
        'silver': 4.1 + Random().nextDouble() * 0.3,
        'gold': 4.5 + Random().nextDouble() * 0.3,
        'platinum': 4.8 + Random().nextDouble() * 0.2,
      },
    ));

    await _saveCustomerAnalytics();
    await _generateCustomerRecommendations();
    notifyListeners();
  }

  /// Generate material profitability analytics
  Future<void> generateMaterialAnalytics(TimeRange timeRange) async {
    final materials = ['steel', 'aluminum', 'copper', 'brass'];

    List<MaterialAnalytics> newAnalytics = [];

    for (final material in materials) {
      final basePrice = _getMaterialBasePrice(material);
      final totalWeight = 10000 + Random().nextDouble() * 30000; // 10-40 tons
      final averagePrice = basePrice * (0.9 + Random().nextDouble() * 0.2); // ±10% variation
      final totalRevenue = totalWeight * averagePrice;
      final appointmentCount = (50 + Random().nextInt(100)).toInt(); // 50-150 appointments

      newAnalytics.add(MaterialAnalytics(
        materialType: material,
        period: timeRange.getDateRange()[0],
        totalWeight: totalWeight,
        totalRevenue: totalRevenue,
        averagePricePerLb: averagePrice,
        profitMargin: 25.0 + Random().nextDouble() * 15, // 25-40% margin
        appointmentCount: appointmentCount,
        customerTierDistribution: {
          'bronze': (appointmentCount * 0.4).round(),
          'silver': (appointmentCount * 0.35).round(),
          'gold': (appointmentCount * 0.20).round(),
          'platinum': (appointmentCount * 0.05).round(),
        },
        regionalPricing: {
          'Tyler': averagePrice * (0.95 + Random().nextDouble() * 0.1),
          'Longview': averagePrice * (0.98 + Random().nextDouble() * 0.04),
          'Kilgore': averagePrice * (0.97 + Random().nextDouble() * 0.06),
        },
        priceHistory: List.generate(12, (i) =>
          basePrice * (0.9 + Random().nextDouble() * 0.2)
        ),
        demandIndex: 30 + Random().nextInt(70) + Random().nextDouble(), // 30-100
        seasonalDistribution: {
          '1': (appointmentCount * 0.08).round(), // January
          '2': (appointmentCount * 0.07).round(),
          '3': (appointmentCount * 0.09).round(),
          '4': (appointmentCount * 0.08).round(),
          '5': (appointmentCount * 0.09).round(),
          '6': (appointmentCount * 0.08).round(),
          '7': (appointmentCount * 0.07).round(),
          '8': (appointmentCount * 0.08).round(),
          '9': (appointmentCount * 0.09).round(),
          '10': (appointmentCount * 0.09).round(),
          '11': (appointmentCount * 0.08).round(),
          '12': (appointmentCount * 0.08).round(),
        },
      ));
    }

    _materialAnalytics.clear();
    _materialAnalytics.addAll(newAnalytics);
    await _saveMaterialAnalytics();

    await _generateMaterialRecommendations();
    notifyListeners();
  }

  double _getMaterialBasePrice(String material) {
    switch (material) {
      case 'steel': return 0.15; // $0.15/lb
      case 'aluminum': return 0.85; // $0.85/lb
      case 'copper': return 3.50; // $3.50/lb
      case 'brass': return 1.20; // $1.20/lb
      default: return 0.10;
    }
  }

  /// Update dashboard preferences
  Future<void> updatePreferences(DashboardPreferences newPreferences) async {
    _preferences = newPreferences;
    await _saveDashboardPreferences();
    notifyListeners();
  }

  /// Get key performance indicators
  Map<String, double> getKPIs() {
    if (_revenueData.isEmpty) return {};

    // Calculate totals for the most recent period
    final latestRevenue = _revenueData.last;
    final latestFacilityMetrics = _facilityMetrics.last;
    final latestCustomerAnalytics = _customerAnalytics.isNotEmpty ? _customerAnalytics.last : null;

    return {
      'totalRevenue': latestRevenue.totalRevenue,
      'netProfit': latestRevenue.netProfit,
      'profitMargin': latestRevenue.profitMargin,
      'totalAppointments': latestRevenue.appointmentCount.toDouble(),
      'facilityUtilization': latestFacilityMetrics.utilizationPercentage ?? 0.0,
      'customerRetention': latestCustomerAnalytics?.retentionRate ?? 0.0,
      'customerSatisfaction': latestFacilityMetrics.customerSatisfactionScore ?? 0.0,
    };
  }

  /// Export analytics data for reporting
  Future<Map<String, dynamic>> exportAnalyticsData() async {
    return {
      'revenueData': _revenueData.map((r) => r.toJson()).toList(),
      'facilityMetrics': _facilityMetrics.map((f) => f.toJson()).toList(),
      'customerAnalytics': _customerAnalytics.map((c) => c.toJson()).toList(),
      'materialAnalytics': _materialAnalytics.map((m) => m.toJson()).toList(),
      'recommendations': _recommendations.map((r) => r.toJson()).toList(),
      'kpis': getKPIs(),
      'exportTimestamp': DateTime.now().toIso8601String(),
    };
  }

  // Private helper methods
  Future<void> _initializeSampleData() async {
    await generateRevenueAnalytics(TimeRange.last30Days);
    await generateFacilityMetrics(TimeRange.last30Days);
    await generateCustomerAnalytics(TimeRange.last30Days);
    await generateMaterialAnalytics(TimeRange.last30Days);
  }

  Future<void> _generateRevenueRecommendations() async {
    if (_revenueData.isEmpty) return;

    final latestRevenue = _revenueData.last;

    // Revenue optimization recommendations
    if (latestRevenue.profitMargin < 20) {
      _recommendations.add(BusinessRecommendation(
        id: 'revenue_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Optimize Pricing Strategy',
        description: 'Current profit margin (${latestRevenue.profitMargin.toStringAsFixed(1)}%) below target. Consider adjusting material pricing or reducing costs.',
        category: 'revenue',
        priority: RecommendationPriority.high,
        createdAt: DateTime.now(),
        metrics: {
          'currentMargin': latestRevenue.profitMargin,
          'targetMargin': 25.0,
          'monthlyRevenue': latestRevenue.totalRevenue,
        },
        expectedImpact: 15, // 15% margin improvement
      ));
    }

    await _saveRecommendations();
  }

  Future<void> _generateFacilityRecommendations() async {
    if (_facilityMetrics.isEmpty) return;

    final latestMetrics = _facilityMetrics.last;

    // Capacity recommendations
    if (latestMetrics.utilizationPercentage > 90) {
      _recommendations.add(BusinessRecommendation(
        id: 'facility_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Expand Facility Capacity',
        description: 'Facility utilization at ${(latestMetrics.utilizationPercentage).toStringAsFixed(1)}%. Consider adding more trucks or extending hours.',
        category: 'facility',
        priority: latestMetrics.utilizationPercentage > 95 ? RecommendationPriority.critical : RecommendationPriority.high,
        createdAt: DateTime.now(),
        metrics: {
          'currentUtilization': latestMetrics.utilizationPercentage,
          'capacityThreshold': 90.0,
          'peakHour': latestMetrics.peakHour,
        },
        expectedImpact: 25, // 25% capacity increase
      ));
    }

    await _saveRecommendations();
  }

  Future<void> _generateCustomerRecommendations() async {
    if (_customerAnalytics.isEmpty) return;

    final analytics = _customerAnalytics.last;

    // Customer retention recommendations
    if (analytics.retentionRate < 80) {
      _recommendations.add(BusinessRecommendation(
        id: 'customer_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Improve Customer Retention',
        description: 'Customer retention rate at ${(analytics.retentionRate).toStringAsFixed(1)}%. Implement loyalty program and follow-up communications.',
        category: 'customer',
        priority: RecommendationPriority.high,
        createdAt: DateTime.now(),
        metrics: {
          'currentRetention': analytics.retentionRate,
          'targetRetention': 85.0,
          'totalCustomers': analytics.totalCustomers,
        },
        expectedImpact: 15, // 15% retention increase
      ));
    }

    await _saveRecommendations();
  }

  Future<void> _generateMaterialRecommendations() async {
    if (_materialAnalytics.isEmpty) return;

    // Find highest demand material
    final highDemandMaterial = _materialAnalytics.reduce((a, b) =>
      a.demandIndex > b.demandIndex ? a : b);

    _recommendations.add(BusinessRecommendation(
      id: 'material_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Stock High-Demand Material: ${highDemandMaterial.materialType}',
      description: 'Demand index for ${highDemandMaterial.materialType} at ${(highDemandMaterial.demandIndex).toStringAsFixed(1)}. Consider increasing inventory and pricing.',
      category: 'operations',
      priority: RecommendationPriority.medium,
      createdAt: DateTime.now(),
      metrics: {
        'material': highDemandMaterial.materialType,
        'demandIndex': highDemandMaterial.demandIndex,
        'monthlyRevenue': highDemandMaterial.totalRevenue,
      },
      expectedImpact: 10, // 10% revenue increase
    ));

    await _saveRecommendations();
  }

  Future<void> _generateRecommendations() async {
    await _generateRevenueRecommendations();
    await _generateFacilityRecommendations();
    await _generateCustomerRecommendations();
    await _generateMaterialRecommendations();
  }

  // Data persistence methods
  Future<void> _loadAllData() async {
    await _loadRevenueData();
    await _loadFacilityMetrics();
    await _loadCustomerAnalytics();
    await _loadMaterialAnalytics();
    await _loadRecommendations();
    await _loadDashboardPreferences();
  }

  Future<void> _saveRevenueData() async {
    final data = _revenueData.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList(_revenueDataKey, data);
  }

  Future<void> _saveFacilityMetrics() async {
    final data = _facilityMetrics.map((f) => jsonEncode(f.toJson())).toList();
    await _prefs.setStringList(_facilityMetricsKey, data);
  }

  Future<void> _saveCustomerAnalytics() async {
    final data = _customerAnalytics.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList(_customerAnalyticsKey, data);
  }

  Future<void> _saveMaterialAnalytics() async {
    final data = _materialAnalytics.map((m) => jsonEncode(m.toJson())).toList();
    await _prefs.setStringList(_materialAnalyticsKey, data);
  }

  Future<void> _saveRecommendations() async {
    final data = _recommendations.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList(_recommendationsKey, data);
  }

  Future<void> _saveDashboardPreferences() async {
    await _prefs.setString(_preferencesKey, jsonEncode(_preferences.toJson()));
  }

  Future<void> _loadRevenueData() async {
    final data = _prefs.getStringList(_revenueDataKey) ?? [];
    _revenueData.clear();
    _revenueData.addAll(data.map((json) => RevenueData.fromJson(jsonDecode(json))));
  }

  Future<void> _loadFacilityMetrics() async {
    final data = _prefs.getStringList(_facilityMetricsKey) ?? [];
    _facilityMetrics.clear();
    _facilityMetrics.addAll(data.map((json) => FacilityMetrics.fromJson(jsonDecode(json))));
  }

  Future<void> _loadCustomerAnalytics() async {
    final data = _prefs.getStringList(_customerAnalyticsKey) ?? [];
    _customerAnalytics.clear();
    _customerAnalytics.addAll(data.map((json) => CustomerAnalytics.fromJson(jsonDecode(json))));
  }

  Future<void> _loadMaterialAnalytics() async {
    final data = _prefs.getStringList(_materialAnalyticsKey) ?? [];
    _materialAnalytics.clear();
    _materialAnalytics.addAll(data.map((json) => MaterialAnalytics.fromJson(jsonDecode(json))));
  }

  Future<void> _loadRecommendations() async {
    final data = _prefs.getStringList(_recommendationsKey) ?? [];
    _recommendations.clear();
    _recommendations.addAll(data.map((json) => BusinessRecommendation.fromJson(jsonDecode(json))));
  }

  Future<void> _loadDashboardPreferences() async {
    final data = _prefs.getString(_preferencesKey);
    if (data != null) {
      _preferences = DashboardPreferences.fromJson(jsonDecode(data));
    }
  }
}

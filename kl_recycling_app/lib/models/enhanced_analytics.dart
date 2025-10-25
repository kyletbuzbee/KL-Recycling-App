/// Enhanced analytics models for comprehensive business intelligence dashboard
/// Includes revenue tracking, facility utilization, operational metrics, and predictive analysis
library;

import 'package:flutter/material.dart';

/// Revenue and profit analysis data
class RevenueData {
  final DateTime date;
  final double totalRevenue;
  final double totalCost;
  final double netProfit;
  final int appointmentCount;
  final Map<String, double> materialRevenue; // material -> revenue
  final Map<String, int> appointmentTypeCount;
  final double averageRevenuePerAppointment;

  RevenueData({
    required this.date,
    required this.totalRevenue,
    required this.totalCost,
    required this.netProfit,
    required this.appointmentCount,
    required this.materialRevenue,
    required this.appointmentTypeCount,
    required this.averageRevenuePerAppointment,
  });

  double get profitMargin => totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'totalRevenue': totalRevenue,
    'totalCost': totalCost,
    'netProfit': netProfit,
    'appointmentCount': appointmentCount,
    'materialRevenue': materialRevenue,
    'appointmentTypeCount': appointmentTypeCount,
    'averageRevenuePerAppointment': averageRevenuePerAppointment,
  };

  factory RevenueData.fromJson(Map<String, dynamic> json) => RevenueData(
    date: DateTime.parse(json['date']),
    totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
    totalCost: json['totalCost']?.toDouble() ?? 0.0,
    netProfit: json['netProfit']?.toDouble() ?? 0.0,
    appointmentCount: json['appointmentCount'] ?? 0,
    materialRevenue: Map<String, double>.from(json['materialRevenue'] ?? {}),
    appointmentTypeCount: Map<String, int>.from(json['appointmentTypeCount'] ?? {}),
    averageRevenuePerAppointment: json['averageRevenuePerAppointment']?.toDouble() ?? 0.0,
  );

  RevenueData copyWith({
    DateTime? date,
    double? totalRevenue,
    double? totalCost,
    double? netProfit,
    int? appointmentCount,
    Map<String, double>? materialRevenue,
    Map<String, int>? appointmentTypeCount,
    double? averageRevenuePerAppointment,
  }) {
    return RevenueData(
      date: date ?? this.date,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCost: totalCost ?? this.totalRevenue,
      netProfit: netProfit ?? this.netProfit,
      appointmentCount: appointmentCount ?? this.appointmentCount,
      materialRevenue: materialRevenue ?? this.materialRevenue,
      appointmentTypeCount: appointmentTypeCount ?? this.appointmentTypeCount,
      averageRevenuePerAppointment: averageRevenuePerAppointment ?? this.averageRevenuePerAppointment,
    );
  }
}

/// Facility utilization and operational metrics
class FacilityMetrics {
  final String facilityId;
  final DateTime date;
  final double utilizationPercentage; // 0-100
  final int totalAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final double averageAppointmentTime; // in minutes
  final double revenue;
  final Map<String, int> appointmentTypeDistribution;
  final Map<String, double> equipmentUtilization; // equipment -> utilization %
  final int peakHour; // busiest hour of day
  final int peakDayOfWeek; // busiest day (1-7, Monday-Sunday)
  final double customerSatisfactionScore;

  FacilityMetrics({
    required this.facilityId,
    required this.date,
    required this.utilizationPercentage,
    required this.totalAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.averageAppointmentTime,
    required this.revenue,
    required this.appointmentTypeDistribution,
    required this.equipmentUtilization,
    required this.peakHour,
    required this.peakDayOfWeek,
    required this.customerSatisfactionScore,
  });

  double get onTimeCompletionRate => totalAppointments > 0
      ? (completedAppointments / totalAppointments) * 100 : 0;

  double get noShowRate => totalAppointments > 0
      ? ((totalAppointments - completedAppointments - cancelledAppointments) / totalAppointments) * 100 : 0;

  Map<String, dynamic> toJson() => {
    'facilityId': facilityId,
    'date': date.toIso8601String(),
    'utilizationPercentage': utilizationPercentage,
    'totalAppointments': totalAppointments,
    'completedAppointments': completedAppointments,
    'cancelledAppointments': cancelledAppointments,
    'averageAppointmentTime': averageAppointmentTime,
    'revenue': revenue,
    'appointmentTypeDistribution': appointmentTypeDistribution,
    'equipmentUtilization': equipmentUtilization,
    'peakHour': peakHour,
    'peakDayOfWeek': peakDayOfWeek,
    'customerSatisfactionScore': customerSatisfactionScore,
  };

  factory FacilityMetrics.fromJson(Map<String, dynamic> json) => FacilityMetrics(
    facilityId: json['facilityId'],
    date: DateTime.parse(json['date']),
    utilizationPercentage: json['utilizationPercentage']?.toDouble() ?? 0.0,
    totalAppointments: json['totalAppointments'] ?? 0,
    completedAppointments: json['completedAppointments'] ?? 0,
    cancelledAppointments: json['cancelledAppointments'] ?? 0,
    averageAppointmentTime: json['averageAppointmentTime']?.toDouble() ?? 0.0,
    revenue: json['revenue']?.toDouble() ?? 0.0,
    appointmentTypeDistribution: Map<String, int>.from(json['appointmentTypeDistribution'] ?? {}),
    equipmentUtilization: Map<String, double>.from(json['equipmentUtilization'] ?? {}),
    peakHour: json['peakHour'] ?? 0,
    peakDayOfWeek: json['peakDayOfWeek'] ?? 1,
    customerSatisfactionScore: json['customerSatisfactionScore']?.toDouble() ?? 0.0,
  );
}

/// Advanced customer analytics and retention metrics
class CustomerAnalytics {
  final DateTime period;
  final int newCustomers;
  final int returningCustomers;
  final int totalCustomers;
  final double retentionRate;
  final Map<String, int> customerTierDistribution; // tier -> count
  final Map<String, double> customerLifetimeValue; // tier -> average LTV
  final Map<String, int> preferredMaterialTypes; // material -> customer count
  final Map<String, int> preferredAppointmentTypes;
  final double averageAppointmentFrequency; // appointments per month
  final Map<String, int> geographicDistribution; // city -> customer count
  final Map<String, double> customerSatisfactionByTier;

  CustomerAnalytics({
    required this.period,
    required this.newCustomers,
    required this.returningCustomers,
    required this.totalCustomers,
    required this.retentionRate,
    required this.customerTierDistribution,
    required this.customerLifetimeValue,
    required this.preferredMaterialTypes,
    required this.preferredAppointmentTypes,
    required this.averageAppointmentFrequency,
    required this.geographicDistribution,
    required this.customerSatisfactionByTier,
  });

  double get customerAcquisitionRate => totalCustomers > 0 ? (newCustomers / totalCustomers) * 100 : 0;

  Map<String, dynamic> toJson() => {
    'period': period.toIso8601String(),
    'newCustomers': newCustomers,
    'returningCustomers': returningCustomers,
    'totalCustomers': totalCustomers,
    'retentionRate': retentionRate,
    'customerTierDistribution': customerTierDistribution,
    'customerLifetimeValue': customerLifetimeValue,
    'preferredMaterialTypes': preferredMaterialTypes,
    'preferredAppointmentTypes': preferredAppointmentTypes,
    'averageAppointmentFrequency': averageAppointmentFrequency,
    'geographicDistribution': geographicDistribution,
    'customerSatisfactionByTier': customerSatisfactionByTier,
  };

  factory CustomerAnalytics.fromJson(Map<String, dynamic> json) => CustomerAnalytics(
    period: DateTime.parse(json['period']),
    newCustomers: json['newCustomers'] ?? 0,
    returningCustomers: json['returningCustomers'] ?? 0,
    totalCustomers: json['totalCustomers'] ?? 0,
    retentionRate: json['retentionRate']?.toDouble() ?? 0.0,
    customerTierDistribution: Map<String, int>.from(json['customerTierDistribution'] ?? {}),
    customerLifetimeValue: Map<String, double>.from(json['customerLifetimeValue'] ?? {}),
    preferredMaterialTypes: Map<String, int>.from(json['preferredMaterialTypes'] ?? {}),
    preferredAppointmentTypes: Map<String, int>.from(json['preferredAppointmentTypes'] ?? {}),
    averageAppointmentFrequency: json['averageAppointmentFrequency']?.toDouble() ?? 0.0,
    geographicDistribution: Map<String, int>.from(json['geographicDistribution'] ?? {}),
    customerSatisfactionByTier: Map<String, double>.from(json['customerSatisfactionByTier'] ?? {}),
  );
}

/// Material profitability and market analysis
class MaterialAnalytics {
  final String materialType;
  final DateTime period;
  final double totalWeight;
  final double totalRevenue;
  final double averagePricePerLb;
  final double profitMargin;
  final int appointmentCount;
  final Map<String, int> customerTierDistribution;
  final Map<String, double> regionalPricing; // region -> avg price
  final List<double> priceHistory; // monthly prices over time
  final double demandIndex; // relative popularity (0-100)
  final Map<String, int> seasonalDistribution; // month -> appointments

  MaterialAnalytics({
    required this.materialType,
    required this.period,
    required this.totalWeight,
    required this.totalRevenue,
    required this.averagePricePerLb,
    required this.profitMargin,
    required this.appointmentCount,
    required this.customerTierDistribution,
    required this.regionalPricing,
    required this.priceHistory,
    required this.demandIndex,
    required this.seasonalDistribution,
  });

  double get marketSharePercentage => totalRevenue > 0 ? (totalWeight * averagePricePerLb / totalRevenue) * 100 : 0;

  Map<String, dynamic> toJson() => {
    'materialType': materialType,
    'period': period.toIso8601String(),
    'totalWeight': totalWeight,
    'totalRevenue': totalRevenue,
    'averagePricePerLb': averagePricePerLb,
    'profitMargin': profitMargin,
    'appointmentCount': appointmentCount,
    'customerTierDistribution': customerTierDistribution,
    'regionalPricing': regionalPricing,
    'priceHistory': priceHistory,
    'demandIndex': demandIndex,
    'seasonalDistribution': seasonalDistribution,
  };

  factory MaterialAnalytics.fromJson(Map<String, dynamic> json) => MaterialAnalytics(
    materialType: json['materialType'],
    period: DateTime.parse(json['period']),
    totalWeight: json['totalWeight']?.toDouble() ?? 0.0,
    totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
    averagePricePerLb: json['averagePricePerLb']?.toDouble() ?? 0.0,
    profitMargin: json['profitMargin']?.toDouble() ?? 0.0,
    appointmentCount: json['appointmentCount'] ?? 0,
    customerTierDistribution: Map<String, int>.from(json['customerTierDistribution'] ?? {}),
    regionalPricing: Map<String, double>.from(json['regionalPricing'] ?? {}),
    priceHistory: List<double>.from(json['priceHistory'] ?? []),
    demandIndex: json['demandIndex']?.toDouble() ?? 0.0,
    seasonalDistribution: Map<String, int>.from(json['seasonalDistribution'] ?? {}),
  );
}

/// Dashboard configuration and user preferences
class DashboardPreferences {
  final List<String> visibleMetrics;
  final Map<String, String> timeRangeSettings; // section -> time_range
  final Map<String, List<String>> chartTypes; // section -> [chart_type1, chart_type2]
  final bool autoRefresh;
  final int refreshIntervalMinutes;
  final Map<String, bool> alertsEnabled;
  final Map<String, double> thresholds; // metric -> threshold_value

  DashboardPreferences({
    required this.visibleMetrics,
    required this.timeRangeSettings,
    required this.chartTypes,
    this.autoRefresh = true,
    this.refreshIntervalMinutes = 5,
    required this.alertsEnabled,
    required this.thresholds,
  });

  Map<String, dynamic> toJson() => {
    'visibleMetrics': visibleMetrics,
    'timeRangeSettings': timeRangeSettings,
    'chartTypes': chartTypes,
    'autoRefresh': autoRefresh,
    'refreshIntervalMinutes': refreshIntervalMinutes,
    'alertsEnabled': alertsEnabled,
    'thresholds': thresholds,
  };

  factory DashboardPreferences.fromJson(Map<String, dynamic> json) => DashboardPreferences(
    visibleMetrics: List<String>.from(json['visibleMetrics'] ?? []),
    timeRangeSettings: Map<String, String>.from(json['timeRangeSettings'] ?? {}),
    chartTypes: Map<String, List<String>>.from(json['chartTypes'] ?? {}),
    autoRefresh: json['autoRefresh'] ?? true,
    refreshIntervalMinutes: json['refreshIntervalMinutes'] ?? 5,
    alertsEnabled: Map<String, bool>.from(json['alertsEnabled'] ?? {}),
    thresholds: Map<String, double>.from(json['thresholds'] ?? {}),
  );
}

/// Business intelligence recommendations based on analytics data
class BusinessRecommendation {
  final String id;
  final String title;
  final String description;
  final String category; // revenue, operations, customer, facility
  final RecommendationPriority priority;
  final DateTime createdAt;
  final DateTime? implementedAt;
  final String? actionTaken;
  final Map<String, dynamic> metrics; // supporting data
  final int expectedImpact; // percentage improvement expected

  BusinessRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.implementedAt,
    this.actionTaken,
    required this.metrics,
    required this.expectedImpact,
  });

  bool get isImplemented => implementedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'priority': priority.name,
    'createdAt': createdAt.toIso8601String(),
    'implementedAt': implementedAt?.toIso8601String(),
    'actionTaken': actionTaken,
    'metrics': metrics,
    'expectedImpact': expectedImpact,
  };

  factory BusinessRecommendation.fromJson(Map<String, dynamic> json) => BusinessRecommendation(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    category: json['category'],
    priority: RecommendationPriority.values.firstWhere(
      (e) => e.name == json['priority'],
      orElse: () => RecommendationPriority.medium,
    ),
    createdAt: DateTime.parse(json['createdAt']),
    implementedAt: json['implementedAt'] != null ? DateTime.parse(json['implementedAt']) : null,
    actionTaken: json['actionTaken'],
    metrics: json['metrics'] ?? {},
    expectedImpact: json['expectedImpact'] ?? 0,
  );
}

enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}

extension RecommendationPriorityExtension on RecommendationPriority {
  String get displayName {
    switch (this) {
      case RecommendationPriority.low: return 'Low';
      case RecommendationPriority.medium: return 'Medium';
      case RecommendationPriority.high: return 'High';
      case RecommendationPriority.critical: return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case RecommendationPriority.low: return const Color(0xFF4CAF50);
      case RecommendationPriority.medium: return const Color(0xFFFFA726);
      case RecommendationPriority.high: return const Color(0xFFF57C00);
      case RecommendationPriority.critical: return const Color(0xFFD32F2F);
    }
  }
}

/// Time range options for analytics
enum TimeRange {
  today,
  yesterday,
  last7Days,
  last30Days,
  last90Days,
  thisMonth,
  lastMonth,
  thisQuarter,
  lastQuarter,
  thisYear,
  lastYear,
  custom,
}

extension TimeRangeExtension on TimeRange {
  String get displayName {
    switch (this) {
      case TimeRange.today: return 'Today';
      case TimeRange.yesterday: return 'Yesterday';
      case TimeRange.last7Days: return 'Last 7 Days';
      case TimeRange.last30Days: return 'Last 30 Days';
      case TimeRange.last90Days: return 'Last 90 Days';
      case TimeRange.thisMonth: return 'This Month';
      case TimeRange.lastMonth: return 'Last Month';
      case TimeRange.thisQuarter: return 'This Quarter';
      case TimeRange.lastQuarter: return 'Last Quarter';
      case TimeRange.thisYear: return 'This Year';
      case TimeRange.lastYear: return 'Last Year';
      case TimeRange.custom: return 'Custom Range';
    }
  }

  List<DateTime> getDateRange() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    switch (this) {
      case TimeRange.today:
        return [startOfToday, now];
      case TimeRange.yesterday:
        final yesterday = startOfToday.subtract(const Duration(days: 1));
        return [yesterday, startOfToday];
      case TimeRange.last7Days:
        return [startOfToday.subtract(const Duration(days: 7)), now];
      case TimeRange.last30Days:
        return [startOfToday.subtract(const Duration(days: 30)), now];
      case TimeRange.last90Days:
        return [startOfToday.subtract(const Duration(days: 90)), now];
      case TimeRange.thisMonth:
        return [DateTime(now.year, now.month, 1), now];
      case TimeRange.lastMonth:
        final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
        final firstDayThisMonth = DateTime(now.year, now.month, 1);
        return [firstDayLastMonth, firstDayThisMonth];
      case TimeRange.thisQuarter:
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final firstMonthOfQuarter = ((quarter - 1) * 3) + 1;
        return [DateTime(now.year, firstMonthOfQuarter, 1), now];
      case TimeRange.lastQuarter:
        final quarter = ((now.month - 1) ~/ 3);
        if (quarter == 0) {
          final firstMonthOfQuarter = 10;
          return [DateTime(now.year - 1, firstMonthOfQuarter, 1), DateTime(now.year, 1, 1)];
        } else {
          final firstMonthOfQuarter = ((quarter - 1) * 3) + 1;
          return [DateTime(now.year, firstMonthOfQuarter, 1), DateTime(now.year, now.month - 3, DateTime(now.year, now.month - 2).day - 1)];
        }
      case TimeRange.thisYear:
        return [DateTime(now.year, 1, 1), now];
      case TimeRange.lastYear:
        return [DateTime(now.year - 1, 1, 1), DateTime(now.year, 1, 1)];
      case TimeRange.custom:
        return [now.subtract(const Duration(days: 30)), now]; // Default 30 days
    }
  }
}

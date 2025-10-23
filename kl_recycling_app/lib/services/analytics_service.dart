import 'dart:math';
import 'package:flutter/material.dart'; // for DateTimeRange
import '../models/gamification.dart' as gamification;

/// Analytics service for detailed environmental impact tracking
class AnalyticsService {
  static const Map<String, ImpactFactor> _impactFactors = {
    'aluminum': ImpactFactor(
      treesSavedPerLb: 0.0005, // Based on typical aluminum recycling impact
      energySavedPerLb: 17.0, // kWh per lb - actual data
      co2AvoidedPerLb: 12.68, // kg CO2 per lb
      waterSavedPerGallon: 1.34, // gallons per lb
    ),
    'steel': ImpactFactor(
      treesSavedPerLb: 0.0003,
      energySavedPerLb: 6.0,
      co2AvoidedPerLb: 3.8,
      waterSavedPerGallon: 0.9,
    ),
    'paper': ImpactFactor(
      treesSavedPerLb: 0.0012, // Paper saves trees directly
      energySavedPerLb: 8.5,
      co2AvoidedPerLb: 2.1,
      waterSavedPerGallon: 12.5,
    ),
    'plastic': ImpactFactor(
      treesSavedPerLb: 0.0001,
      energySavedPerLb: 5.0,
      co2AvoidedPerLb: 1.4,
      waterSavedPerGallon: 2.1,
    ),
    'cardboard': ImpactFactor(
      treesSavedPerLb: 0.0008,
      energySavedPerLb: 7.0,
      co2AvoidedPerLb: 2.0,
      waterSavedPerGallon: 8.0,
    ),
    'glass': ImpactFactor(
      treesSavedPerLb: 0.0002,
      energySavedPerLb: 2.5,
      co2AvoidedPerLb: 1.8,
      waterSavedPerGallon: 0.5,
    ),
    'copper': ImpactFactor(
      treesSavedPerLb: 0.0001,
      energySavedPerLb: 4.0,
      co2AvoidedPerLb: 6.2,
      waterSavedPerGallon: 1.0,
    ),
    'electronics': ImpactFactor(
      treesSavedPerLb: 0.00005,
      energySavedPerLb: 10.0,
      co2AvoidedPerLb: 8.5,
      waterSavedPerGallon: 1.5,
    ),
  };

  /// Calculate comprehensive impact from recycling history
  static EnvironmentalImpact calculateDetailedImpact(
    List<gamification.RecycledItem> history,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    // Filter by date range if provided - use safe filtering
    var filteredHistory = history;
    if (startDate != null) {
      filteredHistory = filteredHistory
          .where((item) => item.recycledDate.isAfter(startDate))
          .toList();
    }
    if (endDate != null) {
      filteredHistory = filteredHistory
          .where((item) => item.recycledDate.isBefore(endDate))
          .toList();
    }

    double totalWeight = 0;
    double totalEnergySaved = 0;
    double totalCO2Avoided = 0;
    double totalWaterSaved = 0;
    int estimatedTreesSaved = 0;

    Map<String, double> materialBreakdown = {};
    Map<String, double> environmentalMetrics = {
      'energy': 0.0,
      'co2': 0.0,
      'water': 0.0,
      'trees': 0.0,
    };

    for (var item in filteredHistory) {
      totalWeight += item.weight;

      // Get the appropriate impact factor
      final materialKey = _getMaterialKey(item.materialType);
      final factor = _impactFactors[materialKey] ?? _impactFactors['steel']!;

      // Calculate impact per item
      final energy = item.weight * factor.energySavedPerLb;
      final co2 = item.weight * factor.co2AvoidedPerLb;
      final water = item.weight * factor.waterSavedPerGallon;
      final trees = item.weight * factor.treesSavedPerLb;

      // Accumulate totals
      totalEnergySaved += energy;
      totalCO2Avoided += co2;
      totalWaterSaved += water;
      estimatedTreesSaved += trees.round();

      // Track material breakdown
      materialBreakdown[materialKey] = (materialBreakdown[materialKey] ?? 0) + item.weight;

      // Track environmental metrics
      environmentalMetrics['energy'] = (environmentalMetrics['energy'] ?? 0) + energy;
      environmentalMetrics['co2'] = (environmentalMetrics['co2'] ?? 0) + co2;
      environmentalMetrics['water'] = (environmentalMetrics['water'] ?? 0) + water;
      environmentalMetrics['trees'] = (environmentalMetrics['trees'] ?? 0) + trees;
    }

    return EnvironmentalImpact(
      totalItems: filteredHistory.length,
      totalWeight: totalWeight,
      totalEnergySaved: totalEnergySaved,
      totalCO2Avoided: totalCO2Avoided,
      totalWaterSaved: totalWaterSaved,
      estimatedTreesSaved: estimatedTreesSaved,
      materialBreakdown: materialBreakdown,
      environmentalMetrics: environmentalMetrics,
      timeRange: (startDate != null && endDate != null)
          ? DateTimeRange(start: startDate, end: endDate)
          : null,
      periodRecyclingHistory: filteredHistory,
    );
  }

  /// Generate weekly analytics data for charts
  static List<WeeklyDataPoint> generateWeeklyChartData(List<gamification.RecyclingItem> history) {
    final now = DateTime.now();
    final List<WeeklyDataPoint> chartData = [];

    // Generate data for last 12 weeks
    for (int i = 11; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weeklyItems = history.where((item) {
        return item.recycledDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
               item.recycledDate.isBefore(weekEnd.add(const Duration(days: 1)));
      }).toList();

      final weeklyImpact = calculateDetailedImpact(
        weeklyItems,
        weekStart,
        weekEnd,
      );

      chartData.add(WeeklyDataPoint(
        weekStart: weekStart,
        weekEnd: weekEnd,
        itemsCount: weeklyItems.length,
        totalWeight: weeklyImpact.totalWeight,
        energySaved: weeklyImpact.totalEnergySaved,
        co2Avoided: weeklyImpact.totalCO2Avoided,
        pointsEarned: weeklyItems.fold(0, (sum, item) => sum + item.points),
      ));
    }

    return chartData;
  }

  /// Get monthly trends
  static List<MonthlyDataPoint> generateMonthlyChartData(List<gamification.RecyclingItem> history) {
    final List<MonthlyDataPoint> monthlyData = [];
    final now = DateTime.now();

    // Last 6 months
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final monthlyItems = history.where((item) {
        return item.recycledDate.isAfter(month.subtract(const Duration(days: 1))) &&
               item.recycledDate.isBefore(nextMonth);
      }).toList();

      final monthlyImpact = calculateDetailedImpact(
        monthlyItems,
        month,
        nextMonth.subtract(const Duration(days: 1)),
      );

      monthlyData.add(MonthlyDataPoint(
        month: month,
        itemsCount: monthlyItems.length,
        totalWeight: monthlyImpact.totalWeight,
        averageWeeklyActivity: monthlyItems.length / 4.0,
        totalEnergySaved: monthlyImpact.totalEnergySaved,
        totalCO2Avoided: monthlyImpact.totalCO2Avoided,
        topMaterial: monthlyImpact.materialBreakdown.isEmpty ? 'none' :
          monthlyImpact.materialBreakdown.entries
            .reduce((a, b) => a.value > b.value ? a : b).key,
      ));
    }

    return monthlyData;
  }

  /// Calculate goal progress
  static GoalProgress calculateGoalProgress(
    List<gamification.RecyclingItem> history,
    double weightGoal, // lbs per month
    int itemsGoal, // items per month
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final monthlyItems = history.where((item) {
      return item.recycledDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
             item.recycledDate.isBefore(monthEnd);
    }).toList();

    final currentMonthImpact = calculateDetailedImpact(
      monthlyItems,
      monthStart,
      monthEnd.subtract(const Duration(days: 1)),
    );

    return GoalProgress(
      weightGoal: weightGoal,
      itemsGoal: itemsGoal,
      currentWeight: currentMonthImpact.totalWeight,
      currentItems: currentMonthImpact.totalItems,
      remainingDaysInMonth: DateTime(now.year, now.month + 1, 1).difference(now).inDays,
      projectedWeight: _calculateProjection(currentMonthImpact.totalWeight, now.day),
      projectedItems: _calculateProjection(currentMonthImpact.totalItems.toDouble(), now.day),
    );
  }

  /// Generate impact summary for sharing
  static ImpactSummary generateImpactSummary(
    List<gamification.RecyclingItem> history,
    gamification.GamificationStats stats,
  ) {
    final totalImpact = calculateDetailedImpact(history, null, null);

    return ImpactSummary(
      totalWeight: totalImpact.totalWeight,
      totalItems: totalImpact.totalItems,
      totalEnergySaved: totalImpact.totalEnergySaved,
      totalCO2Avoided: totalImpact.totalCO2Avoided,
      totalWaterSaved: totalImpact.totalWaterSaved,
      estimatedTreesSaved: totalImpact.estimatedTreesSaved,
      achievementsCount: stats.earnedBadges.length,
      topMaterial: totalImpact.materialBreakdown.isEmpty ? 'steel' :
        totalImpact.materialBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b).key,
      topAchievement: stats.earnedBadges.isEmpty ? null : stats.earnedBadges.first,
      averageMonthlyActivity: _calculateMonthlyAverage(history, totalImpact.totalItems),
    );
  }

  /// Generate environmental comparison data
  static List<EnvironmentalComparison> generateEnvironmentalComparison(List<gamification.RecyclingItem> history) {
    final totalImpact = calculateDetailedImpact(history, null, null);

    // Equivalent to everyday activities
    return [
      EnvironmentalComparison(
        activity: 'Car Miles',
        impact: totalImpact.totalCO2Avoided / 0.404, // kg CO2 per mile
        unit: 'miles not driven',
        icon: '🚗',
        description: 'Equivalent miles your recycling prevented',
      ),
      EnvironmentalComparison(
        activity: 'Home Electricity',
        impact: totalImpact.totalEnergySaved / 13.0, // Average home monthly usage
        unit: 'days of electricity use',
        icon: '⚡',
        description: 'Equivalent electricity saved',
      ),
      EnvironmentalComparison(
        activity: 'Shower Time',
        impact: totalImpact.totalWaterSaved / 2.1, // gallons per 5-minute shower
        unit: '5-minute showers',
        icon: '🚿',
        description: 'Equivalent water savings in showers',
      ),
      EnvironmentalComparison(
        activity: 'Phones Charged',
        impact: totalImpact.totalEnergySaved / 0.008, // kWh per phone charge
        unit: 'phone charges',
        icon: '📱',
        description: 'Equivalent smartphone charges',
      ),
    ];
  }

  /// Helper to normalize material type names
  static String _getMaterialKey(String materialType) {
    // Normalize the material type string to match our impact factors
    final normalized = materialType.toLowerCase().trim();
    if (normalized.contains('aluminum')) return 'aluminum';
    if (normalized.contains('steel') || normalized == 'other') return 'steel';
    if (normalized.contains('copper')) return 'copper';
    if (normalized.contains('brass')) return 'copper'; // Similar to copper
    if (normalized.contains('zinc')) return 'steel'; // Similar to steel
    if (normalized.contains('stainless')) return 'steel'; // Similar to steel
    if (normalized == 'unknown') return 'steel'; // Default fallback

    return 'steel'; // Default fallback for any unrecognized material
  }

  /// Calculate linear projection for remaining month days
  static double _calculateProjection(double currentValue, int daysElapsedInMonth) {
    const totalDaysInMonth = 30; // Approximation
    if (daysElapsedInMonth == 0) return 0;

    final dailyRate = currentValue / daysElapsedInMonth;
    final remainingDays = totalDaysInMonth - daysElapsedInMonth;

    return currentValue + (dailyRate * remainingDays);
  }

  /// Calculate average monthly activity
  static double _calculateMonthlyAverage(List<gamification.RecyclingItem> history, int totalItems) {
    if (history.isEmpty) return 0;

    final firstDate = history.map((item) => item.recycledDate).reduce((a, b) => a.isBefore(b) ? a : b);
    final lastDate = history.map((item) => item.recycledDate).reduce((a, b) => a.isAfter(b) ? a : b);
    final monthsActive = max(1, lastDate.difference(firstDate).inDays ~/ 30);

    return totalItems / monthsActive;
  }
}

/// Data models for analytics

class ImpactFactor {
  final double treesSavedPerLb;
  final double energySavedPerLb;
  final double co2AvoidedPerLb;
  final double waterSavedPerGallon;

  const ImpactFactor({
    required this.treesSavedPerLb,
    required this.energySavedPerLb,
    required this.co2AvoidedPerLb,
    required this.waterSavedPerGallon,
  });
}

class EnvironmentalImpact {
  final int totalItems;
  final double totalWeight;
  final double totalEnergySaved;
  final double totalCO2Avoided;
  final double totalWaterSaved;
  final int estimatedTreesSaved;
  final Map<String, double> materialBreakdown;
  final Map<String, double> environmentalMetrics;
  final DateTimeRange? timeRange;
  final List<gamification.RecyclingItem> periodRecyclingHistory;

  const EnvironmentalImpact({
    required this.totalItems,
    required this.totalWeight,
    required this.totalEnergySaved,
    required this.totalCO2Avoided,
    required this.totalWaterSaved,
    required this.estimatedTreesSaved,
    required this.materialBreakdown,
    required this.environmentalMetrics,
    this.timeRange,
    required this.periodRecyclingHistory,
  });

  String getFormattedWeight() => '${totalWeight.toStringAsFixed(1)} lbs';
  String getFormattedEnergy() => '${totalEnergySaved.toStringAsFixed(0)} kWh';
  String getFormattedCO2() => '${totalCO2Avoided.toStringAsFixed(0)} kg';
  String getFormattedWater() => '${totalWaterSaved.toStringAsFixed(0)} gal';
}

class WeeklyDataPoint {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int itemsCount;
  final double totalWeight;
  final double energySaved;
  final double co2Avoided;
  final int pointsEarned;

  const WeeklyDataPoint({
    required this.weekStart,
    required this.weekEnd,
    required this.itemsCount,
    required this.totalWeight,
    required this.energySaved,
    required this.co2Avoided,
    required this.pointsEarned,
  });

  String getWeekLabel() {
    final startMonth = weekStart.month.toString().padLeft(2, '0');
    final startDay = weekStart.day.toString().padLeft(2, '0');
    final endMonth = weekEnd.month.toString().padLeft(2, '0');
    final endDay = weekEnd.day.toString().padLeft(2, '0');

    if (startMonth == endMonth) {
      return '$startMonth/$startDay-$endDay';
    } else {
      return '$startMonth/$startDay-$endMonth/$endDay';
    }
  }
}

class MonthlyDataPoint {
  final DateTime month;
  final int itemsCount;
  final double totalWeight;
  final double averageWeeklyActivity;
  final double totalEnergySaved;
  final double totalCO2Avoided;
  final String topMaterial;

  const MonthlyDataPoint({
    required this.month,
    required this.itemsCount,
    required this.totalWeight,
    required this.averageWeeklyActivity,
    required this.totalEnergySaved,
    required this.totalCO2Avoided,
    required this.topMaterial,
  });

  String getMonthLabel() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[month.month - 1]} ${month.year}';
  }
}

class GoalProgress {
  final double weightGoal;
  final int itemsGoal;
  final double currentWeight;
  final int currentItems;
  final int remainingDaysInMonth;
  final double projectedWeight;
  final double projectedItems;

  const GoalProgress({
    required this.weightGoal,
    required this.itemsGoal,
    required this.currentWeight,
    required this.currentItems,
    required this.remainingDaysInMonth,
    required this.projectedWeight,
    required this.projectedItems,
  });

  double get weightProgress => currentWeight / weightGoal;
  double get itemsProgress => currentItems / itemsGoal;
  bool get weightGoalMet => currentWeight >= weightGoal;
  bool get itemsGoalMet => currentItems >= itemsGoal;
  String get projectedWeightText => projectedWeight >= weightGoal ? '🎯 On track!' : '📈 Keep going!';
  String get projectedItemsText => projectedItems >= itemsGoal ? '🎯 On track!' : '📈 Keep going!';
}

class ImpactSummary {
  final double totalWeight;
  final int totalItems;
  final double totalEnergySaved;
  final double totalCO2Avoided;
  final double totalWaterSaved;
  final int estimatedTreesSaved;
  final int achievementsCount;
  final String topMaterial;
  final gamification.Badge? topAchievement;
  final double averageMonthlyActivity;

  const ImpactSummary({
    required this.totalWeight,
    required this.totalItems,
    required this.totalEnergySaved,
    required this.totalCO2Avoided,
    required this.totalWaterSaved,
    required this.estimatedTreesSaved,
    required this.achievementsCount,
    required this.topMaterial,
    this.topAchievement,
    required this.averageMonthlyActivity,
  });
}

class EnvironmentalComparison {
  final String activity;
  final double impact;
  final String unit;
  final String icon;
  final String description;

  const EnvironmentalComparison({
    required this.activity,
    required this.impact,
    required this.unit,
    required this.icon,
    required this.description,
  });

  String getFormattedImpact() => '${impact.toStringAsFixed(0)} ${unit.replaceAll(' ', '')}';
}

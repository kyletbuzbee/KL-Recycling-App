import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gamification.dart' as gamification;

class GamificationProvider extends ChangeNotifier {
  gamification.UserGamificationStats _stats = const gamification.UserGamificationStats();
  bool _isLoading = true;

  gamification.UserGamificationStats get stats => _stats;
  bool get isLoading => _isLoading;

  static const String _prefsKey = 'gamification_stats';

  GamificationProvider() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_prefsKey);

      if (statsJson != null) {
        _stats = gamification.UserGamificationStats.fromMap(
          Map<String, dynamic>.from(await Future.value({}..addAll({'dummy': 'dummy'}))),
        );
        // Note: In a real implementation, you'd use json.decode(statsJson)
        // For demo purposes, we'll use empty stats
        _stats = const gamification.UserGamificationStats();
      }
    } catch (e) {
      debugPrint('Error loading gamification stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // In a real implementation you'd use json.encode(stats.toMap())
      // await prefs.setString(_prefsKey, json.encode(_stats.toMap()));
    } catch (e) {
      debugPrint('Error saving gamification stats: $e');
    }
  }

  Future<void> addRecycledItem({
    required String materialType,
    required double weight,
  }) async {
    final points = _calculatePoints(materialType, weight);
    final itemId = DateTime.now().millisecondsSinceEpoch.toString();

    final newItem = gamification.RecycledItem(
      id: itemId,
      materialType: materialType,
      weight: weight,
      recycledDate: DateTime.now(),
      points: points,
    );

    // Add item to history
    final updatedHistory = [..._stats.recyclingHistory, newItem];

    // Update material totals
    final updatedMaterialTotals = Map<String, double>.from(_stats.materialTotals);
    updatedMaterialTotals[materialType] = (updatedMaterialTotals[materialType] ?? 0) + weight;

    // Check for new badges
    final newBadges = _stats.getNewlyEarnedBadges(points, weight.toInt());
    final updatedBadges = List<gamification.Badge>.from(_stats.earnedBadges);

    for (final badgeType in newBadges) {
      updatedBadges.add(gamification.Badge(
        id: '${badgeType.name}_${DateTime.now().millisecondsSinceEpoch}',
        type: badgeType,
        earnedDate: DateTime.now(),
      ));
    }

    // Update stats
    _stats = _stats.copyWith(
      totalPoints: _stats.totalPoints + points,
      totalWeight: (_stats.totalWeight + weight).toInt(),
      totalItems: _stats.totalItems + 1,
      earnedBadges: updatedBadges,
      recyclingHistory: updatedHistory,
      materialTotals: updatedMaterialTotals,
    );

    notifyListeners();
    await _saveStats();
  }

  void simulateDemoData() {
    final List<gamification.RecycledItem> demoItems = [
      gamification.RecycledItem(
        id: '1',
        materialType: 'aluminum',
        weight: 25.0,
        recycledDate: DateTime.now().subtract(const Duration(days: 7)),
        points: 50,
      ),
      gamification.RecycledItem(
        id: '2',
        materialType: 'paper',
        weight: 15.0,
        recycledDate: DateTime.now().subtract(const Duration(days: 5)),
        points: 30,
      ),
      gamification.RecycledItem(
        id: '3',
        materialType: 'plastic',
        weight: 8.0,
        recycledDate: DateTime.now().subtract(const Duration(days: 3)),
        points: 20,
      ),
      gamification.RecycledItem(
        id: '4',
        materialType: 'steel',
        weight: 45.0,
        recycledDate: DateTime.now().subtract(const Duration(days: 1)),
        points: 90,
      ),
    ];

    final Map<String, double> demoMaterialTotals = {
      'aluminum': 25.0,
      'paper': 15.0,
      'plastic': 8.0,
      'steel': 45.0,
    };

    final List<gamification.Badge> demoBadges = [
      gamification.Badge(
        id: 'first_1',
        type: gamification.BadgeType.firstRecycle,
        earnedDate: DateTime.now().subtract(const Duration(days: 7)),
      ),
      gamification.Badge(
        id: 'paper_2',
        type: gamification.BadgeType.paperWarrior,
        earnedDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    _stats = gamification.UserGamificationStats(
      totalPoints: 190,
      totalWeight: 93,
      totalItems: 4,
      earnedBadges: demoBadges,
      recyclingHistory: demoItems,
      materialTotals: demoMaterialTotals,
    );

    _isLoading = false;
    notifyListeners();
    _saveStats();
  }

  int _calculatePoints(String materialType, double weight) {
    // Points per pound varies by material
    final pointsPerPound = switch (materialType.toLowerCase()) {
      'aluminum' => 2,
      'steel' || 'iron' => 2,
      'copper' || 'brass' => 4,
      'plastic' => 1,
      'paper' => 1,
      'glass' => 1,
      _ => 1, // unknown materials
    };

    return (weight * pointsPerPound).toInt();
  }

  void resetStats() {
    _stats = const gamification.UserGamificationStats();
    notifyListeners();
    _saveStats();
  }
}

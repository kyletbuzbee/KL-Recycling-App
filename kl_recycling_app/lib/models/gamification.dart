import 'package:flutter/material.dart';
import 'package:kl_recycling_app/models/photo_estimate.dart' as photo_estimate;

// Type aliases for compatibility
typedef RecyclingItem = RecycledItem;
typedef GamificationStats = UserGamificationStats;
typedef MaterialType = photo_estimate.MaterialType;

enum BadgeType {
  firstRecycle('First Recycle', 'Awarded for your first recycling activity', Icons.recycling, 1),
  paperWarrior('Paper Warrior', 'Recycled 50 lbs of paper', Icons.description, 50),
  metalMaster('Metal Master', 'Recycled 100 lbs of metal', Icons.build, 100),
  bottleCollector('Bottle Collector', 'Recycled 200 plastic bottles', Icons.local_drink, 200),
  ecoWarrior('Eco Warrior', 'Recycled 500 lbs total', Icons.eco, 500),
  sustainabilityChampion('Sustainability Champion', 'Recycled 1000 lbs total', Icons.emoji_events, 1000);

  const BadgeType(this.title, this.description, this.icon, this.requirement);

  final String title;
  final String description;
  final IconData icon;
  final int requirement;
}

class Badge {
  final String id;
  final BadgeType type;
  final DateTime earnedDate;

  const Badge({
    required this.id,
    required this.type,
    required this.earnedDate,
  });

  factory Badge.fromMap(Map<String, dynamic> map) {
    return Badge(
      id: map['id'] ?? '',
      type: BadgeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BadgeType.firstRecycle,
      ),
      earnedDate: DateTime.parse(map['earnedDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'earnedDate': earnedDate.toIso8601String(),
    };
  }
}

class RecycledItem {
  final String id;
  final String materialType;
  final double weight; // in lbs
  final DateTime recycledDate;
  final int points; // calculated based on material type and amount

  const RecycledItem({
    required this.id,
    required this.materialType,
    required this.weight,
    required this.recycledDate,
    required this.points,
  });

  factory RecycledItem.fromMap(Map<String, dynamic> map) {
    return RecycledItem(
      id: map['id'] ?? '',
      materialType: map['materialType'] ?? '',
      weight: (map['weight'] ?? 0.0).toDouble(),
      recycledDate: DateTime.parse(map['recycledDate']),
      points: map['points'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materialType': materialType,
      'weight': weight,
      'recycledDate': recycledDate.toIso8601String(),
      'points': points,
    };
  }
}

class UserGamificationStats {
  final int totalPoints;
  final int totalWeight; // in lbs
  final int totalItems;
  final List<Badge> earnedBadges;
  final List<RecycledItem> recyclingHistory;
  final Map<String, double> materialTotals; // materialType -> total weight

  const UserGamificationStats({
    this.totalPoints = 0,
    this.totalWeight = 0,
    this.totalItems = 0,
    this.earnedBadges = const [],
    this.recyclingHistory = const [],
    this.materialTotals = const {},
  });

  factory UserGamificationStats.fromMap(Map<String, dynamic> map) {
    return UserGamificationStats(
      totalPoints: map['totalPoints'] ?? 0,
      totalWeight: map['totalWeight'] ?? 0,
      totalItems: map['totalItems'] ?? 0,
      earnedBadges: (map['earnedBadges'] as List<dynamic>?)
          ?.map((e) => Badge.fromMap(e))
          .toList() ?? [],
      recyclingHistory: (map['recyclingHistory'] as List<dynamic>?)
          ?.map((e) => RecycledItem.fromMap(e))
          .toList() ?? [],
      materialTotals: (map['materialTotals'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value.toDouble())) ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPoints': totalPoints,
      'totalWeight': totalWeight,
      'totalItems': totalItems,
      'earnedBadges': earnedBadges.map((e) => e.toMap()).toList(),
      'recyclingHistory': recyclingHistory.map((e) => e.toMap()).toList(),
      'materialTotals': materialTotals,
    };
  }

  UserGamificationStats copyWith({
    int? totalPoints,
    int? totalWeight,
    int? totalItems,
    List<Badge>? earnedBadges,
    List<RecycledItem>? recyclingHistory,
    Map<String, double>? materialTotals,
  }) {
    return UserGamificationStats(
      totalPoints: totalPoints ?? this.totalPoints,
      totalWeight: totalWeight ?? this.totalWeight,
      totalItems: totalItems ?? this.totalItems,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      recyclingHistory: recyclingHistory ?? this.recyclingHistory,
      materialTotals: materialTotals ?? this.materialTotals,
    );
  }

  // Helper methods
  bool hasBadge(BadgeType type) {
    return earnedBadges.any((badge) => badge.type == type);
  }

  List<BadgeType> getNewlyEarnedBadges(int newPoints, int newWeight) {
    final List<BadgeType> newBadges = [];

    // Check each badge type
    for (final badgeType in BadgeType.values) {
      // First recycle badge
      if (badgeType == BadgeType.firstRecycle && totalItems == 0 && !hasBadge(badgeType)) {
        newBadges.add(badgeType);
      }
      // Weight-based badges
      else if (badgeType == BadgeType.paperWarrior &&
               (materialTotals['paper'] ?? 0) + (newWeight * 0.3) >= badgeType.requirement &&
               !hasBadge(badgeType)) {
        // Assume ~30% of weight is paper for simplicity
        newBadges.add(badgeType);
      }
      else if ((badgeType == BadgeType.metalMaster || badgeType == BadgeType.ecoWarrior || badgeType == BadgeType.sustainabilityChampion) &&
               totalWeight + newWeight >= badgeType.requirement &&
               !hasBadge(badgeType)) {
        newBadges.add(badgeType);
      }
      else if (badgeType == BadgeType.bottleCollector &&
               materialTotals['plastic'] != null &&
               materialTotals['plastic']! + newWeight >= badgeType.requirement &&
               !hasBadge(badgeType)) {
        newBadges.add(badgeType);
      }
    }

    return newBadges;
  }
}


import 'package:flutter/material.dart';

/// Enum for customer tier levels
enum CustomerTier {
  bronze,
  silver,
  gold,
  platinum,
}

extension CustomerTierExtension on CustomerTier {
  String get displayName {
    switch (this) {
      case CustomerTier.bronze:
        return 'Bronze';
      case CustomerTier.silver:
        return 'Silver';
      case CustomerTier.gold:
        return 'Gold';
      case CustomerTier.platinum:
        return 'Platinum';
    }
  }

  IconData get icon {
    switch (this) {
      case CustomerTier.bronze:
        return Icons.emoji_events;
      case CustomerTier.silver:
        return Icons.star;
      case CustomerTier.gold:
        return Icons.account_circle;
      case CustomerTier.platinum:
        return Icons.diamond;
    }
  }

  double get discountPercentage {
    switch (this) {
      case CustomerTier.bronze:
        return 0.0;
      case CustomerTier.silver:
        return 0.05;
      case CustomerTier.gold:
        return 0.10;
      case CustomerTier.platinum:
        return 0.15;
    }
  }

  int get pointsRequired {
    switch (this) {
      case CustomerTier.bronze:
        return 0;
      case CustomerTier.silver:
        return 100;
      case CustomerTier.gold:
        return 500;
      case CustomerTier.platinum:
        return 1500;
    }
  }

  String get description {
    switch (this) {
      case CustomerTier.bronze:
        return 'Getting started with recycling';
      case CustomerTier.silver:
        return 'Frequent recycler';
      case CustomerTier.gold:
        return 'Dedicated eco-warrior';
      case CustomerTier.platinum:
        return 'Environmental champion';
    }
  }
}

/// Loyalty tier enum for point threshold levels
enum LoyaltyTier {
  bronze,
  silver,
  gold,
  platinum,
}

extension LoyaltyTierExtension on LoyaltyTier {
  String get title {
    switch (this) {
      case LoyaltyTier.bronze:
        return 'Bronze';
      case LoyaltyTier.silver:
        return 'Silver';
      case LoyaltyTier.gold:
        return 'Gold';
      case LoyaltyTier.platinum:
        return 'Platinum';
    }
  }

  IconData get icon {
    switch (this) {
      case LoyaltyTier.bronze:
        return Icons.emoji_events;
      case LoyaltyTier.silver:
        return Icons.star;
      case LoyaltyTier.gold:
        return Icons.account_circle;
      case LoyaltyTier.platinum:
        return Icons.diamond;
    }
  }

  String get description {
    switch (this) {
      case LoyaltyTier.bronze:
        return 'Getting started with recycling';
      case LoyaltyTier.silver:
        return 'Frequent recycler';
      case LoyaltyTier.gold:
        return 'Dedicated eco-warrior';
      case LoyaltyTier.platinum:
        return 'Environmental champion';
    }
  }

  int get pointsRequired {
    switch (this) {
      case LoyaltyTier.bronze:
        return 0;
      case LoyaltyTier.silver:
        return 100;
      case LoyaltyTier.gold:
        return 500;
      case LoyaltyTier.platinum:
        return 1500;
    }
  }
}

/// Enum for transaction types
enum TransactionType {
  scrapSale,
  rewardRedemption,
  referralBonus,
  achievementUnlock,
  earned,
  redeemed,
}

/// Enum for referral status
enum ReferralStatus {
  pending,
  completed,
  expired,
}

/// Enum for reward types
enum RewardType {
  discount,
  cashback,
  freeService,
  service,
  merchandise,
  donation,
}

/// Enum for achievement types
enum AchievementType {
  firstScrapSale,
  volumeMilestone,
  referral,
  consistency,
  milestone,
  social,
}

// Basic Loyalty Profile stub
class LoyaltyProfile {
  final String userId;
  final int totalPoints;
  final int availablePoints;
  final LoyaltyTier currentTier;
  final double discountPercentage;
  final List<LoyaltyPoints> pointsHistory;
  final List<ReferralRecord> referralRecords;
  final List<LoyaltyAchievement> unlockedAchievements;
  final List<dynamic> tierUpgrades;
  final DateTime joinedAt;
  final DateTime lastActivityAt;
  final Map<String, dynamic> preferences;

  LoyaltyProfile({
    required this.userId,
    required this.totalPoints,
    required this.availablePoints,
    this.currentTier = LoyaltyTier.bronze,
    this.discountPercentage = 0.0,
    this.pointsHistory = const [],
    this.referralRecords = const [],
    this.unlockedAchievements = const [],
    this.tierUpgrades = const [],
    DateTime? joinedAt,
    DateTime? lastActivityAt,
    this.preferences = const {},
  }) : joinedAt = joinedAt ?? DateTime.now(),
       lastActivityAt = lastActivityAt ?? DateTime.now();

  // Computed properties expected by services (moved to static)
  static const CustomerTier bronze = CustomerTier.bronze;
  static const CustomerTier silver = CustomerTier.silver;
  static const CustomerTier gold = CustomerTier.gold;

  int getCompletedReferrals() => referralRecords.where((r) => true).length; // Simplified
  int getPendingReferrals() => 0; // Simplified
  bool canUpgradeTier() => false; // Simplified
  LoyaltyTier getNextTier() => LoyaltyTier.bronze; // Simplified
  bool hasUnlockedAchievement(String achievementId) => false; // Simplified

  LoyaltyProfile copyWith({
    String? userId,
    int? totalPoints,
    int? availablePoints,
    LoyaltyTier? currentTier,
    double? discountPercentage,
    List<LoyaltyPoints>? pointsHistory,
    List<ReferralRecord>? referralRecords,
    List<LoyaltyAchievement>? unlockedAchievements,
    List<dynamic>? tierUpgrades,
    DateTime? joinedAt,
    DateTime? lastActivityAt,
    Map<String, dynamic>? preferences,
  }) {
    return LoyaltyProfile(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      availablePoints: availablePoints ?? this.availablePoints,
      currentTier: currentTier ?? this.currentTier,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      pointsHistory: pointsHistory ?? this.pointsHistory,
      referralRecords: referralRecords ?? this.referralRecords,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      tierUpgrades: tierUpgrades ?? this.tierUpgrades,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'availablePoints': availablePoints,
      'currentTier': currentTier.toString(),
      'discountPercentage': discountPercentage,
      'pointsHistory': pointsHistory.map((p) => p.toMap()).toList(),
      'referralRecords': referralRecords.map((r) => r.toMap()).toList(),
      'unlockedAchievements': unlockedAchievements.map((a) => a.toMap()).toList(),
      'tierUpgrades': tierUpgrades,
      'joinedAt': joinedAt.toIso8601String(),
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'preferences': preferences,
    };
  }

  factory LoyaltyProfile.fromMap(Map<String, dynamic> map) {
    return LoyaltyProfile(
      userId: map['userId'] ?? '',
      totalPoints: map['totalPoints'] ?? 0,
      availablePoints: map['availablePoints'] ?? 0,
      currentTier: LoyaltyTier.bronze, // Simplified
      discountPercentage: map['discountPercentage'] ?? 0.0,
      pointsHistory: map['pointsHistory'] != null
          ? (map['pointsHistory'] as List).map((p) => LoyaltyPoints.fromMap(p)).toList()
          : [],
      referralRecords: map['referralRecords'] != null
          ? (map['referralRecords'] as List).map((r) => ReferralRecord.fromMap(r)).toList()
          : [],
      unlockedAchievements: map['unlockedAchievements'] != null
          ? (map['unlockedAchievements'] as List).map((a) => LoyaltyAchievement.fromMap(a)).toList()
          : [],
      tierUpgrades: map['tierUpgrades'] ?? [],
      joinedAt: map['joinedAt'] != null ? DateTime.parse(map['joinedAt']) : null,
      lastActivityAt: map['lastActivityAt'] != null ? DateTime.parse(map['lastActivityAt']) : null,
      preferences: map['preferences'] ?? {},
    );
  }
}

// Basic Loyalty Points stub
class LoyaltyPoints {
  final String id;
  final String userId;
  final int points;
  final String description;
  final DateTime createdAt;
  final String referenceId;
  final TransactionType type;

  LoyaltyPoints({
    required this.id,
    required this.userId,
    required this.points,
    required this.description,
    DateTime? createdAt,
    this.referenceId = '',
    this.type = TransactionType.scrapSale,
  }) : createdAt = createdAt ?? DateTime.now();

  LoyaltyPoints copyWith({
    String? id,
    String? userId,
    int? points,
    String? description,
    DateTime? createdAt,
    String? referenceId,
    TransactionType? type,
  }) {
    return LoyaltyPoints(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      referenceId: referenceId ?? this.referenceId,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'points': points,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'referenceId': referenceId,
      'type': type.name,
    };
  }

  factory LoyaltyPoints.fromMap(Map<String, dynamic> map) {
    return LoyaltyPoints(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      points: map['points'] ?? 0,
      description: map['description'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      referenceId: map['referenceId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.scrapSale,
      ),
    );
  }
}

// Basic Reward stub
class Reward {
  final String id;
  final String name;
  final String description;
  final int pointsRequired;
  final bool isActive;
  final bool isAvailable;
  final int pointsCost;
  final RewardType type;
  final String? imageUrl;
  final DateTime? createdAt;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsRequired,
    this.isActive = true,
    this.isAvailable = true,
    int? pointsCost,
    this.type = RewardType.discount,
    this.imageUrl,
    DateTime? createdAt,
  }) : pointsCost = pointsCost ?? pointsRequired,
       createdAt = createdAt ?? DateTime.now();

  String get title => name;

  Reward copyWith({
    String? id,
    String? name,
    String? description,
    int? pointsRequired,
    bool? isActive,
    bool? isAvailable,
    int? pointsCost,
    RewardType? type,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Reward(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      pointsCost: pointsCost ?? this.pointsCost,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pointsRequired': pointsRequired,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'pointsCost': pointsCost,
      'type': type.name,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      pointsRequired: map['pointsRequired'] ?? 0,
      isActive: map['isActive'] ?? true,
      isAvailable: map['isAvailable'] ?? true,
      pointsCost: map['pointsCost'],
      type: RewardType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RewardType.discount,
      ),
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
}

// Basic Points Rule stub
class PointsRule {
  final String id;
  final String name;
  final String description;
  final int basePoints;
  final AchievementType activityType;
  final Map<String, dynamic> conditions;

  PointsRule({
    required this.id,
    required this.name,
    required this.description,
    this.basePoints = 10,
    this.activityType = AchievementType.firstScrapSale,
    this.conditions = const {},
  });

  int calculatePoints([Map<String, dynamic>? context]) {
    int points = basePoints;
    // Simplified calculation logic
    if (context != null && context.containsKey('multiplier')) {
      points = (points * (context['multiplier'] as num).toInt()).toInt();
    }
    return points;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'basePoints': basePoints,
      'activityType': activityType.name,
      'conditions': conditions,
    };
  }

  factory PointsRule.fromMap(Map<String, dynamic> map) {
    return PointsRule(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      basePoints: map['basePoints'] ?? 10,
      activityType: AchievementType.values.firstWhere(
        (e) => e.name == map['activityType'],
        orElse: () => AchievementType.firstScrapSale,
      ),
      conditions: map['conditions'] ?? {},
    );
  }
}

// Basic Achievement stub
class LoyaltyAchievement {
  final String id;
  final String name;
  final String description;
  final String title;
  final IconData icon;
  final AchievementType type;
  final int pointsReward;
  final bool isHidden;
  final Map<String, dynamic> requirements;

  LoyaltyAchievement({
    required this.id,
    required this.name,
    required this.description,
    required String title,
    required IconData icon,
    this.type = AchievementType.firstScrapSale,
    this.pointsReward = 50,
    this.isHidden = false,
    this.requirements = const {},
  }) : title = title,
       icon = icon;

  bool get isUnlocked => false; // Would be computed based on user progress

  LoyaltyAchievement copyWith({
    String? id,
    String? name,
    String? description,
    String? title,
    IconData? icon,
    AchievementType? type,
    int? pointsReward,
    bool? isHidden,
    Map<String, dynamic>? requirements,
  }) {
    return LoyaltyAchievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      pointsReward: pointsReward ?? this.pointsReward,
      isHidden: isHidden ?? this.isHidden,
      requirements: requirements ?? this.requirements,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'title': title,
      'icon': icon.codePoint, // Store IconData as codePoint
      'type': type.name,
      'pointsReward': pointsReward,
      'isHidden': isHidden,
      'requirements': requirements,
    };
  }

  factory LoyaltyAchievement.fromMap(Map<String, dynamic> map) {
    return LoyaltyAchievement(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      title: map['title'] ?? map['name'] ?? '',
      icon: IconData(map['icon'] ?? Icons.star.codePoint, fontFamily: 'MaterialIcons'),
      type: AchievementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AchievementType.firstScrapSale,
      ),
      pointsReward: map['pointsReward'] ?? 50,
      isHidden: map['isHidden'] ?? false,
      requirements: map['requirements'] ?? {},
    );
  }
}

// Basic Referral Record stub
class ReferralRecord {
  final String id;
  final String referrerId;
  final String referredEmail;

  ReferralRecord({
    required this.id,
    required this.referrerId,
    required this.referredEmail,
  });

  ReferralRecord copyWith({
    String? id,
    String? referrerId,
    String? referredEmail,
  }) {
    return ReferralRecord(
      id: id ?? this.id,
      referrerId: referrerId ?? this.referrerId,
      referredEmail: referredEmail ?? this.referredEmail,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referrerId': referrerId,
      'referredEmail': referredEmail,
    };
  }

  factory ReferralRecord.fromMap(Map<String, dynamic> map) {
    return ReferralRecord(
      id: map['id'] ?? '',
      referrerId: map['referrerId'] ?? '',
      referredEmail: map['referredEmail'] ?? '',
    );
  }
}

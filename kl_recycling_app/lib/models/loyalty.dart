import 'package:flutter/material.dart';

/// Represents different loyalty tiers with their benefits and requirements
enum LoyaltyTier {
  bronze('Bronze', 'Getting Started', Icons.circle, 0, 0.0),
  silver('Silver', 'Regular Recycler', Icons.star_border, 1000, 0.05),
  gold('Gold', 'Dedicated Customer', Icons.grade, 5000, 0.10),
  platinum('Platinum', 'Elite Member', Icons.diamond, 15000, 0.15);

  const LoyaltyTier(this.title, this.description, this.icon, this.pointsRequired, this.discountPercentage);

  final String title;
  final String description;
  final IconData icon;
  final int pointsRequired;
  final double discountPercentage;
}

/// Individual loyalty points transaction/record
class LoyaltyPoints {
  final String id;
  final String userId;
  final String description;
  final int points;
  final TransactionType type;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? referenceId; // appointment, referral, etc.

  const LoyaltyPoints({
    required this.id,
    required this.userId,
    required this.description,
    required this.points,
    required this.type,
    required this.createdAt,
    this.expiresAt,
    this.referenceId,
  });

  factory LoyaltyPoints.fromMap(Map<String, dynamic> map) {
    return LoyaltyPoints(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      description: map['description'] ?? '',
      points: map['points'] ?? 0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.earned,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
      referenceId: map['referenceId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'description': description,
      'points': points,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'referenceId': referenceId,
    };
  }

  bool get isExpired => expiresAt?.isBefore(DateTime.now()) ?? false;
}

enum TransactionType {
  earned,
  redeemed,
  expired,
  bonus,
  referral,
  purchase; // when points are purchased

  String get displayName {
    switch (this) {
      case TransactionType.earned:
        return 'Earned';
      case TransactionType.redeemed:
        return 'Redeemed';
      case TransactionType.expired:
        return 'Expired';
      case TransactionType.bonus:
        return 'Bonus';
      case TransactionType.referral:
        return 'Referral';
      case TransactionType.purchase:
        return 'Purchase';
    }
  }
}

/// Redeemable rewards in the catalog
class Reward {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int pointsCost;
  final RewardType type;
  final bool isActive;
  final int? maxRedemptions; // null means unlimited
  final int currentRedemptions;
  final DateTime createdAt;

  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.pointsCost,
    required this.type,
    this.isActive = true,
    this.maxRedemptions,
    this.currentRedemptions = 0,
    required this.createdAt,
  });

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      pointsCost: map['pointsCost'] ?? 0,
      type: RewardType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RewardType.service,
      ),
      isActive: map['isActive'] ?? true,
      maxRedemptions: map['maxRedemptions'],
      currentRedemptions: map['currentRedemptions'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'pointsCost': pointsCost,
      'type': type.name,
      'isActive': isActive,
      'maxRedemptions': maxRedemptions,
      'currentRedemptions': currentRedemptions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isAvailable => isActive && (maxRedemptions == null || currentRedemptions < maxRedemptions!);
}

// Extension to add copyWith method to Reward
extension RewardExtension on Reward {
  Reward copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    int? pointsCost,
    RewardType? type,
    bool? isActive,
    int? maxRedemptions,
    int? currentRedemptions,
    DateTime? createdAt,
  }) {
    return Reward(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      pointsCost: pointsCost ?? this.pointsCost,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      maxRedemptions: maxRedemptions ?? this.maxRedemptions,
      currentRedemptions: currentRedemptions ?? this.currentRedemptions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum RewardType {
  service('Service Discount'),
  merchandise('Merchandise'),
  experience('Special Experience'),
  donation('Charity Donation');

  const RewardType(this.displayName);
  final String displayName;
}

/// Enhanced achievement system for loyalty
class LoyaltyAchievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementType type;
  final int pointsReward;
  final Map<String, dynamic> requirements; // Flexible requirements system
  final bool isHidden;
  final DateTime? unlockedAt;

  const LoyaltyAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.pointsReward,
    required this.requirements,
    this.isHidden = false,
    this.unlockedAt,
  });

  factory LoyaltyAchievement.fromMap(Map<String, dynamic> map) {
    return LoyaltyAchievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: IconData(map['iconCodePoint'] ?? 0, fontFamily: 'MaterialIcons'),
      type: AchievementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AchievementType.milestone,
      ),
      pointsReward: map['pointsReward'] ?? 0,
      requirements: Map<String, dynamic>.from(map['requirements'] ?? {}),
      isHidden: map['isHidden'] ?? false,
      unlockedAt: map['unlockedAt'] != null ? DateTime.parse(map['unlockedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'type': type.name,
      'pointsReward': pointsReward,
      'requirements': requirements,
      'isHidden': isHidden,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  bool get isUnlocked => unlockedAt != null;
}

enum AchievementType {
  milestone('Milestone'),
  streak('Streak'),
  social('Social'),
  special('Special Event');

  const AchievementType(this.displayName);
  final String displayName;
}

/// Referral program tracking
class ReferralRecord {
  final String id;
  final String referrerUserId;
  final String? referredUserId; // null if not registered yet
  final String referralCode;
  final ReferralStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int pointsRewarded;

  const ReferralRecord({
    required this.id,
    required this.referrerUserId,
    this.referredUserId,
    required this.referralCode,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.pointsRewarded = 0,
  });

  factory ReferralRecord.fromMap(Map<String, dynamic> map) {
    return ReferralRecord(
      id: map['id'] ?? '',
      referrerUserId: map['referrerUserId'] ?? '',
      referredUserId: map['referredUserId'],
      referralCode: map['referralCode'] ?? '',
      status: ReferralStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReferralStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      pointsRewarded: map['pointsRewarded'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referrerUserId': referrerUserId,
      'referredUserId': referredUserId,
      'referralCode': referralCode,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'pointsRewarded': pointsRewarded,
    };
  }

  bool get isCompleted => status == ReferralStatus.completed;
}

enum ReferralStatus {
  pending('Pending'),
  registered('Registered'),
  completed('Completed'),
  expired('Expired');

  const ReferralStatus(this.displayName);
  final String displayName;
}

/// Tier upgrade progression tracking
class TierUpgradeRecord {
  final String id;
  final String userId;
  final LoyaltyTier fromTier;
  final LoyaltyTier toTier;
  final DateTime upgradedAt;
  final int pointsAtUpgrade;

  const TierUpgradeRecord({
    required this.id,
    required this.userId,
    required this.fromTier,
    required this.toTier,
    required this.upgradedAt,
    required this.pointsAtUpgrade,
  });

  factory TierUpgradeRecord.fromMap(Map<String, dynamic> map) {
    return TierUpgradeRecord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fromTier: LoyaltyTier.values.firstWhere(
        (e) => e.name == map['fromTier'],
        orElse: () => LoyaltyTier.bronze,
      ),
      toTier: LoyaltyTier.values.firstWhere(
        (e) => e.name == map['toTier'],
        orElse: () => LoyaltyTier.bronze,
      ),
      upgradedAt: DateTime.parse(map['upgradedAt']),
      pointsAtUpgrade: map['pointsAtUpgrade'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fromTier': fromTier.name,
      'toTier': toTier.name,
      'upgradedAt': upgradedAt.toIso8601String(),
      'pointsAtUpgrade': pointsAtUpgrade,
    };
  }
}

/// Main loyalty profile for each user
class LoyaltyProfile {
  final String userId;
  final LoyaltyTier currentTier;
  final int totalPoints;
  final int availablePoints;
  final List<LoyaltyPoints> pointsHistory;
  final List<LoyaltyAchievement> unlockedAchievements;
  final List<ReferralRecord> referralRecords;
  final List<TierUpgradeRecord> tierUpgrades;
  final Map<String, dynamic> preferences;
  final DateTime joinedAt;
  final DateTime lastActivityAt;

  const LoyaltyProfile({
    required this.userId,
    this.currentTier = LoyaltyTier.bronze,
    this.totalPoints = 0,
    this.availablePoints = 0,
    this.pointsHistory = const [],
    this.unlockedAchievements = const [],
    this.referralRecords = const [],
    this.tierUpgrades = const [],
    this.preferences = const {},
    required this.joinedAt,
    required this.lastActivityAt,
  });

  factory LoyaltyProfile.fromMap(Map<String, dynamic> map) {
    return LoyaltyProfile(
      userId: map['userId'] ?? '',
      currentTier: LoyaltyTier.values.firstWhere(
        (e) => e.name == map['currentTier'],
        orElse: () => LoyaltyTier.bronze,
      ),
      totalPoints: map['totalPoints'] ?? 0,
      availablePoints: map['availablePoints'] ?? 0,
      pointsHistory: (map['pointsHistory'] as List<dynamic>?)
          ?.map((e) => LoyaltyPoints.fromMap(e))
          .toList() ?? [],
      unlockedAchievements: (map['unlockedAchievements'] as List<dynamic>?)
          ?.map((e) => LoyaltyAchievement.fromMap(e))
          .toList() ?? [],
      referralRecords: (map['referralRecords'] as List<dynamic>?)
          ?.map((e) => ReferralRecord.fromMap(e))
          .toList() ?? [],
      tierUpgrades: (map['tierUpgrades'] as List<dynamic>?)
          ?.map((e) => TierUpgradeRecord.fromMap(e))
          .toList() ?? [],
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      joinedAt: DateTime.parse(map['joinedAt']),
      lastActivityAt: DateTime.parse(map['lastActivityAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentTier': currentTier.name,
      'totalPoints': totalPoints,
      'availablePoints': availablePoints,
      'pointsHistory': pointsHistory.map((e) => e.toMap()).toList(),
      'unlockedAchievements': unlockedAchievements.map((e) => e.toMap()).toList(),
      'referralRecords': referralRecords.map((e) => e.toMap()).toList(),
      'tierUpgrades': tierUpgrades.map((e) => e.toMap()).toList(),
      'preferences': preferences,
      'joinedAt': joinedAt.toIso8601String(),
      'lastActivityAt': lastActivityAt.toIso8601String(),
    };
  }

  // Helper methods
  double get discountPercentage => currentTier.discountPercentage;

  bool hasUnlockedAchievement(String achievementId) {
    return unlockedAchievements.any((achievement) => achievement.id == achievementId);
  }

  int getPendingReferrals() {
    return referralRecords.where((r) => r.status == ReferralStatus.pending).length;
  }

  int getCompletedReferrals() {
    return referralRecords.where((r) => r.isCompleted).length;
  }

  LoyaltyTier getNextTier() {
    final currentIndex = LoyaltyTier.values.indexOf(currentTier);
    if (currentIndex < LoyaltyTier.values.length - 1) {
      return LoyaltyTier.values[currentIndex + 1];
    }
    return currentTier; // Already at highest tier
  }

  int get pointsToNextTier {
    final nextTier = getNextTier();
    return nextTier.pointsRequired - totalPoints;
  }

  bool get canUpgradeTier => pointsToNextTier <= 0 && getNextTier() != currentTier;
}

// Extension to add copyWith method to LoyaltyProfile
extension LoyaltyProfileExtension on LoyaltyProfile {
  LoyaltyProfile copyWith({
    String? userId,
    LoyaltyTier? currentTier,
    int? totalPoints,
    int? availablePoints,
    List<LoyaltyPoints>? pointsHistory,
    List<LoyaltyAchievement>? unlockedAchievements,
    List<ReferralRecord>? referralRecords,
    List<TierUpgradeRecord>? tierUpgrades,
    Map<String, dynamic>? preferences,
    DateTime? joinedAt,
    DateTime? lastActivityAt,
  }) {
    return LoyaltyProfile(
      userId: userId ?? this.userId,
      currentTier: currentTier ?? this.currentTier,
      totalPoints: totalPoints ?? this.totalPoints,
      availablePoints: availablePoints ?? this.availablePoints,
      pointsHistory: pointsHistory ?? this.pointsHistory,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      referralRecords: referralRecords ?? this.referralRecords,
      tierUpgrades: tierUpgrades ?? this.tierUpgrades,
      preferences: preferences ?? this.preferences,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }
}

// Extension to add copyWith method to LoyaltyAchievement
extension LoyaltyAchievementExtension on LoyaltyAchievement {
  LoyaltyAchievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    AchievementType? type,
    int? pointsReward,
    Map<String, dynamic>? requirements,
    bool? isHidden,
    DateTime? unlockedAt,
  }) {
    return LoyaltyAchievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      pointsReward: pointsReward ?? this.pointsReward,
      requirements: requirements ?? this.requirements,
      isHidden: isHidden ?? this.isHidden,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

/// Points earning rules for different activities
class PointsRule {
  final String id;
  final String name;
  final String description;
  final int basePoints;
  final String activityType;
  final Map<String, dynamic> conditions; // Additional conditions for earning points

  const PointsRule({
    required this.id,
    required this.name,
    required this.description,
    required this.basePoints,
    required this.activityType,
    this.conditions = const {},
  });

  int calculatePoints([Map<String, dynamic> context = const {}]) {
    // Simple calculation - can be extended with more complex logic
    return basePoints;
  }
}

// Type aliases for compatibility
typedef LoyaltyBadge = LoyaltyAchievement;

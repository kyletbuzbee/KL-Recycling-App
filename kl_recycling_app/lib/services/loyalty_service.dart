import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kl_recycling_app/models/loyalty.dart';
import 'package:kl_recycling_app/services/firebase_service.dart';
import 'package:kl_recycling_app/utils/error_messages.dart';

/// Service class for managing loyalty program functionality
class LoyaltyService {
  final FirebaseService _firebaseService;

  LoyaltyService(this._firebaseService);

  /// Get user loyalty profile
  Future<LoyaltyProfile> getLoyaltyProfile(String userId) async {
    try {
      final data = await _firebaseService.getDocument('loyalty_profiles', userId);
      return LoyaltyProfile.fromMap(data ?? {});
    } catch (e) {
      throw Exception('${ErrorMessages.documentNotFound} Profile not found for user $userId');
    }
  }

  /// Create or update loyalty profile
  Future<void> saveLoyaltyProfile(LoyaltyProfile profile) async {
    try {
      await _firebaseService.setDocument('loyalty_profiles', profile.userId, profile.toMap());
    } catch (e) {
      throw Exception('Failed to save loyalty profile');
    }
  }

  /// Award points to user
  Future<void> awardPoints(String userId, int points, String description, {String? referenceId, TransactionType type = TransactionType.earned}) async {
    final profile = await getLoyaltyProfile(userId);

    final pointEntry = LoyaltyPoints(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      points: points,
      description: description,
      referenceId: referenceId ?? '',
      type: type,
    );

    final updatedProfile = profile.copyWith(
      totalPoints: profile.totalPoints + points,
      availablePoints: profile.availablePoints + points,
      pointsHistory: [...profile.pointsHistory, pointEntry],
    );

    await saveLoyaltyProfile(updatedProfile);
  }

  /// Redeem reward
  Future<bool> redeemReward(String userId, Reward reward) async {
    final profile = await getLoyaltyProfile(userId);

    if (profile.availablePoints < reward.pointsCost || !reward.isAvailable) {
      return false;
    }

    // Deduct points
    final pointEntry = LoyaltyPoints(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      points: -reward.pointsCost,
      description: 'Redeemed: ${reward.name}',
      type: TransactionType.rewardRedemption,
    );

    final updatedProfile = profile.copyWith(
      availablePoints: profile.availablePoints - reward.pointsCost,
      pointsHistory: [...profile.pointsHistory, pointEntry],
    );

    await saveLoyaltyProfile(updatedProfile);
    return true;
  }

  /// Get available rewards
  Future<List<Reward>> getAvailableRewards() async {
    try {
      final data = await _firebaseService.getCollection('rewards');
      return data.map((item) => Reward.fromMap(item)).where((reward) => reward.isAvailable).toList();
    } catch (e) {
      return []; // Return empty list on error
    }
  }

  /// Get points rules
  Future<List<PointsRule>> getPointsRules() async {
    try {
      final data = await _firebaseService.getCollection('points_rules');
      return data.map((item) => PointsRule.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Calculate points for activity
  Future<int> calculatePointsForActivity(String userId, AchievementType activityType, [Map<String, dynamic>? context]) async {
    final rules = await getPointsRules();
    final rule = rules.firstWhere(
      (r) => r.activityType == activityType,
      orElse: () => PointsRule(
        id: 'default',
        name: 'Default Rule',
        description: 'Default points rule',
        basePoints: 10,
      ),
    );
    return rule.calculatePoints(context);
  }

  /// Get achievements
  Future<List<LoyaltyAchievement>> getAchievements() async {
    try {
      final data = await _firebaseService.getCollection('achievements');
      return data.map((item) => LoyaltyAchievement.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Create referral record
  Future<void> createReferral({
    required String referrerId,
    required String referredEmail,
    String? referralCode,
    ReferralStatus status = ReferralStatus.pending,
    DateTime? createdAt,
  }) async {
    try {
      final referralId = DateTime.now().millisecondsSinceEpoch.toString();
      final referral = {
        'id': referralId,
        'referrerId': referrerId,
        'referredEmail': referredEmail,
        'referralCode': referralCode,
        'status': status.name,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };

      await _firebaseService.setDocument('referrals', referralId, referral);
    } catch (e) {
      throw Exception('Failed to create referral record');
    }
  }

  /// Get referral records for user
  Future<List<ReferralRecord>> getReferralRecords(String userId) async {
    try {
      final data = await _firebaseService.queryCollection(
        'referrals',
        'referrerId',
        userId,
      );
      return data.map((item) => ReferralRecord.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Create tier upgrade record
  Future<TierUpgradeRecord> createTierUpgradeRecord({
    required String userId,
    required LoyaltyTier oldTier,
    required LoyaltyTier newTier,
    required int pointsRequired,
    DateTime? upgradedAt,
  }) async {
    return TierUpgradeRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      oldTier: oldTier,
      newTier: newTier,
      pointsRequired: pointsRequired,
      upgradedAt: upgradedAt ?? DateTime.now(),
    );
  }

  /// Get leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    // Simplified leaderboard logic
    return [];
  }

  /// Initialize user profile (first time)
  Future<LoyaltyProfile> initializeUserProfile(String userId) async {
    final profile = LoyaltyProfile(
      userId: userId,
      totalPoints: 0,
      availablePoints: 0,
    );
    await saveLoyaltyProfile(profile);
    return profile;
  }

  // Static constructors for predefined rules/rewards (used in diagnostics)
  static PointsRule scrapSaleRule({
    required int basePoints,
    required AchievementType activityType,
    required Map<String, dynamic> conditions,
  }) {
    return PointsRule(
      id: 'scrap_sale_${activityType.name}',
      name: 'Scrap Sale Bonus',
      description: 'Points for selling scrap materials',
      basePoints: basePoints,
      activityType: activityType,
      conditions: conditions,
    );
  }

  static PointsRule referralRule({
    required int basePoints,
    required AchievementType activityType,
    required Map<String, dynamic> conditions,
  }) {
    return PointsRule(
      id: 'referral_${activityType.name}',
      name: 'Referral Bonus',
      description: 'Points for successful referrals',
      basePoints: basePoints,
      activityType: activityType,
      conditions: conditions,
    );
  }

  static PointsRule achievementRule({
    required int basePoints,
    required AchievementType activityType,
    required Map<String, dynamic> conditions,
  }) {
    return PointsRule(
      id: 'achievement_${activityType.name}',
      name: 'Achievement Bonus',
      description: 'Points for unlocking achievements',
      basePoints: basePoints,
      activityType: activityType,
      conditions: conditions,
    );
  }

  static PointsRule consistencyRule({
    required int basePoints,
    required AchievementType activityType,
    required Map<String, dynamic> conditions,
  }) {
    return PointsRule(
      id: 'consistency_${activityType.name}',
      name: 'Consistency Bonus',
      description: 'Points for consistent activity',
      basePoints: basePoints,
      activityType: activityType,
      conditions: conditions,
    );
  }

  static PointsRule volumeRule({
    required int basePoints,
    required AchievementType activityType,
    required Map<String, dynamic> conditions,
  }) {
    return PointsRule(
      id: 'volume_${activityType.name}',
      name: 'Volume Bonus',
      description: 'Points for processing large volumes',
      basePoints: basePoints,
      activityType: activityType,
      conditions: conditions,
    );
  }

  // Static reward creators
  static Reward createDiscountReward({
    required String name,
    required String imageUrl,
    required int pointsCost,
    required RewardType type,
    required DateTime createdAt,
  }) {
    return Reward(
      id: 'discount_${name.replaceAll(' ', '_').toLowerCase()}',
      name: name,
      description: '$name discount reward',
      pointsRequired: pointsCost,
      pointsCost: pointsCost,
      type: type,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }

  static Reward createCashbackReward({
    required String name,
    required String imageUrl,
    required int pointsCost,
    required RewardType type,
    required DateTime createdAt,
  }) {
    return Reward(
      id: 'cashback_${name.replaceAll(' ', '_').toLowerCase()}',
      name: name,
      description: '$name cashback reward',
      pointsRequired: pointsCost,
      pointsCost: pointsCost,
      type: type,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }

  static Reward createServiceReward({
    required String name,
    required String imageUrl,
    required int pointsCost,
    required RewardType type,
    required DateTime createdAt,
  }) {
    return Reward(
      id: 'service_${name.replaceAll(' ', '_').toLowerCase()}',
      name: name,
      description: '$name service reward',
      pointsRequired: pointsCost,
      pointsCost: pointsCost,
      type: type,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }

  static Reward createMerchandiseReward({
    required String name,
    required String imageUrl,
    required int pointsCost,
    required RewardType type,
    required DateTime createdAt,
  }) {
    return Reward(
      id: 'merchandise_${name.replaceAll(' ', '_').toLowerCase()}',
      name: name,
      description: '$name merchandise reward',
      pointsRequired: pointsCost,
      pointsCost: pointsCost,
      type: type,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }

  static Reward createDonationReward({
    required String name,
    required String imageUrl,
    required int pointsCost,
    required RewardType type,
    required DateTime createdAt,
  }) {
    return Reward(
      id: 'donation_${name.replaceAll(' ', '_').toLowerCase()}',
      name: name,
      description: '$name donation reward',
      pointsRequired: pointsCost,
      pointsCost: pointsCost,
      type: type,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }

  static LoyaltyAchievement createAchievement({
    required String title,
    required String icon,
    required AchievementType type,
    required int pointsReward,
    required Map<String, dynamic> requirements,
  }) {
    return LoyaltyAchievement(
      id: 'achievement_${title.replaceAll(' ', '_').toLowerCase()}',
      name: title,
      description: title,
      title: title,
      icon: _iconFromString(icon),
      type: type,
      pointsReward: pointsReward,
      requirements: requirements,
    );
  }

  static IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'trophy':
        return Icons.emoji_events;
      case 'medal':
        return Icons.military_tech;
      case 'award':
        return Icons.workspace_premium;
      default:
        return Icons.star;
    }
  }
}

/// Tier upgrade record class
class TierUpgradeRecord {
  final String id;
  final String userId;
  final LoyaltyTier oldTier;
  final LoyaltyTier newTier;
  final int pointsRequired;
  final DateTime upgradedAt;

  TierUpgradeRecord({
    required this.id,
    required this.userId,
    required this.oldTier,
    required this.newTier,
    required this.pointsRequired,
    required this.upgradedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'oldTier': oldTier.index,
      'newTier': newTier.index,
      'pointsRequired': pointsRequired,
      'upgradedAt': upgradedAt.toIso8601String(),
    };
  }

  factory TierUpgradeRecord.fromMap(Map<String, dynamic> map) {
    return TierUpgradeRecord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      oldTier: LoyaltyTier.values[map['oldTier'] ?? 0],
      newTier: LoyaltyTier.values[map['newTier'] ?? 1],
      pointsRequired: map['pointsRequired'] ?? 100,
      upgradedAt: DateTime.parse(map['upgradedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

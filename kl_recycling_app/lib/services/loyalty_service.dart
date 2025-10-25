import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kl_recycling_app/models/loyalty.dart';

/// Comprehensive loyalty program service managing points, tiers, rewards, and referrals
class LoyaltyService extends ChangeNotifier {
  static const String _loyaltyProfilesKey = 'loyalty_profiles';
  static const String _rewardsCatalogKey = 'rewards_catalog';
  static const String _pointsRulesKey = 'points_rules';
  static const String _achievementsKey = 'achievements';

  SharedPreferences? _prefs;

  // Data storage
  final Map<String, LoyaltyProfile> _profiles = {};
  final List<Reward> _rewardsCatalog = [];
  final List<PointsRule> _pointsRules = [];
  final List<LoyaltyAchievement> _achievements = [];

  // Initialization
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadLoyaltyData();
      await _initializeDefaultData();
    } catch (e) {
      debugPrint('Error initializing loyalty service: $e');
      // Initialize with empty/default state on failure
      _initializeEmptyState();
    }
    notifyListeners();
  }

  // Public getters
  Map<String, LoyaltyProfile> get profiles => Map.from(_profiles);
  List<Reward> get rewardsCatalog => _rewardsCatalog.where((reward) => reward.isActive).toList();
  List<PointsRule> get pointsRules => List.from(_pointsRules);
  List<LoyaltyAchievement> get achievements => List.from(_achievements);

  /// Get or create loyalty profile for user
  Future<LoyaltyProfile> getLoyaltyProfile(String userId) async {
    if (!_profiles.containsKey(userId)) {
      final profile = LoyaltyProfile(
        userId: userId,
        joinedAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
      );
      _profiles[userId] = profile;
      await _saveLoyaltyProfile(profile);
      notifyListeners();
    }
    return _profiles[userId]!;
  }

  /// Award points for activity
  Future<PointsResult> awardPoints({
    required String userId,
    required String activityType,
    String? referenceId,
    String? description,
    Map<String, dynamic> context = const {},
  }) async {
    try {
      final profile = await getLoyaltyProfile(userId);

      // Find matching rule
      final rule = _pointsRules.firstWhere(
        (rule) => rule.activityType == activityType,
        orElse: () => throw Exception('No points rule found for activity: $activityType'),
      );

      final points = rule.calculatePoints(context);
      final pointsRecord = LoyaltyPoints(
        id: _generatePointsId(),
        userId: userId,
        description: description ?? rule.description,
        points: points,
        type: TransactionType.earned,
        createdAt: DateTime.now(),
        referenceId: referenceId,
      );

      // Update profile
      final updatedProfile = _updateProfileWithPoints(profile, pointsRecord);
      _profiles[userId] = updatedProfile;

      await _saveLoyaltyProfile(updatedProfile);

      // Check for achievements and tier upgrades
      await _checkAchievements(updatedProfile);
      await _checkTierUpgrade(updatedProfile);

      notifyListeners();

      return PointsResult.success(pointsRecord);
    } catch (e) {
      return PointsResult.error('Failed to award points: $e');
    }
  }

  /// Redeem points for reward
  Future<RewardResult> redeemReward(String userId, String rewardId) async {
    try {
      final profile = await getLoyaltyProfile(userId);
      final reward = _rewardsCatalog.firstWhere(
        (r) => r.id == rewardId,
        orElse: () => throw Exception('Reward not found'),
      );

      if (!reward.isAvailable) {
        return RewardResult.error('Reward is not currently available');
      }

      if (profile.availablePoints < reward.pointsCost) {
        return RewardResult.error('Insufficient points balance');
      }

      // Create redemption record
      final redemptionRecord = LoyaltyPoints(
        id: _generatePointsId(),
        userId: userId,
        description: 'Redeemed ${reward.title}',
        points: -reward.pointsCost,
        type: TransactionType.redeemed,
        createdAt: DateTime.now(),
        referenceId: rewardId,
      );

      // Update profile
      final updatedProfile = _updateProfileWithPoints(profile, redemptionRecord);
      _profiles[userId] = updatedProfile;

      // Update reward redemptions
      final rewardIndex = _rewardsCatalog.indexWhere((r) => r.id == rewardId);
      if (rewardIndex != -1) {
        _rewardsCatalog[rewardIndex] = reward.copyWith(
          currentRedemptions: reward.currentRedemptions + 1,
        );
      }

      await _saveLoyaltyProfile(updatedProfile);
      await _saveRewardsCatalog();

      notifyListeners();

      return RewardResult.success(reward);
    } catch (e) {
      return RewardResult.error('Failed to redeem reward: $e');
    }
  }

  /// Create referral record
  Future<ReferralResult> createReferral(String referrerUserId, String referralCode) async {
    try {
      final profile = await getLoyaltyProfile(referrerUserId);

      final referral = ReferralRecord(
        id: _generateReferralId(),
        referrerUserId: referrerUserId,
        referralCode: referralCode,
        status: ReferralStatus.pending,
        createdAt: DateTime.now(),
      );

      final updatedProfile = profile.copyWith(
        referralRecords: [...profile.referralRecords, referral],
      );

      _profiles[referrerUserId] = updatedProfile;
      await _saveLoyaltyProfile(updatedProfile);

      notifyListeners();

      return ReferralResult.success(referral);
    } catch (e) {
      return ReferralResult.error('Failed to create referral: $e');
    }
  }

  /// Complete referral (when referred user signs up)
  Future<bool> completeReferral(String referralId, String referredUserId) async {
    try {
      // Find the referral
      LoyaltyProfile? referrerProfile;
      int referralIndex = -1;

      for (final profile in _profiles.values) {
        referralIndex = profile.referralRecords.indexWhere((r) => r.id == referralId);
        if (referralIndex != -1) {
          referrerProfile = profile;
          break;
        }
      }

      if (referrerProfile == null || referralIndex == -1) {
        return false;
      }

      // Update referral status
      final existingReferral = referrerProfile.referralRecords[referralIndex];
      final updatedReferral = ReferralRecord(
        id: existingReferral.id,
        referrerUserId: existingReferral.referrerUserId,
        referredUserId: referredUserId,
        referralCode: existingReferral.referralCode,
        status: ReferralStatus.completed,
        createdAt: existingReferral.createdAt,
        completedAt: DateTime.now(),
        pointsRewarded: 100, // Referral bonus points
      );

      final updatedRecords = List<ReferralRecord>.from(referrerProfile.referralRecords);
      updatedRecords[referralIndex] = updatedReferral;

      final updatedProfile = referrerProfile.copyWith(
        referralRecords: updatedRecords,
      );

      _profiles[referrerProfile.userId] = updatedProfile;

      // Award referral points
      await awardPoints(
        userId: referrerProfile.userId,
        activityType: 'referral',
        referenceId: referralId,
        description: 'Referral bonus for bringing in a new customer',
      );

      await _saveLoyaltyProfile(updatedProfile);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error completing referral: $e');
      return false;
    }
  }

  /// Get points history for user
  List<LoyaltyPoints> getPointsHistory(String userId) {
    return _profiles[userId]?.pointsHistory ?? [];
  }

  /// Get leaderboard (top point earners)
  List<LeaderboardEntry> getLeaderboard([int limit = 10]) {
    final entries = _profiles.values.map((profile) => LeaderboardEntry(
      userId: profile.userId,
      totalPoints: profile.totalPoints,
      currentTier: profile.currentTier,
      completedReferrals: profile.getCompletedReferrals(),
    )).toList();

    entries.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    return entries.take(limit).toList();
  }

  /// Add custom achievement definition
  void addAchievement(LoyaltyAchievement achievement) {
    _achievements.add(achievement);
    _saveAchievements();
    notifyListeners();
  }

  /// Add reward to catalog
  void addReward(Reward reward) {
    _rewardsCatalog.add(reward);
    _saveRewardsCatalog();
    notifyListeners();
  }

  /// Update reward in catalog
  void updateReward(Reward updatedReward) {
    final index = _rewardsCatalog.indexWhere((r) => r.id == updatedReward.id);
    if (index != -1) {
      _rewardsCatalog[index] = updatedReward;
      _saveRewardsCatalog();
      notifyListeners();
    }
  }

  /// Get active points rules
  List<PointsRule> getActivePointsRules() {
    return _pointsRules.where((rule) => true).toList(); // All rules are active for now
  }

  // Private helper methods
  LoyaltyProfile _updateProfileWithPoints(LoyaltyProfile profile, LoyaltyPoints pointsRecord) {
    final updatedHistory = [...profile.pointsHistory, pointsRecord];
    final newTotalPoints = profile.totalPoints + pointsRecord.points;

    // Ensure points don't go negative
    final newAvailablePoints = profile.availablePoints + pointsRecord.points;

    return profile.copyWith(
      totalPoints: newTotalPoints,
      availablePoints: max(0, newAvailablePoints),
      pointsHistory: updatedHistory,
      lastActivityAt: DateTime.now(),
    );
  }

  Future<void> _checkAchievements(LoyaltyProfile profile) async {
    final unlockedAchievements = <LoyaltyAchievement>[];

    for (final achievement in _achievements) {
      if (!profile.hasUnlockedAchievement(achievement.id) && !achievement.isHidden) {
        // Check requirements - simplified version
        if (_meetsAchievementRequirements(profile, achievement)) {
          final unlockedAchievement = achievement.copyWith(
            unlockedAt: DateTime.now(),
          );

          unlockedAchievements.add(unlockedAchievement);

          // Award achievement points
          await awardPoints(
            userId: profile.userId,
            activityType: 'achievement',
            referenceId: achievement.id,
            description: 'Achievement unlocked: ${achievement.title}',
          );
        }
      }
    }

    if (unlockedAchievements.isNotEmpty) {
      final updatedAchievements = [...profile.unlockedAchievements, ...unlockedAchievements];
      final updatedProfile = profile.copyWith(
        unlockedAchievements: updatedAchievements,
      );

      _profiles[profile.userId] = updatedProfile;
      await _saveLoyaltyProfile(updatedProfile);
    }
  }

  Future<void> _checkTierUpgrade(LoyaltyProfile profile) async {
    if (!profile.canUpgradeTier) return;

    final upgradeRecord = TierUpgradeRecord(
      id: _generateTierUpgradeId(),
      userId: profile.userId,
      fromTier: profile.currentTier,
      toTier: profile.getNextTier(),
      upgradedAt: DateTime.now(),
      pointsAtUpgrade: profile.totalPoints,
    );

    final updatedUpgrades = [...profile.tierUpgrades, upgradeRecord];
    final updatedProfile = profile.copyWith(
      currentTier: profile.getNextTier(),
      tierUpgrades: updatedUpgrades,
    );

    _profiles[profile.userId] = updatedProfile;
    await _saveLoyaltyProfile(updatedProfile);

    // Show tier upgrade notification (could be handled by notification service)
    debugPrint('User ${profile.userId} upgraded to ${profile.currentTier.title} tier!');
  }

  bool _meetsAchievementRequirements(LoyaltyProfile profile, LoyaltyAchievement achievement) {
    // Simplified achievement checking - in real implementation would be more complex
    final requirements = achievement.requirements;

    if (requirements.containsKey('minPoints')) {
      if (profile.totalPoints < requirements['minPoints']) return false;
    }

    if (requirements.containsKey('minReferrals')) {
      if (profile.getCompletedReferrals() < requirements['minReferrals']) return false;
    }

    return true; // Basic implementation
  }

  Future<void> _initializeDefaultData() async {
    if (_pointsRules.isEmpty) {
      _initializePointsRules();
    }
    if (_achievements.isEmpty) {
      _initializeAchievements();
    }
    if (_rewardsCatalog.isEmpty) {
      _initializeRewardsCatalog();
    }
  }

  void _initializeEmptyState() {
    // Initialize with empty/default state when SharedPreferences fails
    // No data is loaded or saved, but the service remains functional
  }

  void _initializePointsRules() {
    _pointsRules.addAll([
      PointsRule(
        id: 'appointment',
        name: 'Appointment Completed',
        description: 'Completed a recycling appointment',
        basePoints: 50,
        activityType: 'appointment',
      ),
      PointsRule(
        id: 'photo_estimate',
        name: 'Photo Estimate',
        description: 'Requested a photo estimate',
        basePoints: 25,
        activityType: 'photo_estimate',
      ),
      PointsRule(
        id: 'referral',
        name: 'Referral Bonus',
        description: 'Successfully referred a new customer',
        basePoints: 100,
        activityType: 'referral',
      ),
      PointsRule(
        id: 'achievement',
        name: 'Achievement Unlocked',
        description: 'Unlocked a new achievement',
        basePoints: 50,
        activityType: 'achievement',
      ),
      PointsRule(
        id: 'review',
        name: 'Review Submitted',
        description: 'Submitted a review for service',
        basePoints: 25,
        activityType: 'review',
      ),
    ]);
    _savePointsRules();
  }

  void _initializeAchievements() {
    _achievements.addAll([
      LoyaltyAchievement(
        id: 'first_appointment',
        title: 'First Appointment',
        description: 'Complete your first recycling appointment',
        icon: Icons.schedule,
        type: AchievementType.milestone,
        pointsReward: 50,
        requirements: {'minAppointments': 1},
      ),
      LoyaltyAchievement(
        id: 'frequent_customer',
        title: 'Frequent Customer',
        description: 'Complete 10 appointments',
        icon: Icons.repeat,
        type: AchievementType.milestone,
        pointsReward: 100,
        requirements: {'minAppointments': 10},
      ),
      LoyaltyAchievement(
        id: 'loyal_supporter',
        title: 'Loyal Supporter',
        description: 'Complete 50 appointments',
        icon: Icons.loyalty,
        type: AchievementType.milestone,
        pointsReward: 250,
        requirements: {'minAppointments': 50},
      ),
      LoyaltyAchievement(
        id: 'referral_master',
        title: 'Referral Master',
        description: 'Successfully refer 5 new customers',
        icon: Icons.group_add,
        type: AchievementType.social,
        pointsReward: 200,
        requirements: {'minReferrals': 5},
      ),
    ]);
    _saveAchievements();
  }

  void _initializeRewardsCatalog() {
    _rewardsCatalog.addAll([
      Reward(
        id: 'discount_10',
        title: '\$10 Service Discount',
        description: 'Get \$10 off your next service',
        imageUrl: 'assets/images/loyalty/discount.png',
        pointsCost: 200,
        type: RewardType.service,
        createdAt: DateTime.now(),
      ),
      Reward(
        id: 'discount_25',
        title: '\$25 Service Discount',
        description: 'Get \$25 off your next service',
        imageUrl: 'assets/images/loyalty/discount.png',
        pointsCost: 500,
        type: RewardType.service,
        createdAt: DateTime.now(),
      ),
      Reward(
        id: 'free_pickup',
        title: 'Free Priority Pickup',
        description: 'Free priority pickup service (up to 500 lbs)',
        imageUrl: 'assets/images/loyalty/truck.png',
        pointsCost: 300,
        type: RewardType.service,
        createdAt: DateTime.now(),
      ),
      Reward(
        id: 'eco_tshirt',
        title: 'K&L Eco T-Shirt',
        description: 'Premium recycled material t-shirt',
        imageUrl: 'assets/images/loyalty/tshirt.png',
        pointsCost: 400,
        type: RewardType.merchandise,
        createdAt: DateTime.now(),
      ),
      Reward(
        id: 'charity_donation',
        title: '\$20 Charity Donation',
        description: '\$20 donation to local environmental charity of your choice',
        imageUrl: 'assets/images/loyalty/charity.png',
        pointsCost: 250,
        type: RewardType.donation,
        createdAt: DateTime.now(),
      ),
    ]);
    _saveRewardsCatalog();
  }

  String _generatePointsId() => 'pts_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateReferralId() => 'ref_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateTierUpgradeId() => 'tier_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

  Future<void> _loadLoyaltyData() async {
    try {
      if (_prefs == null) return; // Skip loading when SharedPreferences is unavailable

      // Load profiles
      final profilesData = _prefs!.getString(_loyaltyProfilesKey);
      if (profilesData != null) {
        final data = jsonDecode(profilesData) as Map<String, dynamic>;
        for (final entry in data.entries) {
          final profile = LoyaltyProfile.fromMap(entry.value as Map<String, dynamic>);
          _profiles[entry.key] = profile;
        }
      }

      // Load rewards catalog
      final rewardsData = _prefs!.getString(_rewardsCatalogKey);
      if (rewardsData != null) {
        final data = jsonDecode(rewardsData) as List<dynamic>;
        _rewardsCatalog.clear();
        for (final item in data) {
          _rewardsCatalog.add(Reward.fromMap(item as Map<String, dynamic>));
        }
      }

      // Load points rules
      final rulesData = _prefs!.getString(_pointsRulesKey);
      if (rulesData != null) {
        final data = jsonDecode(rulesData) as List<dynamic>;
        _pointsRules.clear();
        for (final item in data) {
          _pointsRules.add(PointsRule(
            id: item['id'],
            name: item['name'],
            description: item['description'],
            basePoints: item['basePoints'],
            activityType: item['activityType'],
            conditions: item['conditions'] ?? {},
          ));
        }
      }

      // Load achievements
      final achievementsData = _prefs!.getString(_achievementsKey);
      if (achievementsData != null) {
        final data = jsonDecode(achievementsData) as List<dynamic>;
        _achievements.clear();
        for (final item in data) {
          _achievements.add(LoyaltyAchievement.fromMap(item as Map<String, dynamic>));
        }
      }
    } catch (e) {
      debugPrint('Error loading loyalty data: $e');
    }
  }

  Future<void> _saveLoyaltyProfile(LoyaltyProfile profile) async {
    try {
      if (_prefs == null) return; // Skip saving when SharedPreferences is unavailable
      final profilesData = _profiles.map((k, v) => MapEntry(k, v.toMap()));
      await _prefs!.setString(_loyaltyProfilesKey, jsonEncode(profilesData));
    } catch (e) {
      debugPrint('Error saving loyalty profile: $e');
    }
  }

  Future<void> _saveRewardsCatalog() async {
    try {
      if (_prefs == null) return; // Skip saving when SharedPreferences is unavailable
      final rewardsData = _rewardsCatalog.map((r) => r.toMap()).toList();
      await _prefs!.setString(_rewardsCatalogKey, jsonEncode(rewardsData));
    } catch (e) {
      debugPrint('Error saving rewards catalog: $e');
    }
  }

  Future<void> _savePointsRules() async {
    try {
      if (_prefs == null) return; // Skip saving when SharedPreferences is unavailable
      final rulesData = _pointsRules.map((r) => {
        'id': r.id,
        'name': r.name,
        'description': r.description,
        'basePoints': r.basePoints,
        'activityType': r.activityType,
        'conditions': r.conditions,
      }).toList();
      await _prefs!.setString(_pointsRulesKey, jsonEncode(rulesData));
    } catch (e) {
      debugPrint('Error saving points rules: $e');
    }
  }

  Future<void> _saveAchievements() async {
    try {
      if (_prefs == null) return; // Skip saving when SharedPreferences is unavailable
      final achievementsData = _achievements.map((a) => a.toMap()).toList();
      await _prefs!.setString(_achievementsKey, jsonEncode(achievementsData));
    } catch (e) {
      debugPrint('Error saving achievements: $e');
    }
  }
}

/// Result classes for loyalty operations
class PointsResult {
  final bool success;
  final LoyaltyPoints? pointsRecord;
  final String? error;

  PointsResult._({this.success = false, this.pointsRecord, this.error});

  factory PointsResult.success(LoyaltyPoints pointsRecord) {
    return PointsResult._(success: true, pointsRecord: pointsRecord);
  }

  factory PointsResult.error(String error) {
    return PointsResult._(error: error);
  }
}

class RewardResult {
  final bool success;
  final Reward? reward;
  final String? error;

  RewardResult._({this.success = false, this.reward, this.error});

  factory RewardResult.success(Reward reward) {
    return RewardResult._(success: true, reward: reward);
  }

  factory RewardResult.error(String error) {
    return RewardResult._(error: error);
  }
}

class ReferralResult {
  final bool success;
  final ReferralRecord? referral;
  final String? error;

  ReferralResult._({this.success = false, this.referral, this.error});

  factory ReferralResult.success(ReferralRecord referral) {
    return ReferralResult._(success: true, referral: referral);
  }

  factory ReferralResult.error(String error) {
    return ReferralResult._(error: error);
  }
}

/// Leaderboard entry
class LeaderboardEntry {
  final String userId;
  final int totalPoints;
  final LoyaltyTier currentTier;
  final int completedReferrals;

  const LeaderboardEntry({
    required this.userId,
    required this.totalPoints,
    required this.currentTier,
    required this.completedReferrals,
  });
}

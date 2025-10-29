import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kl_recycling_app/features/loyalty/models/loyalty.dart';
import 'package:kl_recycling_app/features/loyalty/logic/loyalty_service.dart';

/// Result wrapper classes for provider operations
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int totalPoints;
  final LoyaltyTier currentTier;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.totalPoints,
    required this.currentTier,
    required this.rank,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? 'Anonymous',
      totalPoints: map['totalPoints'] ?? 0,
      currentTier: LoyaltyTier.bronze, // Simplified
      rank: map['rank'] ?? 0,
    );
  }
}

class PointsResult {
  final bool success;
  final String? message;
  final int? earnedPoints;

  PointsResult({
    required this.success,
    this.message,
    this.earnedPoints,
  });
}

class RewardResult {
  final bool success;
  final String? message;
  final Reward? reward;

  RewardResult({
    required this.success,
    this.message,
    this.reward,
  });
}

class ReferralResult {
  final bool success;
  final String? message;
  final String? referralCode;

  ReferralResult({
    required this.success,
    this.message,
    this.referralCode,
  });
}

// Stream controller for loyalty tier changes
class LoyaltyTierChangeEvent {
  final int currentPoints;
  final LoyaltyTier previousTier;
  final LoyaltyTier newTier;
  final String userId;

  LoyaltyTierChangeEvent({
    required this.currentPoints,
    required this.previousTier,
    required this.newTier,
    required this.userId,
  });
}

// Stream controller for broadcasting tier changes across the app
class LoyaltyEventService {
  static final StreamController<LoyaltyTierChangeEvent> _tierChangeController =
      StreamController<LoyaltyTierChangeEvent>.broadcast();

  static Stream<LoyaltyTierChangeEvent> get tierChangeStream =>
      _tierChangeController.stream;

  static void notifyTierChange(LoyaltyTierChangeEvent event) {
    _tierChangeController.add(event);
  }

  static void dispose() {
    _tierChangeController.close();
  }
}

/// Provider class for managing loyalty program state
class LoyaltyProvider extends ChangeNotifier {
  final LoyaltyService _loyaltyService;

  LoyaltyProvider(this._loyaltyService);

  // State variables
  LoyaltyProfile? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;
  List<LeaderboardEntry> _leaderboard = [];
  List<Reward> _rewardsCatalog = [];
  List<LoyaltyAchievement> _achievements = [];

  // Getters
  LoyaltyProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPoints => _currentProfile?.availablePoints ?? 0;
  int get totalPoints => _currentProfile?.totalPoints ?? 0;
  LoyaltyTier get currentTier => _currentProfile?.currentTier ?? LoyaltyTier.bronze;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  List<Reward> get rewardsCatalog => _rewardsCatalog;
  List<LoyaltyAchievement> get achievements => _achievements;
  List<LoyaltyPoints> get pointsHistory => _currentProfile?.pointsHistory ?? [];
  String get currentTierText => currentTier.title;
  double get tierProgressPercentage {
    if (_currentProfile == null) return 0.0;
    final nextTier = _getNextTier();
    if (nextTier == null) return 1.0; // Max tier reached

    final currentRequired = currentTier.pointsRequired;
    final nextRequired = nextTier.pointsRequired;
    final progress = totalPoints - currentRequired;
    final range = nextRequired - currentRequired;

    return range > 0 ? (progress / range).clamp(0.0, 1.0) : 1.0;
  }

  String get tierProgressText {
    final nextTier = _getNextTier();
    if (nextTier == null) return 'Maximum tier reached!';

    final pointsNeeded = nextTier.pointsRequired - totalPoints;
    if (pointsNeeded <= 0) return 'Ready to upgrade to ${nextTier.title}!';

    return '$pointsNeeded points to ${nextTier.title}';
  }

  int get completedReferrals => _currentProfile?.getCompletedReferrals() ?? 0;
  int get pendingReferrals => _currentProfile?.getPendingReferrals() ?? 0;
  double get discountPercentage => _currentProfile?.discountPercentage ?? 0.0;
  int get pointsToNextTier {
    final nextTier = _getNextTier();
    if (nextTier == null) return 0;
    return (nextTier.pointsRequired - totalPoints).clamp(0, double.infinity).toInt();
  }

  String get currentUserId => _currentProfile?.userId ?? '';
  bool get hasError => _errorMessage != null;

  // Methods
  Future<void> initializeForUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentProfile = await _loyaltyService.getLoyaltyProfile(userId);
      await _loadAdditionalData();
    } catch (e) {
      _currentProfile = await _loyaltyService.initializeUserProfile(userId);
      _errorMessage = 'Initialized new profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAdditionalData() async {
    try {
      _rewardsCatalog = await _loyaltyService.getAvailableRewards();
      _achievements = await _loyaltyService.getAchievements();

      final leaderboardData = await _loyaltyService.getLeaderboard(limit: 10);
      _leaderboard = leaderboardData.map((entry) => LeaderboardEntry.fromMap(entry)).toList();
    } catch (e) {
      // Handle errors silently for additional data
    }
  }

  Future<PointsResult> awardPoints(int points, String description, {AchievementType? activityType}) async {
    if (_currentProfile == null) {
      return PointsResult(success: false, message: 'No active user profile');
    }

    try {
      await _loyaltyService.awardPoints(
        _currentProfile!.userId,
        points,
        description,
        type: TransactionType.earned,
      );

      // Check for tier change before updating profile
      final previousTier = _currentProfile!.currentTier;
      final newTotalPoints = _currentProfile!.totalPoints + points;

      // Update local profile
      final pointEntry = LoyaltyPoints(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentProfile!.userId,
        points: points,
        description: description,
      );

      _currentProfile = _currentProfile!.copyWith(
        totalPoints: newTotalPoints,
        availablePoints: _currentProfile!.availablePoints + points,
        pointsHistory: [..._currentProfile!.pointsHistory, pointEntry],
      );

      // Check if tier changed after points update
      final newTier = _getTierFromPoints(newTotalPoints);
      if (newTier != previousTier) {
        // Notify tier change via event service
        LoyaltyEventService.notifyTierChange(
          LoyaltyTierChangeEvent(
            currentPoints: newTotalPoints,
            previousTier: previousTier,
            newTier: newTier,
            userId: _currentProfile!.userId,
          ),
        );
      }

      notifyListeners();
      return PointsResult(success: true, earnedPoints: points);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return PointsResult(success: false, message: e.toString());
    }
  }

  Future<RewardResult> redeemReward(Reward reward) async {
    if (_currentProfile == null) {
      return RewardResult(success: false, message: 'No active user profile');
    }

    if (_currentProfile!.availablePoints < reward.pointsCost) {
      return RewardResult(success: false, message: 'Insufficient points');
    }

    try {
      final success = await _loyaltyService.redeemReward(_currentProfile!.userId, reward);

      if (success) {
        // Update local profile
        final pointEntry = LoyaltyPoints(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: _currentProfile!.userId,
          points: -reward.pointsCost,
          description: 'Redeemed: ${reward.name}',
          type: TransactionType.rewardRedemption,
        );

        _currentProfile = _currentProfile!.copyWith(
          availablePoints: _currentProfile!.availablePoints - reward.pointsCost,
          pointsHistory: [..._currentProfile!.pointsHistory, pointEntry],
        );

        notifyListeners();
        return RewardResult(success: true, reward: reward);
      } else {
        return RewardResult(success: false, message: 'Redemption failed');
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return RewardResult(success: false, message: e.toString());
    }
  }

  Future<ReferralResult> createReferral(String referredEmail) async {
    if (_currentProfile == null) {
      return ReferralResult(success: false, message: 'No active user profile');
    }

    try {
      await _loyaltyService.createReferral(
        referrerId: _currentProfile!.userId,
        referredEmail: referredEmail,
      );

      // Update local profile
      final referralRecord = ReferralRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        referrerId: _currentProfile!.userId,
        referredEmail: referredEmail,
      );

      _currentProfile = _currentProfile!.copyWith(
        referralRecords: [..._currentProfile!.referralRecords, referralRecord],
      );

      notifyListeners();
      return ReferralResult(success: true);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return ReferralResult(success: false, message: e.toString());
    }
  }

  Future<void> refreshData() async {
    if (_currentProfile != null) {
      await initializeForUser(_currentProfile!.userId);
    }
  }

  LoyaltyTier? _getNextTier() {
    final currentIndex = currentTier.index;
    if (currentIndex < LoyaltyTier.values.length - 1) {
      return LoyaltyTier.values[currentIndex + 1];
    }
    return null; // Last tier
  }

  LoyaltyTier _getTierFromPoints(int points) {
    if (points >= 5000) return LoyaltyTier.platinum;
    if (points >= 2500) return LoyaltyTier.gold;
    if (points >= 1000) return LoyaltyTier.silver;
    return LoyaltyTier.bronze;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }


}

import 'package:flutter/material.dart';
import 'package:kl_recycling_app/models/loyalty.dart';
import 'package:kl_recycling_app/services/loyalty_service.dart';

/// Provider for managing loyalty program state
class LoyaltyProvider extends ChangeNotifier {
  late LoyaltyService _loyaltyService;

  // Current user loyalty data
  String? _currentUserId;
  LoyaltyProfile? _currentProfile;
  bool _isLoading = true;

  // Cached data for UI
  List<Reward> _rewardsCatalog = [];
  List<LoyaltyPoints> _pointsHistory = [];
  List<LoyaltyAchievement> _achievements = [];
  List<LeaderboardEntry> _leaderboard = [];
  bool _isInitialized = false;
  String? _errorMessage;

  LoyaltyProvider(this._loyaltyService) {
    // Initialize the service immediately
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _loyaltyService.initialize();
      debugPrint('Loyalty service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing loyalty service: $e');
      _errorMessage = 'Failed to initialize loyalty service';
    } finally {
      // Always set initialized to true to prevent infinite loading
      _isInitialized = true;
    }
  }

  // Current user loyalty profile management
  Future<void> initializeForUser(String userId) async {
    if (_currentUserId == userId) return; // Already initialized

    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      _currentProfile = await _loyaltyService.getLoyaltyProfile(userId);
      _pointsHistory = _loyaltyService.getPointsHistory(userId);
      await _refreshRewardsCatalog();
      await _refreshAchievements();
      await _refreshLeaderboard();
    } catch (e) {
      debugPrint('Error initializing loyalty for user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    if (_currentUserId == null) return;

    try {
      _currentProfile = await _loyaltyService.getLoyaltyProfile(_currentUserId!);
      _pointsHistory = _loyaltyService.getPointsHistory(_currentUserId!);
      await _refreshRewardsCatalog();
      await _refreshAchievements();
      await _refreshLeaderboard();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing loyalty data: $e');
    }
  }

  // Getters
  String? get currentUserId => _currentUserId;
  LoyaltyProfile? get currentProfile => _currentProfile;
  bool get isLoading => !_isInitialized || _isLoading; // Only loading if not initialized OR during specific operations
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  List<Reward> get rewardsCatalog => _rewardsCatalog;
  List<LoyaltyPoints> get pointsHistory => _pointsHistory;
  List<LoyaltyAchievement> get achievements => _achievements;
  List<LeaderboardEntry> get leaderboard => _leaderboard;

  // Computed properties for current user
  int get currentPoints => _currentProfile?.availablePoints ?? 0;
  int get totalPoints => _currentProfile?.totalPoints ?? 0;
  LoyaltyTier get currentTier => _currentProfile?.currentTier ?? LoyaltyTier.bronze;
  double get discountPercentage => _currentProfile?.discountPercentage ?? 0.0;
  int get completedReferrals => _currentProfile?.getCompletedReferrals() ?? 0;
  int get pendingReferrals => _currentProfile?.getPendingReferrals() ?? 0;
  Map<String, dynamic> get preferences => _currentProfile?.preferences ?? {};

  // Points and rewards management
  Future<PointsResult> awardPoints({
    required String activityType,
    String? referenceId,
    String? description,
    Map<String, dynamic> context = const {},
  }) async {
    if (_currentUserId == null) {
      return PointsResult.error('No user initialized');
    }

    final result = await _loyaltyService.awardPoints(
      userId: _currentUserId!,
      activityType: activityType,
      referenceId: referenceId,
      description: description,
      context: context,
    );

    if (result.success) {
      await refreshData(); // Refresh all data after awarding points
    }

    return result;
  }

  Future<RewardResult> redeemReward(String rewardId) async {
    if (_currentUserId == null) {
      return RewardResult.error('No user initialized');
    }

    final result = await _loyaltyService.redeemReward(_currentUserId!, rewardId);

    if (result.success) {
      await refreshData(); // Refresh all data after redemption
    }

    return result;
  }

  // Referral management
  Future<ReferralResult> createReferral(String referralCode) async {
    if (_currentUserId == null) {
      return ReferralResult.error('No user initialized');
    }

    final result = await _loyaltyService.createReferral(_currentUserId!, referralCode);

    if (result.success) {
      await refreshData(); // Refresh data after creating referral
    }

    return result;
  }

  Future<bool> completeReferral(String referralId, String referredUserId) async {
    final result = await _loyaltyService.completeReferral(referralId, referredUserId);

    if (result) {
      await refreshData(); // Refresh data after completing referral
    }

    return result;
  }

  // Data refresh methods
  Future<void> _refreshRewardsCatalog() async {
    _rewardsCatalog = _loyaltyService.rewardsCatalog;
  }

  Future<void> _refreshAchievements() async {
    _achievements = _loyaltyService.achievements;
  }

  Future<void> _refreshLeaderboard() async {
    _leaderboard = _loyaltyService.getLeaderboard();
  }

  // Preferences management
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    if (_currentProfile == null) return;

    _currentProfile = _currentProfile!.copyWith(
      preferences: preferences,
    );
    notifyListeners();

    // In a real implementation, save to service
  }

  // Utility methods
  List<Reward> getAvailableRewards() {
    return _rewardsCatalog.where((reward) => reward.isAvailable).toList();
  }

  List<LoyaltyPoints> getPointsHistoryForPeriod(DateTime startDate, DateTime endDate) {
    return _pointsHistory.where((point) =>
      point.createdAt.isAfter(startDate) && point.createdAt.isBefore(endDate)
    ).toList();
  }

  List<LoyaltyAchievement> getUnlockedAchievements() {
    return _achievements.where((achievement) => achievement.isUnlocked).toList();
  }

  List<LoyaltyAchievement> getHiddenAchievements() {
    return _achievements.where((achievement) => achievement.isHidden).toList();
  }

  bool canAffordReward(String rewardId) {
    final reward = _rewardsCatalog.firstWhere(
      (r) => r.id == rewardId,
      orElse: () => Reward(
        id: '',
        title: '',
        description: '',
        imageUrl: '',
        pointsCost: 0,
        type: RewardType.service,
        createdAt: DateTime.now(),
      ),
    );

    return reward.id.isNotEmpty && currentPoints >= reward.pointsCost;
  }

  // Clear user data (for logout)
  void clearUserData() {
    _currentUserId = null;
    _currentProfile = null;
    _pointsHistory = [];
    _isLoading = false;
    notifyListeners();
  }

  // Setter for provider chain
  set loyaltyService(LoyaltyService service) {
    _loyaltyService = service;
  }

  // Demo data for testing
  Future<void> loadDemoData() async {
    if (_currentUserId == null) return;

    await awardPoints(
      activityType: 'appointment',
      description: 'Demo appointment completion',
    );

    await awardPoints(
      activityType: 'photo_estimate',
      description: 'Demo photo estimate',
    );

    await refreshData();
  }

  // Points balance calculations
  int get earnedPointsThisMonth {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _pointsHistory
        .where((point) =>
            point.type == TransactionType.earned &&
            point.createdAt.isAfter(startOfMonth))
        .fold(0, (sum, point) => sum + point.points);
  }

  int get redeemedPointsThisMonth {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _pointsHistory
        .where((point) =>
            point.type == TransactionType.redeemed &&
            point.createdAt.isAfter(startOfMonth))
        .fold(0, (sum, point) => sum + point.points.abs()); // Absolute value since redeemed are negative
  }

  // Tier progress calculations
  double get tierProgressPercentage {
    if (_currentProfile == null) return 0.0;

    final nextTier = _currentProfile!.getNextTier();
    if (nextTier == _currentProfile!.currentTier) return 1.0; // Max tier

    final pointsToNext = _currentProfile!.pointsToNextTier;
    final totalPointsToNext = nextTier.pointsRequired - _currentProfile!.currentTier.pointsRequired;

    return (totalPointsToNext - pointsToNext) / totalPointsToNext;
  }

  String get tierProgressText {
    if (_currentProfile == null) return '';

    final nextTier = _currentProfile!.getNextTier();
    if (nextTier == _currentProfile!.currentTier) {
      return 'Max tier reached!';
    }

    return '${_currentProfile!.pointsToNextTier} points to ${nextTier.title}';
  }
}

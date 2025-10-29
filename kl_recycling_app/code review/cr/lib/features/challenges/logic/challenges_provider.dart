import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kl_recycling_app/features/challenges/models/challenges.dart';
import 'package:kl_recycling_app/features/challenges/logic/challenges_service.dart';

import 'package:kl_recycling_app/features/gamification/models/gamification.dart' as gamification;
import 'package:kl_recycling_app/features/notifications/logic/notification_service.dart';

class ChallengesProvider with ChangeNotifier {
  final ChallengesService _challengesService;


  // State
  List<Challenge> _challenges = [];
  ChallengeProgress? _currentProgress;
  List<ChallengeProgress> _userProgress = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Demo user ID (in a real app, this would come from auth)
  final String _currentUserId = 'demo_user_001';

  // Stream subscriptions
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _challengesSubscription;
  StreamSubscription<ChallengeProgress?>? _progressSubscription;

  ChallengesProvider()
      : _challengesService = ChallengesService() {
    _initializeStreams();
  }

  // Getters
  List<Challenge> get challenges => _challenges;
  ChallengeProgress? get currentProgress => _currentProgress;
  List<ChallengeProgress> get userProgress => _userProgress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filter state
  ChallengesFilter _currentFilter = ChallengesFilter.all;
  ChallengesFilter get currentFilter => _currentFilter;

  List<Challenge> get filteredChallengesList {
    switch (_currentFilter) {
      case ChallengesFilter.all:
        return _challenges;
      case ChallengesFilter.active:
        return _challenges.where((c) => c.status == ChallengeStatus.active).toList();
      case ChallengesFilter.completed:
        return _challenges.where((c) => c.status == ChallengeStatus.completed).toList();
      case ChallengesFilter.upcoming:
        return _challenges.where((c) => c.status == ChallengeStatus.upcoming).toList();
      default:
        return _challenges;
    }
  }

  void setFilter(ChallengesFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  // Getters for filtered challenges
  List<Challenge> get dailyChallenges =>
      _challenges.where((c) => c.type == ChallengeType.daily && c.status == ChallengeStatus.active).toList();

  List<Challenge> get weeklyChallenges =>
      _challenges.where((c) => c.type == ChallengeType.weekly && c.status == ChallengeStatus.active).toList();

  List<Challenge> get monthlyChallenges =>
      _challenges.where((c) => c.type == ChallengeType.monthly && c.status == ChallengeStatus.active).toList();

  List<Challenge> get popularChallenges =>
      _challenges.where((c) => c.isPopular || c.participantCount > 100).toList();

  // Computed properties
  int get activeChallengeCount => _challenges.where((c) => c.status == ChallengeStatus.active).length;
  int get userJoinedCount => _userProgress.length;

  bool isJoined(String challengeId) {
    return _userProgress.any((progress) => progress.challengeId == challengeId);
  }

  ChallengeProgress? getProgress(String challengeId) {
    return _userProgress.cast<ChallengeProgress?>().firstWhere(
          (progress) => progress?.challengeId == challengeId,
          orElse: () => null,
        );
  }

  // Initialization
  void _initializeStreams() {
    _challengesSubscription = _challengesService.subscribeToChallenges() as StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?;
    _challengesSubscription?.onData((snapshot) {
      final challenges = snapshot.docs
          .map((doc) => doc.data())
          .map((data) => Challenge.fromMap(data))
          .toList();
      _challenges = challenges;
      notifyListeners();
    });

    _progressSubscription = _challengesService.progressStream.listen((progress) {
      _currentProgress = progress;
      notifyListeners();
    });
  }

  // Load initial data
  Future<void> initialize() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Initialize default challenges if needed
      await _challengesService.initializeDefaultChallenges();

      // Load active challenges
      _challenges = await _challengesService.getActiveChallenges();

      // Load user progress
      _userProgress = await _challengesService.getUserProgress(_currentUserId);

      // Check for expired challenges
      await _challengesService.checkExpiredChallenges();

      // Schedule initial notifications
      await _scheduleChallengeNotifications();

    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Join a challenge
  Future<void> joinChallenge(String challengeId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final progress = await _challengesService.joinChallenge(_currentUserId, challengeId);
      _userProgress.add(progress);

      // Reload challenges to get updated participant count
      await loadChallenges();

      // Schedule notifications for this challenge
      await _scheduleChallengeNotification(challengeId);

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update progress from recycling activity
  Future<void> updateProgressFromRecycle(gamification.RecycledItem recycledItem) async {
    try {
      await _challengesService.updateProgressFromRecycle(_currentUserId, recycledItem);

      // Refresh user progress
      _userProgress = await _challengesService.getUserProgress(_currentUserId);

      // Check for achievements and send notifications
      await _checkForAchievements();

      notifyListeners();
    } catch (e) {
      // Log error but don't throw - this is background activity
      debugPrint('Error updating challenge progress: $e');
    }
  }

  // Load challenges (force refresh)
  Future<void> loadChallenges() async {
    _setLoading(true);
    try {
      _challenges = await _challengesService.getActiveChallenges();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      return await _challengesService.getUserChallengeStats(_currentUserId);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  // Get leaderboard for a challenge
  Future<ChallengeLeaderboard> getLeaderboard(String challengeId) async {
    try {
      return await _challengesService.getChallengeLeaderboard(challengeId);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  // Cleanup old challenges
  Future<int> cleanupOldChallenges({int daysOld = 30}) async {
    try {
      return await _challengesService.cleanupOldChallenges(_currentUserId, daysOld);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  // Check for achievements and send notifications
  Future<void> _checkForAchievements() async {
    try {
      final userStats = await getUserStats();

      // Check for milestone achievements
      final completedChallenges = userStats['completedChallenges'] as int? ?? 0;

      // Send achievement notifications
      if (completedChallenges > 0) {
        final challenge = _challenges.firstWhere(
          (c) => c.rewardPoints > 0,
          orElse: () => _challenges.isNotEmpty ? _challenges.first : Challenge(
            id: '', title: 'Challenge', description: '', type: ChallengeType.daily,
            difficulty: ChallengeDifficulty.easy,
            participationType: ChallengeParticipationType.individual,
            status: ChallengeStatus.active, startDate: DateTime.now(), endDate: DateTime.now().add(const Duration(days: 1)),
            targetValue: 1, metric: 'items', rewardPoints: 25, createdAt: DateTime.now(),
          ),
        );

        if (completedChallenges == 1) {
          await NotificationService.sendAchievementNotification(
            achievementTitle: 'First Challenge Completed!',
            description: 'You completed your first recycling challenge. Keep it up!',
          );
        } else if (completedChallenges == 5) {
          await NotificationService.sendAchievementNotification(
            achievementTitle: 'Challenge Master!',
            description: 'Completed 5 challenges! You\'re on fire!',
          );
        } else if (completedChallenges % 10 == 0) {
          await NotificationService.sendAchievementNotification(
            achievementTitle: 'Legendary Challenger!',
            description: 'Completed $completedChallenges challenges! You\'re a recycling legend!',
          );
        }
      }

      // Send milestone notifications for progress
      for (final progress in _userProgress) {
        final challenge = _challenges.firstWhere(
          (c) => c.id == progress.challengeId,
          orElse: () => Challenge(
            id: '', title: '', description: '', type: ChallengeType.daily,
            difficulty: ChallengeDifficulty.easy,
            participationType: ChallengeParticipationType.individual,
            status: ChallengeStatus.active, startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 1)),
            targetValue: 100, metric: 'items', rewardPoints: 25, createdAt: DateTime.now(),
          ),
        );

        final percentage = challenge.progressPercentage;

        // Notify at 50% and 90%
        if (percentage >= 0.5 && !progress.notifiedHalfway && !progress.notifiedCompleted) {
          await NotificationService.sendMilestoneNotification(
            milestoneType: 'progress',
            value: 50,
            unit: '% complete',
          );
          // In a real app, you'd update the progress notifiedHalfway field
        } else if (percentage >= 0.9 && !progress.notifiedCompleted) {
          await NotificationService.sendMilestoneNotification(
            milestoneType: 'progress',
            value: 90,
            unit: '% complete - almost there!',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for achievements: $e');
    }
  }

  // Schedule notifications for challenges
  Future<void> _scheduleChallengeNotifications() async {
    for (final progress in _userProgress) {
      await _scheduleChallengeNotification(progress.challengeId);
    }
  }

  Future<void> _scheduleChallengeNotification(String challengeId) async {
    try {
      final challenge = _challenges.firstWhere((c) => c.id == challengeId);
      final progress = getProgress(challengeId);

      if (challenge.type == ChallengeType.daily && progress != null) {
        // Schedule reminder if daily challenge is less than 50% complete
        if (challenge.progressPercentage < 0.5) {
          await NotificationService.scheduleDailyReminder(
            time: const TimeOfDay(hour: 19, minute: 0), // 7 PM
          );
        }
      }

      if (challenge.type == ChallengeType.weekly) {
        final daysLeft = challenge.timeRemaining?.inDays ?? 0;
        if (daysLeft <= 1 && challenge.progressPercentage < 0.7) {
          // Send urgent reminder for weekly challenges
          await NotificationService.sendEcoTip(); // Could be challenge reminder
        }
      }
    } catch (e) {
      debugPrint('Error scheduling challenge notification: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get challenge by ID
  Challenge? getChallengeById(String challengeId) {
    try {
      return _challenges.firstWhere((challenge) => challenge.id == challengeId);
    } catch (e) {
      return null;
    }
  }

  // Get recommended challenges for user
  List<Challenge> getRecommendedChallenges() {
    final completedIds = _userProgress
        .where((p) => p.currentValue >= 100) // Simplified completion check
        .map((p) => p.challengeId)
        .toSet();

    final uncompletedChallenges = _challenges
        .where((c) => !completedIds.contains(c.id) && c.status == ChallengeStatus.active)
        .toList();

    // Sort by: popular first, then by participant count
    uncompletedChallenges.sort((a, b) {
      if (a.isPopular && !b.isPopular) return -1;
      if (!a.isPopular && b.isPopular) return 1;
      return b.participantCount.compareTo(a.participantCount);
    });

    return uncompletedChallenges.take(5).toList();
  }

  // Get user's challenge completion rate
  double getCompletionRate() {
    if (_userProgress.isEmpty) return 0.0;
    final completedCount = _userProgress.where((p) => p.currentValue >= 100).length;
    return completedCount / _userProgress.length;
  }

  // Simulate demo data for development
  Future<void> loadDemoData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Join some challenges
      const demoChallengeIds = ['daily_recycle_basic', 'weekly_aluminum_master'];
      for (final challengeId in demoChallengeIds) {
        try {
          await joinChallenge(challengeId);
        } catch (e) {
          // Challenge might not exist yet
        }
      }

      // Simulate some progress
      final fakeItem1 = gamification.RecycledItem(
        id: 'demo_1',
        materialType: 'aluminum',
        weight: 5.5,
        recycledDate: DateTime.now(),
        points: 25,
      );

      final fakeItem2 = gamification.RecycledItem(
        id: 'demo_2',
        materialType: 'plastic',
        weight: 2.0,
        recycledDate: DateTime.now(),
        points: 10,
      );

      await updateProgressFromRecycle(fakeItem1);
      await updateProgressFromRecycle(fakeItem2);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _challengesSubscription?.cancel();
    _progressSubscription?.cancel();
    _challengesService.dispose();
    super.dispose();
  }
}

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kl_recycling_app/core/services/firebase_service.dart';
import 'package:kl_recycling_app/features/challenges/logic/challenges_service.dart';
import 'package:kl_recycling_app/features/social/models/social_models.dart';

/// Social Service - Core engine for all Phase 4 social features
class SocialService {
  static const String _userProfilesCollection = 'user_profiles';
  static const String _activityFeedCollection = 'activity_feed';
  static const String _leaderboardsCollection = 'leaderboards';
  static const String _streaksCollection = 'recycling_streaks';
  static const String _referralsCollection = 'referrals';

  final FirebaseService _firebaseService;
  final ChallengesService _challengesService;

  final StreamController<ActivityFeedItem> _activityStreamController = StreamController<ActivityFeedItem>.broadcast();

  SocialService(this._firebaseService, this._challengesService) {
    _initializeListeners();
  }

  /// Initialize real-time listeners for social features
  void _initializeListeners() {
    // Listen to activity feed updates
    _firebaseService.firestore
        .collection(_activityFeedCollection)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final activity = ActivityFeedItem.fromMap(change.doc.data()!);
              _activityStreamController.add(activity);
            }
          }
        });
  }

  Stream<ActivityFeedItem> get activityFeed => _activityStreamController.stream;

  // ============ USER PROFILE MANAGEMENT ============

  /// Create or update user social profile
  Future<void> createOrUpdateProfile(UserProfile profile) async {
    final profileData = profile.toMap();
    profileData['lastActive'] = FieldValue.serverTimestamp();

    await _firebaseService.firestore
        .collection(_userProfilesCollection)
        .doc(profile.id)
        .set(profileData, SetOptions(merge: true));
  }

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _firebaseService.firestore
        .collection(_userProfilesCollection)
        .doc(userId)
        .get();

    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  /// Update user gamification stats
  Future<void> updateUserStats(String userId, Map<String, dynamic> statsUpdate) async {
    await _firebaseService.firestore
        .collection(_userProfilesCollection)
        .doc(userId)
        .update({
          'gamificationStats': statsUpdate,
          'lastActive': FieldValue.serverTimestamp(),
        });
  }

  // ============ ACTIVITY FEED MANAGEMENT ============

  /// Post activity to the public feed
  Future<void> postActivity(ActivityFeedItem activity) async {
    final activityData = activity.toMap();
    activityData['timestamp'] = FieldValue.serverTimestamp();

    await _firebaseService.firestore
        .collection(_activityFeedCollection)
        .doc(activity.id)
        .set(activityData);
  }

  /// Get user's activity feed
  Future<List<ActivityFeedItem>> getUserActivity(String userId, {int limit = 20}) async {
    final querySnapshot = await _firebaseService.firestore
        .collection(_activityFeedCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs
        .map((doc) => ActivityFeedItem.fromMap(doc.data()))
        .toList();
  }

  /// Like/unlike activity
  Future<void> toggleLike(String activityId, String userId) async {
    final activityRef = _firebaseService.firestore
        .collection(_activityFeedCollection)
        .doc(activityId);

    final doc = await activityRef.get();
    if (!doc.exists) return;

    final activity = ActivityFeedItem.fromMap(doc.data()!);
    final likes = List<String>.from(activity.likesBy);

    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }

    await activityRef.update({'likes': likes.length, 'likesBy': likes});
  }

  /// Add comment to activity
  Future<void> addComment(String activityId, ActivityComment comment) async {
    final commentData = comment.toMap();
    commentData['timestamp'] = FieldValue.serverTimestamp();

    await _firebaseService.firestore
        .collection(_activityFeedCollection)
        .doc(activityId)
        .collection('comments')
        .doc(comment.id)
        .set(commentData);
  }

  // ============ LEADERBOARD MANAGEMENT ============

  /// Update leaderboards with user's latest progress
  Future<void> updateLeaderboards(String userId, String userName,
      Map<String, dynamic> scores, String region) async {

    final batch = _firebaseService.firestore.batch();

    // Update global leaderboard
    final globalRef = _firebaseService.firestore
        .collection(_leaderboardsCollection)
        .doc('global');

    for (final entry in scores.entries) {
      final leaderboardRef = globalRef.collection(entry.key).doc('ranking');

      await _updateLeaderboardPosition(leaderboardRef, userId, userName,
          entry.value as int, region);
    }

    await batch.commit();
  }

  /// Get enhanced leaderboard for specific type
  Future<EnhancedLeaderboard> getLeaderboard(LeaderboardType type, {String? region}) async {
    final leaderboardId = type == LeaderboardType.global ? 'global' :
        type == LeaderboardType.regional ? 'regional_${region ?? 'default'}' :
        '${type.name}_${region ?? 'all'}';

    final doc = await _firebaseService.firestore
        .collection(_leaderboardsCollection)
        .doc(leaderboardId)
        .get();

    if (!doc.exists) {
      return EnhancedLeaderboard(
        id: leaderboardId,
        type: type,
        lastUpdated: DateTime.now(),
      );
    }

    final data = doc.data()!;
    final globalRankings = (data['globalRankings'] as List<dynamic>?)
        ?.map((e) => LeaderboardEntry.fromMap(e))
        .toList() ?? [];

    final regionalRankings = (data['regionalRankings'] as Map<String, dynamic>?)
        ?.map((key, value) => MapEntry(key,
            (value as List<dynamic>).map((e) => LeaderboardEntry.fromMap(e)).toList()))
        ?? {};

    return EnhancedLeaderboard(
      id: leaderboardId,
      type: type,
      globalRankings: globalRankings,
      regionalRankings: regionalRankings,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      totalParticipants: data['totalParticipants'] ?? 0,
    );
  }

  Future<void> _updateLeaderboardPosition(
      DocumentReference ref, String userId, String userName, int score, String region) async {

    final doc = await ref.get();
    List<LeaderboardEntry> currentRankings = [];

    if (doc.exists) {
      final docData = doc.data() as Map<String, dynamic>;
      currentRankings = (docData['rankings'] as List<dynamic>?)
          ?.map((e) => LeaderboardEntry.fromMap(e))
          .toList() ?? [];
    }

    // Remove existing entry if present
    currentRankings.removeWhere((entry) => entry.userId == userId);

    // Add/update new entry
    currentRankings.add(LeaderboardEntry(
      userId: userId,
      userName: userName,
      score: score,
      rank: 0, // Will be calculated below
    ));

    // Sort by score (highest first) and assign ranks
    currentRankings.sort((a, b) => b.score.compareTo(a.score));
    for (int i = 0; i < currentRankings.length; i++) {
      currentRankings[i] = LeaderboardEntry(
        userId: currentRankings[i].userId,
        userName: currentRankings[i].userName,
        userAvatar: currentRankings[i].userAvatar,
        score: currentRankings[i].score,
        rank: i + 1,
      );
    }

    // Keep only top 100
    if (currentRankings.length > 100) {
      currentRankings = currentRankings.sublist(0, 100);
    }

    await ref.set({
      'rankings': currentRankings.map((e) => e.toMap()).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // ============ STREAK TRACKING SYSTEM ============

  /// Update user recycling streak
  Future<void> updateRecyclingStreak(String userId, DateTime activityDate) async {
    final streakRef = _firebaseService.firestore
        .collection(_streaksCollection)
        .doc(userId);

    final doc = await streakRef.get();
    RecyclingStreak currentStreak;

    if (!doc.exists) {
      // Create new streak
      currentStreak = RecyclingStreak(
        userId: userId,
        lastActivityDate: activityDate,
        activityDates: [activityDate],
      );
    } else {
      currentStreak = RecyclingStreak.fromMap(doc.data()!);
    }

    // Update streak logic
    final today = DateTime(activityDate.year, activityDate.month, activityDate.day);
    final lastActivity = DateTime(
      currentStreak.lastActivityDate.year,
      currentStreak.lastActivityDate.month,
      currentStreak.lastActivityDate.day,
    );

    final daysDiff = today.difference(lastActivity).inDays;

    if (daysDiff == 1) {
      // Consecutive day - increment streak
      currentStreak = RecyclingStreak(
        userId: currentStreak.userId,
        currentStreak: currentStreak.currentStreak + 1,
        longestStreak: max(currentStreak.longestStreak, currentStreak.currentStreak + 1),
        lastActivityDate: activityDate,
        activityDates: [...currentStreak.activityDates, activityDate].take(30).toList(),
        materialStreaks: currentStreak.materialStreaks,
        streakMultiplier: currentStreak.streakMultiplier,
        milestones: currentStreak.milestones,
      );
    } else if (daysDiff == 0) {
      // Same day - no change
      return;
    } else {
      // Streak broken - reset to 1
      currentStreak = RecyclingStreak(
        userId: currentStreak.userId,
        currentStreak: 1,
        longestStreak: currentStreak.longestStreak,
        lastActivityDate: activityDate,
        activityDates: [activityDate],
        materialStreaks: currentStreak.materialStreaks,
        streakMultiplier: 1,
        milestones: currentStreak.milestones,
      );
    }

    // Check for milestone achievements
    await _checkStreakMilestones(userId, currentStreak);

    await streakRef.set(currentStreak.toMap());
  }

  /// Get user's recycling streak
  Future<RecyclingStreak?> getUserStreak(String userId) async {
    final doc = await _firebaseService.firestore
        .collection(_streaksCollection)
        .doc(userId)
        .get();

    if (!doc.exists) return null;
    return RecyclingStreak.fromMap(doc.data()!);
  }

  Future<void> _checkStreakMilestones(String userId, RecyclingStreak streak) async {
    final defaultMilestones = [
      StreakMilestone(streakCount: 7, title: 'Week Warrior', description: '7 days straight!', rewardPoints: 50),
      StreakMilestone(streakCount: 14, title: 'Fortnite Champion', description: '14 day streak!', rewardPoints: 100),
      StreakMilestone(streakCount: 30, title: 'Month Master', description: '30 days of consistency!', rewardPoints: 250),
      StreakMilestone(streakCount: 60, title: 'Streak Legend', description: '60 days straight!', rewardPoints: 500),
    ];

    for (final milestone in defaultMilestones) {
      if (streak.currentStreak >= milestone.streakCount &&
          !streak.milestones.any((m) => m.streakCount == milestone.streakCount && m.isAchieved)) {

        // Award milestone
        final updatedMilestones = [...streak.milestones];
        updatedMilestones.add(StreakMilestone(
          streakCount: milestone.streakCount,
          title: milestone.title,
          description: milestone.description,
          isAchieved: true,
          achievedAt: DateTime.now(),
          rewardPoints: milestone.rewardPoints,
        ));

        streak = RecyclingStreak(
          userId: streak.userId,
          currentStreak: streak.currentStreak,
          longestStreak: streak.longestStreak,
          lastActivityDate: streak.lastActivityDate,
          activityDates: streak.activityDates,
          materialStreaks: streak.materialStreaks,
          streakMultiplier: streak.streakMultiplier,
          milestones: updatedMilestones,
        );

        // Post to activity feed
        await postActivity(ActivityFeedItem(
          id: 'streak_${userId}_${milestone.streakCount}_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          userName: 'User', // Would get from profile
          type: ActivityType.streak,
          title: '🔥 ${milestone.title}',
          description: milestone.description,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  // ============ REFERRAL SYSTEM ============

  /// Generate or get referral code for user
  Future<String> getOrCreateReferralCode(String userId, String userName) async {
    final referralRef = _firebaseService.firestore
        .collection(_referralsCollection)
        .doc(userId);

    final doc = await referralRef.get();

    if (doc.exists) {
      final referral = ReferralProgram.fromMap(doc.data()!);
      return referral.referralCode;
    }

    // Generate unique referral code
    final code = _generateReferralCode(userName);

    final referral = ReferralProgram(
      referralCode: code,
      referrerId: userId,
      referrerName: userName,
      createdAt: DateTime.now(),
      lastUsed: DateTime.now(),
    );

    await referralRef.set(referral.toMap());
    return code;
  }

  /// Process referral signup
  Future<void> processReferralSignup(String referralCode, String newUserId) async {
    final referralQuery = await _firebaseService.firestore
        .collection(_referralsCollection)
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    if (referralQuery.docs.isNotEmpty) {
      final doc = referralQuery.docs.first;
      final referral = ReferralProgram.fromMap(doc.data());

      // Update referral with new user
      final updatedUsers = [...referral.referredUsers, newUserId];
      final updatedReferral = ReferralProgram(
        referralCode: referral.referralCode,
        referrerId: referral.referrerId,
        referrerName: referral.referrerName,
        referredUsers: updatedUsers,
        totalReferrals: updatedUsers.length,
        successfulReferrals: updatedUsers.length,
        totalBonusEarned: (updatedUsers.length * 25), // 25 points per referral
        rewards: referral.rewards,
        createdAt: referral.createdAt,
        lastUsed: DateTime.now(),
        isActive: referral.isActive,
      );

      await doc.reference.update(updatedReferral.toMap());
    }
  }

  String _generateReferralCode(String userName) {
    final cleanName = userName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final randomSuffix = Random().nextInt(9999).toString().padLeft(4, '0');
    return '${cleanName}_$randomSuffix'.substring(0, 15); // Keep it short
  }

  // ============ SOCIAL SHARING ============

  /// Share achievement or milestone to external platforms
  Future<void> shareContent(ShareableContent content) async {
    await Share.share(
      '${content.title}\n\n${content.description}\n\n#RecycleApp #Sustainable',
      subject: 'Recycling Achievement',
    );
  }

  /// Generate shareable content from user achievement
  ShareableContent createShareableContent(String userName, String achievementType, {
    int? streakCount,
    int? challengePoints,
    String? challengeName,
  }) {
    switch (achievementType) {
      case 'streak':
        return ShareableContent(
          id: 'share_streak_${DateTime.now().millisecondsSinceEpoch}',
          type: 'streak',
          title: '🔥 $streakCount-Day Recycling Streak! 💪',
          description: '$userName has maintained a $streakCount-day recycling streak! Who else can beat this?',
          hashtags: ['RecyclingStreak', 'SustainableLiving', 'GreenLiving'],
          createdAt: DateTime.now(),
          metadata: {'streakCount': streakCount, 'userName': userName},
        );

      case 'challenge_complete':
        return ShareableContent(
          id: 'share_challenge_${DateTime.now().millisecondsSinceEpoch}',
          type: 'challenge',
          title: '🏆 Challenge Complete! 🎯',
          description: '$userName just completed "$challengeName" and earned $challengePoints points!',
          hashtags: ['ChallengeComplete', 'RecyclingChampion', 'Sustainability'],
          createdAt: DateTime.now(),
          metadata: {'challengeName': challengeName, 'points': challengePoints},
        );

      default:
        return ShareableContent(
          id: 'share_general_${DateTime.now().millisecondsSinceEpoch}',
          type: 'achievement',
          title: '🌱 Recycling Achievement! 🌍',
          description: '$userName is making a difference through recycling!',
          hashtags: ['Recycling', 'Sustainability', 'GreenLiving'],
          createdAt: DateTime.now(),
          metadata: {'userName': userName},
        );
    }
  }

  // ============ SOCIAL UTILITIES ============

  /// Get leaderboard rank for specific user and type
  Future<int?> getUserRank(String userId, LeaderboardType type, {String? region}) async {
    final leaderboard = await getLeaderboard(type, region: region);

    if (type == LeaderboardType.global) {
      final entry = leaderboard.globalRankings.firstWhere(
        (entry) => entry.userId == userId,
        orElse: () => LeaderboardEntry(userId: userId, userName: '', score: 0, rank: 0),
      );
      return entry.rank > 0 ? entry.rank : null;
    }

    if (region != null && leaderboard.regionalRankings.containsKey(region)) {
      final regionalEntries = leaderboard.regionalRankings[region]!;
      final entry = regionalEntries.firstWhere(
        (entry) => entry.userId == userId,
        orElse: () => LeaderboardEntry(userId: userId, userName: '', score: 0, rank: 0),
      );
      return entry.rank > 0 ? entry.rank : null;
    }

    return null;
  }

  /// Get social stats for user dashboard
  Future<Map<String, int>> getSocialStats(String userId) async {
    final results = await Future.wait([
      getUserStreak(userId),
      getUserActivity(userId, limit: 1000), // Get all activity for counts
    ]);

    final streak = results[0] as RecyclingStreak?;
    final activities = results[1] as List<ActivityFeedItem>;

    final totalLikes = activities.fold<int>(0, (total, activity) => total + activity.likes);
    final totalComments = activities.fold<int>(0, (total, activity) => total + activity.comments);

    return {
      'currentStreak': streak?.currentStreak ?? 0,
      'longestStreak': streak?.longestStreak ?? 0,
      'totalActivities': activities.length,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
    };
  }

  /// Cleanup old activity feed items (older than 90 days)
  Future<void> cleanupOldActivities() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

    final oldActivities = await _firebaseService.firestore
        .collection(_activityFeedCollection)
        .where('timestamp', isLessThan: cutoffTimestamp)
        .get();

    final batch = _firebaseService.firestore.batch();
    for (final doc in oldActivities.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Dispose resources
  void dispose() {
    _activityStreamController.close();
  }
}

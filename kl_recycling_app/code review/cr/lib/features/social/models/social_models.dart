import 'package:cloud_firestore/cloud_firestore.dart';

/// Social Models - Core data structures for Phase 4 social features

/// User Profile for social features and gamification
class UserProfile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final int totalPointsEarned;
  final int currentLevel;
  final int experiencePoints;
  final Map<String, dynamic> gamificationStats;
  final bool isOnline;
  final DateTime lastActive;
  final List<String> achievements;
  final List<String> completedChallenges;
  final Map<String, dynamic> preferences;

  UserProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.totalPointsEarned = 0,
    this.currentLevel = 1,
    this.experiencePoints = 0,
    required this.gamificationStats,
    this.isOnline = false,
    required this.lastActive,
    this.achievements = const [],
    this.completedChallenges = const [],
    this.preferences = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'totalPointsEarned': totalPointsEarned,
      'currentLevel': currentLevel,
      'experiencePoints': experiencePoints,
      'gamificationStats': gamificationStats,
      'isOnline': isOnline,
      'lastActive': Timestamp.fromDate(lastActive),
      'achievements': achievements,
      'completedChallenges': completedChallenges,
      'preferences': preferences,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '',
      avatarUrl: map['avatarUrl'],
      bio: map['bio'],
      totalPointsEarned: map['totalPointsEarned'] ?? 0,
      currentLevel: map['currentLevel'] ?? 1,
      experiencePoints: map['experiencePoints'] ?? 0,
      gamificationStats: map['gamificationStats'] ?? {},
      isOnline: map['isOnline'] ?? false,
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      achievements: List<String>.from(map['achievements'] ?? []),
      completedChallenges: List<String>.from(map['completedChallenges'] ?? []),
      preferences: map['preferences'] ?? {},
    );
  }
}

/// Activity Feed Item for social interactions
class ActivityFeedItem {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final ActivityType type;
  final String title;
  final String description;
  final String? imageUrl;
  final int likes;
  final List<String> likesBy;
  final int comments;
  final List<String> commentsBy;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final bool isPublic;
  final String? challengeId;

  ActivityFeedItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar = '',
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
    this.likes = 0,
    this.likesBy = const [],
    this.comments = 0,
    this.commentsBy = const [],
    required this.timestamp,
    this.metadata = const {},
    this.isPublic = true,
    this.challengeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'type': type.name,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'likes': likes,
      'likesBy': likesBy,
      'comments': comments,
      'commentsBy': commentsBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'isPublic': isPublic,
      'challengeId': challengeId,
    };
  }

  factory ActivityFeedItem.fromMap(Map<String, dynamic> map) {
    return ActivityFeedItem(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'] ?? '',
      type: _activityTypeFromString(map['type'] ?? 'achievement'),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      likes: map['likes'] ?? 0,
      likesBy: List<String>.from(map['likesBy'] ?? []),
      comments: map['comments'] ?? 0,
      commentsBy: List<String>.from(map['commentsBy'] ?? []),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'] ?? {},
      isPublic: map['isPublic'] ?? true,
      challengeId: map['challengeId'],
    );
  }

  static ActivityType _activityTypeFromString(String typeString) {
    switch (typeString) {
      case 'achievement': return ActivityType.achievement;
      case 'challenge_complete': return ActivityType.challenge_complete;
      case 'recycling': return ActivityType.recycling;
      case 'level_up': return ActivityType.level_up;
      case 'streak': return ActivityType.streak;
      default: return ActivityType.achievement;
    }
  }
}

/// Activity Type enumeration
enum ActivityType {
  achievement,
  challenge_complete,
  recycling,
  level_up,
  streak,
}

/// Activity Comment for discussions
class ActivityComment {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime timestamp;
  final List<String> likes;
  final List<String> replies;

  ActivityComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.timestamp,
    this.likes = const [],
    this.replies = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'replies': replies,
    };
  }

  factory ActivityComment.fromMap(Map<String, dynamic> map) {
    return ActivityComment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(map['likes'] ?? []),
      replies: List<String>.from(map['replies'] ?? []),
    );
  }
}

/// Leaderboard Entry for rankings
class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? userAvatar;
  final int score;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.score,
    required this.rank,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'score': score,
      'rank': rank,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'],
      score: map['score'] ?? 0,
      rank: map['rank'] ?? 0,
    );
  }
}

/// Enhanced Leaderboard with regional support
class EnhancedLeaderboard {
  final String id;
  final LeaderboardType type;
  final List<LeaderboardEntry> globalRankings;
  final Map<String, List<LeaderboardEntry>> regionalRankings;
  final DateTime lastUpdated;
  final int totalParticipants;

  EnhancedLeaderboard({
    required this.id,
    required this.type,
    this.globalRankings = const [],
    this.regionalRankings = const {},
    required this.lastUpdated,
    this.totalParticipants = 0,
  });
}

/// Leaderboard Type enumeration
enum LeaderboardType {
  global,
  regional,
  weekly,
  monthly,
}

/// Recycling Streak tracking
class RecyclingStreak {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivityDate;
  final List<DateTime> activityDates;
  final Map<String, dynamic> materialStreaks;
  final int streakMultiplier;
  final List<StreakMilestone> milestones;
  final int bonusPoints;

  RecyclingStreak({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastActivityDate,
    required this.activityDates,
    this.materialStreaks = const {},
    this.streakMultiplier = 1,
    this.milestones = const [],
    this.bonusPoints = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': Timestamp.fromDate(lastActivityDate),
      'activityDates': activityDates.map((date) => Timestamp.fromDate(date)).toList(),
      'materialStreaks': materialStreaks,
      'streakMultiplier': streakMultiplier,
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'bonusPoints': bonusPoints,
    };
  }

  factory RecyclingStreak.fromMap(Map<String, dynamic> map) {
    return RecyclingStreak(
      userId: map['userId'] ?? '',
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastActivityDate: (map['lastActivityDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activityDates: (map['activityDates'] as List<dynamic>?)
          ?.map((ts) => (ts as Timestamp).toDate())
          .toList() ?? [],
      materialStreaks: map['materialStreaks'] ?? {},
      streakMultiplier: map['streakMultiplier'] ?? 1,
      milestones: (map['milestones'] as List<dynamic>?)
          ?.map((m) => StreakMilestone.fromMap(m))
          .toList() ?? [],
      bonusPoints: map['bonusPoints'] ?? 0,
    );
  }
}

/// Streak Milestone for achievements
class StreakMilestone {
  final int streakCount;
  final String title;
  final String description;
  final bool isAchieved;
  final DateTime? achievedAt;
  final int rewardPoints;

  StreakMilestone({
    required this.streakCount,
    required this.title,
    required this.description,
    this.isAchieved = false,
    this.achievedAt,
    required this.rewardPoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'streakCount': streakCount,
      'title': title,
      'description': description,
      'isAchieved': isAchieved,
      'achievedAt': achievedAt != null ? Timestamp.fromDate(achievedAt!) : null,
      'rewardPoints': rewardPoints,
    };
  }

  factory StreakMilestone.fromMap(Map<String, dynamic> map) {
    return StreakMilestone(
      streakCount: map['streakCount'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isAchieved: map['isAchieved'] ?? false,
      achievedAt: (map['achievedAt'] as Timestamp?)?.toDate(),
      rewardPoints: map['rewardPoints'] ?? 0,
    );
  }
}

/// Referral Program tracking
class ReferralProgram {
  final String referralCode;
  final String referrerId;
  final String referrerName;
  final List<String> referredUsers;
  final int totalReferrals;
  final int successfulReferrals;
  final int totalBonusEarned;
  final List<Map<String, dynamic>> rewards;
  final DateTime createdAt;
  final DateTime lastUsed;
  final bool isActive;

  ReferralProgram({
    required this.referralCode,
    required this.referrerId,
    required this.referrerName,
    this.referredUsers = const [],
    this.totalReferrals = 0,
    this.successfulReferrals = 0,
    this.totalBonusEarned = 0,
    this.rewards = const [],
    required this.createdAt,
    required this.lastUsed,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'referralCode': referralCode,
      'referrerId': referrerId,
      'referrerName': referrerName,
      'referredUsers': referredUsers,
      'totalReferrals': totalReferrals,
      'successfulReferrals': successfulReferrals,
      'totalBonusEarned': totalBonusEarned,
      'rewards': rewards,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUsed': Timestamp.fromDate(lastUsed),
      'isActive': isActive,
    };
  }

  factory ReferralProgram.fromMap(Map<String, dynamic> map) {
    return ReferralProgram(
      referralCode: map['referralCode'] ?? '',
      referrerId: map['referrerId'] ?? '',
      referrerName: map['referrerName'] ?? '',
      referredUsers: List<String>.from(map['referredUsers'] ?? []),
      totalReferrals: map['totalReferrals'] ?? 0,
      successfulReferrals: map['successfulReferrals'] ?? 0,
      totalBonusEarned: map['totalBonusEarned'] ?? 0,
      rewards: List<Map<String, dynamic>>.from(map['rewards'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUsed: (map['lastUsed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}

/// Shareable Content for social media sharing
class ShareableContent {
  final String id;
  final String type;
  final String title;
  final String description;
  final String? imageUrl;
  final List<String> hashtags;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  ShareableContent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.hashtags,
    required this.createdAt,
    this.metadata = const {},
  });
}

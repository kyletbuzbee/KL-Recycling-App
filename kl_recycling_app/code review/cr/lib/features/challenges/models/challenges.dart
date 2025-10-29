// Challenges Models - Core data structures for challenge system
// KL Recycling App

/// Challenge Type enumeration
enum ChallengeType {
  daily,
  weekly,
  monthly,
  special,
  streak,
  materialSpecific,
  seasonal,
  competition,
  team,
  adaptive,
  surprise,
  timeLimited,
  community,
  chain,
}

/// Difficulty Level for challenges
enum ChallengeDifficulty {
  easy,
  medium,
  hard,
}

/// Participation Type for challenges
enum ChallengeParticipationType {
  individual,
  team,
}

/// Challenge Status enumeration
enum ChallengeStatus {
  upcoming,
  active,
  completed,
  expired,
  failed,
}

/// POINT 1: Using separate LeaderboardEntry to avoid naming conflicts
/// We'll import the social version as a prefix or hide the challenge one
/// Core Challenge Model
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final ChallengeParticipationType participationType;
  final DateTime startDate;
  final DateTime endDate;
  final int targetValue;
  final String metric;
  final int rewardPoints;
  final Map<String, dynamic> requirements;
  final ChallengeStatus status;
  final int maxParticipants;
  final String createdBy;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  // Computed properties for easy access
  int _currentValue = 0;
  int _participantCount = 0;
  bool _isPopular = false;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.participationType,
    required this.startDate,
    required this.endDate,
    required this.targetValue,
    required this.metric,
    required this.rewardPoints,
    this.requirements = const {},
    this.status = ChallengeStatus.upcoming,
    this.maxParticipants = 100,
    this.createdBy = '',
    required this.createdAt,
    this.metadata = const {},
  });

  // Getters for computed properties
  int get currentValue => _currentValue;
  String get targetUnit => metric;
  int get participantCount => _participantCount;
  bool get isPopular => _isPopular;

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (_currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Time remaining until challenge ends
  Duration? get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return null;
    return endDate.difference(now);
  }

  // Methods to update computed properties (can be called by providers/services)
  void updateProgress(int currentValue) {
    _currentValue = currentValue;
  }

  void updateParticipantCount(int count) {
    _participantCount = count;
    _isPopular = count >= 50; // Mark as popular if 50+ participants
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'difficulty': difficulty.name,
      'participationType': participationType.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'targetValue': targetValue,
      'metric': metric,
      'rewardPoints': rewardPoints,
      'requirements': requirements,
      'status': status.name,
      'maxParticipants': maxParticipants,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: _challengeTypeFromString(map['type']),
      difficulty: _challengeDifficultyFromString(map['difficulty']),
      participationType: _participationTypeFromString(map['participationType']),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      targetValue: map['targetValue'] ?? 0,
      metric: map['metric'] ?? '',
      rewardPoints: map['rewardPoints'] ?? 0,
      requirements: map['requirements'] ?? {},
      status: _challengeStatusFromString(map['status']),
      maxParticipants: map['maxParticipants'] ?? 100,
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      metadata: map['metadata'] ?? {},
    );
  }
}

/// Challenge Participation Model - TRACK USER PROGRESS
class ChallengeParticipation {
  final String id;
  final String challengeId;
  final String userId;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;
  final DateTime? completedAt;
  final int pointsEarned;
  final Map<String, dynamic> progressData;
  final DateTime joinedAt;
  final DateTime lastUpdated;

  ChallengeParticipation({
    required this.id,
    required this.challengeId,
    required this.userId,
    this.currentProgress = 0,
    this.targetProgress = 0,
    this.isCompleted = false,
    this.completedAt,
    this.pointsEarned = 0,
    this.progressData = const {},
    required this.joinedAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challengeId': challengeId,
      'userId': userId,
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'pointsEarned': pointsEarned,
      'progressData': progressData,
      'joinedAt': joinedAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ChallengeParticipation.fromMap(Map<String, dynamic> map) {
    return ChallengeParticipation(
      id: map['id'] ?? '',
      challengeId: map['challengeId'] ?? '',
      userId: map['userId'] ?? '',
      currentProgress: map['currentProgress'] ?? 0,
      targetProgress: map['targetProgress'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      pointsEarned: map['pointsEarned'] ?? 0,
      progressData: map['progressData'] ?? {},
      joinedAt: DateTime.parse(map['joinedAt']),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}

/// Challenge Leaderboard Entry - TO AVOID NAMING CONFLICTS WITH SOCIAL
class ChallengeLeaderboardEntry {
  final String userId;
  final String userName;
  final String? userAvatar;
  final int score;
  final int rank;

  ChallengeLeaderboardEntry({
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

  factory ChallengeLeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return ChallengeLeaderboardEntry(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'],
      score: map['score'] ?? 0,
      rank: map['rank'] ?? 0,
    );
  }
}

/// Challenge Results Model
class ChallengeResult {
  final String id;
  final String challengeId;
  final List<ChallengeLeaderboardEntry> rankings;
  final DateTime calculatedAt;
  final int totalParticipants;
  final Map<String, dynamic> summaryStats;

  ChallengeResult({
    required this.id,
    required this.challengeId,
    required this.rankings,
    required this.calculatedAt,
    this.totalParticipants = 0,
    this.summaryStats = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challengeId': challengeId,
      'rankings': rankings.map((r) => r.toMap()).toList(),
      'calculatedAt': calculatedAt.toIso8601String(),
      'totalParticipants': totalParticipants,
      'summaryStats': summaryStats,
    };
  }

  factory ChallengeResult.fromMap(Map<String, dynamic> map) {
    return ChallengeResult(
      id: map['id'] ?? '',
      challengeId: map['challengeId'] ?? '',
      rankings: (map['rankings'] as List<dynamic>?)
          ?.map((r) => ChallengeLeaderboardEntry.fromMap(r))
          .toList() ?? [],
      calculatedAt: DateTime.parse(map['calculatedAt']),
      totalParticipants: map['totalParticipants'] ?? 0,
      summaryStats: map['summaryStats'] ?? {},
    );
  }
}

/// Add missing Challenge types and status for broader coverage
extension ChallengeTypeExtension on ChallengeType {
  static const names = {
    ChallengeType.daily: 'daily',
    ChallengeType.weekly: 'weekly',
    ChallengeType.monthly: 'monthly',
    ChallengeType.special: 'special',
    ChallengeType.streak: 'streak',
    ChallengeType.materialSpecific: 'materialSpecific',
    ChallengeType.seasonal: 'seasonal',
    ChallengeType.competition: 'competition',
    ChallengeType.team: 'team',
    ChallengeType.adaptive: 'adaptive',
    ChallengeType.surprise: 'surprise',
    ChallengeType.timeLimited: 'timeLimited',
    ChallengeType.community: 'community',
    ChallengeType.chain: 'chain',
  };
}

extension ChallengeStatusExtension on ChallengeStatus {
  static const names = {
    ChallengeStatus.upcoming: 'upcoming',
    ChallengeStatus.active: 'active',
    ChallengeStatus.completed: 'completed',
    ChallengeStatus.expired: 'expired',
    ChallengeStatus.failed: 'failed',
  };
}

/// CHALLENGE PROGRESS MODEL - MISSING CLASS CAUSING ERRORS
class ChallengeProgress {
  final String id;
  final String challengeId;
  final String userId;
  final int currentValue;
  final int targetValue;
  final double progressPercentage;
  final DateTime lastUpdated;
  final bool isCompleted;
  final Map<String, dynamic> metadata;

  // Notification tracking properties
  final bool notifiedHalfway;
  final bool notifiedCompleted;

  ChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.userId,
    this.currentValue = 0,
    this.targetValue = 0,
    this.progressPercentage = 0.0,
    required this.lastUpdated,
    this.isCompleted = false,
    this.metadata = const {},
    this.notifiedHalfway = false,
    this.notifiedCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challengeId': challengeId,
      'userId': userId,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'progressPercentage': progressPercentage,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isCompleted': isCompleted,
      'notifiedHalfway': notifiedHalfway,
      'notifiedCompleted': notifiedCompleted,
      'metadata': metadata,
    };
  }

  factory ChallengeProgress.fromMap(Map<String, dynamic> map) {
    return ChallengeProgress(
      id: map['id'] ?? '',
      challengeId: map['challengeId'] ?? '',
      userId: map['userId'] ?? '',
      currentValue: map['currentValue'] ?? 0,
      targetValue: map['targetValue'] ?? 0,
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(map['lastUpdated']),
      isCompleted: map['isCompleted'] ?? false,
      metadata: map['metadata'] ?? {},
    );
  }
}

/// CHALLENGE LEADERBOARD MODEL - MISSING CLASS CAUSING ERRORS
class ChallengeLeaderboard {
  final String challengeId;
  final List<ChallengeLeaderboardEntry> rankings;
  final DateTime lastUpdated;
  final int totalParticipants;
  final Map<String, dynamic> summaryStats;

  ChallengeLeaderboard({
    required this.challengeId,
    required this.rankings,
    required this.lastUpdated,
    this.totalParticipants = 0,
    this.summaryStats = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'rankings': rankings.map((r) => r.toMap()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'totalParticipants': totalParticipants,
      'summaryStats': summaryStats,
    };
  }

  factory ChallengeLeaderboard.fromMap(Map<String, dynamic> map) {
    return ChallengeLeaderboard(
      challengeId: map['challengeId'] ?? '',
      rankings: (map['rankings'] as List<dynamic>?)
          ?.map((r) => ChallengeLeaderboardEntry.fromMap(r))
          .toList() ?? [],
      lastUpdated: DateTime.parse(map['lastUpdated']),
      totalParticipants: map['totalParticipants'] ?? 0,
      summaryStats: map['summaryStats'] ?? {},
    );
  }
}

/// CHALLENGE MILESTONE MODEL - MISSING CLASS CAUSING ERRORS
class ChallengeMilestone {
  final String id;
  final String challengeId;
  final String userId;
  final int milestoneValue;
  final String title;
  final String description;
  final bool isAchieved;
  final DateTime? achievedAt;
  final int rewardPoints;
  final Map<String, dynamic> metadata;

  ChallengeMilestone({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.milestoneValue,
    required this.title,
    required this.description,
    this.isAchieved = false,
    this.achievedAt,
    this.rewardPoints = 0,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challengeId': challengeId,
      'userId': userId,
      'milestoneValue': milestoneValue,
      'title': title,
      'description': description,
      'isAchieved': isAchieved,
      'achievedAt': achievedAt?.toIso8601String(),
      'rewardPoints': rewardPoints,
      'metadata': metadata,
    };
  }

  factory ChallengeMilestone.fromMap(Map<String, dynamic> map) {
    return ChallengeMilestone(
      id: map['id'] ?? '',
      challengeId: map['challengeId'] ?? '',
      userId: map['userId'] ?? '',
      milestoneValue: map['milestoneValue'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isAchieved: map['isAchieved'] ?? false,
      achievedAt: map['achievedAt'] != null ? DateTime.parse(map['achievedAt']) : null,
      rewardPoints: map['rewardPoints'] ?? 0,
      metadata: map['metadata'] ?? {},
    );
  }
}

/// CHALLENGE TEMPLATES MODEL - MISSING CLASS CAUSING ERRORS
class ChallengeTemplates {
  final String id;
  final String name;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final int rewardPoints;
  final Map<String, dynamic> criteria;
  final Map<String, dynamic> metadata;

  ChallengeTemplates({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.difficulty = ChallengeDifficulty.medium,
    this.rewardPoints = 50,
    this.criteria = const {},
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'difficulty': difficulty.name,
      'rewardPoints': rewardPoints,
      'criteria': criteria,
      'metadata': metadata,
    };
  }

  factory ChallengeTemplates.fromMap(Map<String, dynamic> map) {
    return ChallengeTemplates(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: _challengeTypeFromString(map['type']),
      difficulty: _challengeDifficultyFromString(map['difficulty']),
      rewardPoints: map['rewardPoints'] ?? 50,
      criteria: map['criteria'] ?? {},
      metadata: map['metadata'] ?? {},
    );
  }

  // Factory methods for common templates
  factory ChallengeTemplates.dailyRecycling() {
    return ChallengeTemplates(
      id: 'daily_recycling',
      name: 'Daily Recycling Goal',
      description: 'Recycle at least 10 items per day to maintain your streak',
      type: ChallengeType.daily,
      difficulty: ChallengeDifficulty.easy,
      rewardPoints: 25,
      criteria: {'targetValue': 10, 'metric': 'items'},
    );
  }

  factory ChallengeTemplates.weekWarrior() {
    return ChallengeTemplates(
      id: 'week_warrior',
      name: 'Week Warrior',
      description: 'Recycle every day for an entire week',
      type: ChallengeType.weekly,
      difficulty: ChallengeDifficulty.medium,
      rewardPoints: 100,
      criteria: {'targetValue': 7, 'metric': 'consecutive_days'},
    );
  }
}

/// CHALLENGES FILTER ENUM - MISSING CLASS CAUSING ERRORS
enum ChallengesFilter {
  all,
  active,
  completed,
  upcoming,
  popular,
  myChallenges,
  byDifficulty,
  byType,
}

/// Helper Functions for ENUM CONVERSION
ChallengeType _challengeTypeFromString(String? type) {
  switch (type) {
    case 'daily': return ChallengeType.daily;
    case 'weekly': return ChallengeType.weekly;
    case 'monthly': return ChallengeType.monthly;
    case 'special': return ChallengeType.special;
    case 'streak': return ChallengeType.streak;
    case 'materialSpecific': return ChallengeType.materialSpecific;
    case 'seasonal': return ChallengeType.seasonal;
    case 'competition': return ChallengeType.competition;
    case 'team': return ChallengeType.team;
    case 'adaptive': return ChallengeType.adaptive;
    case 'surprise': return ChallengeType.surprise;
    case 'timeLimited': return ChallengeType.timeLimited;
    case 'community': return ChallengeType.community;
    case 'chain': return ChallengeType.chain;
    default: return ChallengeType.daily;
  }
}

ChallengeDifficulty _challengeDifficultyFromString(String? difficulty) {
  switch (difficulty) {
    case 'easy': return ChallengeDifficulty.easy;
    case 'medium': return ChallengeDifficulty.medium;
    case 'hard': return ChallengeDifficulty.hard;
    default: return ChallengeDifficulty.medium;
  }
}

ChallengeParticipationType _participationTypeFromString(String? type) {
  switch (type) {
    case 'individual': return ChallengeParticipationType.individual;
    case 'team': return ChallengeParticipationType.team;
    default: return ChallengeParticipationType.individual;
  }
}

ChallengeStatus _challengeStatusFromString(String? status) {
  switch (status) {
    case 'upcoming': return ChallengeStatus.upcoming;
    case 'active': return ChallengeStatus.active;
    case 'completed': return ChallengeStatus.completed;
    case 'expired': return ChallengeStatus.expired;
    default: return ChallengeStatus.upcoming;
  }
}

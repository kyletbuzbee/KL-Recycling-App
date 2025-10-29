import 'package:cloud_firestore/cloud_firestore.dart';

/// Core User Profile Model
/// Basic user information for authentication and profile management
class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.isEmailVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'isEmailVerified': isEmailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      isEmailVerified: map['isEmailVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// User Preferences
class UserPreferences {
  final bool enableNotifications;
  final bool darkMode;
  final String language;
  final Map<String, dynamic> customSettings;

  UserPreferences({
    this.enableNotifications = true,
    this.darkMode = false,
    this.language = 'en',
    this.customSettings = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'enableNotifications': enableNotifications,
      'darkMode': darkMode,
      'language': language,
      'customSettings': customSettings,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      enableNotifications: map['enableNotifications'] ?? true,
      darkMode: map['darkMode'] ?? false,
      language: map['language'] ?? 'en',
      customSettings: map['customSettings'] ?? {},
    );
  }
}

/// User Activity Stats
class UserActivityStats {
  final String userId;
  final int totalPickups;
  final int totalRecycled;
  final int currentStreak;
  final int longestStreak;
  final double totalWeight;
  final int totalPoints;
  final DateTime lastActivity;

  UserActivityStats({
    required this.userId,
    this.totalPickups = 0,
    this.totalRecycled = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalWeight = 0.0,
    this.totalPoints = 0,
    required this.lastActivity,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalPickups': totalPickups,
      'totalRecycled': totalRecycled,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalWeight': totalWeight,
      'totalPoints': totalPoints,
      'lastActivity': Timestamp.fromDate(lastActivity),
    };
  }

  factory UserActivityStats.fromMap(Map<String, dynamic> map) {
    return UserActivityStats(
      userId: map['userId'] ?? '',
      totalPickups: map['totalPickups'] ?? 0,
      totalRecycled: map['totalRecycled'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      totalWeight: (map['totalWeight'] ?? 0.0).toDouble(),
      totalPoints: map['totalPoints'] ?? 0,
      lastActivity: (map['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  customer,
  admin,
}

class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isAdmin;
  final int loyaltyPoints;
  final int serviceRequestsCount;
  final String? profileImageUrl;

  const User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    required this.createdAt,
    this.updatedAt,
    required this.isAdmin,
    required this.loyaltyPoints,
    required this.serviceRequestsCount,
    this.profileImageUrl,
  });

  // Getters
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    return email.split('@')[0];
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0].toUpperCase()}${lastName![0].toUpperCase()}';
    }
    return email[0].toUpperCase();
  }

  CustomerTier get customerTier {
    if (loyaltyPoints >= 1000) return CustomerTier.platinum;
    if (loyaltyPoints >= 500) return CustomerTier.gold;
    if (loyaltyPoints >= 100) return CustomerTier.silver;
    return CustomerTier.bronze;
  }

  String get fullName => [firstName, lastName].where((name) => name != null && name.isNotEmpty).join(' ');

  // Factory constructors
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return User(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'],
      lastName: data['lastName'],
      phone: data['phone'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isAdmin: data['isAdmin'] ?? false,
      loyaltyPoints: data['loyaltyPoints'] ?? 0,
      serviceRequestsCount: data['serviceRequestsCount'] ?? 0,
      profileImageUrl: data['profileImageUrl'],
    );
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'],
      lastName: map['lastName'],
      phone: map['phone'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isAdmin: map['isAdmin'] ?? false,
      loyaltyPoints: map['loyaltyPoints'] ?? 0,
      serviceRequestsCount: map['serviceRequestsCount'] ?? 0,
      profileImageUrl: map['profileImageUrl'],
    );
  }

  // Conversion methods
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isAdmin': isAdmin,
      'loyaltyPoints': loyaltyPoints,
      'serviceRequestsCount': serviceRequestsCount,
      'profileImageUrl': profileImageUrl,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isAdmin': isAdmin,
      'loyaltyPoints': loyaltyPoints,
      'serviceRequestsCount': serviceRequestsCount,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Copy with method
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAdmin,
    int? loyaltyPoints,
    int? serviceRequestsCount,
    String? profileImageUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAdmin: isAdmin ?? this.isAdmin,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      serviceRequestsCount: serviceRequestsCount ?? this.serviceRequestsCount,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  // Equality operator
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is User &&
    runtimeType == other.runtimeType &&
    id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, tier: $customerTier)';
  }
}

enum CustomerTier {
  bronze,
  silver,
  gold,
  platinum,
}

extension CustomerTierExtension on CustomerTier {
  String get displayName {
    switch (this) {
      case CustomerTier.bronze:
        return 'Bronze';
      case CustomerTier.silver:
        return 'Silver';
      case CustomerTier.gold:
        return 'Gold';
      case CustomerTier.platinum:
        return 'Platinum';
    }
  }

  Color get color {
    switch (this) {
      case CustomerTier.bronze:
        return const Color(0xFFCD7F32);
      case CustomerTier.silver:
        return const Color(0xFFC0C0C0);
      case CustomerTier.gold:
        return const Color(0xFFFFD700);
      case CustomerTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  String get description {
    switch (this) {
      case CustomerTier.bronze:
        return 'Welcome to KL Recycling!';
      case CustomerTier.silver:
        return 'Active recycler - great job!';
      case CustomerTier.gold:
        return 'Gold member - valued customer!';
      case CustomerTier.platinum:
        return 'Platinum elite - our best customer!';
    }
  }

  int get minimumPoints {
    switch (this) {
      case CustomerTier.bronze:
        return 0;
      case CustomerTier.silver:
        return 100;
      case CustomerTier.gold:
        return 500;
      case CustomerTier.platinum:
        return 1000;
    }
  }
}

class Color {
  const Color(int value);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum CustomerTier {
  standard,
  premium,
  enterprise,
}

enum BusinessType {
  construction,
  manufacturing,
  automotive,
  electronics,
  industrial,
  demolition,
  other,
}

enum ContractStatus {
  active,
  pending,
  expired,
  terminated,
  suspended,
}

class BusinessCustomer {
  final String id;
  final String? firebaseId;
  final String companyName;
  final String businessType;
  final CustomerTier tier;
  final DateTime createdAt;
  final DateTime lastActivity;
  final bool isActive;
  final double lifetimeValue;
  final int totalTransactions;
  final double averageTransaction;

  // Billing & Payment Information
  final Map<String, dynamic> billingInfo;

  // Account Status
  final ContractStatus contractStatus;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;

  // Business Information
  final String? ein;
  final String? licenseNumber;
  final String? taxId;
  final String? businessAddress;
  final String? businessPhone;

  // Volume Pricing
  final Map<String, double> volumeDiscounts;
  final double minimumOrderValue;

  // Service Preferences
  final Set<String> preferredMaterials;
  final bool rushServiceAllowed;
  final List<String> specialInstructions;

  // Account Manager
  final String? accountManagerId;
  final String? accountManagerName;
  final String? accountExecutiveNotes;

  // Communication Preferences
  final bool emailNotifications;
  final bool smsNotifications;
  final List<String> reportFrequency; // ['weekly', 'monthly', 'quarterly']

  const BusinessCustomer({
    required this.id,
    this.firebaseId,
    required this.companyName,
    required this.businessType,
    this.tier = CustomerTier.standard,
    required this.createdAt,
    required this.lastActivity,
    this.isActive = true,
    this.lifetimeValue = 0.0,
    this.totalTransactions = 0,
    this.averageTransaction = 0.0,
    this.billingInfo = const {},
    this.contractStatus = ContractStatus.active,
    this.contractStartDate,
    this.contractEndDate,
    this.ein,
    this.licenseNumber,
    this.taxId,
    this.businessAddress,
    this.businessPhone,
    this.volumeDiscounts = const {},
    this.minimumOrderValue = 0.0,
    this.preferredMaterials = const {},
    this.rushServiceAllowed = false,
    this.specialInstructions = const [],
    this.accountManagerId,
    this.accountManagerName,
    this.accountExecutiveNotes,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.reportFrequency = const ['monthly'],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseId': firebaseId,
      'companyName': companyName,
      'businessType': businessType,
      'tier': tier.name,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'isActive': isActive,
      'lifetimeValue': lifetimeValue,
      'totalTransactions': totalTransactions,
      'averageTransaction': averageTransaction,
      'billingInfo': billingInfo,
      'contractStatus': contractStatus.name,
      'contractStartDate': contractStartDate?.toIso8601String(),
      'contractEndDate': contractEndDate?.toIso8601String(),
      'ein': ein,
      'licenseNumber': licenseNumber,
      'taxId': taxId,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'volumeDiscounts': volumeDiscounts,
      'minimumOrderValue': minimumOrderValue,
      'preferredMaterials': preferredMaterials.toList(),
      'rushServiceAllowed': rushServiceAllowed,
      'specialInstructions': specialInstructions,
      'accountManagerId': accountManagerId,
      'accountManagerName': accountManagerName,
      'accountExecutiveNotes': accountExecutiveNotes,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'reportFrequency': reportFrequency,
    };
  }

  factory BusinessCustomer.fromJson(Map<String, dynamic> json) {
    return BusinessCustomer(
      id: json['id'],
      firebaseId: json['firebaseId'],
      companyName: json['companyName'],
      businessType: json['businessType'],
      tier: CustomerTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => CustomerTier.standard,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      lastActivity: DateTime.parse(json['lastActivity']),
      isActive: json['isActive'] ?? true,
      lifetimeValue: (json['lifetimeValue'] ?? 0.0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
      averageTransaction: (json['averageTransaction'] ?? 0.0).toDouble(),
      billingInfo: Map<String, dynamic>.from(json['billingInfo'] ?? {}),
      contractStatus: ContractStatus.values.firstWhere(
        (e) => e.name == json['contractStatus'],
        orElse: () => ContractStatus.active,
      ),
      contractStartDate: json['contractStartDate'] != null
          ? DateTime.parse(json['contractStartDate'])
          : null,
      contractEndDate: json['contractEndDate'] != null
          ? DateTime.parse(json['contractEndDate'])
          : null,
      ein: json['ein'],
      licenseNumber: json['licenseNumber'],
      taxId: json['taxId'],
      businessAddress: json['businessAddress'],
      businessPhone: json['businessPhone'],
      volumeDiscounts: Map<String, double>.from(json['volumeDiscounts'] ?? {}),
      minimumOrderValue: (json['minimumOrderValue'] ?? 0.0).toDouble(),
      preferredMaterials: Set<String>.from(json['preferredMaterials'] ?? []),
      rushServiceAllowed: json['rushServiceAllowed'] ?? false,
      specialInstructions: List<String>.from(json['specialInstructions'] ?? []),
      accountManagerId: json['accountManagerId'],
      accountManagerName: json['accountManagerName'],
      accountExecutiveNotes: json['accountExecutiveNotes'],
      emailNotifications: json['emailNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? false,
      reportFrequency: List<String>.from(json['reportFrequency'] ?? ['monthly']),
    );
  }

  // Convenience getters
  String get formattedLifetimeValue {
    return NumberFormat.currency(symbol: '\$').format(lifetimeValue);
  }

  String get formattedAverageTransaction {
    return NumberFormat.currency(symbol: '\$').format(averageTransaction);
  }

  String get tierDisplayName {
    switch (tier) {
      case CustomerTier.standard:
        return 'Standard';
      case CustomerTier.premium:
        return 'Premium';
      case CustomerTier.enterprise:
        return 'Enterprise';
    }
  }

  String get contractStatusDisplay {
    switch (contractStatus) {
      case ContractStatus.active:
        return 'Active';
      case ContractStatus.pending:
        return 'Pending';
      case ContractStatus.expired:
        return 'Expired';
      case ContractStatus.terminated:
        return 'Terminated';
      case ContractStatus.suspended:
        return 'Suspended';
    }
  }

  Color get tierColor {
    switch (tier) {
      case CustomerTier.standard:
        return const Color(0xFF64748B); // Slate
      case CustomerTier.premium:
        return const Color(0xFFF59E0B); // Amber
      case CustomerTier.enterprise:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  Color get statusColor {
    switch (contractStatus) {
      case ContractStatus.active:
        return const Color(0xFF10B981); // Green
      case ContractStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case ContractStatus.expired:
        return const Color(0xFFEF4444); // Red
      case ContractStatus.terminated:
        return const Color(0xFF7F1D1D); // Dark Red
      case ContractStatus.suspended:
        return const Color(0xFFDC2626); // Red
    }
  }

  // Methods
  BusinessCustomer copyWith({
    String? id,
    String? firebaseId,
    String? companyName,
    String? businessType,
    CustomerTier? tier,
    DateTime? createdAt,
    DateTime? lastActivity,
    bool? isActive,
    double? lifetimeValue,
    int? totalTransactions,
    double? averageTransaction,
    Map<String, dynamic>? billingInfo,
    ContractStatus? contractStatus,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? ein,
    String? licenseNumber,
    String? taxId,
    String? businessAddress,
    String? businessPhone,
    Map<String, double>? volumeDiscounts,
    double? minimumOrderValue,
    Set<String>? preferredMaterials,
    bool? rushServiceAllowed,
    List<String>? specialInstructions,
    String? accountManagerId,
    String? accountManagerName,
    String? accountExecutiveNotes,
    bool? emailNotifications,
    bool? smsNotifications,
    List<String>? reportFrequency,
  }) {
    return BusinessCustomer(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      companyName: companyName ?? this.companyName,
      businessType: businessType ?? this.businessType,
      tier: tier ?? this.tier,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      isActive: isActive ?? this.isActive,
      lifetimeValue: lifetimeValue ?? this.lifetimeValue,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      averageTransaction: averageTransaction ?? this.averageTransaction,
      billingInfo: billingInfo ?? this.billingInfo,
      contractStatus: contractStatus ?? this.contractStatus,
      contractStartDate: contractStartDate ?? this.contractStartDate,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      ein: ein ?? this.ein,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      taxId: taxId ?? this.taxId,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      volumeDiscounts: volumeDiscounts ?? this.volumeDiscounts,
      minimumOrderValue: minimumOrderValue ?? this.minimumOrderValue,
      preferredMaterials: preferredMaterials ?? this.preferredMaterials,
      rushServiceAllowed: rushServiceAllowed ?? this.rushServiceAllowed,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      accountManagerId: accountManagerId ?? this.accountManagerId,
      accountManagerName: accountManagerName ?? this.accountManagerName,
      accountExecutiveNotes: accountExecutiveNotes ?? this.accountExecutiveNotes,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      reportFrequency: reportFrequency ?? this.reportFrequency,
    );
  }
}

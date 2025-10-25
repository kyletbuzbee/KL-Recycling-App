/// Complete appointment scheduling system for K&L Recycling facilities
library;
import 'package:flutter/material.dart';

/// Main appointment model
class Appointment {
  final String id;
  final String customerId;
  final String? businessCustomerId; // For B2B appointments
  final String facilityId;
  final DateTime scheduledDateTime;
  final Duration duration;
  final AppointmentType type;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedDriverId;
  final String? assignedEquipmentId;
  final double? estimatedWeight;
  final List<String> materialTypes;
  final AppointmentPriority priority;
  final Map<String, dynamic>? metadata;

  Appointment({
    required this.id,
    required this.customerId,
    this.businessCustomerId,
    required this.facilityId,
    required this.scheduledDateTime,
    this.duration = const Duration(hours: 1),
    this.type = AppointmentType.materialPickup,
    this.status = AppointmentStatus.scheduled,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.assignedDriverId,
    this.assignedEquipmentId,
    this.estimatedWeight,
    this.materialTypes = const [],
    this.priority = AppointmentPriority.normal,
    this.metadata,
  });

  DateTime get endDateTime => scheduledDateTime.add(duration);

  bool get isOverdue => DateTime.now().isAfter(endDateTime) && status == AppointmentStatus.scheduled;

  bool get isUpcoming => scheduledDateTime.isAfter(DateTime.now()) && status == AppointmentStatus.scheduled;

  bool overlapsWith(Appointment other) {
    if (facilityId != other.facilityId) return false;
    if (scheduledDateTime.isAtSameMomentAs(other.scheduledDateTime)) return true;

    final thisStart = scheduledDateTime;
    final thisEnd = endDateTime;
    final otherStart = other.scheduledDateTime;
    final otherEnd = other.endDateTime;

    return (thisStart.isBefore(otherEnd) && thisEnd.isAfter(otherStart));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'businessCustomerId': businessCustomerId,
    'facilityId': facilityId,
    'scheduledDateTime': scheduledDateTime.toIso8601String(),
    'duration': duration.inMinutes,
    'type': type.name,
    'status': status.name,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'assignedDriverId': assignedDriverId,
    'assignedEquipmentId': assignedEquipmentId,
    'estimatedWeight': estimatedWeight,
    'materialTypes': materialTypes,
    'priority': priority.name,
    'metadata': metadata,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'],
    customerId: json['customerId'],
    businessCustomerId: json['businessCustomerId'],
    facilityId: json['facilityId'],
    scheduledDateTime: DateTime.parse(json['scheduledDateTime']),
    duration: Duration(minutes: json['duration'] ?? 60),
    type: AppointmentType.values.firstWhere((e) => e.name == json['type']),
    status: AppointmentStatus.values.firstWhere((e) => e.name == json['status']),
    notes: json['notes'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    assignedDriverId: json['assignedDriverId'],
    assignedEquipmentId: json['assignedEquipmentId'],
    estimatedWeight: json['estimatedWeight'],
    materialTypes: List<String>.from(json['materialTypes'] ?? []),
    priority: AppointmentPriority.values.firstWhere((e) => e.name == json['priority']),
    metadata: json['metadata'],
  );

  Appointment copyWith({
    String? customerId,
    String? businessCustomerId,
    String? facilityId,
    DateTime? scheduledDateTime,
    Duration? duration,
    AppointmentType? type,
    AppointmentStatus? status,
    String? notes,
    String? assignedDriverId,
    String? assignedEquipmentId,
    double? estimatedWeight,
    List<String>? materialTypes,
    AppointmentPriority? priority,
    Map<String, dynamic>? metadata,
  }) {
    return Appointment(
      id: id,
      customerId: customerId ?? this.customerId,
      businessCustomerId: businessCustomerId ?? this.businessCustomerId,
      facilityId: facilityId ?? this.facilityId,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedEquipmentId: assignedEquipmentId ?? this.assignedEquipmentId,
      estimatedWeight: estimatedWeight ?? this.estimatedWeight,
      materialTypes: materialTypes ?? this.materialTypes,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum AppointmentType {
  materialPickup,          // Standard pickup appointment
  containerDelivery,        // Roll-off container delivery/pickup
  bulkMaterial,            // Large volume commercial pickup
  hazardousMaterial,       // Special handling materials
  consultation,            // Customer consultation
  emergencyPickup,         // Urgent/emergency service
}

extension AppointmentTypeExtension on AppointmentType {
  String get displayName {
    switch (this) {
      case AppointmentType.materialPickup: return 'Material Pickup';
      case AppointmentType.containerDelivery: return 'Container Service';
      case AppointmentType.bulkMaterial: return 'Bulk Material';
      case AppointmentType.hazardousMaterial: return 'Hazardous Material';
      case AppointmentType.consultation: return 'Consultation';
      case AppointmentType.emergencyPickup: return 'Emergency Pickup';
    }
  }

  IconData get icon {
    switch (this) {
      case AppointmentType.materialPickup: return Icons.local_shipping;
      case AppointmentType.containerDelivery: return Icons.call_to_action;
      case AppointmentType.bulkMaterial: return Icons.inventory_2;
      case AppointmentType.hazardousMaterial: return Icons.warning;
      case AppointmentType.consultation: return Icons.chat;
      case AppointmentType.emergencyPickup: return Icons.emergency;
    }
  }

  Color get color {
    switch (this) {
      case AppointmentType.materialPickup: return const Color(0xFF2196F3);
      case AppointmentType.containerDelivery: return const Color(0xFF4CAF50);
      case AppointmentType.bulkMaterial: return const Color(0xFFFF9800);
      case AppointmentType.hazardousMaterial: return const Color(0xFFF44336);
      case AppointmentType.consultation: return const Color(0xFF9C27B0);
      case AppointmentType.emergencyPickup: return const Color(0xFFFF5722);
    }
  }
}

enum AppointmentStatus {
  scheduled,      // Confirmed appointment
  confirmed,      // Customer confirmed
  inProgress,     // Currently being serviced
  completed,      // Successfully completed
  cancelled,      // Cancelled by customer
  noShow,         // Customer didn't show up
  rescheduled,    // Moved to different time
  delayed,        // Delayed due to operational issues
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get displayName {
    switch (this) {
      case AppointmentStatus.scheduled: return 'Scheduled';
      case AppointmentStatus.confirmed: return 'Confirmed';
      case AppointmentStatus.inProgress: return 'In Progress';
      case AppointmentStatus.completed: return 'Completed';
      case AppointmentStatus.cancelled: return 'Cancelled';
      case AppointmentStatus.noShow: return 'No Show';
      case AppointmentStatus.rescheduled: return 'Rescheduled';
      case AppointmentStatus.delayed: return 'Delayed';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.scheduled: return const Color(0xFF2196F3);
      case AppointmentStatus.confirmed: return const Color(0xFF4CAF50);
      case AppointmentStatus.inProgress: return const Color(0xFFFF9800);
      case AppointmentStatus.completed: return const Color(0xFF4CAF50);
      case AppointmentStatus.cancelled: return const Color(0xFF9E9E9E);
      case AppointmentStatus.noShow: return const Color(0xFFF44336);
      case AppointmentStatus.rescheduled: return const Color(0xFFFF9800);
      case AppointmentStatus.delayed: return const Color(0xFFFF5722);
    }
  }
}

enum AppointmentPriority {
  low,      // Standard scheduling
  normal,   // Default priority
  high,     // Preferred customers
  urgent,   // Same-day or emergency
}

extension AppointmentPriorityExtension on AppointmentPriority {
  String get displayName {
    switch (this) {
      case AppointmentPriority.low: return 'Low';
      case AppointmentPriority.normal: return 'Normal';
      case AppointmentPriority.high: return 'High';
      case AppointmentPriority.urgent: return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentPriority.low: return const Color(0xFF9E9E9E);
      case AppointmentPriority.normal: return const Color(0xFF2196F3);
      case AppointmentPriority.high: return const Color(0xFFFF9800);
      case AppointmentPriority.urgent: return const Color(0xFFF44336);
    }
  }
}

/// Facility information and capacity
class Facility {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final bool isActive;
  final Map<String, dynamic> operatingHours; // day -> {open, close}
  final int maxConcurrentAppointments;
  final List<String> supportedAppointmentTypes;
  final Map<String, dynamic> equipment; // Equipment available at facility
  final Map<String, dynamic> capabilities;
  final DateTime createdAt;

  Facility({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.isActive = true,
    required this.operatingHours,
    this.maxConcurrentAppointments = 5,
    required this.supportedAppointmentTypes,
    required this.equipment,
    required this.capabilities,
    required this.createdAt,
  });

  /// Check if facility is open at given datetime
  bool isOpenAt(DateTime dateTime) {
    final dayOfWeek = dateTime.weekday; // 1 = Monday, 7 = Sunday
    final dayName = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'][dayOfWeek - 1];

    if (!operatingHours.containsKey(dayName)) return false;

    final hours = operatingHours[dayName] as Map<String, dynamic>;
    if (hours['closed'] == true) return false;

    final openHour = hours['open'] as int;
    final closeHour = hours['close'] as int;

    return dateTime.hour >= openHour && dateTime.hour < closeHour;
  }

  /// Get available time slots for a date
  List<TimeSlot> getAvailableSlots(DateTime date, List<Appointment> existingAppointments) {
    final slots = <TimeSlot>[];

    if (!isOpenAt(date)) return slots;

    final dayOfWeek = date.weekday;
    final dayName = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'][dayOfWeek - 1];
    final hours = operatingHours[dayName] as Map<String, dynamic>;

    final openHour = hours['open'] as int;
    final closeHour = hours['close'] as int;

    // Create slots every 30 minutes
    for (int hour = openHour; hour < closeHour; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final slotTime = DateTime(date.year, date.month, date.day, hour, minute);
        if (slotTime.isAfter(DateTime.now()) || slotTime.day == DateTime.now().day) {
          final isAvailable = !_hasConflictAtTime(slotTime, existingAppointments);
          slots.add(TimeSlot(
            dateTime: slotTime,
            duration: const Duration(minutes: 30),
            available: isAvailable,
            capacity: maxConcurrentAppointments,
            bookedCount: _getBookedCountAtTime(slotTime, existingAppointments),
          ));
        }
      }
    }

    return slots;
  }

  bool _hasConflictAtTime(DateTime slotTime, List<Appointment> appointments) {
    return appointments.any((apt) =>
      apt.facilityId == id &&
      apt.status != AppointmentStatus.cancelled &&
      apt.status != AppointmentStatus.completed &&
      apt.scheduledDateTime.isBefore(slotTime.add(const Duration(minutes: 30))) &&
      apt.endDateTime.isAfter(slotTime)
    );
  }

  int _getBookedCountAtTime(DateTime slotTime, List<Appointment> appointments) {
    return appointments.where((apt) =>
      apt.facilityId == id &&
      apt.status != AppointmentStatus.cancelled &&
      apt.status != AppointmentStatus.completed &&
      apt.scheduledDateTime.isBefore(slotTime.add(const Duration(minutes: 30))) &&
      apt.endDateTime.isAfter(slotTime)
    ).length;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'isActive': isActive,
    'operatingHours': operatingHours,
    'maxConcurrentAppointments': maxConcurrentAppointments,
    'supportedAppointmentTypes': supportedAppointmentTypes,
    'equipment': equipment,
    'capabilities': capabilities,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    isActive: json['isActive'] ?? true,
    operatingHours: json['operatingHours'],
    maxConcurrentAppointments: json['maxConcurrentAppointments'] ?? 5,
    supportedAppointmentTypes: List<String>.from(json['supportedAppointmentTypes'] ?? []),
    equipment: json['equipment'] ?? {},
    capabilities: json['capabilities'] ?? {},
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// Time slot representation
class TimeSlot {
  final DateTime dateTime;
  final Duration duration;
  final bool available;
  final int capacity;
  final int bookedCount;

  TimeSlot({
    required this.dateTime,
    required this.duration,
    required this.available,
    required this.capacity,
    required this.bookedCount,
  });

  double get utilizationPercentage => capacity > 0 ? (bookedCount / capacity) * 100 : 0;

  bool get isFull => bookedCount >= capacity;
}

/// Scheduling conflict information
class SchedulingConflict {
  final String appointmentId;
  final String conflictReason;
  final List<String> conflictingAppointmentIds;
  final DateTime proposedAlternativeTime;

  SchedulingConflict({
    required this.appointmentId,
    required this.conflictReason,
    required this.conflictingAppointmentIds,
    required this.proposedAlternativeTime,
  });
}

/// Appointment search and filter options
class AppointmentFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final AppointmentStatus? status;
  final AppointmentType? type;
  final String? customerId;
  final String? facilityId;
  final AppointmentPriority? priority;

  AppointmentFilters({
    this.startDate,
    this.endDate,
    this.status,
    this.type,
    this.customerId,
    this.facilityId,
    this.priority,
  });

  bool matches(Appointment appointment) {
    if (startDate != null && appointment.scheduledDateTime.isBefore(startDate!)) return false;
    if (endDate != null && appointment.scheduledDateTime.isAfter(endDate!)) return false;
    if (status != null && appointment.status != status) return false;
    if (type != null && appointment.type != type) return false;
    if (customerId != null && appointment.customerId != customerId) return false;
    if (facilityId != null && appointment.facilityId != facilityId) return false;
    if (priority != null && appointment.priority != priority) return false;
    return true;
  }
}

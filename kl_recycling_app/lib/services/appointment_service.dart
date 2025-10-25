import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kl_recycling_app/models/appointment.dart';
import 'package:kl_recycling_app/services/loyalty_service.dart';

/// Complete appointment service managing scheduling, bookings, and facility coordination
class AppointmentService extends ChangeNotifier {
  static const String _appointmentsKey = 'appointments';
  static const String _facilitiesKey = 'facilities';

  late SharedPreferences _prefs;
  late LoyaltyService _loyaltyService;

  // Data storage
  final List<Appointment> _appointments = [];
  final Map<String, Facility> _facilities = {};

  // Current state
  AppointmentFilters _currentFilters = AppointmentFilters();

  // Initialization
  Future<void> initialize([LoyaltyService? loyaltyService]) async {
    _loyaltyService = loyaltyService ?? LoyaltyService();
    _prefs = await SharedPreferences.getInstance();
    await _loadAppointments();
    await _loadFacilities();
    await _initializeDefaultFacilities();
    notifyListeners();
  }

  // Public getters
  List<Appointment> get appointments => List.from(_filteredAppointments);
  Map<String, Facility> get facilities => Map.from(_facilities);
  AppointmentFilters get currentFilters => _currentFilters;

  List<Appointment> get _filteredAppointments {
    return _appointments.where(_currentFilters.matches).toList()
      ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
  }

  /// Create a new appointment
  Future<AppointmentResult> createAppointment({
    required String customerId,
    String? businessCustomerId,
    required String facilityId,
    required DateTime scheduledDateTime,
    required AppointmentType type,
    Duration duration = const Duration(hours: 1),
    String? notes,
    double? estimatedWeight,
    List<String>? materialTypes,
    AppointmentPriority priority = AppointmentPriority.normal,
  }) async {
    try {
      // Validate facility exists and is available
      final facility = _facilities[facilityId];
      if (facility == null) {
        return AppointmentResult.error('Facility not found');
      }

      if (!facility.isActive) {
        return AppointmentResult.error('Facility is not currently active');
      }

      // Check operating hours
      if (!facility.isOpenAt(scheduledDateTime) || !facility.isOpenAt(scheduledDateTime.add(duration))) {
        return AppointmentResult.error('Facility is not open at the requested time');
      }

      // Create appointment
      final appointment = Appointment(
        id: _generateAppointmentId(),
        customerId: customerId,
        businessCustomerId: businessCustomerId,
        facilityId: facilityId,
        scheduledDateTime: scheduledDateTime,
        duration: duration,
        type: type,
        status: AppointmentStatus.scheduled,
        notes: notes,
        createdAt: DateTime.now(),
        estimatedWeight: estimatedWeight,
        materialTypes: materialTypes ?? [],
        priority: priority,
      );

      // Check for conflicts
      final conflicts = _findConflicts(appointment);
      if (conflicts.isNotEmpty) {
        final alternatives = _findAlternativeTimes(appointment);
        return AppointmentResult.conflict(conflicts, alternatives);
      }

      // Add appointment
      _appointments.add(appointment);
      await _saveAppointments();

      notifyListeners();

      return AppointmentResult.success(appointment);

    } catch (e) {
      return AppointmentResult.error('Failed to create appointment: $e');
    }
  }

  /// Update existing appointment
  Future<AppointmentResult> updateAppointment({
    required String appointmentId,
    DateTime? scheduledDateTime,
    AppointmentStatus? status,
    String? notes,
    String? assignedDriverId,
    String? assignedEquipmentId,
  }) async {
    try {
      final appointmentIndex = _appointments.indexWhere((apt) => apt.id == appointmentId);
      if (appointmentIndex == -1) {
        return AppointmentResult.error('Appointment not found');
      }

      final existingAppointment = _appointments[appointmentIndex];
      Appointment updatedAppointment = existingAppointment;

      if (scheduledDateTime != null) {
        // Check for conflicts if time is changing
        final tempAppointment = existingAppointment.copyWith(
          scheduledDateTime: scheduledDateTime,
        );

        final conflicts = _findConflicts(tempAppointment);
        if (conflicts.isNotEmpty) {
          final alternatives = _findAlternativeTimes(tempAppointment);
          return AppointmentResult.conflict(conflicts, alternatives);
        }

        updatedAppointment = updatedAppointment.copyWith(
          scheduledDateTime: scheduledDateTime,
        );
      }

      updatedAppointment = updatedAppointment.copyWith(
        status: status,
        notes: notes,
        assignedDriverId: assignedDriverId,
        assignedEquipmentId: assignedEquipmentId,
      );

      _appointments[appointmentIndex] = updatedAppointment;
      await _saveAppointments();

      notifyListeners();

      return AppointmentResult.success(updatedAppointment);

    } catch (e) {
      return AppointmentResult.error('Failed to update appointment: $e');
    }
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      final appointmentIndex = _appointments.indexWhere((apt) => apt.id == appointmentId);
      if (appointmentIndex == -1) return false;

      _appointments[appointmentIndex] = _appointments[appointmentIndex].copyWith(
        status: AppointmentStatus.cancelled,
      );

      await _saveAppointments();
      notifyListeners();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get available time slots for facility and date
  List<TimeSlot> getAvailableSlots(String facilityId, DateTime date) {
    final facility = _facilities[facilityId];
    if (facility == null) return [];

    final facilityAppointments = _appointments.where((apt) =>
      apt.facilityId == facilityId &&
      apt.scheduledDateTime.year == date.year &&
      apt.scheduledDateTime.month == date.month &&
      apt.scheduledDateTime.day == date.day &&
      apt.status != AppointmentStatus.cancelled &&
      apt.status != AppointmentStatus.completed
    ).toList();

    return facility.getAvailableSlots(date, facilityAppointments);
  }

  /// Get customer's appointments
  List<Appointment> getCustomerAppointments(String customerId) {
    return _appointments.where((apt) => apt.customerId == customerId).toList()
      ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
  }

  /// Get facility appointments for date range
  List<Appointment> getFacilityAppointments(String facilityId, {DateTime? startDate, DateTime? endDate}) {
    return _appointments.where((apt) {
      if (apt.facilityId != facilityId) return false;
      if (startDate != null && apt.scheduledDateTime.isBefore(startDate)) return false;
      if (endDate != null && apt.scheduledDateTime.isAfter(endDate)) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
  }

  /// Find optimal scheduling suggestions
  List<DateTime> getSchedulingSuggestions({
    required String facilityId,
    required AppointmentType type,
    required int durationMinutes,
    int maxSuggestions = 3,
  }) {
    final suggestions = <DateTime>[];
    final now = DateTime.now();

    // Check next 7 days
    for (int day = 0; day < 7; day++) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: day));
      final slots = getAvailableSlots(facilityId, date);

      for (final slot in slots.where((s) => s.available)) {
        // Check if we can fit the duration
        final consecutiveSlots = _getConsecutiveAvailableSlots(slots, slot.dateTime, durationMinutes);
        if (consecutiveSlots.length >= (durationMinutes / 30).ceil()) {
          suggestions.add(slot.dateTime);
          if (suggestions.length >= maxSuggestions) {
            return suggestions;
          }
        }
      }
    }

    return suggestions;
  }

  /// Update filters
  void updateFilters(AppointmentFilters filters) {
    _currentFilters = filters;
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _currentFilters = AppointmentFilters();
    notifyListeners();
  }

  /// Get busy time slots for analytics
  List<TimeSlot> getBusyTimeSlots(String facilityId, int daysAhead) {
    final facility = _facilities[facilityId];
    if (facility == null) return [];

    final slots = <TimeSlot>[];
    final now = DateTime.now();

    for (int day = 0; day < daysAhead; day++) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: day));
      final daySlots = getAvailableSlots(facilityId, date);
      slots.addAll(daySlots.where((slot) => !slot.available));
    }

    return slots;
  }

  /// Export appointments for business reporting
  Future<Map<String, dynamic>> exportAppointmentsData() async {
    return {
      'appointments': _appointments.map((apt) => apt.toJson()).toList(),
      'facilities': _facilities.values.map((fac) => fac.toJson()).toList(),
      'export_timestamp': DateTime.now().toIso8601String(),
      'total_appointments': _appointments.length,
      'active_appointments': _appointments.where((apt) =>
        apt.status != AppointmentStatus.cancelled &&
        apt.status != AppointmentStatus.completed
      ).length,
      'facilities_count': _facilities.length,
    };
  }

  // Private helper methods
  List<SchedulingConflict> _findConflicts(Appointment appointment) {
    final conflicts = <SchedulingConflict>[];

    final conflictingAppointments = _appointments.where((apt) =>
      apt.id != appointment.id &&
      apt.facilityId == appointment.facilityId &&
      apt.overlapsWith(appointment) &&
      apt.status != AppointmentStatus.cancelled &&
      apt.status != AppointmentStatus.completed
    ).toList();

    if (conflictingAppointments.isNotEmpty) {
      conflicts.add(SchedulingConflict(
        appointmentId: appointment.id,
        conflictReason: 'Time slot overlaps with existing appointments',
        conflictingAppointmentIds: conflictingAppointments.map((apt) => apt.id).toList(),
        proposedAlternativeTime: appointment.scheduledDateTime.add(const Duration(hours: 1)),
      ));
    }

    return conflicts;
  }

  List<DateTime> _findAlternativeTimes(Appointment appointment) {
    final facility = _facilities[appointment.facilityId];
    if (facility == null) return [];

    final alternatives = <DateTime>[];
    final originalTime = appointment.scheduledDateTime;

    // Try times within same day
    final sameDaySlots = getAvailableSlots(appointment.facilityId,
      DateTime(originalTime.year, originalTime.month, originalTime.day));

    for (final slot in sameDaySlots.where((s) => s.available)) {
      if (slot.dateTime != originalTime) {
        alternatives.add(slot.dateTime);
        if (alternatives.length >= 3) return alternatives;
      }
    }

    // Try next available days
    for (int day = 1; day <= 7; day++) {
      final nextDay = originalTime.add(Duration(days: day));
      final nextDaySlots = getAvailableSlots(appointment.facilityId,
        DateTime(nextDay.year, nextDay.month, nextDay.day));

      for (final slot in nextDaySlots.where((s) => s.available)) {
        alternatives.add(slot.dateTime);
        if (alternatives.length >= 3) return alternatives;
      }
    }

    return alternatives;
  }

  List<TimeSlot> _getConsecutiveAvailableSlots(List<TimeSlot> allSlots, DateTime startTime, int durationMinutes) {
    final consecutive = <TimeSlot>[];
    final slotsNeeded = (durationMinutes / 30).ceil();

    final startSlot = allSlots.firstWhere(
      (slot) => slot.dateTime.isAtSameMomentAs(startTime) || slot.dateTime.isAfter(startTime),
      orElse: () => allSlots.first,
    );

    var currentTime = startSlot.dateTime;

    for (final slot in allSlots.where((s) => s.dateTime.isAtSameMomentAs(currentTime) || s.dateTime.isAfter(currentTime))) {
      if (slot.available) {
        consecutive.add(slot);
        if (consecutive.length >= slotsNeeded) break;
        currentTime = currentTime.add(const Duration(minutes: 30));
      } else {
        break; // Stop at first unavailable slot
      }
    }

    return consecutive;
  }

  String _generateAppointmentId() {
    return 'apt_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  Future<void> _initializeDefaultFacilities() async {
    if (_facilities.isNotEmpty) return;

    // Create default K&L Recycling facilities
    final defaultFacilities = [
      Facility(
        id: 'facility_main',
        name: 'K&L Recycling - Main Yard',
        address: '1234 Industrial Drive, Springfield, IL',
        latitude: 39.7817,
        longitude: -89.6501,
        operatingHours: {
          'monday': {'open': 7, 'close': 17, 'closed': false},
          'tuesday': {'open': 7, 'close': 17, 'closed': false},
          'wednesday': {'open': 7, 'close': 17, 'closed': false},
          'thursday': {'open': 7, 'close': 17, 'closed': false},
          'friday': {'open': 7, 'close': 17, 'closed': false},
          'saturday': {'open': 8, 'close': 16, 'closed': false},
          'sunday': {'closed': true},
        },
        supportedAppointmentTypes: [
          'materialPickup',
          'containerDelivery',
          'bulkMaterial',
          'hazardousMaterial',
          'consultation',
          'emergencyPickup',
        ],
        equipment: {
          'trucks': 5,
          'forklifts': 3,
          'scales': 2,
          'crushers': 1,
        },
        capabilities: {
          'maxLoad': 50000, // lbs
          'supportsHazardous': true,
          'containerService': true,
        },
        createdAt: DateTime.now(),
      ),
      // Add more facilities as needed for expansion
    ];

    for (final facility in defaultFacilities) {
      _facilities[facility.id] = facility;
    }

    await _saveFacilities();
  }

  Future<void> _loadAppointments() async {
    try {
      final jsonData = _prefs.getStringList(_appointmentsKey) ?? [];
      for (final jsonStr in jsonData) {
        final appointmentData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final appointment = Appointment.fromJson(appointmentData);
        _appointments.add(appointment);
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
    }
  }

  Future<void> _loadFacilities() async {
    try {
      final jsonData = _prefs.getString(_facilitiesKey);
      if (jsonData != null) {
        final data = jsonDecode(jsonData) as Map<String, dynamic>;
        for (final entry in data.entries) {
          final facility = Facility.fromJson(entry.value as Map<String, dynamic>);
          _facilities[entry.key] = facility;
        }
      }
    } catch (e) {
      debugPrint('Error loading facilities: $e');
    }
  }

  Future<void> _saveAppointments() async {
    try {
      final jsonData = _appointments.map((apt) => jsonEncode(apt.toJson())).toList();
      await _prefs.setStringList(_appointmentsKey, jsonData);
    } catch (e) {
      debugPrint('Error saving appointments: $e');
    }
  }

  Future<void> _saveFacilities() async {
    try {
      final facilitiesData = _facilities.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs.setString(_facilitiesKey, jsonEncode(facilitiesData));
    } catch (e) {
      debugPrint('Error saving facilities: $e');
    }
  }
}

/// Result class for appointment operations
class AppointmentResult {
  final bool success;
  final Appointment? appointment;
  final String? error;
  final List<SchedulingConflict>? conflicts;
  final List<DateTime>? alternatives;

  AppointmentResult._({
    this.success = false,
    this.appointment,
    this.error,
    this.conflicts,
    this.alternatives,
  });

  factory AppointmentResult.success(Appointment appointment) {
    return AppointmentResult._(success: true, appointment: appointment);
  }

  factory AppointmentResult.error(String error) {
    return AppointmentResult._(error: error);
  }

  factory AppointmentResult.conflict(List<SchedulingConflict> conflicts, List<DateTime> alternatives) {
    return AppointmentResult._(conflicts: conflicts, alternatives: alternatives);
  }

  bool get hasConflict => conflicts != null && conflicts!.isNotEmpty;
}

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Driver status for different operational states
enum DriverStatus {
  offline('Offline', Colors.grey, Icons.location_off),
  available('Available', Colors.green, Icons.location_on),
  enRoute('En Route', Colors.blue, Icons.directions_car),
  onPickup('On Pickup', Colors.orange, Icons.inventory),
  maintenance('Maintenance', Colors.red, Icons.build),
  break_('On Break', Colors.amber, Icons.restaurant);

  const DriverStatus(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

/// Driver vehicle information
class DriverVehicle {
  final String vehicleId;
  final String licensePlate;
  final String make;
  final String model;
  final String year;
  final String truckType; // e.g., 'roll-off', 'compactor', 'flatbed'
  final int capacity; // in cubic yards or tons
  final List<String> specialEquipment; // e.g., ['lift_gate', 'air_ride', 'loading_dock']

  const DriverVehicle({
    required this.vehicleId,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    required this.truckType,
    required this.capacity,
    this.specialEquipment = const [],
  });

  factory DriverVehicle.fromMap(Map<String, dynamic> map) {
    return DriverVehicle(
      vehicleId: map['vehicleId'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? '',
      truckType: map['truckType'] ?? '',
      capacity: map['capacity'] ?? 0,
      specialEquipment: List<String>.from(map['specialEquipment'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'licensePlate': licensePlate,
      'make': make,
      'model': model,
      'year': year,
      'truckType': truckType,
      'capacity': capacity,
      'specialEquipment': specialEquipment,
    };
  }

  bool get hasLiftGate => specialEquipment.contains('lift_gate');
  bool get hasAirRide => specialEquipment.contains('air_ride');
  bool get hasLoadingDock => specialEquipment.contains('loading_dock');
}

/// Real-time driver location data point
class DriverLocation {
  final String driverId;
  final String driverName;
  final double latitude;
  final double longitude;
  final DriverStatus status;
  final DateTime timestamp;
  final double? speedKmh; // Speed in km/h
  final double? heading; // Direction in degrees (0-360)
  final int batteryLevel; // Battery percentage for mobile app
  final String? currentPickupId;
  final DriverVehicle vehicle;

  const DriverLocation({
    required this.driverId,
    required this.driverName,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.timestamp,
    this.speedKmh,
    this.heading,
    this.batteryLevel = 100,
    this.currentPickupId,
    required this.vehicle,
  });

  factory DriverLocation.fromMap(Map<String, dynamic> map) {
    return DriverLocation(
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      status: DriverStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DriverStatus.offline,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      speedKmh: map['speedKmh']?.toDouble(),
      heading: map['heading']?.toDouble(),
      batteryLevel: map['batteryLevel'] ?? 100,
      currentPickupId: map['currentPickupId'],
      vehicle: DriverVehicle.fromMap(map['vehicle'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'speedKmh': speedKmh,
      'heading': heading,
      'batteryLevel': batteryLevel,
      'currentPickupId': currentPickupId,
      'vehicle': vehicle.toMap(),
    };
  }

  /// Calculate distance to another location in kilometers
  double distanceTo(double otherLat, double otherLng) {
    const earthRadius = 6371; // km

    final lat1Rad = latitude * math.pi / 180;
    final lat2Rad = otherLat * math.pi / 180;
    final deltaLatRad = (otherLat - latitude) * math.pi / 180;
    final deltaLngRad = (otherLng - longitude) * math.pi / 180;

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculate ETA to destination (rough estimate)
  Duration? calculateETA(double destLat, double destLng, {double averageSpeedKmh = 40.0}) {
    final distance = distanceTo(destLat, destLng);
    if (distance == 0) return Duration.zero;

    final speedToUse = speedKmh ?? averageSpeedKmh;
    if (speedToUse <= 0) return null;

    final hours = distance / speedToUse;
    return Duration(seconds: (hours * 3600).round());
  }

  /// Check if driver is within service area
  bool isInServiceArea(List<List<double>> serviceAreaBounds) {
    // Simple rectangular bounds check
    // In production, you'd use proper geospatial calculations
    for (final bound in serviceAreaBounds) {
      final minLat = bound[0];
      final maxLat = bound[1];
      final minLng = bound[2];
      final maxLng = bound[3];

      if (latitude >= minLat && latitude <= maxLat &&
          longitude >= minLng && longitude <= maxLng) {
        return true;
      }
    }
    return false;
  }

  /// Create a new DriverLocation with updated properties
  DriverLocation copyWith({
    String? driverId,
    String? driverName,
    double? latitude,
    double? longitude,
    DriverStatus? status,
    DateTime? timestamp,
    double? speedKmh,
    double? heading,
    int? batteryLevel,
    String? currentPickupId,
    DriverVehicle? vehicle,
  }) {
    return DriverLocation(
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      speedKmh: speedKmh ?? this.speedKmh,
      heading: heading ?? this.heading,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      currentPickupId: currentPickupId ?? this.currentPickupId,
      vehicle: vehicle ?? this.vehicle,
    );
  }
}

/// Pickup request for driver assignment
class PickupRequest {
  final String pickupId;
  final String customerId;
  final String customerName;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime scheduledTime;
  final String materialType;
  final double estimatedWeight;
  final int estimatedDuration; // in minutes
  final String specialInstructions;
  final List<String> requiredEquipment;

  const PickupRequest({
    required this.pickupId,
    required this.customerId,
    required this.customerName,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.scheduledTime,
    required this.materialType,
    required this.estimatedWeight,
    this.estimatedDuration = 30,
    this.specialInstructions = '',
    this.requiredEquipment = const [],
  });

  factory PickupRequest.fromMap(Map<String, dynamic> map) {
    return PickupRequest(
      pickupId: map['pickupId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduledTime'] ?? 0),
      materialType: map['materialType'] ?? '',
      estimatedWeight: map['estimatedWeight']?.toDouble() ?? 0.0,
      estimatedDuration: map['estimatedDuration'] ?? 30,
      specialInstructions: map['specialInstructions'] ?? '',
      requiredEquipment: List<String>.from(map['requiredEquipment'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pickupId': pickupId,
      'customerId': customerId,
      'customerName': customerName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'materialType': materialType,
      'estimatedWeight': estimatedWeight,
      'estimatedDuration': estimatedDuration,
      'specialInstructions': specialInstructions,
      'requiredEquipment': requiredEquipment,
    };
  }
}

/// Driver performance metrics
class DriverMetrics {
  final String driverId;
  final int totalPickups;
  final double averageRating;
  final int onTimePickups;
  final Duration averagePickupTime;
  final double customerSatisfaction;
  final int totalMilesDriven;
  final DateTime periodStart;
  final DateTime periodEnd;

  const DriverMetrics({
    required this.driverId,
    required this.totalPickups,
    required this.averageRating,
    required this.onTimePickups,
    required this.averagePickupTime,
    required this.customerSatisfaction,
    required this.totalMilesDriven,
    required this.periodStart,
    required this.periodEnd,
  });

  factory DriverMetrics.fromMap(Map<String, dynamic> map) {
    return DriverMetrics(
      driverId: map['driverId'] ?? '',
      totalPickups: map['totalPickups'] ?? 0,
      averageRating: map['averageRating']?.toDouble() ?? 0.0,
      onTimePickups: map['onTimePickups'] ?? 0,
      averagePickupTime: Duration(minutes: map['averagePickupTimeMinutes'] ?? 0),
      customerSatisfaction: map['customerSatisfaction']?.toDouble() ?? 0.0,
      totalMilesDriven: map['totalMilesDriven'] ?? 0,
      periodStart: DateTime.fromMillisecondsSinceEpoch(map['periodStart'] ?? 0),
      periodEnd: DateTime.fromMillisecondsSinceEpoch(map['periodEnd'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'totalPickups': totalPickups,
      'averageRating': averageRating,
      'onTimePickups': onTimePickups,
      'averagePickupTimeMinutes': averagePickupTime.inMinutes,
      'customerSatisfaction': customerSatisfaction,
      'totalMilesDriven': totalMilesDriven,
      'periodStart': periodStart.millisecondsSinceEpoch,
      'periodEnd': periodEnd.millisecondsSinceEpoch,
    };
  }

  double get onTimePercentage => totalPickups > 0 ? (onTimePickups / totalPickups) * 100 : 0.0;
}

/// Route optimization data for driver assignment
class RouteOptimizationData {
  final String driverId;
  final List<PickupRequest> assignedPickups;
  final List<double> routeCoordinates; // [lat1, lng1, lat2, lng2, ...]
  final Duration estimatedRouteTime;
  final double estimatedMiles;
  final DateTime optimizedAt;

  const RouteOptimizationData({
    required this.driverId,
    required this.assignedPickups,
    required this.routeCoordinates,
    required this.estimatedRouteTime,
    required this.estimatedMiles,
    required this.optimizedAt,
  });

  factory RouteOptimizationData.fromMap(Map<String, dynamic> map) {
    return RouteOptimizationData(
      driverId: map['driverId'] ?? '',
      assignedPickups: (map['assignedPickups'] as List<dynamic>?)
          ?.map((e) => PickupRequest.fromMap(e))
          .toList() ?? [],
      routeCoordinates: List<double>.from(map['routeCoordinates'] ?? []),
      estimatedRouteTime: Duration(minutes: map['estimatedRouteTimeMinutes'] ?? 0),
      estimatedMiles: map['estimatedMiles']?.toDouble() ?? 0.0,
      optimizedAt: DateTime.fromMillisecondsSinceEpoch(map['optimizedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'assignedPickups': assignedPickups.map((e) => e.toMap()).toList(),
      'routeCoordinates': routeCoordinates,
      'estimatedRouteTimeMinutes': estimatedRouteTime.inMinutes,
      'estimatedMiles': estimatedMiles,
      'optimizedAt': optimizedAt.millisecondsSinceEpoch,
    };
  }
}

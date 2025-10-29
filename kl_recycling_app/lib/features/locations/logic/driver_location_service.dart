import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kl_recycling_app/features/locations/models/driver_location.dart';
import 'package:kl_recycling_app/core/services/firebase_service.dart';
import 'package:flutter/foundation.dart';

/// Service for tracking driver locations and managing pickup operations
class DriverLocationService {
  final FirebaseFirestore _firestore;

  // Stream controllers for real-time updates
  final StreamController<List<DriverLocation>> _driversStreamController =
      StreamController<List<DriverLocation>>.broadcast();

  final StreamController<DriverLocation?> _currentDriverStreamController =
      StreamController<DriverLocation?>.broadcast();

  final StreamController<Map<String, dynamic>> _pickupUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Location tracking
  StreamSubscription<Position>? _positionSubscription;
  bool _isTrackingLocation = false;

  // Current user/driver data
  String? _currentDriverId;
  DriverLocation? _currentDriverLocation;

  // Service area boundaries (lat_min, lat_max, lng_min, lng_max)
  final List<List<double>> _serviceAreaBounds = [
    [39.0, 41.0, -76.0, -74.0], // Example: Eastern Pennsylvania area
  ];

  DriverLocationService() : _firestore = FirebaseService().firestore;

  // Stream getters
  Stream<List<DriverLocation>> get driversStream => _driversStreamController.stream;
  Stream<DriverLocation?> get currentDriverStream => _currentDriverStreamController.stream;
  Stream<Map<String, dynamic>> get pickupUpdatesStream => _pickupUpdatesController.stream;

  bool get isTrackingLocation => _isTrackingLocation;
  DriverLocation? get currentDriverLocation => _currentDriverLocation;

  /// Initialize the driver location service
  Future<void> initialize(String driverId) async {
    _currentDriverId = driverId;

    // Load initial driver data
    await _loadInitialDriverData();

    // Subscribe to real-time driver updates
    await _subscribeToDriverUpdates();

    // Subscribe to pickup updates
    await _subscribeToPickupUpdates();

    debugPrint('DriverLocationService initialized for driver: $driverId');
  }

  /// Start location tracking for current driver
  Future<void> startLocationTracking() async {
    if (_currentDriverId == null) {
      throw 'Driver not initialized';
    }

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions denied forever';
      }

      // Configure location settings
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: Duration(seconds: 30),
      );

      // Start listening to position updates
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onLocationUpdate,
        onError: (error) {
          debugPrint('Location tracking error: $error');
        },
      );

      _isTrackingLocation = true;
      debugPrint('Location tracking started');

    } catch (e) {
      debugPrint('Failed to start location tracking: $e');
      rethrow;
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTrackingLocation = false;
    debugPrint('Location tracking stopped');
  }

  /// Update driver status
  Future<void> updateDriverStatus(DriverStatus newStatus, {String? currentPickupId}) async {
    if (_currentDriverId == null || _currentDriverLocation == null) return;

    try {
      final updatedLocation = _currentDriverLocation!.copyWith(
        status: newStatus,
        currentPickupId: currentPickupId,
        timestamp: DateTime.now(),
      );

      await _updateDriverLocation(updatedLocation);
      debugPrint('Driver status updated to: ${newStatus.label}');
    } catch (e) {
      debugPrint('Failed to update driver status: $e');
    }
  }

  /// Get available drivers in service area
  Future<List<DriverLocation>> getAvailableDrivers() async {
    try {
      final querySnapshot = await _firestore
          .collection('driver_locations')
          .where('status', isEqualTo: DriverStatus.available.name)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 1))
          )) // Only get recent updates
          .get();

      final drivers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return DriverLocation.fromMap(data);
      }).where((driver) {
        // Filter to service area
        return driver.isInServiceArea(_serviceAreaBounds);
      }).toList();

      return drivers;
    } catch (e) {
      debugPrint('Failed to get available drivers: $e');
      return [];
    }
  }

  /// Assign pickup to driver
  Future<void> assignPickupToDriver(String pickupId, String driverId) async {
    try {
      await _firestore.collection('pickup_assignments').doc(pickupId).set({
        'pickupId': pickupId,
        'driverId': driverId,
        'assignedAt': FieldValue.serverTimestamp(),
        'status': 'assigned',
      });

      // Update driver's current pickup
      await updateDriverStatus(DriverStatus.enRoute, currentPickupId: pickupId);

      // Send notification to driver (would integrate with notification service)
      debugPrint('Pickup $pickupId assigned to driver $driverId');
    } catch (e) {
      debugPrint('Failed to assign pickup: $e');
      rethrow;
    }
  }

  /// Complete pickup
  Future<void> completePickup(String pickupId) async {
    try {
      await _firestore.collection('pickup_assignments').doc(pickupId).update({
        'completedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // Update driver status back to available
      await updateDriverStatus(DriverStatus.available);

      // Trigger cloud function for business logic
      await _firestore.collection('pickup_completions').doc(pickupId).set({
        'pickupId': pickupId,
        'completedAt': FieldValue.serverTimestamp(),
        'driverId': _currentDriverId,
      });

      debugPrint('Pickup $pickupId completed by driver $_currentDriverId');
    } catch (e) {
      debugPrint('Failed to complete pickup: $e');
      rethrow;
    }
  }

  /// Get optimized route for driver
  Future<List<PickupRequest>> getOptimizedRoute(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection('pickup_assignments')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'assigned')
          .orderBy('assignedAt')
          .get();

      final pickupRequests = <PickupRequest>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final pickupId = data['pickupId'] as String?;

        if (pickupId != null) {
          // Load pickup details (in real implementation, this would be a join)
          final pickupDoc = await _firestore.collection('pickups').doc(pickupId).get();
          if (pickupDoc.exists) {
            pickupRequests.add(PickupRequest.fromMap(pickupDoc.data()!));
          }
        }
      }

      // Sort by distance from current location (simple optimization)
      if (_currentDriverLocation != null && pickupRequests.isNotEmpty) {
        pickupRequests.sort((a, b) {
          final distanceA = _currentDriverLocation!.distanceTo(a.latitude, a.longitude);
          final distanceB = _currentDriverLocation!.distanceTo(b.latitude, b.longitude);
          return distanceA.compareTo(distanceB);
        });
      }

      return pickupRequests;
    } catch (e) {
      debugPrint('Failed to get optimized route: $e');
      return [];
    }
  }

  /// Calculate ETA to pickup location
  Future<Duration?> calculateETA(double destLat, double destLng) async {
    return _currentDriverLocation?.calculateETA(destLat, destLng);
  }

  /// Get driver performance metrics
  Future<DriverMetrics> getDriverMetrics(String driverId, {DateTime? periodStart, DateTime? periodEnd}) async {
    final start = periodStart ?? DateTime.now().subtract(const Duration(days: 30));
    final end = periodEnd ?? DateTime.now();

    try {
      final querySnapshot = await _firestore
          .collection('pickup_completions')
          .where('driverId', isEqualTo: driverId)
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final completions = querySnapshot.docs.map((doc) => doc.data()).toList();

      // Calculate metrics (simplified)
      final totalPickups = completions.length;
      final onTimePickups = completions.where((c) =>
        (c['completedAt'] as Timestamp).toDate().isBefore((c['scheduledTime'] as Timestamp).toDate().add(const Duration(minutes: 15)))
      ).length;

      return DriverMetrics(
        driverId: driverId,
        totalPickups: totalPickups,
        averageRating: 4.5, // Placeholder
        onTimePickups: onTimePickups,
        averagePickupTime: const Duration(minutes: 25),
        customerSatisfaction: 4.2, // Placeholder
        totalMilesDriven: 1250, // Placeholder
        periodStart: start,
        periodEnd: end,
      );
    } catch (e) {
      debugPrint('Failed to get driver metrics: $e');
      return DriverMetrics(
        driverId: driverId,
        totalPickups: 0,
        averageRating: 0.0,
        onTimePickups: 0,
        averagePickupTime: Duration.zero,
        customerSatisfaction: 0.0,
        totalMilesDriven: 0,
        periodStart: start,
        periodEnd: end,
      );
    }
  }

  // Private methods

  Future<void> _loadInitialDriverData() async {
    if (_currentDriverId == null) return;

    try {
      // Load last known location
      final locationDoc = await _firestore
          .collection('driver_locations')
          .doc(_currentDriverId)
          .get();

      if (locationDoc.exists) {
        _currentDriverLocation = DriverLocation.fromMap(locationDoc.data()!);
        _currentDriverStreamController.add(_currentDriverLocation);
      }
    } catch (e) {
      debugPrint('Failed to load initial driver data: $e');
    }
  }

  Future<void> _subscribeToDriverUpdates() async {
    // Subscribe to all drivers' locations for coordination
    final driversQuery = _firestore
        .collection('driver_locations')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1))
        ));

    driversQuery.snapshots().listen((snapshot) {
      final drivers = snapshot.docs.map((doc) =>
        DriverLocation.fromMap(doc.data())
      ).toList();
      _driversStreamController.add(drivers);
    });
  }

  Future<void> _subscribeToPickupUpdates() async {
    if (_currentDriverId == null) return;

    final assignmentsQuery = _firestore
        .collection('pickup_assignments')
        .where('driverId', isEqualTo: _currentDriverId);

    assignmentsQuery.snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null) {
            _pickupUpdatesController.add({
              'type': change.type == DocumentChangeType.added ? 'assigned' : 'updated',
              'pickupId': data['pickupId'],
              'data': data,
            });
          }
        }
      }
    });
  }

  DriverLocation _createDriverLocation(Position position) {
    // Create sample vehicle data (in real app, this would come from database)
    final vehicle = DriverVehicle(
      vehicleId: 'truck_001',
      licensePlate: 'KL-REC-001',
      make: 'Mack',
      model: 'Granite',
      year: '2022',
      truckType: 'roll-off',
      capacity: 40, // 40 cubic yards
      specialEquipment: ['lift_gate', 'air_ride'],
    );

    return DriverLocation(
      driverId: _currentDriverId!,
      driverName: 'John Driver', // Would come from auth/user data
      latitude: position.latitude,
      longitude: position.longitude,
      status: _currentDriverLocation?.status ?? DriverStatus.available,
        timestamp: position.timestamp ?? DateTime.now(),
      speedKmh: position.speed * 3.6, // Convert m/s to km/h
      heading: position.heading,
      batteryLevel: 85, // Would be polled from device
      currentPickupId: _currentDriverLocation?.currentPickupId,
      vehicle: vehicle,
    );
  }

  void _onLocationUpdate(Position position) {
    final driverLocation = _createDriverLocation(position);
    _currentDriverLocation = driverLocation;
    _currentDriverStreamController.add(driverLocation);

    // Upload location to Firebase (throttled updates)
    _updateDriverLocation(driverLocation);
  }

  Future<void> _updateDriverLocation(DriverLocation location) async {
    try {
      await _firestore
          .collection('driver_locations')
          .doc(location.driverId)
          .set(location.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to update driver location: $e');
    }
  }

  /// Simulate driver data for development/testing
  Future<void> loadDemoData() async {
    // Create demo drivers
    final demoDrivers = [
      DriverLocation(
        driverId: 'driver_001',
        driverName: 'Mike Johnson',
        latitude: 40.7128, // NYC coordinates
        longitude: -74.0060,
        status: DriverStatus.available,
        timestamp: DateTime.now(),
        vehicle: DriverVehicle(
          vehicleId: 'truck_001',
          licensePlate: 'KL-REC-001',
          make: 'Mack',
          model: 'Granite',
          year: '2022',
          truckType: 'roll-off',
          capacity: 40,
        ),
      ),
      DriverLocation(
        driverId: 'driver_002',
        driverName: 'Sarah Davis',
        latitude: 40.7589, // Slightly different location
        longitude: -73.9851,
        status: DriverStatus.enRoute,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        currentPickupId: 'pickup_123',
        vehicle: DriverVehicle(
          vehicleId: 'truck_002',
          licensePlate: 'KL-REC-002',
          make: 'Peterbilt',
          model: '579',
          year: '2021',
          truckType: 'compactor',
          capacity: 30,
        ),
      ),
    ];

    // Save to Firestore
    for (final driver in demoDrivers) {
      await _updateDriverLocation(driver);
    }

    debugPrint('Demo driver data loaded');
  }

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
    _driversStreamController.close();
    _currentDriverStreamController.close();
    _pickupUpdatesController.close();
  }
}

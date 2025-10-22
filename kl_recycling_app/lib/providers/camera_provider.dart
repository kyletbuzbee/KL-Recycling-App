import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kl_recycling_app/models/photo_estimate.dart' as models;

class CameraProvider with ChangeNotifier {
  final List<models.PhotoEstimate> _estimates = [];
  bool _isLoading = false;
  CameraController? _controller;
  bool _isInitialized = false;

  List<models.PhotoEstimate> get estimates => _estimates;
  bool get isLoading => _isLoading;
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<void> initializeCamera() async {
    if (_isInitialized) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final firstCamera = cameras.first;
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      rethrow;
    }
  }

  Future<void> disposeCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<String?> takePicture() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      final image = await _controller!.takePicture();
      return image.path;
    } catch (e) {
      debugPrint('Take picture error: $e');
      rethrow;
    }
  }

  void addEstimate(models.PhotoEstimate estimate) {
    _estimates.add(estimate);
    _saveEstimates();
    notifyListeners();
  }

  void removeEstimate(String estimateId) {
    _estimates.removeWhere((estimate) => estimate.id == estimateId);
    _saveEstimates();
    notifyListeners();
  }

  Future<Position?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }

  double calculateEstimatePrice(models.MaterialType materialType, double weight) {
    // Simplified pricing logic - this would be more sophisticated in production
    final basePrices = {
      models.MaterialType.steel: 0.15,
      models.MaterialType.aluminum: 0.85,
      models.MaterialType.copper: 3.25,
      models.MaterialType.brass: 1.95,
      models.MaterialType.zinc: 0.65,
      models.MaterialType.stainless: 0.35,
    };

    final pricePerLb = basePrices[materialType] ?? 0.10;
    return weight * pricePerLb;
  }

  Future<void> loadStoredEstimates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final estimatesJson = prefs.getStringList('photo_estimates') ?? [];

      _estimates.clear();
      for (final jsonStr in estimatesJson) {
        final estimate = models.PhotoEstimate.fromJson(jsonDecode(jsonStr));
        _estimates.add(estimate);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Load estimates error: $e');
    }
  }

  Future<void> _saveEstimates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final estimatesJson = _estimates
          .map((estimate) => estimate != null ? jsonEncode(estimate.toJson()) : null)
          .where((json) => json != null)
          .cast<String>()
          .toList();

      await prefs.setStringList('photo_estimates', estimatesJson);
    } catch (e) {
      debugPrint('Save estimates error: $e');
    }
  }

  Future<void> submitEstimates() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call - replace with actual implementation
      await Future.delayed(const Duration(seconds: 2));

      // Here you would send the estimates to your backend
      for (final estimate in _estimates) {
        // Submit each estimate
        debugPrint('Submitting estimate: ${estimate.id}');
      }

      _estimates.clear();
      _saveEstimates();

    } catch (e) {
      debugPrint('Submit estimates error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disposeCamera();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'weight_prediction_service_interface.dart';
import 'stub_weight_prediction_service.dart';
import 'tflite_weight_prediction_service.dart';

/// Provider that manages the AI strategy pattern for weight prediction services
/// Automatically selects the appropriate service based on platform capabilities
class WeightPredictionServiceProvider extends ChangeNotifier {
  /// Singleton instance for global access
  static WeightPredictionServiceProvider? _instance;

  late WeightPredictionServiceInterface _currentService;
  bool _isInitialized = false;

  WeightPredictionServiceProvider._();

  /// Get the singleton instance
  static WeightPredictionServiceProvider get instance {
    _instance ??= WeightPredictionServiceProvider._();
    return _instance!;
  }

  /// Initialize the appropriate service based on platform
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try TFLite service first (available on mobile platforms)
      final tfliteService = TFLiteWeightPredictionService();

      if (tfliteService.isSupported) {
        await tfliteService.initialize();
        _currentService = tfliteService;
        debugPrint('Using TFLite Weight Prediction Service');
      } else {
        // Fallback to stub service (works everywhere)
        final stubService = StubWeightPredictionService();
        _currentService = stubService;
        debugPrint('Using Stub Weight Prediction Service (fallback)');
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize AI service: $e');
      // Still set as initialized with stub fallback
      _currentService = StubWeightPredictionService();
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Get the current active service
  WeightPredictionServiceInterface get service => _currentService;

  /// Check if services are initialized
  bool get isInitialized => _isInitialized;

  /// Get service information for debugging
  Map<String, dynamic> get serviceInfo => {
    'service_name': _currentService.serviceName,
    'is_supported': _currentService.isSupported,
    'platform': kIsWeb ? 'web' : 'mobile',
    'initialized': _isInitialized,
  };
}

/// Provider wrapper for dependency injection in the widget tree
class AiServiceProvider extends ChangeNotifier {
  final WeightPredictionServiceInterface _predictionService;

  AiServiceProvider({
    WeightPredictionServiceInterface? predictionService,
  }) : _predictionService = predictionService ?? WeightPredictionServiceProvider.instance.service;

  /// Get the weight prediction service
  WeightPredictionServiceInterface get weightPredictionService => _predictionService;
}

/// Extension to easily access the AI service from BuildContext
extension AiServiceExtension on BuildContext {
  WeightPredictionServiceInterface get weightPredictionService {
    try {
      return read<AiServiceProvider>().weightPredictionService;
    } catch (e) {
      // Fallback to singleton instance if provider not available
      return WeightPredictionServiceProvider.instance.service;
    }
  }
}

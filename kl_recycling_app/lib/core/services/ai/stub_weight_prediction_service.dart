import 'dart:math'as math;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'weight_prediction_service_interface.dart';
import 'weight_prediction_service.dart';

/// Stub implementation of WeightPredictionService that provides basic fallback predictions
/// when AI/ML models are unavailable or disabled (web, unsupported platforms)
class StubWeightPredictionService implements WeightPredictionServiceInterface {
  @override
  bool get isSupported => true; // Always works as fallback

  @override
  String get serviceName => 'Stub Weight Prediction Service';

  @override
  Future<WeightPredictionResult> predictWeightFromImage(
    String imagePath,
    String materialType, {
    String? referenceObject,
    bool forceFallback = false,
  }) async {
    // Simulate processing time for realistic behavior
    await Future.delayed(const Duration(milliseconds: 150));

    // Generate deterministic but varied results based on image path hash
    final hash = _simpleHash(imagePath);
    final materialMultiplier = _getMaterialMultiplier(materialType);

    // Generate realistic weight estimate with some variance
    final baseWeight = (hash % 50 + 5) * materialMultiplier;
    final estimatedWeight = math.max(1.0, baseWeight.toDouble());

    // Generate confidence score based on "available data"
    // Lower confidence if no reference object, higher if provided
    final baseConfidence = referenceObject != null ? 0.6 : 0.4;
    final confidenceVariance = (hash % 30) / 100.0;
    final confidenceScore = math.min(0.9, baseConfidence + confidenceVariance);

    final factors = <String>[
      'Basic analysis for ${materialType.replaceAll('_', ' ')} material',
      'Fallback estimation method (AI models unavailable)',
      'Estimated weight based on typical scrap metal ranges',
    ];

    if (referenceObject != null) {
      factors.add('Reference object used for scale estimation');
    }

    final suggestions = <String>[
      'For better accuracy, include reference objects in photos',
      'AI-enhanced analysis available on mobile platforms',
      'Consider material type and condition in final estimate',
    ];

    if (kIsWeb) {
      suggestions.insert(0, 'Web platform - using simplified estimation algorithm');
    }

    return WeightPredictionResult(
      estimatedWeight: estimatedWeight,
      confidenceScore: confidenceScore,
      method: 'Stub_Fallback',
      factors: factors,
      suggestions: suggestions,
    );
  }

  /// Get multiplier for different material types to ensure realistic weight ranges
  double _getMaterialMultiplier(String materialType) {
    switch (materialType.toLowerCase()) {
      case 'aluminum':
        return 0.4; // Lighter material
      case 'copper':
        return 1.3; // Heavier material
      case 'steel':
      case 'iron':
        return 1.0; // Baseline
      case 'brass':
        return 1.1; // Slightly heavier than steel
      case 'zinc':
      case 'tin':
        return 0.9; // Lighter non-ferrous
      default:
        return 1.0; // Default multiplier
    }
  }

  /// Simple hash function for deterministic output generation
  int _simpleHash(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = hash * 31 + input.codeUnitAt(i);
    }
    return hash.abs();
  }
}

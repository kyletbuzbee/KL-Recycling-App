import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kl_recycling_app/core/services/ai/weight_prediction_service.dart';

/// Advanced Model Manager for ensemble orchestration and performance optimization
class ModelManager {
  final EnhancedWeightPredictionService _predictionService;
  final Map<String, ModelPerformanceMetrics> _modelMetrics = {};
  final Map<String, double> _ensembleWeights = {};
  bool _dataCollectionEnabled = true;

  // Health monitoring
  final Map<String, DateTime> _lastHealthCheck = {};
  final Duration _healthCheckInterval = const Duration(minutes: 30);

  // Prediction caching for ensemble decisions
  final Map<String, ModelStubInterface> _activeModels = {};
  final Map<String, List<ModelPrediction>> _predictionHistory = {};

  ModelManager(this._predictionService) {
    _initializeDefaultWeights();
    _loadPersistedWeights();
    _startHealthMonitoring();
  }

  /// Initialize default ensemble weights based on model reliability
  void _initializeDefaultWeights() {
    _ensembleWeights.addAll({
      'scrap_metal_detector': 0.4,   // Primary object detection
      'depth_estimator': 0.2,        // Shape analysis
      'shape_classifier': 0.25,      // Geometric corrections
      'ensemble_model': 0.15,        // Final synthesis
    });
  }

  /// Load persisted ensemble weights from local storage
  Future<void> _loadPersistedWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weightsJson = prefs.getString('ensemble_weights');
      if (weightsJson != null) {
        final Map<String, dynamic> weights = jsonDecode(weightsJson);
        weights.forEach((key, value) {
          _ensembleWeights[key] = value as double;
        });
        _normalizeWeights(); // Ensure weights sum to 1
      }
    } catch (e) {
      debugPrint('Failed to load ensemble weights: $e');
    }
  }

  /// Persist ensemble weights to local storage
  Future<void> _savePersistedWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ensemble_weights', jsonEncode(_ensembleWeights));
    } catch (e) {
      debugPrint('Failed to save ensemble weights: $e');
    }
  }

  /// Normalize weights to ensure they sum to 1
  void _normalizeWeights() {
    final totalWeight = _ensembleWeights.values.fold(0.0, (sum, w) => sum + w);
    if (totalWeight > 0) {
      _ensembleWeights.updateAll((key, weight) => weight / totalWeight);
    }
  }

  /// Start background health monitoring for all models
  void _startHealthMonitoring() {
    Timer.periodic(_healthCheckInterval, (_) => _performHealthChecks());
  }

  /// Perform health checks on all active models
  Future<void> _performHealthChecks() async {
    for (final modelName in _ensembleWeights.keys) {
      await _checkModelHealth(modelName);
    }
  }

  /// Check health of individual model
  Future<void> _checkModelHealth(String modelName) async {
    try {
      final model = await _predictionService.getModel(modelName);
      if (model != null) {
        final isHealthy = await _testModelPerformance(model, modelName);
        _updateModelHealth(modelName, isHealthy);
      }
    } catch (e) {
      debugPrint('Health check failed for $modelName: $e');
      _updateModelHealth(modelName, false);
    }
  }

  /// Test model performance with synthetic input
  Future<bool> _testModelPerformance(ModelStubInterface model, String modelName) async {
    try {
      // Use a small test input to verify model responsiveness
      final testInput = Float32List(64); // Small test input
      final result = await model.runInference(testInput);

      // Verify result structure
      return result.isNotEmpty && _validateModelOutput(result, modelName);
    } catch (e) {
      return false;
    }
  }

  /// Validate model output structure
  bool _validateModelOutput(Map<String, dynamic> output, String modelName) {
    switch (modelName) {
      case 'scrap_metal_detector':
        return output.containsKey('detection') &&
               output['detection']?.containsKey('bboxes') == true &&
               output['detection']?.containsKey('scores') == true;

      case 'depth_estimator':
        return output.containsKey('depth') &&
               output['depth']?.containsKey('depth_map') == true;

      case 'shape_classifier':
        return output.containsKey('shape') &&
               output['shape']?.containsKey('shape_probabilities') == true;

      case 'ensemble_model':
        return output.containsKey('ensemble') &&
               output['ensemble']?.containsKey('final_weight') == true;

      default:
        return false;
    }
  }

  /// Update model health status
  void _updateModelHealth(String modelName, bool isHealthy) {
    _modelMetrics.putIfAbsent(modelName, () => ModelPerformanceMetrics(modelName));

    final metrics = _modelMetrics[modelName]!;
    metrics.updateHealth(isHealthy);
    _lastHealthCheck[modelName] = DateTime.now();
  }

  /// Get optimal model selection for image characteristics
  Map<String, double> getOptimalEnsembleWeights(
    ImageCharacteristics characteristics,
    DeviceCapabilities capabilities,
  ) {
    final optimalWeights = Map<String, double>.from(_ensembleWeights);

    // Adjust weights based on image characteristics
    if (characteristics.hasClearMetalObjects) {
      optimalWeights['scrap_metal_detector'] = optimalWeights['scrap_metal_detector']! * 1.2;
    }

    if (characteristics.hasDepthCues) {
      optimalWeights['depth_estimator'] = optimalWeights['depth_estimator']! * 1.3;
    }

    if (characteristics.isRegularShape) {
      optimalWeights['shape_classifier'] = optimalWeights['shape_classifier']! * 1.1;
    }

    // Adjust based on device capabilities
    if (!capabilities.supportsGPU) {
      // Prefer lighter models on less powerful devices
      optimalWeights['ensemble_model'] = optimalWeights['ensemble_model']! * 0.8;
    }

    // Renormalize
    final totalWeight = optimalWeights.values.fold(0.0, (sum, w) => sum + w);
    optimalWeights.updateAll((key, weight) => weight / totalWeight);

    return optimalWeights;
  }

  /// Record prediction performance for continuous learning
  void recordPredictionResult(ModelPrediction prediction, Map<String, dynamic> actualResult) {
    if (!_dataCollectionEnabled) return;

    // Update model metrics
    _modelMetrics.putIfAbsent(prediction.modelName, () => ModelPerformanceMetrics(prediction.modelName));
    _modelMetrics[prediction.modelName]!.recordPrediction(
      prediction.processingTime,
      prediction.confidence,
      true, // Assuming successful prediction
    );

    // Update prediction history
    _predictionHistory.putIfAbsent(prediction.modelName, () => []);
    _predictionHistory[prediction.modelName]!.add(prediction);

    // Keep only last 50 predictions per model
    if (_predictionHistory[prediction.modelName]!.length > 50) {
      _predictionHistory[prediction.modelName]!.removeAt(0);
    }

    // Periodic weight adjustment based on performance
    _updateEnsembleWeights();
  }

  /// Update ensemble weights based on model performance history
  void _updateEnsembleWeights() {
    // Only update weights if we have sufficient data
    final hasEnoughData = _modelMetrics.values.every((metrics) =>
      metrics.predictionCount > 10
    );

    if (!hasEnoughData) return;

    // Calculate new weights based on accuracy and speed
    final performanceScores = <String, double>{};

    for (final entry in _modelMetrics.entries) {
      final metrics = entry.value;
      final accuracyBoost = metrics.averageConfidence;
      final speedPenalty = min(1.0, metrics.averageProcessingTime / 5000.0); // Normalize to 5s max

      // Combined score: accuracy matters more than speed
      performanceScores[entry.key] = (accuracyBoost * 0.7) + ((1 - speedPenalty) * 0.3);
    }

    // Update weights based on performance scores
    final totalScore = performanceScores.values.fold(0.0, (sum, score) => sum + score);

    for (final entry in performanceScores.entries) {
      _ensembleWeights[entry.key] = entry.value / totalScore;
    }

    // Persist updated weights
    _savePersistedWeights();
  }

  /// Get ensemble prediction combining multiple model outputs
  Future<EnsembleResult> computeEnsemblePrediction(
    Map<String, Map<String, dynamic>> modelOutputs,
    ImageCharacteristics characteristics,
    DeviceCapabilities capabilities,
  ) async {
    final optimalWeights = getOptimalEnsembleWeights(characteristics, capabilities);
    final predictions = <WeightedPrediction>[];

    // Collect predictions from each model with their weights
    for (final entry in modelOutputs.entries) {
      final modelName = entry.key;
      final outputs = entry.value;
      final weight = optimalWeights[modelName] ?? 0.0;

      if (weight > 0) {
        final weightEstimate = _extractPredictionFromModelOutput(outputs, modelName);
        if (weightEstimate != null) {
          // Extract confidence from model output
          final confidence = _extractConfidenceFromModelOutput(outputs, modelName);
          final processingTime = outputs['processing_time_ms'] as double? ?? 100.0;

          final prediction = ModelPrediction(modelName, weightEstimate, confidence, processingTime);
          predictions.add(WeightedPrediction(prediction, weight));
        }
      }
    }

    // Compute weighted ensemble prediction
    if (predictions.isEmpty) {
      return EnsembleResult.fallback();
    }

    return _combineWeightedPredictions(predictions);
  }

  /// Extract prediction from model output
  double? _extractPredictionFromModelOutput(Map<String, dynamic> output, String modelName) {
    try {
      switch (modelName) {
        case 'scrap_metal_detector':
          return _extractDetectionWeight(output);
        case 'depth_estimator':
          return _extractDepthWeight(output);
        case 'shape_classifier':
          return _extractShapeWeight(output);
        case 'ensemble_model':
          return output['ensemble']?['final_weight'] as double?;
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Failed to extract prediction from $modelName: $e');
      return null;
    }
  }

  /// Extract confidence from model output
  double _extractConfidenceFromModelOutput(Map<String, dynamic> output, String modelName) {
    try {
      switch (modelName) {
        case 'scrap_metal_detector':
          final detection = output['detection'];
          if (detection != null && detection['scores'] is List) {
            final scores = (detection['scores'] as List<dynamic>).cast<double>();
            return scores.isNotEmpty ? scores.reduce(max) : 0.5;
          }
          return 0.5;

        case 'depth_estimator':
          final depth = output['depth'];
          return depth?['confidence'] as double? ?? 0.6;

        case 'shape_classifier':
          final shape = output['shape'];
          if (shape != null && shape['shape_probabilities'] is List) {
            final probs = (shape['shape_probabilities'] as List<dynamic>).cast<double>();
            return probs.isNotEmpty ? probs.reduce(max) : 0.6;
          }
          return 0.6;

        case 'ensemble_model':
          return output['ensemble']?['confidence'] as double? ?? 0.9;

        default:
          return 0.5;
      }
    } catch (e) {
      debugPrint('Failed to extract confidence from $modelName: $e');
      return 0.5;
    }
  }

  double? _extractDetectionWeight(Map<String, dynamic> output) {
    final detection = output['detection'];
    if (detection == null) return null;

    final scores = detection['scores'] as List<dynamic>?;
    if (scores == null || scores.isEmpty) return null;

    // Estimate weight based on detection confidence
    final maxScore = scores.cast<double>().reduce(max);
    return 5.0 + (maxScore * 45.0); // Scale to reasonable weight range
  }

  double? _extractDepthWeight(Map<String, dynamic> output) {
    final depth = output['depth'];
    if (depth == null) return null;

    final depthMap = depth['depth_map'] as List<dynamic>?;
    if (depthMap == null || depthMap.isEmpty) return null;

    // Simple depth-based estimation (would be more sophisticated in practice)
    final avgDepth = depthMap.cast<double>().reduce((a, b) => a + b) / depthMap.length;
    return max(1.0, avgDepth * 10.0); // Scale appropriately
  }

  double? _extractShapeWeight(Map<String, dynamic> output) {
    final shape = output['shape'];
    if (shape == null) return null;

    final probabilities = shape['shape_probabilities'] as List<dynamic>?;
    if (probabilities == null || probabilities.isEmpty) return null;

    // Use shape probabilities to adjust weight estimate
    final maxProb = probabilities.cast<double>().reduce(max);
    return 10.0 + (maxProb * 40.0); // Shape-adjusted weight estimate
  }

  /// Combine weighted predictions into final ensemble result
  EnsembleResult _combineWeightedPredictions(List<WeightedPrediction> predictions) {
    double totalWeight = 0.0;
    double weightedSum = 0.0;
    double totalConfidence = 0.0;
    final factors = <String>[];

    for (final prediction in predictions) {
      final weight = prediction.weight;
      final value = prediction.prediction.weightEstimate;

      weightedSum += value * weight;
      totalWeight += weight;
      totalConfidence += prediction.prediction.confidence * weight;

      factors.add('${prediction.prediction.modelName}: ${value.toStringAsFixed(1)}lbs (weight: ${(weight * 100).round()}%)');
    }

    final finalWeight = totalWeight > 0 ? weightedSum / totalWeight : predictions.first.prediction.weightEstimate;
    final finalConfidence = totalWeight > 0 ? totalConfidence / totalWeight : predictions.first.prediction.confidence;

    return EnsembleResult(
      finalWeight: finalWeight,
      confidence: finalConfidence,
      modelCount: predictions.length,
      factors: factors,
      weights: predictions.map((p) => p.weight).toList(),
    );
  }

  /// Get model performance statistics
  Map<String, Map<String, dynamic>> getModelPerformanceStats() {
    return _modelMetrics.map((key, value) => MapEntry(key, value.toMap()));
  }

  /// Enable or disable data collection
  void setDataCollectionEnabled(bool enabled) {
    _dataCollectionEnabled = enabled;
  }

  /// Dispose and clean up resources
  void dispose() {
    _activeModels.clear();
    _predictionHistory.clear();
  }
}

/// Performance metrics for individual models
class ModelPerformanceMetrics {
  final String modelName;
  int predictionCount = 0;
  int successCount = 0;
  int failureCount = 0;
  double totalProcessingTime = 0.0;
  double totalConfidence = 0.0;
  DateTime lastHealthCheck = DateTime.now();
  bool isHealthy = true;

  ModelPerformanceMetrics(this.modelName);

  double get averageProcessingTime => predictionCount > 0 ? totalProcessingTime / predictionCount : 0.0;
  double get averageConfidence => predictionCount > 0 ? totalConfidence / predictionCount : 0.0;
  double get successRate => predictionCount > 0 ? successCount / predictionCount : 0.0;

  void recordPrediction(double processingTime, double confidence, bool success) {
    predictionCount++;
    totalProcessingTime += processingTime;
    totalConfidence += confidence;

    if (success) {
      successCount++;
    } else {
      failureCount++;
    }
  }

  void updateHealth(bool healthy) {
    isHealthy = healthy;
    lastHealthCheck = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'modelName': modelName,
      'predictionCount': predictionCount,
      'successCount': successCount,
      'failureCount': failureCount,
      'averageProcessingTime': averageProcessingTime,
      'averageConfidence': averageConfidence,
      'successRate': successRate,
      'isHealthy': isHealthy,
      'lastHealthCheck': lastHealthCheck.toIso8601String(),
    };
  }
}

/// Represents a single prediction from a model
class ModelPrediction {
  final String modelName;
  final double weightEstimate;
  final double confidence;
  final double processingTime;

  ModelPrediction(this.modelName, this.weightEstimate, this.confidence, this.processingTime);
}

/// Weighted prediction for ensemble calculation
class WeightedPrediction {
  final ModelPrediction prediction;
  final double weight;

  WeightedPrediction(this.prediction, this.weight);
}

/// Characteristics of input image for ensemble optimization
class ImageCharacteristics {
  final bool hasClearMetalObjects;
  final bool hasDepthCues;
  final bool isRegularShape;
  final double imageClarity;
  final int estimatedObjectCount;

  ImageCharacteristics({
    this.hasClearMetalObjects = false,
    this.hasDepthCues = false,
    this.isRegularShape = false,
    this.imageClarity = 0.5,
    this.estimatedObjectCount = 1,
  });
}

/// Device capabilities for model selection
class DeviceCapabilities {
  final bool supportsGPU;
  final bool supportsNNAPI;
  final bool supportsMetal;
  final int availableMemoryMB;
  final String performanceTier;

  DeviceCapabilities({
    this.supportsGPU = false,
    this.supportsNNAPI = false,
    this.supportsMetal = false,
    this.availableMemoryMB = 1024,
    this.performanceTier = 'standard',
  });
}

/// Result of ensemble prediction
class EnsembleResult {
  final double finalWeight;
  final double confidence;
  final int modelCount;
  final List<String> factors;
  final List<double> weights;
  final bool isFallback;

  EnsembleResult({
    required this.finalWeight,
    required this.confidence,
    required this.modelCount,
    required this.factors,
    required this.weights,
  }) : isFallback = false;

  EnsembleResult.fallback()
      : finalWeight = 10.0,
        confidence = 0.1,
        modelCount = 0,
        factors = ['Fallback estimation - no models available'],
        weights = [],
        isFallback = true;
}

// Extension methods for EnhancedWeightPredictionService integration
extension ModelManagerExtensions on EnhancedWeightPredictionService {
  Future<ModelStubInterface?> getModel(String modelName) async {
    // This would return the actual model or stub based on availability
    // For now, return a basic stub
    return ModelStub(modelName);
  }
}

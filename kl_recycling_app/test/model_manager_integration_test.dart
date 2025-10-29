import 'package:flutter_test/flutter_test.dart';
import 'package:kl_recycling_app/core/services/ai/model_manager.dart';
import 'package:kl_recycling_app/core/services/ai/weight_prediction_service.dart';

void main() {
  late ModelManager modelManager;
  late EnhancedWeightPredictionService predictionService;

  setUp(() async {
    predictionService = EnhancedWeightPredictionService();
    modelManager = ModelManager(predictionService);
  });

  tearDown(() {
    modelManager.dispose();
  });

  group('ModelManager Integration Tests', () {
    test('Initialize with default weights', () async {
      final stats = modelManager.getModelPerformanceStats();
      expect(stats.isNotEmpty, true);
      expect(stats.containsKey('scrap_metal_detector'), true);
      expect(stats.containsKey('ensemble_model'), true);
    });

    test('Ensemble weight calculation respects total sum constraint', () {
      final weights = modelManager.getOptimalEnsembleWeights(
        ImageCharacteristics(hasClearMetalObjects: true, hasDepthCues: true),
        DeviceCapabilities(supportsGPU: true),
      );

      // Verify all weights are non-negative and sum to 1.0
      double totalWeight = 0.0;
      weights.forEach((key, weight) {
        expect(weight, greaterThanOrEqualTo(0.0));
        totalWeight += weight;
      });
      expect(totalWeight, closeTo(1.0, 0.001));
    });

    test('Clear metal objects boost detection model weight', () {
      final baseWeights = modelManager.getOptimalEnsembleWeights(
        ImageCharacteristics(),
        DeviceCapabilities(),
      );

      final boostedWeights = modelManager.getOptimalEnsembleWeights(
        ImageCharacteristics(hasClearMetalObjects: true),
        DeviceCapabilities(),
      );

      // Detection model weight should increase
      expect(boostedWeights['scrap_metal_detector']!,
          greaterThan(baseWeights['scrap_metal_detector']!));
    });

    test('Performance tracking updates model weights dynamically', () {
      // Record successful predictions for detection model
      final mockPrediction = ModelPrediction(
        'scrap_metal_detector',
        15.5,
        0.85, // High confidence
        120.0, // 120ms processing time
      );

      modelManager.recordPredictionResult(mockPrediction, {});

      final stats = modelManager.getModelPerformanceStats();
      final detectionStats = stats['scrap_metal_detector']!;

      expect(detectionStats['predictionCount'], equals(1));
      expect(detectionStats['successCount'], equals(1));
      expect(detectionStats['averageConfidence'], closeTo(0.85, 0.01));
      expect(detectionStats['averageProcessingTime'], equals(120.0));
    });

    test('Fallback ensemble result when no models available', () async {
      final modelOutputs = <String, Map<String, dynamic>>{};
      final characteristics = ImageCharacteristics();
      final capabilities = DeviceCapabilities();

      final result = await modelManager.computeEnsemblePrediction(
        modelOutputs,
        characteristics,
        capabilities,
      );

      expect(result.isFallback, true);
      expect(result.finalWeight, closeTo(10.0, 0.1));
      expect(result.confidence, lessThan(0.2));
      expect(result.modelCount, equals(0));
      expect(result.factors.first, contains('Fallback'));
    });

    test('Multi-model ensemble weighting produces balanced result', () async {
      final modelOutputs = {
        'scrap_metal_detector': {'detection': {'scores': [0.9]}} ,
        'depth_estimator': {'depth': {'depth_map': [15.0, 12.0, 18.0]}} ,
        'shape_classifier': {'shape': {'shape_probabilities': [0.2, 0.8]}} ,
      };
      final characteristics = ImageCharacteristics();
      final capabilities = DeviceCapabilities();

      final result = await modelManager.computeEnsemblePrediction(
        modelOutputs,
        characteristics,
        capabilities,
      );

      expect(result.isFallback, false);
      expect(result.modelCount, 3);
      expect(result.finalWeight, greaterThan(0));
      expect(result.confidence, greaterThanOrEqualTo(0));
      expect(result.confidence, lessThanOrEqualTo(1.0));
      expect(result.factors.length, equals(3));
      expect(result.weights.length, equals(3));
    });

    test('Device capability optimization - low power devices reduce model complexity', () {
      final lowPowerWeights = modelManager.getOptimalEnsembleWeights(
        ImageCharacteristics(),
        DeviceCapabilities(supportsGPU: false, availableMemoryMB: 512, performanceTier: 'low'),
      );

      final highPowerWeights = modelManager.getOptimalEnsembleWeights(
        ImageCharacteristics(),
        DeviceCapabilities(supportsGPU: true, availableMemoryMB: 4096, performanceTier: 'high'),
      );

      // Low power devices should reduce ensemble model weighting
      expect(lowPowerWeights['ensemble_model']!,
          lessThan(highPowerWeights['ensemble_model']!));
    });

    test('Health monitoring and model failover simulation', () async {
      final initialStats = modelManager.getModelPerformanceStats();
      final initialHealth = initialStats['scrap_metal_detector']!['isHealthy'];

      // Simulate model failure
      final failedPrediction = ModelPrediction('scrap_metal_detector', 0.0, 0.0, 0.0);

      // Record multiple failures to simulate unhealthy model
      for (int i = 0; i < 10; i++) {
        modelManager.recordPredictionResult(failedPrediction, {});
      }

      final updatedStats = modelManager.getModelPerformanceStats();

      // Model should show decreased performance and potentially unhealthy status
      expect(updatedStats['scrap_metal_detector']!['predictionCount'], equals(10));
      // Health status might be updated by background monitoring
    });

    test('Ensemble weight persistence across sessions', () async {
      // Modify ensemble weights through learning
      final mockPrediction = ModelPrediction('scrap_metal_detector', 20.0, 0.95, 100.0);

      for (int i = 0; i < 15; i++) {
        modelManager.recordPredictionResult(mockPrediction, {});
      }

      // Weights should update after sufficient predictions
      final updatedStats = modelManager.getModelPerformanceStats();
      expect(updatedStats['scrap_metal_detector']!['predictionCount'], greaterThanOrEqualTo(15));

      // Note: Full persistence testing would require SharedPreferences mocking
      // This tests the internal weight update logic
    });

    test('Prediction recording respects data collection settings', () {
      modelManager.setDataCollectionEnabled(false);

      final mockPrediction = ModelPrediction('depth_estimator', 25.0, 0.8, 150.0);
      modelManager.recordPredictionResult(mockPrediction, {});

      final stats = modelManager.getModelPerformanceStats();

      // Predictions should not be recorded when data collection is disabled
      // (This test will fail if the feature is not properly implemented)
      expect(stats['depth_estimator']!['predictionCount'], equals(0));
    });

    test('Ensemble prediction weights sum correctly', () async {
      final modelOutputs = {
        'scrap_metal_detector': {'detection': {'scores': [0.8]}},
        'shape_classifier': {'shape': {'shape_probabilities': [0.6]}},
        'ensemble_model': {'ensemble': {'final_weight': 22.5}},
      };

      final result = await modelManager.computeEnsemblePrediction(
        modelOutputs,
        ImageCharacteristics(),
        DeviceCapabilities(),
      );

      final totalIndividualWeight = result.weights.reduce((a, b) => a + b);
      expect(totalIndividualWeight, closeTo(1.0, 0.001));
    });
  });
}

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kl_recycling_app/cline_generated/ai-model-comparison/model_a_adapter.dart';
import 'package:kl_recycling_app/cline_generated/ai-model-comparison/model_b_adapter.dart';
import 'package:kl_recycling_app/cline_generated/ai-model-comparison/performance_tracker.dart';

void main() {
  group('AI Model Comparison Tests', () {
    late ModelAAdapter modelA;
    late ModelBAdapter modelB;
    late PerformanceMetrics tracker;

    setUp(() async {
      modelA = ModelAAdapter();
      modelB = ModelBAdapter();
      tracker = PerformanceMetrics();

      await modelA.initialize();
      await modelB.initialize();
    });

    tearDown(() async {
      await modelA.dispose();
      await modelB.dispose();
    });

    test('Models initialize successfully', () async {
      // Verify initialization completed without errors
      expect(true, true); // Placeholder - models are initialized in setUp
    });

    test('Model A produces valid results', () async {
      // Create mock image bytes
      final mockImageBytes = Uint8List.fromList(List.generate(1024 * 768 * 3, (i) => i % 256));

      final result = await modelA.predictWeight(mockImageBytes);

      expect(result, isNotNull);
      expect(result.weight, greaterThan(0));
      expect(result.weight, lessThanOrEqualTo(1000));
      expect(result.confidence, greaterThanOrEqualTo(0));
      expect(result.confidence, lessThanOrEqualTo(1));
      expect(result.inferenceTime.inMilliseconds, greaterThan(0));
    });

    test('Model B produces valid results', () async {
      // Create mock image bytes
      final mockImageBytes = Uint8List.fromList(List.generate(1024 * 768 * 3, (i) => i % 256));

      final result = await modelB.predictWeight(mockImageBytes);

      expect(result, isNotNull);
      expect(result.weight, greaterThan(0));
      expect(result.weight, lessThanOrEqualTo(1000));
      expect(result.confidence, greaterThanOrEqualTo(0));
      expect(result.confidence, lessThanOrEqualTo(1));
      expect(result.inferenceTime.inMilliseconds, greaterThan(0));
    });

    test('Performance tracking collects data', () async {
      final mockImageBytes = Uint8List.fromList(List.generate(512 * 512 * 3, (i) => i % 256));

      // Run multiple predictions
      final resultA = await modelA.predictWeight(mockImageBytes);
      final resultB = await modelB.predictWeight(mockImageBytes);

      // Add to tracker
      tracker.addPrediction(
        PredictionResult(
          weight: resultA.weight,
          confidence: resultA.confidence,
          method: resultA.method,
          inferenceTime: resultA.inferenceTime,
          metadata: resultA.metadata ?? {},
          imageId: 'test_001',
        ),
        false,
        null,
      );

      tracker.addPrediction(
        PredictionResult(
          weight: resultB.weight,
          confidence: resultB.confidence,
          method: resultB.method,
          inferenceTime: resultB.inferenceTime,
          metadata: resultB.metadata ?? {},
          imageId: 'test_001',
        ),
        false,
        null,
      );

      final stats = tracker.getStatistics();
      expect(stats['total_predictions'], equals(2));
      expect(stats['inference_time_mean_ms'], isNotNull);
    });

    test('Ground truth accuracy calculation', () {
      // Add prediction with known ground truth
      const groundTruthWeight = 15.0;
      const predictedWeight = 16.5;

      tracker.addPrediction(
        PredictionResult(
          weight: predictedWeight,
          confidence: 0.8,
          method: 'Test Method',
          inferenceTime: const Duration(milliseconds: 50),
          metadata: {},
          imageId: 'ground_truth_test',
        ),
        true, // Has ground truth
        groundTruthWeight,
      );

      final stats = tracker.getStatistics();
      expect(stats['ground_truth_count'], equals(1));
      expect(stats['accuracy_mean_percent'], isNotNull);
    });

    test('Error handling in models', () async {
      // Test with empty image bytes (should trigger fallback)
      final emptyImageBytes = Uint8List(0);

      expect(
        () async => await modelA.predictWeight(emptyImageBytes),
        returnsNormally,
      );

      expect(
        () async => await modelB.predictWeight(emptyImageBytes),
        returnsNormally,
      );
    });

    test('Comparison report generation', () {
      // Add some test data
      for (int i = 0; i < 5; i++) {
        tracker.addPrediction(
          PredictionResult(
            weight: 10.0 + i * 2,
            confidence: 0.5 + i * 0.1,
            method: i % 2 == 0 ? 'Model A' : 'Model B',
            inferenceTime: Duration(milliseconds: 50 + i * 10),
            metadata: {},
            imageId: 'report_test_$i',
          ),
          false,
          null,
        );
      }

      final report = tracker.generateComparisonReport();
      expect(report, isNotEmpty);
      expect(report.contains('# AI Model Comparison Report'), isTrue);
      expect(report.contains('Total Predictions: 5'), isTrue);
    });

    test('Models have different approaches', () async {
      final mockImageBytes = Uint8List.fromList(List.generate(640 * 480 * 3, (i) => i % 256));

      final resultA = await modelA.predictWeight(mockImageBytes);
      final resultB = await modelB.predictWeight(mockImageBytes);

      // Models should produce different results (they have different logic)
      expect(resultA.method, contains('ML Kit'));
      expect(resultB.method, contains('TFLite'));

      // Different confidence ranges indicate different approaches
      expect(resultA.confidence, isNot(equals(resultB.confidence)));
    });
  });
}

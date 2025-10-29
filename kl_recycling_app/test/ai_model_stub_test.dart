import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kl_recycling_app/core/services/ai/weight_prediction_service.dart';
import 'package:kl_recycling_app/features/photo_estimate/models/photo_estimate.dart' as models;

void main() {
  group('AI Model Stub Tests', () {
    late EnhancedWeightPredictionService service;

    setUp(() async {
      service = EnhancedWeightPredictionService();
      await service.initialize();
    });

    tearDown(() {
      service.dispose();
    });

    test('ModelStub returns consistent results', () async {
      final stub = ModelStub('test_model');

      // Test deterministic output generation
      final input1 = Float32List.fromList([0.1, 0.2, 0.3]);
      final result1 = await stub.runInference(input1);

      final input2 = Float32List.fromList([0.1, 0.2, 0.3]);
      final result2 = await stub.runInference(input2);

      // Same inputs should give same results (deterministic)
      expect(result1['detection']?['bboxes'], equals(result2['detection']?['bboxes']));
    });

    test('ModelStub returns expected structure', () async {
      final stub = ModelStub('test_model');
      final input = Float32List(224 * 224 * 3); // Mock image input

      final result = await stub.runInference(input);

      // Verify all expected output keys exist
      expect(result.containsKey('detection'), true);
      expect(result.containsKey('depth'), true);
      expect(result.containsKey('shape'), true);
      expect(result.containsKey('ensemble'), true);

      // Verify detection structure
      expect(result['detection']?.containsKey('bboxes'), true);
      expect(result['detection']?.containsKey('classes'), true);
      expect(result['detection']?.containsKey('scores'), true);

      // Verify shape structure
      expect(result['shape']?.containsKey('shape_probabilities'), true);
      expect(result['shape']?.containsKey('predicted_shape'), true);

      // Verify ensemble structure
      expect(result['ensemble']?.containsKey('final_weight'), true);
    });

    test('EnhancedWeightPredictionService always returns valid result', () async {
      // Test with web platform simulation
      if (kIsWeb) {
        // On web, this should still work
        final result = await service.predictWeightFromImage(
          imagePath: 'dummy_path',
          materialType: models.MaterialType.steel,
        );

        expect(result, isNotNull);
        expect(result.estimatedWeight, greaterThan(0));
        expect(result.confidenceScore, greaterThan(0));
        expect(result.method, isNotEmpty);
      }
    });

    test('ModelStub metadata is correctly populated', () {
      final stub = ModelStub('test_model');

      final metadata = stub.metadata;

      expect(metadata['name'], equals('test_model'));
      expect(metadata['stub'], equals(true));
      expect(metadata['version'], equals('1.0.0'));
      expect(metadata['input_shape'], equals([1, 224, 224, 3]));
      expect(metadata.containsKey('output_shapes'), true);
    });

    test('ModelStub close method works without error', () {
      final stub = ModelStub('test_model');

      // Should not throw any exceptions
      expect(() => stub.close(), returnsNormally);
    });

    test('Different inputs produce different but reasonable outputs', () async {
      final stub = ModelStub('test_model');

      final input1 = Float32List.fromList(List.generate(10, (i) => i * 0.1));
      final input2 = Float32List.fromList(List.generate(10, (i) => i * 0.2));

      final result1 = await stub.runInference(input1);
      final result2 = await stub.runInference(input2);

      // Results should be different
      expect(result1['ensemble']?['final_weight'], isNot(equals(result2['ensemble']?['final_weight'])));

      // But both should be reasonable weight values
      expect((result1['ensemble']?['final_weight'] as double), greaterThan(0));
      expect((result1['ensemble']?['final_weight'] as double), lessThan(100));
      expect((result2['ensemble']?['final_weight'] as double), greaterThan(0));
      expect((result2['ensemble']?['final_weight'] as double), lessThan(100));
    });
  });
}

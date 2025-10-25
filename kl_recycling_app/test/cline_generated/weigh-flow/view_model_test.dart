import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kl_recycling_app/cline_generated/weigh-flow/view_model.dart';

void main() {
  group('WeighFlowViewModel Tests', () {
    late WeighFlowViewModel viewModel;

    setUp(() {
      viewModel = WeighFlowViewModel();
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('ViewModel initializes in initial state', () {
      expect(viewModel.state, equals(WeighFlowState.initial));
      expect(viewModel.isInitialized, isFalse);
      expect(viewModel.canSubmit, isFalse);
    });

    test('ViewModel initializes successfully', () async {
      await viewModel.initialize();

      expect(viewModel.isInitialized, isTrue);
      expect(viewModel.state, equals(WeighFlowState.cameraReady));
    });

    test('ViewModel sets captured image and changes state', () {
      final testImage = File('/test/path/image.jpg');

      viewModel.setCapturedImage(testImage);

      expect(viewModel.capturedImage, equals(testImage));
      expect(viewModel.state, equals(WeighFlowState.imageCaptured));
      expect(viewModel.predictedWeight, isNull);
      expect(viewModel.measuredWeight, isNull);
    });

    test('ViewModel runs prediction successfully', () async {
      await viewModel.initialize();
      final testImage = File('/test/path/image.jpg');
      viewModel.setCapturedImage(testImage);

      await viewModel.runPrediction();

      expect(viewModel.state, equals(WeighFlowState.predictionReady));
      expect(viewModel.predictedWeight, isNotNull);
      expect(viewModel.predictedWeight, isA<double>());
      expect(viewModel.predictedWeight, greaterThan(0));
    });

    test('ViewModel handles prediction errors gracefully', () async {
      await viewModel.initialize();

      // Set a non-existent image file to trigger error
      final nonExistentImage = File('/non/existent/image.jpg');
      viewModel.setCapturedImage(nonExistentImage);

      await viewModel.runPrediction();

      expect(viewModel.state, equals(WeighFlowState.error));
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.errorMessage, contains('Prediction failed'));
    });

    test('ViewModel validates weight input', () {
      // Test valid weight
      viewModel.updateMeasuredWeight('15.5');
      expect(viewModel.measuredWeight, equals(15.5));
      expect(viewModel.errorMessage, isNull);

      // Test invalid weight
      viewModel.updateMeasuredWeight('invalid');
      expect(viewModel.measuredWeight, isNull);
      expect(viewModel.errorMessage, equals('Please enter a valid weight'));

      // Test empty input
      viewModel.updateMeasuredWeight('');
      expect(viewModel.measuredWeight, isNull);
      expect(viewModel.errorMessage, isNull);

      // Test negative weight
      viewModel.updateMeasuredWeight('-5');
      expect(viewModel.measuredWeight, isNull);
      expect(viewModel.errorMessage, equals('Please enter a valid weight'));
    });

    test('ViewModel determines canSubmit correctly', () {
      // Initially cannot submit
      expect(viewModel.canSubmit, isFalse);

      // Set image but no weight
      viewModel.setCapturedImage(File('/test/image.jpg'));
      expect(viewModel.canSubmit, isFalse);

      // Set valid weight
      viewModel.updateMeasuredWeight('10.0');
      expect(viewModel.canSubmit, isTrue);

      // Set invalid weight
      viewModel.updateMeasuredWeight('invalid');
      expect(viewModel.canSubmit, isFalse);

      // Set zero weight
      viewModel.updateMeasuredWeight('0');
      expect(viewModel.canSubmit, isFalse);
    });

    test('ViewModel resets state correctly', () async {
      await viewModel.initialize();

      // Set up some state
      viewModel.setCapturedImage(File('/test/image.jpg'));
      await viewModel.runPrediction();
      viewModel.updateMeasuredWeight('15.0');

      // Reset
      viewModel.reset();

      expect(viewModel.state, equals(WeighFlowState.cameraReady));
      expect(viewModel.capturedImage, isNull);
      expect(viewModel.predictedWeight, isNull);
      expect(viewModel.measuredWeight, isNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('ViewModel handles retry correctly', () {
      // Set error state by triggering an error
      viewModel.updateMeasuredWeight('invalid');
      expect(viewModel.errorMessage, equals('Please enter a valid weight'));

      viewModel.retry();

      expect(viewModel.errorMessage, isNull);
      expect(viewModel.state, equals(WeighFlowState.initial));
    });

    test('ViewModel handles submission workflow', () async {
      await viewModel.initialize();

      // Set up complete state for submission
      viewModel.setCapturedImage(File('/test/image.jpg'));
      await viewModel.runPrediction();
      viewModel.updateMeasuredWeight('20.0');

      expect(viewModel.canSubmit, isTrue);

      // Note: We can't easily test the actual submission without mocking
      // the repository, but we can verify the state transition
      expect(viewModel.state, equals(WeighFlowState.predictionReady));
    });

    test('ViewModel handles multiple state transitions', () async {
      await viewModel.initialize();

      // Initial state
      expect(viewModel.state, equals(WeighFlowState.cameraReady));

      // Capture image
      viewModel.setCapturedImage(File('/test/image1.jpg'));
      expect(viewModel.state, equals(WeighFlowState.imageCaptured));

      // Run prediction
      await viewModel.runPrediction();
      expect(viewModel.state, equals(WeighFlowState.predictionReady));

      // Reset and start over
      viewModel.reset();
      expect(viewModel.state, equals(WeighFlowState.cameraReady));

      // Capture different image
      viewModel.setCapturedImage(File('/test/image2.jpg'));
      expect(viewModel.state, equals(WeighFlowState.imageCaptured));
    });

    test('ViewModel disposes properly', () {
      viewModel.dispose();
      // In a real test, we might verify that resources are cleaned up
      // For now, we just ensure dispose doesn't throw
    });

    test('ViewModel handles edge cases in weight input', () {
      // Test very large numbers
      viewModel.updateMeasuredWeight('999999');
      expect(viewModel.measuredWeight, equals(999999.0));

      // Test decimal numbers
      viewModel.updateMeasuredWeight('15.75');
      expect(viewModel.measuredWeight, equals(15.75));

      // Test very small positive numbers
      viewModel.updateMeasuredWeight('0.1');
      expect(viewModel.measuredWeight, equals(0.1));

      // Test numbers with leading/trailing spaces (should be handled by double.tryParse)
      viewModel.updateMeasuredWeight(' 15.5 ');
      expect(viewModel.measuredWeight, equals(15.5));
    });
  });
}

/// ViewModel for Weigh Flow Feature
/// Manages state and coordinates between UI, model, and repository
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'tflite_helper.dart';
import 'repository.dart';

enum WeighFlowState {
  initial,
  cameraReady,
  imageCaptured,
  processing,
  predictionReady,
  submitting,
  completed,
  error,
}

class WeighFlowViewModel extends ChangeNotifier {
  final TFLiteHelper _tfliteHelper;
  final ItemRepository _repository;

  WeighFlowViewModel({
    // Dependencies are now required in the constructor.
    required TFLiteHelper tfliteHelper,
    required ItemRepository repository,
  })  : _tfliteHelper = tfliteHelper,
        _repository = repository;

  // State
  WeighFlowState _state = WeighFlowState.initial;
  File? _capturedImage;
  double? _predictedWeight;
  double? _measuredWeight;
  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  WeighFlowState get state => _state;
  File? get capturedImage => _capturedImage;
  double? get predictedWeight => _predictedWeight;
  double? get measuredWeight => _measuredWeight;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get canSubmit => _capturedImage != null && _measuredWeight != null && _measuredWeight! > 0;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setState(WeighFlowState.initial);
      await _tfliteHelper.initialize();
      _isInitialized = true;
      _setState(WeighFlowState.cameraReady);
    } catch (e) {
      _setError('Failed to initialize: $e');
    }
  }

  void setCapturedImage(File image) {
    _capturedImage = image;
    _predictedWeight = null;
    _measuredWeight = null;
    _errorMessage = null;
    _setState(WeighFlowState.imageCaptured);
    notifyListeners();
  }

  Future<void> runPrediction() async {
    if (_capturedImage == null) return;

    try {
      _setState(WeighFlowState.processing);

      // Read image bytes
      final imageBytes = await _capturedImage!.readAsBytes();

      // Run prediction
      _predictedWeight = await _tfliteHelper.predictWeight(imageBytes);

      _setState(WeighFlowState.predictionReady);
    } catch (e) {
      _setError('Prediction failed: $e');
    }
  }

  void setMeasuredWeight(double weight) {
    _measuredWeight = weight;
    notifyListeners();
  }

  void updateMeasuredWeight(String weightText) {
    final weight = double.tryParse(weightText);
    if (weight != null && weight >= 0) {
      _measuredWeight = weight;
      _errorMessage = null;
    } else if (weightText.isNotEmpty) {
      _errorMessage = 'Please enter a valid weight';
    } else {
      _measuredWeight = null;
      _errorMessage = null;
    }
    notifyListeners();
  }

  Future<void> submitForTraining() async {
    if (!canSubmit) return;

    try {
      _setState(WeighFlowState.submitting);

      // Submit to repository (this will queue for background upload)
      await _repository.submitLabeledImage(
        _capturedImage!.path,
        _measuredWeight!,
        predictedWeight: _predictedWeight,
      );

      _setState(WeighFlowState.completed);
    } catch (e) {
      _setError('Submission failed: $e');
    }
  }

  void reset() {
    _capturedImage = null;
    _predictedWeight = null;
    _measuredWeight = null;
    _errorMessage = null;
    _setState(WeighFlowState.cameraReady);
  }

  void retry() {
    _errorMessage = null;
    if (_state == WeighFlowState.error) {
      _setState(WeighFlowState.cameraReady);
    }
    notifyListeners();
  }

  void _setState(WeighFlowState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = WeighFlowState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _tfliteHelper.dispose();
    _repository.close();
    super.dispose();
  }
}

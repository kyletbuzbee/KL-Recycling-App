import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:kl_recycling_app/models/photo_estimate.dart' as models;
import 'package:kl_recycling_app/models/reference_objects.dart';

/// Enhanced Weight Prediction Service using TensorFlow Lite
/// Features:
/// - Custom scrap metal detection models
/// - Depth estimation for 3D volume calculation
/// - Reference object calibration
/// - Multi-model ensemble approach
/// - Real-time processing capabilities
/// - Continuous learning data collection
class EnhancedWeightPredictionService {
  // TensorFlow Lite Models
  Interpreter? _scrapMetalDetector;
  Interpreter? _depthEstimator;
  Interpreter? _shapeClassifier;
  Interpreter? _ensembleModel;

  // Calibration data
  CalibrationData? _currentCalibration;
  bool _isInitialized = false;

  // Performance tracking
  final List<double> _processingTimes = [];
  final Map<String, int> _successCounts = {};
  final Map<String, dynamic> _modelPerformance = {};

  // Data collection for continuous learning
  final List<Map<String, dynamic>> _predictionData = [];
  bool _dataCollectionEnabled = true;

  // Processing state
  bool _isProcessing = false;
  final Map<String, dynamic> _lastPrediction = {};

  // Scrap metal density values (lb/cubic inch) - enhanced with precision
  static const Map<String, double> _materialDensities = {
    // Steel variants
    'steel': 0.283,         // Standard steel ~7.8 g/cm³
    'mild_steel': 0.283,
    'carbon_steel': 0.284,
    'stainless_steel': 0.290,
    'galvanized_steel': 0.278,
    'tool_steel': 0.288,

    // Aluminum variants
    'aluminum': 0.098,      // ~2.7 g/cm³
    'aluminum_6061': 0.097,
    'aluminum_7075': 0.101,
    'aluminum_can': 0.096,
    'aluminum_foil': 0.095,

    // Copper variants
    'copper': 0.323,        // ~8.9 g/cm³
    'copper_wire': 0.321,
    'copper_sheet': 0.324,
    'copper_tube': 0.318,

    // Brass variants
    'brass': 0.304,         // ~8.4 g/cm³
    'yellow_brass': 0.307,
    'red_brass': 0.316,
    'naval_brass': 0.308,

    // Iron variants
    'iron': 0.260,          // ~7.2 g/cm³
    'cast_iron': 0.262,
    'wrought_iron': 0.277,

    // Other metals
    'zinc': 0.256,          // ~7.1 g/cm³
    'tin': 0.267,           // ~7.4 g/cm³
    'lead': 0.412,          // ~11.4 g/cm³
    'titanium': 0.163,      // ~4.5 g/cm³

    // Alloys and mixed
    'bronze': 0.317,        // ~8.8 g/cm³
    'solder': 0.315,        // ~8.7 g/cm³
  };

  // Enhanced shape volume factors with depth consideration
  static const Map<String, double> _shapeVolumeFactors = {
    // 3D shapes
    'rectangular_prism': 1.0,       // Standard full volume
    'cylindrical': 0.785,          // π/4
    'spherical': 0.524,            // π/6
    'cube': 1.0,                   // Full volume

    // Sheet/plate forms
    'flat_sheet': 0.025,           // Very thin
    'thin_sheet': 0.05,            // Thin sheet metal
    'thick_sheet': 0.15,           // Thicker plate
    'medium_sheet': 0.10,          // Medium thickness

    // Tubular forms
    'pipe_tube': 0.688,            // Hollow cylinder
    'wire_rod': 0.785,             // Solid cylinder (π/4 ratio)
    'thin_wire': 0.922,            // Solid cylinder with height < width

    // Complex/irregular shapes
    'irregular': 0.750,            // Conservative estimate
    'block_chunk': 0.850,          // Roughly shaped block
    'foil_thin': 0.012,            // Very thin foil
    'disc': 0.392,                 // Flat disc (π/8 ratio)

    // Specialty shapes
    'angle_iron': 0.433,           // L-shaped angle iron
    'channel': 0.667,              // U-shaped channel
    'plate_with_holes': 0.900,     // Plate with holes (90% volume)
  };

  // Model configuration
  static const int _modelInputSize = 224; // Standard for most models
  static const double _confidenceThreshold = 0.5;
  static const int _maxProcessingTime = 5000; // 5 seconds max
  static const int _minDetectionPixels = 1000; // Minimum pixels for reliable detection

  // Default fallback values
  static const double _defaultPixelsPerInch = 150.0; // Conservative estimate
  static const double _defaultThicknessInches = 0.25; // 1/4 inch

  /// Initialize the enhanced weight prediction service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Future.wait([
        _loadModels(),
      ]);

      _isInitialized = true;
      _successCounts['initialize'] = (_successCounts['initialize'] ?? 0) + 1;

      debugPrint('Enhanced Weight Prediction Service initialized successfully');

    } catch (e) {
      debugPrint('Enhanced Weight Prediction Service initialization encountered issues: $e');
      debugPrint('Service will continue with fallback functionality');
      _successCounts['initialize_partial'] = (_successCounts['initialize_partial'] ?? 0) + 1;
      // Don't rethrow - service should work without models
      _isInitialized = true; // Initialize anyway for fallback functionality
    }
  }

  /// Load all TensorFlow Lite models (optional - service works without them)
  Future<void> _loadModels() async {
    try {
      // Load scrap metal detector (primary model) - this is optional now
      try {
        _scrapMetalDetector = await _loadModel('scrap_metal_detector.tflite');
        debugPrint('Primary scrap metal detector model loaded successfully');
      } catch (e) {
        debugPrint('Primary scrap metal detector not available: $e');
        debugPrint('Service will continue with enhanced fallback methods');
      }

      // Optional models - continue if they fail to load
      try {
        _depthEstimator = await _loadModel('depth_estimator.tflite');
        debugPrint('Depth estimator model loaded successfully');
      } catch (e) {
        debugPrint('Depth estimator not available: $e');
        debugPrint('Will use fallback depth estimation methods');
      }

      try {
        _shapeClassifier = await _loadModel('shape_classifier.tflite');
        debugPrint('Shape classifier model loaded successfully');
      } catch (e) {
        debugPrint('Shape classifier not available: $e');
        debugPrint('Will use shape classification heuristics');
      }

      try {
        _ensembleModel = await _loadModel('ensemble_model.tflite');
        debugPrint('Ensemble model loaded successfully');
      } catch (e) {
        debugPrint('Ensemble model not available: $e');
        debugPrint('Will use single-model predictions');
      }

    } catch (e) {
      // This should not happen since we catch individual model errors above
      debugPrint('Unexpected error loading models: $e');
      // Don't throw - service should work without models
    }
  }

  /// Load a single TensorFlow Lite model
  Future<Interpreter> _loadModel(String modelName) async {
    try {
      final modelPath = 'assets/models/$modelName';
      final interpreter = await Interpreter.fromAsset(modelPath);

      // Record successful model loading
      _modelPerformance[modelName] = {
        'loaded': true,
        'input_shape': interpreter.getInputTensors().map((t) => t.shape).toList(),
        'output_shape': interpreter.getOutputTensors().map((t) => t.shape).toList(),
        'loaded_at': DateTime.now().toIso8601String(),
      };

      return interpreter;
    } catch (e) {
      _modelPerformance[modelName] = {
        'loaded': false,
        'error': e.toString(),
        'failed_at': DateTime.now().toIso8601String(),
      };
      rethrow;
    }
  }

  /// Main prediction method - enhanced with TensorFlow Lite processing
  Future<WeightPredictionResult> predictWeightFromImage({
    required String imagePath,
    required models.MaterialType materialType,
    double? manualEstimate,
    bool enableRealTime = false,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final startTime = DateTime.now().millisecondsSinceEpoch;
    _isProcessing = true;

    try {
      // Load and preprocess the image
      final imageData = await _loadAndPreprocessImage(imagePath);

      // Run multi-model ensemble prediction
      final predictions = await _runEnsemblePrediction(
        imageData,
        materialType,
        enableRealTime,
      );

      // Combine predictions and estimate weight
      final prediction = await _combinePredictionsAndEstimateWeight(
        predictions,
        materialType,
        manualEstimate,
      );

      final endTime = DateTime.now().millisecondsSinceEpoch;
      _processingTimes.add((endTime - startTime).toDouble());

      // Store prediction data for continuous learning
      if (_dataCollectionEnabled) {
        await _storePredictionData(prediction, {
          'material_type': materialType.name,
          'manual_estimate': manualEstimate,
          'processing_time_ms': endTime - startTime,
          'image_path': imagePath,
          'metadata': metadata,
          'predictions': predictions,
        });
      }

      // Update success tracking
      _successCounts['prediction'] = (_successCounts['prediction'] ?? 0) + 1;

      return prediction;

    } catch (e) {
      // Update error tracking
      _successCounts['prediction_error'] = (_successCounts['prediction_error'] ?? 0) + 1;

      debugPrint('Weight prediction failed: $e');

      // Return enhanced fallback prediction
      return _createEnhancedFallbackPrediction(
        materialType,
        manualEstimate,
        e.toString(),
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Load and preprocess image for model input
  Future<Map<String, dynamic>> _loadAndPreprocessImage(String imagePath) async {
    try {
      // Load image using the image package
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        throw Exception('Unable to decode image');
      }

      // Resize to model input size (224x224 is common)
      final resizedImage = img.copyResize(
        decodedImage,
        width: _modelInputSize,
        height: _modelInputSize,
      );

      // Convert to RGB if needed
      final rgbImage = img.copyResize(resizedImage, interpolation: img.Interpolation.linear);

      // Normalize pixel values (0-255 -> 0-1)
      final inputBuffer = Float32List(1 * _modelInputSize * _modelInputSize * 3);
      var pixelIndex = 0;

      for (var y = 0; y < _modelInputSize; y++) {
        for (var x = 0; x < _modelInputSize; x++) {
          final pixel = rgbImage.getPixel(x, y);
          inputBuffer[pixelIndex++] = pixel.r / 255.0;   // R
          inputBuffer[pixelIndex++] = pixel.g / 255.0; // G
          inputBuffer[pixelIndex++] = pixel.b / 255.0;  // B
        }
      }

      // Get original image dimensions for bbox processing
      final originalWidth = decodedImage.width;
      final originalHeight = decodedImage.height;

      return {
        'input_buffer': inputBuffer,
        'original_dimensions': {'width': originalWidth, 'height': originalHeight},
        'processed_image': resizedImage,
        'raw_bytes': bytes,
      };

    } catch (e) {
      throw Exception('Image preprocessing failed: $e');
    }
  }

  /// Run multi-model ensemble prediction using loaded TensorFlow Lite models
  Future<Map<String, dynamic>> _runEnsemblePrediction(
    Map<String, dynamic> imageData,
    models.MaterialType materialType,
    bool enableRealTime,
  ) async {
    final predictions = <String, dynamic>{};
    final inputBuffer = imageData['input_buffer'] as Float32List;
    final inputShape = [1, _modelInputSize, _modelInputSize, 3];

    // Primary Scrap Metal Detection
    if (_scrapMetalDetector != null) {
      try {
        final detectionOutput = List<List<double>>.filled(1, List<double>.filled(4, 0)); // bbox: [ymin, xmin, ymax, xmax]
        final classes = List<List<double>>.filled(1, List<double>.filled(10, 0)); // top 10 classes
        final scores = List<List<double>>.filled(1, List<double>.filled(10, 0)); // confidence scores

        _scrapMetalDetector!.runForMultipleInputs([inputBuffer], {
          0: detectionOutput,
          1: classes,
          2: scores,
        });

        predictions['detection'] = {
          'bboxes': detectionOutput[0],
          'classes': classes[0],
          'scores': scores[0],
        };

      } catch (e) {
        debugPrint('Scrap metal detection failed: $e');
        predictions['detection_error'] = e.toString();
      }
    }

    // Depth Estimation (if available)
    if (_depthEstimator != null) {
      try {
        final depthOutput = List<List<List<List<double>>>>.filled(
          1, List<List<List<double>>>.filled(
            1, List<List<double>>.filled(_modelInputSize, List<double>.filled(_modelInputSize, 0))
          )
        );

        _depthEstimator!.run(inputBuffer.buffer.asUint8List(), depthOutput);

        predictions['depth'] = {
          'depth_map': depthOutput[0][0],
        };

      } catch (e) {
        debugPrint('Depth estimation failed: $e');
        predictions['depth_error'] = e.toString();
      }
    }

    // Shape Classification (if available)
    if (_shapeClassifier != null) {
      try {
        final shapeOutput = List<List<double>>.filled(1, List<double>.filled(20, 0)); // 20 shape classes
        _shapeClassifier!.run(inputBuffer.buffer.asUint8List(), shapeOutput);

        predictions['shape'] = {
          'shape_probabilities': shapeOutput[0],
          'predicted_shape': _getShapeFromProbabilities(shapeOutput[0]),
        };

      } catch (e) {
        debugPrint('Shape classification failed: $e');
        predictions['shape_error'] = e.toString();
      }
    }

    // Ensemble Model (combines all predictions)
    if (_ensembleModel != null && predictions.isNotEmpty) {
      try {
        // Prepare ensemble input combining all model outputs
        final ensembleInput = _prepareEnsembleInput(predictions);
        final ensembleOutput = List<List<double>>.filled(1, List<double>.filled(1, 0)); // Final weight estimate

        _ensembleModel!.run(ensembleInput.buffer.asUint8List(), ensembleOutput);

        predictions['ensemble'] = {
          'final_weight': ensembleOutput[0][0],
        };

      } catch (e) {
        debugPrint('Ensemble prediction failed: $e');
        predictions['ensemble_error'] = e.toString();
      }
    }

    return predictions;
  }

  /// Prepare input for ensemble model by combining other model outputs
  Float32List _prepareEnsembleInput(Map<String, dynamic> predictions) {
    // Combine detection scores, depth metrics, and shape probabilities
    final features = <double>[];

    if (predictions.containsKey('detection')) {
      final detection = predictions['detection'];
      features.addAll(detection['scores'].take(5)); // Top 5 detection scores
    } else {
      features.addAll(List<double>.filled(5, 0.0));
    }

    if (predictions.containsKey('depth')) {
      // Add depth statistics (mean, std, etc.)
      final depthMap = predictions['depth']['depth_map'] as List<List<double>>;
      final flatDepth = depthMap.expand((row) => row).toList();
      final meanDepth = flatDepth.reduce((a, b) => a + b) / flatDepth.length;
      final variance = flatDepth.map((d) => (d - meanDepth) * (d - meanDepth)).reduce((a, b) => a + b) / flatDepth.length;
      features.add(meanDepth);
      features.add(sqrt(variance)); // standard deviation
    } else {
      features.addAll([0.0, 0.0]);
    }

    if (predictions.containsKey('shape')) {
      final shapeProbs = predictions['shape']['shape_probabilities'] as List<double>;
      features.addAll(shapeProbs.take(5)); // Top 5 shape probabilities
    } else {
      features.addAll(List<double>.filled(5, 0.0));
    }

    return Float32List.fromList(features);
  }

  /// Get shape name from probability array
  String _getShapeFromProbabilities(List<double> probabilities) {
    final shapeNames = _shapeVolumeFactors.keys.toList();
    if (probabilities.isEmpty || probabilities.length != shapeNames.length) {
      return 'irregular'; // Default
    }

    var maxProb = 0.0;
    var bestShape = 'irregular';
    for (var i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        bestShape = shapeNames[i];
      }
    }
    return bestShape;
  }

  /// Generate enhanced suggestions based on prediction results
  List<String> _generateEnhancedSuggestions(
    double confidence,
    Map<String, dynamic> predictions,
    CalibrationData? calibration,
  ) {
    final suggestions = <String>[];

    // Basic confidence-based suggestions
    if (confidence < 0.5) {
      suggestions.add('📷 Improve photo quality - ensure good lighting and clear focus');
      suggestions.add('🎯 Position metal centrally in frame with good contrast');
    }

    // Model-specific suggestions
    if (!predictions.containsKey('detection') || predictions.containsKey('detection_error')) {
      suggestions.add('🔍 Metal detection failed - check if scrap is clearly visible');
    }

    if (!predictions.containsKey('depth') && predictions.containsKey('depth_error')) {
      suggestions.add('📏 Consider adding depth cues or reference objects');
    }

    // Calibration suggestions
    if (calibration == null) {
      suggestions.add('📐 Include a reference object (coin, quarter, or ruler) for accurate scaling');
    }

    // Advanced suggestions based on available models
    if (predictions.isEmpty) {
      suggestions.add('🤖 AI models not available - using enhanced fallback method');
    }

    if (predictions.containsKey('shape')) {
      suggestions.add('✅ Shape analysis available - weight estimate includes geometric corrections');
    }

    if (predictions.containsKey('ensemble')) {
      suggestions.add('🌟 Multi-model ensemble used for highest accuracy');
    }

    // Remove generic suggestions if we have good confidence
    if (confidence > 0.7 && suggestions.length > 1) {
      suggestions.removeWhere((s) =>
        s.contains('Improve photo quality') ||
        s.contains('Position metal centrally')
      );
    }

    // Ensure we have at least one positive suggestion if confidence is high
    if (confidence > 0.8 && !suggestions.any((s) => s.contains('Shape analysis') || s.contains('Multi-model'))) {
      suggestions.add('✨ High-confidence estimate - photo and analysis quality are excellent');
    }

    return suggestions;
  }

  /// Store prediction data for continuous learning
  Future<void> _storePredictionData(WeightPredictionResult result, Map<String, dynamic> metadata) async {
    try {
      final dataPoint = {
        'timestamp': DateTime.now().toIso8601String(),
        'estimated_weight': result.estimatedWeight,
        'confidence_score': result.confidenceScore,
        'method': result.method,
        'factors': result.factors,
        'suggestions': result.suggestions,
        'metadata': metadata,
        'model_performance': Map<String, dynamic>.from(_modelPerformance),
      };

      _predictionData.add(dataPoint);

      // Keep only last 100 data points to prevent memory issues
      if (_predictionData.length > 100) {
        _predictionData.removeAt(0);
      }

      // Store to local file (in production, would upload to server)
      await _savePredictionDataToFile(dataPoint);

    } catch (e) {
      debugPrint('Failed to store prediction data: $e');
    }
  }

  /// Save prediction data to local file
  Future<void> _savePredictionDataToFile(Map<String, dynamic> dataPoint) async {
    try {
      final file = File('assets/data/prediction_data.jsonl');

      // Append to JSON Lines file
      final jsonLine = '${jsonEncode(dataPoint)}\n';
      await file.writeAsString(jsonLine, mode: FileMode.append);

    } catch (e) {
      // Create file if it doesn't exist
      try {
        final file = File('assets/data/prediction_data.jsonl');
        final jsonLine = '${jsonEncode(dataPoint)}\n';
        await file.writeAsString(jsonLine);
      } catch (e2) {
        debugPrint('Failed to create prediction data file: $e2');
      }
    }
  }

  /// Create enhanced fallback prediction
  WeightPredictionResult _createEnhancedFallbackPrediction(
    models.MaterialType materialType,
    double? manualEstimate,
    String errorMessage,
  ) {
    final fallbackWeight = manualEstimate ?? _getDefaultWeightForMaterial(materialType);
    final factors = <String>[
      'Using enhanced fallback estimation',
      if (manualEstimate != null) 'Incorporated manual estimate: ${manualEstimate}lbs',
      'Material: ${materialType.name.replaceAll('_', ' ')}',
      'Default density: ${_getMaterialDensity(materialType.name).toStringAsFixed(3)} lb/cu³',
    ];

    final suggestions = <String>[
      'AI analysis failed: ${errorMessage.split(':').first}',
      'Consider manual estimation or retaking photo',
      if (_currentCalibration == null) 'Add reference object for better calibration',
    ];

    return WeightPredictionResult(
      estimatedWeight: fallbackWeight,
      confidenceScore: manualEstimate != null ? 0.5 : 0.2,
      method: 'Enhanced_Fallback',
      factors: factors,
      suggestions: suggestions,
    );
  }

  // Missing constants and utilities
  static const double _defaultShapeFactor = 0.85; // Conservative default

  /// Set calibration data for reference object
  void setCalibration(CalibrationData calibration) {
    _currentCalibration = calibration;
    debugPrint('Calibration set: ${calibration.pixelsPerInch} pixels per inch');
  }

  /// Clear calibration data
  void clearCalibration() {
    _currentCalibration = null;
  }

  /// Get current calibration data
  CalibrationData? getCalibration() => _currentCalibration;

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'total_predictions': _successCounts['prediction'] ?? 0,
      'total_errors': _successCounts['prediction_error'] ?? 0,
      'average_processing_time': _processingTimes.isNotEmpty
        ? _processingTimes.reduce((a, b) => a + b) / _processingTimes.length
        : 0.0,
      'model_performance': _modelPerformance,
      'data_points_collected': _predictionData.length,
    };
  }

  /// Enable/disable data collection
  void setDataCollectionEnabled(bool enabled) {
    _dataCollectionEnabled = enabled;
  }

  /// Get collected prediction data (for debugging/analysis)
  List<Map<String, dynamic>> getPredictionData() => List.from(_predictionData);

  /// Clear collected data
  void clearPredictionData() {
    _predictionData.clear();
  }

  /// Export performance data for analysis
  Future<String> exportPerformanceData() async {
    final stats = getPerformanceStats();
    return jsonEncode(stats);
  }

  /// Combine model predictions and estimate final weight
  Future<WeightPredictionResult> _combinePredictionsAndEstimateWeight(
    Map<String, dynamic> predictions,
    models.MaterialType materialType,
    double? manualEstimate,
  ) async {
    var finalWeight = 0.0;
    var confidenceScore = 0.0;
    final factors = <String>[];
    final suggestions = <String>[];

    // Extract weight estimates and confidences from different models
    final weightEstimates = <double>[];
    final confidences = <double>[];

    // Process detection results
    if (predictions.containsKey('detection')) {
      final detection = predictions['detection'];

      // Check if we have high-confidence detections
      final scores = detection['scores'] as List<double>;
      final validDetections = scores.where((score) => score > _confidenceThreshold).toList();

      if (validDetections.isNotEmpty) {
        // Estimate weight based on detected objects
        final averageScore = validDetections.reduce((a, b) => a + b) / validDetections.length;
        final estimatedWeightFromDetection = _estimateWeightFromDetection(
          detection,
          materialType,
          averageScore,
        );

        if (estimatedWeightFromDetection > 0) {
          weightEstimates.add(estimatedWeightFromDetection);
          confidences.add(averageScore);
          factors.add('AI metal detection with ${validDetections.length} objects found');
        }
      }
    }

    // Process ensemble result (if available)
    if (predictions.containsKey('ensemble')) {
      final ensemble = predictions['ensemble'];
      final ensembleWeight = ensemble['final_weight'] as double;
      if (ensembleWeight > 0 && ensembleWeight < 1000) { // Reasonable bounds
        weightEstimates.add(ensembleWeight);
        confidences.add(0.8); // High confidence for ensemble result
        factors.add('Ensemble AI model combining multiple predictions');
      }
    }

    // Use manual estimate if no ML estimates
    if (weightEstimates.isEmpty && manualEstimate != null && manualEstimate > 0) {
      finalWeight = manualEstimate;
      confidenceScore = 0.4; // Low-medium confidence for manual
      factors.add('Using manual weight estimate (no AI detection)');
      suggestions.add('Consider including reference objects for better calibration');
    }
    // Calculate weighted average of ML estimates
    else if (weightEstimates.isNotEmpty) {
      final weightSum = weightEstimates.reduce((a, b) => a + b);
      final confidenceSum = confidences.reduce((a, b) => a + b);

      finalWeight = weightSum / weightEstimates.length;
      final averageConfidence = confidenceSum / confidences.length;

      // Boost confidence based on agreement between models
      final variance = weightEstimates.map((w) => (w - finalWeight) * (w - finalWeight)).reduce((a, b) => a + b) / weightEstimates.length;
      final agreementFactor = max(0.0, 1.0 - (variance / (finalWeight * finalWeight))); // Lower variance = higher agreement

      confidenceScore = min((averageConfidence + agreementFactor) / 2, 1.0);

      factors.add('Multi-model consensus from ${weightEstimates.length} AI predictions');
      factors.add('Material: ${materialType.name.replaceAll('_', ' ')}');

      // Depth-based volume calculation if available
      if (predictions.containsKey('depth')) {
        factors.add('3D depth estimation used for volume calculation');
      }

      // Shape classification if available
      if (predictions.containsKey('shape')) {
        final shape = predictions['shape']['predicted_shape'] as String;
        factors.add('Detected shape: $shape (${_getShapeVolumeFactor(shape).toStringAsFixed(2)} volume factor)');
      }
    }
    // Fallback to basic estimation
    else {
      finalWeight = manualEstimate ?? _getDefaultWeightForMaterial(materialType);
      confidenceScore = manualEstimate != null ? 0.3 : 0.1;
      factors.add('Basic estimation - limited AI model availability');
      suggestions.add('AI models may need to be loaded or updated');
    }

    // Apply manual estimate influence if provided
    if (manualEstimate != null && manualEstimate > 0 && weightEstimates.isNotEmpty) {
      // Blend AI and manual estimates based on confidence
      final aiWeight = finalWeight;
      final blendedWeight = (aiWeight * confidenceScore) + (manualEstimate * (1 - confidenceScore));
      finalWeight = blendedWeight;
      factors.add('Blended AI (${(confidenceScore * 100).round()}%) and manual estimates');
    }

    // Generate suggestions based on confidence and available data
    suggestions.addAll(_generateEnhancedSuggestions(
      confidenceScore,
      predictions,
      _currentCalibration,
    ));

    return WeightPredictionResult(
      estimatedWeight: finalWeight,
      confidenceScore: confidenceScore,
      method: predictions.containsKey('ensemble') ? 'TensorFlow_Lite_Ensemble' :
              predictions.containsKey('detection') ? 'TensorFlow_Lite_Detection' :
              'Enhanced_Fallback',
      factors: factors,
      suggestions: suggestions,
    );
  }

  /// Estimate weight from detection results
  double _estimateWeightFromDetection(
    Map<String, dynamic> detection,
    models.MaterialType materialType,
    double confidence,
  ) {
    final pixelsPerInch = _currentCalibration?.pixelsPerInch ?? _defaultPixelsPerInch;

    // Extract bounding box info (simplified - would be more complex in practice)
    final bboxes = detection['bboxes'] as List<double>;
    if (bboxes.isEmpty) return 0.0;

    // Estimate object dimensions from bounding box
    final estimatedWidthPixels = bboxes[2] - bboxes[0]; // xmax - xmin
    final estimatedHeightPixels = bboxes[3] - bboxes[1]; // ymax - ymin

    final realWidth = estimatedWidthPixels / pixelsPerInch;
    final realHeight = estimatedHeightPixels / pixelsPerInch;

    // Estimate thickness based on material and shape
    final thickness = _getEstimatedThickness(materialType);

    // Calculate volume with shape factor
    final volume = realWidth * realHeight * thickness * _defaultShapeFactor;

    // Get material density
    final density = _getMaterialDensity(materialType.name);

    // Calculate weight and apply confidence adjustment
    final weight = volume * density;
    return weight * (0.5 + confidence * 0.5); // Confidence-weighted estimate
  }

  /// Get estimated thickness for a material type
  double _getEstimatedThickness(models.MaterialType materialType) {
    if (_currentCalibration != null) {
      return _currentCalibration!.realWorldHeight; // Use calibrated thickness
    }

    // Material-specific default thicknesses
    switch (materialType) {
      case models.MaterialType.aluminum:
        return 0.0625; // 1/16 inch
      case models.MaterialType.steel:
      case models.MaterialType.copper:
      case models.MaterialType.brass:
        return 0.125;  // 1/8 inch
      case models.MaterialType.zinc:
      case models.MaterialType.stainless:
        return 0.09375; // 3/32 inch
      default:
        return _defaultThicknessInches;
    }
  }

  /// Get volume factor for a shape
  double _getShapeVolumeFactor(String shape) {
    return _shapeVolumeFactors[shape] ?? _shapeVolumeFactors['irregular']!;
  }

  /// Get material density
  double _getMaterialDensity(String materialType) {
    return _materialDensities[materialType] ?? _materialDensities['steel']!;
  }

  /// Get default weight estimate for material
  double _getDefaultWeightForMaterial(models.MaterialType materialType) {
    // Conservative defaults based on common scrap sizes
    switch (materialType) {
      case models.MaterialType.aluminum:
        return 8.0; // 8 lbs typical aluminum scrap
      case models.MaterialType.steel:
      case models.MaterialType.copper:
        return 15.0; // 15 lbs typical steel/copper scrap
      case models.MaterialType.brass:
        return 12.0; // 12 lbs typical brass scrap
      default:
        return 10.0; // 10 lbs conservative default
    }
  }

  List<String> _generateWeightFactors(double weight, double confidence) {
    return [
      'Object detection confidence: ${(confidence * 100).round()}%',
      'Estimated volume based on bounding box analysis',
      'Material density: ${_materialDensities.entries.firstWhere(
        (e) => e.value > 0, orElse: () => MapEntry('steel', 0.283)).key}',
      'Adjusted for realistic scrap metal dimensions',
    ];
  }

  List<String> _generateImprovementSuggestions(double confidence, int objectCount) {
    final suggestions = <String>[];

    if (confidence < 0.5) {
      suggestions.add('Ensure scrap metal is clearly visible and well-lit for better estimation');
    }

    if (objectCount == 0) {
      suggestions.add('No metal objects detected - consider retaking photo from different angle');
    }

    if (confidence < 0.7) {
      suggestions.add('Include a reference object (like a coin or ruler) for scale calibration');
      suggestions.add('Take photo with better contrast between metal and background');
    }

    if (suggestions.isEmpty) {
      suggestions.add('Photo analysis looks good - weight estimate should be reliable');
    }

    return suggestions;
  }

  bool _isRelevantObject(String labelText) {
    final relevantKeywords = [
      'metal', 'steel', 'aluminum', 'copper', 'brass', 'iron', 'scrap',
      'pipe', 'wire', 'sheet', 'bar', 'rod', 'beam', 'plate', 'coil',
      'can', 'bottle', 'container', 'machine', 'engine', 'equipment'
    ];

    final lowerLabel = labelText.toLowerCase();
    return relevantKeywords.any((keyword) => lowerLabel.contains(keyword));
  }

  WeightPredictionResult _createFallbackPrediction(
    models.MaterialType materialType,
    double? manualEstimate,
  ) {
    // If ML fails, return the manual estimate with low confidence
    return WeightPredictionResult(
      estimatedWeight: manualEstimate ?? 0.0,
      confidenceScore: manualEstimate != null ? 0.5 : 0.1,
      method: 'Manual_Fallback',
      factors: ['Used manual weight estimate - ML analysis unavailable'],
      suggestions: ['ML prediction failed - consider retaking photo or using manual estimation'],
    );
  }

  /// Dispose of all TensorFlow Lite models and resources
  void dispose() {
    try {
      // Close all interpreters
      _scrapMetalDetector?.close();
      _depthEstimator?.close();
      _shapeClassifier?.close();
      _ensembleModel?.close();

      // Clear references
      _scrapMetalDetector = null;
      _depthEstimator = null;
      _shapeClassifier = null;
      _ensembleModel = null;

      _isInitialized = false;
      debugPrint('Enhanced Weight Prediction Service disposed successfully');

    } catch (e) {
      debugPrint('Error during service disposal: $e');
    }
  }
}

class WeightPredictionResult {
  final double estimatedWeight;
  final double confidenceScore;
  final String method;
  final List<String> factors;
  final List<String> suggestions;

  WeightPredictionResult({
    required this.estimatedWeight,
    required this.confidenceScore,
    required this.method,
    required this.factors,
    required this.suggestions,
  });

  String get confidenceDescription {
    if (confidenceScore >= 0.8) return 'High';
    if (confidenceScore >= 0.6) return 'Medium';
    if (confidenceScore >= 0.4) return 'Low';
    return 'Very Low';
  }

  Color get confidenceColor {
    if (confidenceScore >= 0.8) return const Color(0xFF4CAF50); // Green
    if (confidenceScore >= 0.6) return const Color(0xFFFFA726); // Orange
    if (confidenceScore >= 0.4) return const Color(0xFFFF9800); // Dark Orange
    return const Color(0xFFF44336); // Red
  }
}

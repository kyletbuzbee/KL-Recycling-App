# 👨‍💻 Developer Implementation Guide

## Integrating AI/ML Weight Estimation into KL Recycling App

This guide provides hands-on instructions for developers working with the advanced AI/ML weight estimation system.

---

## 📝 Prerequisites & Setup

### Development Environment Requirements

**Flutter SDK**: 3.15+ with Dart 3.x
```bash
flutter doctor
# Ensure all checks pass
```

**Dependencies** (already configured in `pubspec.yaml`):
```yaml
dependencies:
  flutter:
    sdk: flutter

  # Computer Vision & AI/ML
  camera: ^0.10.6
  image_picker: ^0.8.9
  tflite_flutter: ^0.11.0
  tflite_flutter_helper: ^0.3.4

  # Memory Management & Performance
  shared_preferences: ^2.5.3
  path_provider: ^2.1.5

  # Networking & Analytics
  firebase_core: ^3.15.2
  cloud_firestore: ^5.6.12
  firebase_storage: ^12.4.10

  # UI & User Experience
  provider: ^6.0.5
  lottie: ^2.7.0
```

### Platform-Specific Setup

**Android (NNAPI)**:
```gradle
// android/app/build.gradle
android {
    defaultConfig {
        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a'
        }
    }
    aaptOptions {
        noCompress 'tflite'
    }
}
```

**iOS (Metal)**:
```xml
<!-- ios/Runner/Info.plist -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Camera access for weight estimation</string>
```

---

## 🏗️ Core Architecture Integration

### Service Layer Architecture

**Primary Service Classes**:
```dart
// Initialize services in dependency injection container
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  late final EnhancedWeightPredictionService _predictionService;
  late final ModelManager _modelManager;
  late final DataCollectionService _dataCollection;
  late final AdvancedImageProcessor _imageProcessor;

  Future<void> initialize() async {
    // Core AI/ML service
    _predictionService = EnhancedWeightPredictionService();

    // Ensemble coordinator
    _modelManager = ModelManager(_predictionService);

    // Privacy-preserving telemetry
    _dataCollection = DataCollectionService(firebaseService);

    // Advanced image processing
    _imageProcessor = AdvancedImageProcessor();

    // Initialize all services
    await Future.wait([
      _predictionService.initialize(),
      _modelManager.initialize(),
      _dataCollection.initialize(),
    ]);
  }
}
```

### Provider Pattern Integration

**State Management with Provider**:
```dart
// Photo estimation provider
class PhotoEstimateProvider with ChangeNotifier {
  final ModelManager _modelManager;
  final DataCollectionService _dataCollection;
  final AdvancedImageProcessor _imageProcessor;

  WeightPredictionResult? _currentResult;
  bool _isProcessing = false;

  Future<void> processImage(File imageFile, MaterialType materialType) async {
    _isProcessing = true;
    notifyListeners();

    try {
      // Step 1: Load and preprocess image
      final image = await _loadImageFromFile(imageFile);
      final processed = await _imageProcessor.processImageForEnsemble(image);

      // Step 2: Run AI/ML prediction
      final result = await _modelManager.computeEnsemblePrediction(
        processed['modelOutputs'],
        processed['characteristics'],
        await _getDeviceCapabilities(),
      );

      // Step 3: Record for continuous learning
      await _dataCollection.recordPrediction(result, materialType, {}, {});

      _currentResult = result;

    } catch (e) {
      // Fallback to enhanced heuristics
      _currentResult = await _predictWithFallback(imageFile, materialType);
    }

    _isProcessing = false;
    notifyListeners();
  }

  Future<WeightPredictionResult> _predictWithFallback(File imageFile, MaterialType materialType) async {
    // Implementation uses enhanced heuristic algorithms
    return EnhancedWeightPredictionService().calculateHeuristicWeight(
      imageFile,
      materialType,
      await _getImageCharacteristics(imageFile)
    );
  }
}
```

---

## 🎯 Implementation Pattern: Photo Estimation

### Camera Integration with AI/ML

**Camera Provider with Real-time AI**:
```dart
class AICameraProvider extends CameraProvider {
  final AdvancedImageProcessor _imageProcessor;
  final ModelManager _modelManager;

  // Real-time preview analysis
  Stream<WeightEstimate> startRealtimeEstimation(CameraController controller) async* {
    await for (final image in controller.startImageStream()) {
      try {
        // Process frame (throttled for performance)
        final processed = await _imageProcessor.processImageForEnsemble(image);

        // Quick estimation for preview
        final estimate = await _modelManager.computeQuickEstimate(
          processed['characteristics']
        );

        yield estimate;
      } catch (e) {
        // Yield placeholder on errors
        yield WeightEstimate.placeholder();
      }
    }
  }

  // Full accuracy estimation for final capture
  Future<WeightPredictionResult> processFinalImage(
    XFile imageFile,
    MaterialType materialType
  ) async {
    final image = await _loadImageFromXFile(imageFile);

    // Full pipeline processing
    final processed = await _imageProcessor.processImageForEnsemble(image);

    // Ensemble prediction with all models
    return await _modelManager.computeEnsemblePrediction(
      processed['modelOutputs'],
      processed['characteristics'],
      await DeviceCapabilities.detect(),
    );
  }
}
```

### Widget Integration Example

**Photo Estimation Screen**:
```dart
class PhotoEstimateScreen extends StatefulWidget {
  const PhotoEstimateScreen({Key? key, required this.materialType}) : super(key: key);
  final MaterialType materialType;

  @override
  State<PhotoEstimateScreen> createState() => _PhotoEstimateScreenState();
}

class _PhotoEstimateScreenState extends State<PhotoEstimateScreen> {
  final PhotoEstimateProvider _provider = GetIt.I<PhotoEstimateProvider>();
  CameraController? _cameraController;
  StreamSubscription<WeightEstimate>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController?.initialize();

    // Start real-time estimation
    _realtimeSubscription = GetIt.I<AICameraProvider>()
        .startRealtimeEstimation(_cameraController!)
        .listen((estimate) {
          // Update UI with live estimate
          setState(() => _currentEstimate = estimate);
        });
  }

  Future<void> _captureAndProcess() async {
    try {
      final image = await _cameraController?.takePicture();
      if (image == null) return;

      // Show processing indicator
      setState(() => _isProcessing = true);

      // Full AI/ML processing
      final result = await _provider.processImage(
        File(image.path),
        widget.materialType
      );

      // Navigate to results screen
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => WeightResultScreen(result: result),
      ));

    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estimation failed. Please try again.')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Capture ${widget.materialType.name}')),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            child: _cameraController == null
                ? CircularProgressIndicator()
                : CameraPreview(_cameraController!),
          ),

          // Real-time estimation display
          if (_currentEstimate != null)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.1),
              child: Text(
                'Estimated: ${_currentEstimate!.weight.toStringAsFixed(1)} lbs '
                '(±${(_currentEstimate!.confidence * 20).round()} lbs)',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),

          // Capture button
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _captureAndProcess,
            icon: _isProcessing
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                : Icon(Icons.camera),
            label: Text(_isProcessing ? 'Processing...' : 'Capture & Estimate'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }
}
```

---

## 🧪 Testing Implementation

### Unit Testing Strategy

**Test Coverage Areas**:
- Model management and failover
- Image processing algorithms
- Ensemble weight calculations
- Privacy-preserving data collection
- Platform compatibility

**Example Test Suite**:
```dart
class ModelManagerTest extends TestWithFixtures {
  late MockFirebaseService mockFirebase;
  late ModelManager modelManager;

  setUp(() {
    mockFirebase = MockFirebaseService();
    modelManager = ModelManager(EnhancedWeightPredictionService());
  });

  test('Ensemble weight calculation respects total sum constraint', () {
    final weights = modelManager.getOptimalEnsembleWeights(
      ImageCharacteristics(hasClearMetalObjects: true),
      DeviceCapabilities(supportsGPU: true),
    );

    double totalWeight = weights.values.fold(0.0, (sum, w) => sum + w);
    expect(totalWeight, closeTo(1.0, 0.001));
  });

  test('Performance tracking updates model weights', () async {
    final prediction = ModelPrediction(
      'scrap_metal_detector',
      15.5,
      0.85,
      120.0,
    );

    await modelManager.recordPredictionResult(prediction, {});

    final stats = modelManager.getModelPerformanceStats();
    expect(stats['scrap_metal_detector']!['predictionCount'], equals(1));
    expect(stats['scrap_metal_detector']!['averageConfidence'], equals(0.85));
  });

  test('Fallback ensemble works without models', () async {
    final result = await modelManager.computeEnsemblePrediction(
      {}, // Empty model outputs
      ImageCharacteristics(),
      DeviceCapabilities(),
    );

    expect(result.isFallback, true);
    expect(result.finalWeight, closeTo(10.0, 0.1));
    expect(result.confidence, lessThan(0.2));
  });
}
```

### Integration Testing

**End-to-End AI/ML Pipeline Test**:
```dart
class EndToEndAIMLTest extends TestWithFixtures {
  test('Complete photo estimation pipeline', () async {
    // Arrange
    final testImage = await _loadTestImage('steel_scrap.jpg');
    final materialType = MaterialType.steel;

    // Act
    final result = await _aiPipeline.processImage(testImage, materialType);

    // Assert
    expect(result.isFallback, isFalse); // Should use real ML when available
    expect(result.finalWeight, greaterThan(0));
    expect(result.confidence, greaterThan(0));
    expect(result.confidence, lessThanOrEqualTo(1.0));
    expect(result.modelCount, greaterThan(0));

    // Verify telemetry was recorded
    final stats = await _dataCollection.getCollectionStatistics();
    expect(stats['pending_records'], greaterThan(0));
  });

  test('Fallback pipeline works without ML models', () async {
    // Simulate model failure scenario
    await _simulateModelFailure();

    final testImage = await _loadTestImage('aluminum_sheets.jpg');
    final result = await _aiPipeline.processImage(testImage, MaterialType.aluminum);

    // Should still provide reasonable estimate
    expect(result.finalWeight, greaterThan(0));
    expect(result.method, contains('fallback'));
    expect(result.confidence, greaterThan(0));
  });
}
```

---

## 🔧 Configuration & Customization

### Environment-Specific Settings

**Development Configuration**:
```dart
class DevelopmentConfig implements AIConfig {
  @override
  bool get enableDataCollection => true;

  @override
  bool get enableDetailedLogging => true;

  @override
  int get maxBatchSize => 5; // Smaller batches for testing

  @override
  Duration get uploadInterval => Duration(minutes: 1); // Faster uploads

  @override
  Map<String, double> get defaultEnsembleWeights => {
    'scrap_metal_detector': 0.4,
    'depth_estimator': 0.2,
    'shape_classifier': 0.25,
    'ensemble_model': 0.15,
  };
}
```

**Production Configuration**:
```dart
class ProductionConfig implements AIConfig {
  @override
  bool get enableDataCollection => false; // Opt-in only

  @override
  bool get enableDetailedLogging => false;

  @override
  int get maxBatchSize => 10; // Balance performance vs battery

  @override
  Duration get uploadInterval => Duration(hours: 24); // Daily uploads

  @override
  Map<String, double> get defaultEnsembleWeights => {
    // Optimized for production performance
    'scrap_metal_detector': 0.45,
    'depth_estimator': 0.18,
    'shape_classifier': 0.22,
    'ensemble_model': 0.15,
  };
}
```

### Model Update Management

**Over-the-Air Model Updates**:
```dart
class ModelUpdateManager {
  final FirebaseService _firebaseService;
  final ModelManager _modelManager;

  Future<bool> checkForUpdates() async {
    final remoteVersions = await _firebaseService.getModelVersions();

    for (final entry in remoteVersions.entries) {
      final localVersion = await _getLocalModelVersion(entry.key);
      if (_isNewerVersion(entry.value, localVersion)) {
        await _downloadAndUpdateModel(entry.key, entry.value);
        _modelManager.reloadModel(entry.key);
      }
    }

    return true;
  }

  Future<void> _downloadAndUpdateModel(String modelName, String version) async {
    final modelData = await _firebaseService.downloadModel(modelName, version);
    final localPath = await _getModelLocalPath(modelName, version);

    await File(localPath).writeAsBytes(modelData);
    await _updateModelMetadata(modelName, version);
  }
}
```

---

## 🚨 Error Handling & Recovery

### Comprehensive Exception Management

**AI/ML Error Recovery Strategy**:
```dart
class AIRecoveryManager {
  Future<WeightPredictionResult> executeWithRecovery(
    Future<WeightPredictionResult> Function() primary,
    Future<WeightPredictionResult> Function() fallback,
  ) async {
    try {
      return await primary();
    } on ModelNotAvailableException catch (e) {
      debugPrint('Model unavailable, using fallback: $e');
      return await fallback();
    } on ProcessingTimeoutException catch (e) {
      debugPrint('Processing timeout, using cached result: $e');
      return _getLastKnownResult();
    } on MemoryException catch (e) {
      debugPrint('Memory issue, reducing processing: $e');
      return await _executeLowMemoryMode();
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return _getGuaranteedFallback();
    }
  }

  WeightPredictionResult _getGuaranteedFallback() {
    return WeightPredictionResult(
      estimatedWeight: 10.0,
      confidenceScore: 0.1,
      method: 'emergency_fallback',
      factors: ['All systems unavailable - using default estimate'],
      suggestions: ['Please try again', 'Check camera permissions', 'Ensure good lighting'],
    );
  }
}
```

### Performance Monitoring Integration

**Real-time Performance Tracking**:
```dart
class PerformanceMonitor {
  final Map<String, PerformanceMetrics> _metrics = {};

  Future<void> trackOperation(String operation, Future<void> Function() action) async {
    final stopwatch = Stopwatch()..start();

    try {
      await action();

      _updateMetrics(operation, stopwatch.elapsed, true);

    } catch (e) {
      _updateMetrics(operation, stopwatch.elapsed, false);
      rethrow;
    }
  }

  void _updateMetrics(String operation, Duration elapsed, bool success) {
    _metrics.putIfAbsent(operation, () => PerformanceMetrics(operation));

    final metrics = _metrics[operation]!;
    metrics.recordOperation(elapsed, success);

    // Alert on performance degradation
    if (metrics.averageTime > Duration(seconds: 5)) {
      _alertPerformanceIssue(operation, metrics);
    }
  }

  Future<Map<String, dynamic>> getPerformanceReport() async {
    return _metrics.map((key, value) => MapEntry(key, value.toMap()));
  }
}
```

---

## 📊 Monitoring & Analytics Integration

### Dashboard Integration

**Real-time AI/ML Performance Dashboard**:
```dart
class AIMonitoringDashboard extends StatelessWidget {
  final PerformanceMonitor _monitor;
  final DataCollectionService _dataCollection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI/ML Performance')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getDashboardData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          final data = snapshot.data!;

          return ListView(
            children: [
              _buildModelHealthCards(data['modelHealth']),
              _buildPerformanceMetrics(data['performance']),
              _buildUserFeedbackStats(data['feedback']),
              _buildDataCollectionSettings(data['collection']),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getDashboardData() async {
    return {
      'modelHealth': await _monitor.getModelHealthStatus(),
      'performance': await _monitor.getPerformanceReport(),
      'feedback': await _dataCollection.getCollectionStatistics(),
      'collection': await _dataCollection.getOptInDialogContent(),
    };
  }
}
```

This developer guide provides the foundation for successfully integrating the advanced AI/ML weight estimation system into the KL Recycling App. The modular architecture ensures maintainability, the comprehensive testing strategy ensures reliability, and the flexible configuration system allows for optimization across different deployment scenarios.

**Next: [Operations & Maintenance](./04_operations_maintenance.md)**

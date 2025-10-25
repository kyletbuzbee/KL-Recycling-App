# AI Model Comparison Feature

This feature implements a side-by-side comparison between two AI models for scrap metal weight prediction:

## Models Being Tested

### Model A: ML Kit + Fallback Heuristics
- Uses Google ML Kit Object Detection for primary analysis
- Falls back to rule-based heuristics when ML fails
- Currently implemented in production

### Model B: Custom TensorFlow Lite Ensemble
- Custom-trained models: scrap_metal_detector + depth_estimator + shape_classifier + ensemble
- Domain-specific training on KL Recycling scrap metal data
- Advanced ensemble approach for higher accuracy

## Test Framework

This implementation provides tools to:
- Switch between models in real-time
- Measure inference time and accuracy
- Collect ground truth data for validation
- Generate comparison reports

## File Structure

```
lib/cline_generated/ai-model-comparison/
├── screen.dart                 # Main comparison UI screen
├── view_model.dart             # State management for comparison
├── repository.dart             # Data access and persistence
├── model_a_adapter.dart        # Adapter for ML Kit approach
├── model_b_adapter.dart        # Adapter for TFLite approach
└── performance_tracker.dart    # Metrics collection

test/cline_generated/ai-model-comparison/
├── model_comparison_test.dart  # Integration tests
├── model_a_adapter_test.dart   # Unit tests for Model A
├── model_b_adapter_test.dart   # Unit tests for Model B
└── performance_test.dart       # Performance benchmarks
```

## Important Packages

The feature uses these existing project dependencies:
- `camera: ^0.10.5+9` - For photo capture
- `tflite_flutter: ^0.10.1` - For TFLite model inference
- `google_mlkit_object_detection: ^0.12.0` - For ML Kit detection
- `sqflite: ^2.3.0` - For local data queuing
- `shared_preferences: ^2.2.2` - For settings persistence

## Testing the Feature

### UI Testing
- Open the comparison screen from debug menu
- Switch between models using the toggle
- Take photos of scrap metal items
- Observe prediction confidence and timing

### Performance Testing
- Run `flutter test test/cline_generated/ai-model-comparison/`
- Check console logs for inference times
- Verify both models produce reasonable predictions

### Integration Testing
- Test on real devices with camera access
- Verify offline operation works
- Check that data collection queues properly for later analysis

## Current Status

✅ Feature branch created: `feature/cline-generated/ai-model-comparison`
✅ Directory structure set up
✅ Model adapters partially implemented
⚠️  UI screen needs camera integration
⚠️  Performance measurement needs refinement
⚠️  Ground truth data collection not yet implemented

## TODO for AI Agent Implementation

1. Complete camera integration in screen.dart
2. Implement real TFLite model loading in model_b_adapter.dart
3. Add performance measurement in view_model.dart
4. Create comprehensive test suite
5. Implement data collection for accuracy validation

## Usage Instructions

To integrate this feature into your app:
1. Import the comparison screen
2. Add a navigation route
3. Include in debug menu for testing
4. Later migrate successful model to production

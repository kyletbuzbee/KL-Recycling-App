# Weigh Flow Feature

The Weigh Flow feature provides a complete workflow for capturing scrap metal images, running AI predictions, and submitting labeled data for model training.

## Overview

This feature implements a Compose-style Flutter UI that guides users through:
1. Capturing images of scrap metal (camera or gallery)
2. Running AI predictions using TensorFlow Lite models
3. Entering measured weights for ground truth data
4. Submitting labeled images for background upload and training

## Architecture

### Components

- **screen.dart**: Main UI screen with state-based navigation
- **view_model.dart**: State management and business logic
- **repository.dart**: Data persistence and background upload queuing
- **tflite_helper.dart**: TensorFlow Lite model inference (mock implementation)

### State Flow

```
Initial → Camera Ready → Image Captured → Processing → Prediction Ready → Submitting → Completed
   ↓           ↓              ↓              ↓             ↓                ↓           ↓
   └───────────┴──────────────┴──────────────┴─────────────┴────────────────┴───────────┘
                    Error (any state) ← Retry/Start Over
```

## Integration

### Adding to Navigation

To integrate the Weigh Flow screen into your app navigation:

```dart
import 'package:kl_recycling_app/cline_generated/weigh-flow/screen.dart';

// In your navigation setup
routes: {
  '/weigh-flow': (context) => const WeighFlowScreen(),
  // ... other routes
}
```

### Using with Camera Provider

The screen integrates with the existing `CameraProvider`:

```dart
// Ensure camera provider is available in your widget tree
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CameraProvider()),
    // ... other providers
  ],
  child: MaterialApp(
    // ... app configuration
  ),
)
```

### Database Integration

The feature uses SQLite for local persistence and background queuing:

- **Items Table**: Stores scrap metal item definitions
- **Labeled Images Table**: Queues images for upload with metadata

## Testing on Device

### Prerequisites

1. **Camera Permissions**: Ensure camera permissions are granted
2. **Storage Permissions**: Required for saving images and database
3. **Network**: For background uploads (optional for testing)

### Test Workflow

1. **Launch the Feature**
   ```bash
   flutter run
   # Navigate to Weigh Flow screen
   ```

2. **Camera Testing**
   - Tap "Take Photo" to capture images
   - Tap "Gallery" to select existing images
   - Verify image preview displays correctly

3. **AI Prediction Testing**
   - Capture or select an image
   - Tap "Run AI Prediction"
   - Verify prediction appears (mock values for now)

4. **Weight Input Testing**
   - Enter measured weight in the text field
   - Test validation (invalid inputs, negative numbers)
   - Verify "Submit for Training" button enables/disables correctly

5. **Submission Testing**
   - Enter valid weight and tap "Submit for Training"
   - Verify completion screen appears
   - Check database for queued uploads

### Mock Data

The current implementation uses mock data for:
- **TFLite Model**: Returns realistic weight predictions based on image size
- **Network Upload**: Simulates background upload with 2-second delay
- **Database**: Uses real SQLite for persistence

## Development

### Running Tests

```bash
# Run all weigh-flow tests
flutter test test/cline_generated/weigh-flow/

# Run specific test files
flutter test test/cline_generated/weigh-flow/tflite_helper_test.dart
flutter test test/cline_generated/weigh-flow/repository_test.dart
flutter test test/cline_generated/weigh-flow/view_model_test.dart
flutter test test/cline_generated/weigh-flow/weigh_flow_screen_test.dart
```

### Code Analysis

```bash
# Run Flutter analyzer
flutter analyze lib/cline_generated/weigh-flow/

# Check for issues
flutter analyze
```

## TODO for Production

### Model Integration
- [ ] Replace mock TFLite implementation with real model loading
- [ ] Add model download/update mechanism
- [ ] Implement proper image preprocessing (resize, normalize)

### Network Integration
- [ ] Replace mock upload with real API endpoints
- [ ] Add authentication headers
- [ ] Implement retry logic for failed uploads
- [ ] Add upload progress indicators

### Performance
- [ ] Optimize image processing pipeline
- [ ] Add model caching and preloading
- [ ] Implement background task processing
- [ ] Add offline queue management

### UI/UX
- [ ] Add loading indicators for long operations
- [ ] Implement better error messaging
- [ ] Add confirmation dialogs for destructive actions
- [ ] Support multiple image selection

## Dependencies

The feature uses these existing project dependencies:
- `camera: ^0.10.5+2` - Camera functionality
- `image_picker: ^0.8.7+4` - Gallery image selection
- `sqflite: ^2.3.0` - Local database
- `path: ^1.9.0` - File path utilities
- `provider: ^6.0.5` - State management

## File Structure

```
lib/cline_generated/weigh-flow/
├── screen.dart              # Main UI screen
├── view_model.dart          # State management
├── repository.dart          # Data layer
├── tflite_helper.dart       # Model inference
└── README.md               # This file

test/cline_generated/weigh-flow/
├── tflite_helper_test.dart  # Model tests
├── repository_test.dart     # Database tests
├── view_model_test.dart     # State management tests
└── weigh_flow_screen_test.dart # UI tests
```

## Support

For issues or questions about the Weigh Flow feature:
1. Check the test files for usage examples
2. Review the mock implementations for integration patterns
3. Ensure camera and storage permissions are properly configured
4. Verify database paths and file system access

## Version History

- **v1.0.0**: Initial implementation with mock data
- **TODO**: Real TFLite model integration
- **TODO**: Production API endpoints
- **TODO**: Enhanced error handling and retry logic

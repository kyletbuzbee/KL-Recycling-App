/// Interface for weight prediction services using strategy pattern
import 'package:kl_recycling_app/core/services/ai/weight_prediction_service.dart';

abstract class WeightPredictionServiceInterface {
  /// Predict weight from image with fallback support
  Future<WeightPredictionResult> predictWeightFromImage(
    String imagePath,
    String materialType, {
    String? referenceObject,
    bool forceFallback = false,
  });

  /// Check if this service is supported on current platform
  bool get isSupported;

  /// Get service name for debugging
  String get serviceName;
}

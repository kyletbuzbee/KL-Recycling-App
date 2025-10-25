import 'package:flutter/material.dart';

/// Utility class for generating actionable error messages and recovery suggestions
class ErrorMessages {
  // UI Error Messages with guidance
  static const Map<String, Map<String, String>> _errorMessages = {
    'camera_permission_denied': {
      'title': 'Camera Permission Required',
      'message': 'We need camera access to photograph your scrap metal for weight estimation.',
      'action_text': 'Grant Permission',
      'detailed_help': 'Go to Settings → Privacy → Camera and enable access for K&L Recycling app.',
      'secondary_action': 'Use Photo Library Instead',
    },
    'camera_not_available': {
      'title': 'Camera Unavailable',
      'message': 'Your device camera is currently in use or not accessible.',
      'action_text': 'Try Again',
      'detailed_help': 'Close other apps using the camera and restart the app.',
      'secondary_action': 'Use Manual Estimate',
    },
    'ai_model_load_failed': {
      'title': 'AI System Loading Error',
      'message': 'The AI weight estimation models could not be loaded.',
      'action_text': 'Retry Loading',
      'detailed_help': 'Try restarting the app or check your internet connection for model downloads.',
      'secondary_action': 'Use Manual Mode',
    },
    'image_processing_failed': {
      'title': 'Photo Processing Failed',
      'message': 'We couldn\'t analyze your photo. Try taking a clearer image.',
      'action_text': 'Take New Photo',
      'detailed_help': 'Ensure good lighting, focus on scrap metal, and avoid blurry images.',
      'secondary_action': 'Enter Weight Manually',
    },
    'network_connection_lost': {
      'title': 'Connection Lost',
      'message': 'Internet connection is required for some features.',
      'action_text': 'Check Connection',
      'detailed_help': 'Verify your internet connection and try again.',
      'secondary_action': 'Continue Offline',
    },
    'storage_full': {
      'title': 'Storage Full',
      'message': 'Not enough space to save photos or data.',
      'action_text': 'Free Up Space',
      'detailed_help': 'Delete unused files or clear app cache to free up storage.',
      'secondary_action': 'Continue with Limitations',
    },
    'location_permission_denied': {
      'title': 'Location Access Needed',
      'message': 'Location helps us provide better service area information.',
      'action_text': 'Enable Location',
      'detailed_help': 'Go to Settings → Privacy → Location Services to enable access.',
      'secondary_action': 'Continue Without Location',
    },
    'general_error': {
      'title': 'Something Went Wrong',
      'message': 'An unexpected error occurred. We\'re working to fix it.',
      'action_text': 'Try Again',
      'detailed_help': 'Restart the app or contact support if the problem persists.',
      'secondary_action': 'Use Basic Features',
    },
  };

  /// Get error message data by error type
  static Map<String, String> getErrorMessage(String errorType) {
    return _errorMessages[errorType] ?? _errorMessages['general_error']!;
  }

  /// Generate error snackbar with actions
  static SnackBar getErrorSnackBar(
    BuildContext context,
    String errorType, {
    VoidCallback? onActionPressed,
    VoidCallback? onSecondaryActionPressed,
  }) {
    final errorData = getErrorMessage(errorType);

    return SnackBar(
      duration: const Duration(seconds: 8),
      behavior: SnackBarBehavior.floating,
      content: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  errorData['title']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  errorData['message']!,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: errorData['action_text']!,
        onPressed: onActionPressed ?? () {},
        textColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Show error dialog with detailed help
  static Future<void> showErrorDialog(
    BuildContext context,
    String errorType, {
    VoidCallback? onPrimaryAction,
    VoidCallback? onSecondaryAction,
    String? customTitle,
    String? customMessage,
  }) async {
    final errorData = getErrorMessage(errorType);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customTitle ?? errorData['title']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customMessage ?? errorData['message']!),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Help & Troubleshooting',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorData['detailed_help']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (errorData['secondary_action'] != null)
            TextButton(
              onPressed: onSecondaryAction ?? () => Navigator.of(context).pop(),
              child: Text(errorData['secondary_action']!),
            ),
          ElevatedButton(
            onPressed: onPrimaryAction ?? () => Navigator.of(context).pop(),
            child: Text(errorData['action_text']!),
          ),
        ],
      ),
    );
  }

  /// Generate AI analysis error guidance specifically for photo analysis
  static Map<String, String> getPhotoAnalysisErrorGuidance(String errorType) {
    const Map<String, Map<String, String>> photoErrors = {
      'no_metal_detected': {
        'title': 'No Metal Detected',
        'primary_suggestion': 'Ensure scrap metal fills at least 20% of your photo frame',
        'secondary_suggestion': 'Use good lighting and clear focus',
        'action': 'Take New Photo',
      },
      'low_confidence': {
        'title': 'Analysis Uncertainty',
        'primary_suggestion': 'Try different angles or add a reference object (coin, quarter)',
        'secondary_suggestion': 'Ensure metal is clean and clearly visible',
        'action': 'Improve Photo Quality',
      },
      'blur_detected': {
        'title': 'Image Too Blurry',
        'primary_suggestion': 'Hold camera steady and use autofocus',
        'secondary_suggestion': 'Tap to focus directly on the metal scrap',
        'action': 'Retake Photo',
      },
      'poor_lighting': {
        'title': 'Poor Lighting Conditions',
        'primary_suggestion': 'Move to well-lit area or use flash if available',
        'secondary_suggestion': 'Avoid direct sunlight causing harsh shadows',
        'action': 'Adjust Lighting',
      },
      'complex_background': {
        'title': 'Complex Background Detected',
        'primary_suggestion': 'Use plain background or isolate scrap metal',
        'secondary_suggestion': 'Move metal away from clutter or patterns',
        'action': 'Simplify Scene',
      },
    };

    return photoErrors[errorType] ?? {
      'title': 'Analysis Challenge',
      'primary_suggestion': 'Try taking a clearer photo with good lighting',
      'secondary_suggestion': 'Consider manual weight estimation',
      'action': 'Take Better Photo',
    };
  }

  /// Show photo-specific error guidance
  static Widget buildPhotoAnalysisErrorWidget(
    BuildContext context,
    String errorType, {
    required VoidCallback onRetakePhoto,
    VoidCallback? onManualEntry,
  }) {
    final guidance = getPhotoAnalysisErrorGuidance(errorType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            guidance['title']!,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            guidance['primary_suggestion']!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            guidance['secondary_suggestion']!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (onManualEntry != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManualEntry,
                    icon: const Icon(Icons.edit),
                    label: const Text('Manual Entry'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (onManualEntry != null) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRetakePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(guidance['action']!),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Generate troubleshooting checklist widget
  static Widget buildTroubleshootingChecklist(BuildContext context, List<String> issues) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.build_circle,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Troubleshooting Steps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...issues.map((issue) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

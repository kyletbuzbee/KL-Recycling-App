// Error message constants for consistent error handling across the app
class ErrorMessages {
  // General errors
  static const String genericError = 'An unexpected error occurred. Please try again.';
  static const String networkError = 'No internet connection. Please check your connection and try again.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String serverError = 'Server error. Please try again later.';

  // Authentication errors
  static const String invalidCredentials = 'Invalid email or password.';
  static const String emailNotVerified = 'Please verify your email before signing in.';
  static const String accountDisabled = 'This account has been disabled.';
  static const String weakPassword = 'Password must be at least 6 characters long.';
  static const String emailAlreadyInUse = 'An account with this email already exists.';
  static const String invalidEmail = 'Please enter a valid email address.';

  // Permission errors
  static const String cameraPermission = 'Camera permission is required for this feature.';
  static const String locationPermission = 'Location permission is required for this feature.';
  static const String storagePermission = 'Storage permission is required for this feature.';

  // Loyalty specific errors
  static const String insufficientPoints = 'You don\'t have enough points for this reward.';
  static const String rewardNotAvailable = 'This reward is no longer available.';
  static const String tierUpgradeFailed = 'Unable to upgrade tier. Please try again.';
  static const String achievementNotUnlocked = 'Achievement requirements not met.';

  // Weight prediction errors
  static const String imageProcessingFailed = 'Failed to process image. Please try again with a different photo.';
  static const String noObjectsDetected = 'No recyclable objects detected in the image.';
  static const String predictionFailed = 'Unable to estimate weight. Please try again.';

  // Form validation errors
  static const String requiredField = 'This field is required.';
  static const String invalidPhone = 'Please enter a valid phone number.';
  static const String invalidWeight = 'Please enter a valid weight.';
  static const String invalidQuantity = 'Please enter a valid quantity.';

  // Firebase/Firestore errors
  static const String documentNotFound = 'The requested information could not be found.';
  static const String permissionDenied = 'You don\'t have permission to perform this action.';
  static const String quotaExceeded = 'Service quota exceeded. Please try again later.';

  // File upload errors
  static const String fileTooLarge = 'File is too large. Please select a smaller file.';
  static const String unsupportedFileType = 'This file type is not supported.';
  static const String uploadFailed = 'Failed to upload file. Please try again.';
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kl_recycling_app/utils/logger.dart';
import 'package:kl_recycling_app/utils/error_messages.dart';

/// Service for centralized error handling across the application
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;

  ErrorHandlerService._internal();

  /// Handle and log any error that occurs in the app
  void handleError(dynamic error, StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool reportToAnalytics = true,
  }) {
    // Log the error with structured logging
    AppLogger.e('Error handled by ErrorHandlerService: $error', error, stackTrace);

    if (context != null) {
      AppLogger.e('Context: $context');
    }

    if (additionalData != null && additionalData.isNotEmpty) {
      AppLogger.e('Additional data: $additionalData');
    }

    // In development, also print to console for easier debugging
    if (kDebugMode) {
      debugPrint('[ERROR HANDLER] $error');
      if (stackTrace != null) {
        debugPrint('[STACK TRACE] $stackTrace');
      }
    }

    // Report to crash analytics if enabled and not in development
    if (reportToAnalytics && !kDebugMode) {
      _reportErrorToAnalytics(error, stackTrace, context, additionalData);
    }
  }

  /// Report error to external analytics/crash reporting services
  void _reportErrorToAnalytics(dynamic error, StackTrace? stackTrace, String? context, Map<String, dynamic>? additionalData) {
    try {
      final errorReport = {
        'error': error.toString(),
        'stackTrace': stackTrace?.toString(),
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'flutter_mobile',
        'additionalData': additionalData ?? {},
      };

      // TODO: Add actual crash reporting service integration
      // Example integrations:
      //
      // Sentry:
      // await Sentry.captureException(error, stackTrace: stackTrace);
      //
      // Firebase Crashlytics:
      // await FirebaseCrashlytics.instance.recordError(error, stackTrace);
      //
      // Custom analytics:
      // await analytics.logEvent(name: 'app_error', parameters: {
      //   'error_type': error.runtimeType.toString(),
      //   'context': context ?? 'unknown',
      //   'has_stacktrace': stackTrace != null,
      // });

      AppLogger.i('Error reported to analytics: ${error.runtimeType}');
    } catch (reportingError) {
      AppLogger.w('Failed to report error to analytics: $reportingError');
      // Don't allow analytics reporting failures to crash the app
    }
  }

  /// Execute an operation with automatic error handling and retry logic
  Future<T?> executeOperation<T>(
    Future<T> Function() operation, {
    String? operationName,
    int maxRetries = 1,
    Duration retryDelay = const Duration(milliseconds: 500),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      attempts++;

      try {
        final result = await operation();

        // Log successful operation if it was retried
        if (attempts > 1 && operationName != null) {
          AppLogger.i('Operation "$operationName" succeeded on attempt $attempts');
        }

        return result;
      } catch (error, stackTrace) {
        final shouldRetryThisError = shouldRetry?.call(error) ?? (error is Exception && error.toString().contains('network'));

        if (attempts < maxRetries && shouldRetryThisError) {
          AppLogger.w('Operation "$operationName" failed on attempt $attempts, retrying in ${retryDelay.inMilliseconds}ms', error);

          await Future.delayed(retryDelay * attempts); // Progressive delay
          continue;
        }

        // Final failure - handle the error
        handleError(error, stackTrace,
          context: operationName ?? 'ExecuteOperation',
          additionalData: {
            'attempts': attempts,
            'maxRetries': maxRetries,
          },
        );

        return null; // Return null to indicate failure
      }
    }

    return null;
  }

  /// Handle Firebase/AI service errors with appropriate user messages
  String getUserFriendlyErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Network and connection errors
    if (errorStr.contains('network') || errorStr.contains('connection') || errorStr.contains('unreachable')) {
      return 'Please check your internet connection and try again.';
    }

    // Authentication errors
    if (errorStr.contains('auth') || errorStr.contains('authentication') || errorStr.contains('login')) {
      return 'Authentication failed. Please check your credentials and try again.';
    }

    // Camera/permission errors
    if (errorStr.contains('camera') || errorStr.contains('permission') || errorStr.contains('denied')) {
      return 'Camera access is required. Please grant permission and try again.';
    }

    // Storage/space errors
    if (errorStr.contains('storage') || errorStr.contains('space') || errorStr.contains('disk')) {
      return 'Storage space is low. Please free up space and try again.';
    }

    // ML/AI model errors
    if (errorStr.contains('model') || errorStr.contains('ai') || errorStr.contains('ml')) {
      return 'AI analysis temporarily unavailable. You can still enter weight manually.';
    }

    // Rate limiting
    if (errorStr.contains('too many') || errorStr.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    // Default message
    return 'An unexpected error occurred. Please try again.';
  }

  /// Get error snackbar for UI display
  SnackBar getErrorSnackBar({
    required BuildContext context,
    required String errorType,
    VoidCallback? onActionPressed,
  }) {
    return ErrorMessages.getErrorSnackBar(
      context,
      errorType,
      onActionPressed: onActionPressed,
    );
  }

  /// Handle fatal errors that require app restart or user notification
  void handleFatalError(dynamic error, StackTrace? stackTrace, {
    String? message,
    bool showDialog = true,
  }) {
    handleError(error, stackTrace, context: 'Fatal Error');

    // In production, you might want to show a dialog or navigate to error screen
    if (showDialog && message != null) {
      // This would be implemented with a dialog showing service
      AppLogger.e('Fatal error occurred: $message');
    }
  }

  /// Validate operation preconditions and throw descriptive errors
  void validateOperation({
    required String operationName,
    bool? condition,
    String? conditionMessage,
    dynamic Function()? validator,
  }) {
    try {
      if (condition != null && !condition) {
        throw ArgumentError('$operationName: $conditionMessage');
      }

      if (validator != null) {
        validator();
      }
    } catch (error, stackTrace) {
      handleError(error, stackTrace, context: 'Validation Error - $operationName');
      rethrow;
    }
  }
}

/// Extension to add error handling to futures
extension ErrorHandlingExtension<T> on Future<T> {
  /// Execute with error handling
  Future<T?> withErrorHandling({
    String? operationName,
    void Function(dynamic error, StackTrace? stackTrace)? onError,
  }) {
    return catchError((error, stackTrace) {
      ErrorHandlerService().handleError(error, stackTrace, context: operationName);
      onError?.call(error, stackTrace);
      return null; // Return null on error
    });
  }
}

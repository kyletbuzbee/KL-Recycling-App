import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kl_recycling_app/utils/logger.dart';
import 'package:kl_recycling_app/services/error_handler_service.dart';

/// Production analytics and monitoring service for the KL Recycling App
class AnalyticsMonitoringService {
  static final AnalyticsMonitoringService _instance = AnalyticsMonitoringService._internal();
  factory AnalyticsMonitoringService() => _instance;

  AnalyticsMonitoringService._internal();

  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  /// Initialize analytics monitoring
  Future<void> initialize() async {
    try {
      AppLogger.i('Initializing Analytics Monitoring Service');

      // TODO: Initialize production analytics services
      // Example: Firebase Analytics, Mixpanel, Amplitude, etc.
      //
      // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      // await Mixpanel.initialize('YOUR_TOKEN');
      // await Sentry.init(options: defaultSentryOptions);

      _setupErrorTracking();
      _setupLifecycleTracking();

      AppLogger.i('Analytics Monitoring Service initialized successfully');
    } catch (error, stackTrace) {
      _errorHandler.handleError(error, stackTrace, context: 'AnalyticsMonitoringService.initialize');
    }
  }

  /// Track user events across the app
  Future<void> trackEvent(String eventName, {
    Map<String, dynamic>? parameters,
    bool includeDeviceContext = true,
  }) async {
    try {
      final eventParams = _buildEventParameters(parameters, includeDeviceContext);

      // Log event locally
      AppLogger.i('Analytics Event: $eventName', null, null);

      // TODO: Track in production analytics services
      // Example implementations:
      //
      // Firebase Analytics:
      // await FirebaseAnalytics.instance.logEvent(name: eventName, parameters: eventParams);
      //
      // Mixpanel:
      // mixpanel.track(eventName, properties: eventParams);
      //
      // Custom analytics:
      // await _sendToCustomAnalytics(eventName, eventParams);

    } catch (error, stackTrace) {
      _errorHandler.handleError(error, stackTrace,
        context: 'AnalyticsMonitoringService.trackEvent',
        additionalData: {'eventName': eventName, 'parameters': parameters},
      );
    }
  }

  /// Track screen views
  Future<void> trackScreenView(String screenName, {
    String? previousScreen,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await trackEvent('screen_view', parameters: {
        'screen_name': screenName,
        'previous_screen': previousScreen,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalData,
      });

      AppLogger.i('Screen view tracked: $screenName');
    } catch (error, stackTrace) {
      _errorHandler.handleError(error, stackTrace,
        context: 'AnalyticsMonitoringService.trackScreenView',
        additionalData: {'screenName': screenName},
      );
    }
  }

  /// Track business metrics (conversions, revenue, etc.)
  Future<void> trackBusinessMetric(String metricName, {
    required double value,
    String? currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await trackEvent('business_metric', parameters: {
        'metric_name': metricName,
        'value': value,
        'currency': currency ?? 'USD',
        'timestamp': DateTime.now().toIso8601String(),
        ...?metadata,
      });

      AppLogger.i('Business metric tracked: $metricName = $value');
    } catch (error, stackTrace) {
      _errorHandler.handleError(error, stackTrace,
        context: 'AnalyticsMonitoringService.trackBusinessMetric',
        additionalData: {'metricName': metricName, 'value': value},
      );
    }
  }

  /// Track user engagement (time spent, feature usage, etc.)
  Future<void> trackEngagement(String featureName, {
    Duration? duration,
    Map<String, dynamic>? engagementData,
  }) async {
    try {
      await trackEvent('user_engagement', parameters: {
        'feature_name': featureName,
        'duration_seconds': duration?.inSeconds ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
        ...?engagementData,
      });

      AppLogger.i('User engagement tracked: $featureName');
    } catch (error, stackTrace) {
      _errorHandler.handleError(error, stackTrace,
        context: 'AnalyticsMonitoringService.trackEngagement',
        additionalData: {'featureName': featureName},
      );
    }
  }

  /// Track errors and crashes (already handled by ErrorHandlerService, but can add additional analytics)
  Future<void> trackError(String errorType, {
    String? errorMessage,
    String? screenName,
    Map<String, dynamic>? errorDetails,
  }) async {
    try {
      await trackEvent('error_occurred', parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'screen_name': screenName,
        'timestamp': DateTime.now().toIso8601String(),
        ...?errorDetails,
      });

      AppLogger.i('Error tracked: $errorType');
    } catch (error, stackTrace) {
      // Use non-analytics error reporting to avoid recursion
      _errorHandler.handleError(error, stackTrace,
        context: 'AnalyticsMonitoringService.trackError',
        reportToAnalytics: false,
      );
    }
  }

  /// Set user properties for analytics
  Future<void> setUserProperty(String propertyName, dynamic value) async {
    try {
      // TODO: Set user properties in analytics services
      // Example:
      // await FirebaseAnalytics.instance.setUserProperty(name: propertyName, value: value?.toString());
      // mixpanel.getPeople().set(propertyName, value);

      AppLogger.i('User property set: $propertyName = $value');
    } catch (error, stackTrace) {
      _errorHandler.handleError(error, stackTrace,
        context: 'AnalyticsMonitoringService.setUserProperty',
        additionalData: {'propertyName': propertyName},
      );
    }
  }

  /// Enable/disable analytics collection
  Future<void> setAnalyticsEnabled(bool enabled) async {
    try {
      // TODO: Enable/disable analytics collection across all services
      // Example:
      // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);

      AppLogger.i('Analytics collection ${(enabled ? 'enabled' : 'disabled')}');
    } catch (error, stackTrace) {
      _errorHandler.handleError(error, stackTrace,
        context: 'AnalyticsMonitoringService.setAnalyticsEnabled',
        additionalData: {'enabled': enabled},
      );
    }
  }

  // Private methods

  void _setupErrorTracking() {
    // Global error tracking setup
    // In Flutter 3.x+, errors that aren't caught by zones can be tracked here
    FlutterError.onError = (FlutterErrorDetails details) {
      trackError('flutter_error', errorMessage: details.exceptionAsString(), errorDetails: {
        'library': details.library,
        'stack_trace_summary': details.stack?.toString().split('\n').take(5).join('\n'),
      });
    };
  }

  void _setupLifecycleTracking() {
    // App lifecycle tracking could be added here if needed
    // This would typically monitor app foreground/background events
  }

  Map<String, dynamic> _buildEventParameters(Map<String, dynamic>? parameters, bool includeDeviceContext) {
    final baseParams = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (parameters != null) {
      baseParams.addAll(parameters);
    }

    if (includeDeviceContext) {
      // TODO: Add device/platform context when available
      // Example:
      // 'platform': Platform.operatingSystem,
      // 'app_version': packageInfo.version,
      // 'device_model': deviceInfo.model,
      baseParams.addAll({
        'platform': 'flutter_mobile',
        'app_version': '1.0.0', // Would be dynamic in production
      });
    }

    return baseParams;
  }

  // TODO: Implement actual service integrations in production
  // Future<void> _sendToCustomAnalytics(String eventName, Map<String, dynamic> parameters) async {
  //   // Custom analytics implementation
  // }
}

/// Extension methods for easy analytics tracking
extension AnalyticsExtensions on BuildContext {
  /// Track screen view when context is used
  void trackScreenView(String screenName) {
    AnalyticsMonitoringService().trackScreenView(screenName);
  }

  /// Track user interaction
  void trackInteraction(String action, {Map<String, dynamic>? parameters}) {
    AnalyticsMonitoringService().trackEvent('user_interaction_${action}', parameters: parameters);
  }
}

/// Convenience class for quick analytics access
class Analytics {
  static final AnalyticsMonitoringService _service = AnalyticsMonitoringService();

  static Future<void> initialize() => _service.initialize();
  static Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) =>
      _service.trackEvent(eventName, parameters: parameters);
  static Future<void> trackScreenView(String screenName, {String? previousScreen}) =>
      _service.trackScreenView(screenName, previousScreen: previousScreen);
  static Future<void> trackBusinessMetric(String metricName, {required double value, String? currency}) =>
      _service.trackBusinessMetric(metricName, value: value, currency: currency);
  static Future<void> trackEngagement(String featureName, {Duration? duration}) =>
      _service.trackEngagement(featureName, duration: duration);
  static Future<void> setUserProperty(String propertyName, dynamic value) =>
      _service.setUserProperty(propertyName, value);
  static Future<void> setAnalyticsEnabled(bool enabled) => _service.setAnalyticsEnabled(enabled);
}

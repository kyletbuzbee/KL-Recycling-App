import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kl_recycling_app/core/services/firebase_service.dart';
import 'package:kl_recycling_app/features/gamification/models/gamification.dart';

/// Analytics service for tracking user behavior and app performance
class AnalyticsService {
  static const String _collectionName = 'analytics_events';
  static const String _performanceCollectionName = 'performance_metrics';
  static final FirebaseService _firebaseService = FirebaseService();

  static String? _userId;
  static String? _sessionId;
  static DateTime? _sessionStartTime;

  /// Initialize analytics service
  static Future<void> initialize() async {
    await _firebaseService.initialize();
    await _startNewSession();

    // Set up periodic performance tracking
    Timer.periodic(const Duration(minutes: 5), (_) => _trackPerformanceMetrics());
  }

  /// Set the current user ID for analytics
  static void setUserId(String userId) {
    _userId = userId;
  }

  /// Track a user action or event
  static Future<void> trackEvent({
    required String eventName,
    required String category,
    Map<String, dynamic>? parameters,
    String? screenName,
  }) async {
    final event = {
      'event_name': eventName,
      'category': category,
      'user_id': _userId,
      'session_id': _sessionId,
      'screen_name': screenName,
      'timestamp': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.toString(),
      'parameters': parameters ?? {},
    };

    try {
      await _firebaseService.firestore
          .collection(_collectionName)
          .add(event);

      // Log to console in debug mode
      if (kDebugMode) {
        debugPrint('[ANALYTICS] $eventName in $category: ${parameters ?? {}}');
      }
    } catch (e) {
      debugPrint('Failed to track event: $e');
      // Store locally for later upload
      await _storeEventLocally(event);
    }
  }

  /// Track screen views
  static Future<void> trackScreenView(String screenName, {Map<String, dynamic>? parameters}) async {
    await trackEvent(
      eventName: 'screen_view',
      category: 'navigation',
      parameters: {
        'screen_name': screenName,
        ...?parameters,
      },
      screenName: screenName,
    );
  }

  /// Track recycling activity
  static Future<void> trackRecyclingActivity(RecycledItem item) async {
    await trackEvent(
      eventName: 'recycling_completed',
      category: 'gamification',
      parameters: {
        'material_type': item.materialType,
        'weight': item.weight,
        'points_earned': item.points,
      },
    );
  }

  /// Track feature usage
  static Future<void> trackFeatureUsage(String featureName,
      {Map<String, dynamic>? metadata}) async {
    await trackEvent(
      eventName: 'feature_used',
      category: 'engagement',
      parameters: {
        'feature_name': featureName,
        ...?metadata,
      },
    );
  }

  /// Track errors (separate from crash reporting)
  static Future<void> trackError(String errorType, String context,
      {String? additionalInfo}) async {
    await trackEvent(
      eventName: 'error_occurred',
      category: 'errors',
      parameters: {
        'error_type': errorType,
        'error_context': context,
        'additional_info': additionalInfo,
      },
    );
  }

  /// Track AI model performance
  static Future<void> trackAIPerformance({
    required String modelName,
    required double confidenceScore,
    required Duration processingTime,
    required bool success,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent(
      eventName: 'ai_model_used',
      category: 'ai_performance',
      parameters: {
        'model_name': modelName,
        'confidence_score': confidenceScore,
        'processing_time_ms': processingTime.inMilliseconds,
        'success': success,
        ...?metadata,
      },
    );
  }

  /// Track user flow completion
  static Future<void> trackFlowCompletion({
    required String flowName,
    required bool completed,
    required Duration timeSpent,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent(
      eventName: completed ? 'flow_completed' : 'flow_abandoned',
      category: 'user_flows',
      parameters: {
        'flow_name': flowName,
        'time_spent_ms': timeSpent.inMilliseconds,
        'completed': completed,
        ...?metadata,
      },
    );
  }

  /// Get analytics data for dashboard
  static Future<Map<String, dynamic>> getAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    try {
      final snapshot = await _firebaseService.firestore
          .collection(_collectionName)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final events = snapshot.docs.map((doc) => doc.data()).toList();

      // Analyze event data
      final stats = _analyzeEvents(events);

      return {
        'total_events': events.length,
        'event_breakdown': stats,
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      debugPrint('Failed to get analytics data: $e');
      return {};
    }
  }

  /// Track performance metrics
  static Future<void> _trackPerformanceMetrics() async {
    if (_sessionStartTime == null) return;

    final metrics = {
      'session_duration_ms': DateTime.now().difference(_sessionStartTime!).inMilliseconds,
      'user_id': _userId,
      'session_id': _sessionId,
      'timestamp': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.toString(),
      'memory_info': await _getMemoryInfo(),
    };

    try {
      await _firebaseService.firestore
          .collection(_performanceCollectionName)
          .add(metrics);
    } catch (e) {
      debugPrint('Failed to track performance metrics: $e');
    }
  }

  /// Upload stored events when connection is restored
  static Future<void> uploadStoredEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final storedEvents = prefs.getStringList('stored_analytics_events') ?? [];

    if (storedEvents.isEmpty) return;

    final successfulUploads = <String>[];

    for (final eventJson in storedEvents) {
      try {
        final event = jsonDecode(eventJson) as Map<String, dynamic>;
        // Convert timestamp if present
        if (event.containsKey('timestamp_string')) {
          event['timestamp'] = Timestamp.fromDate(
            DateTime.parse(event['timestamp_string']),
          );
          event.remove('timestamp_string');
        }

        await _firebaseService.firestore
            .collection(_collectionName)
            .add(event);

        successfulUploads.add(eventJson);
      } catch (e) {
        debugPrint('Failed to upload stored event: $e');
      }
    }

    // Remove successfully uploaded events
    storedEvents.removeWhere((event) => successfulUploads.contains(event));
    await prefs.setStringList('stored_analytics_events', storedEvents);

    if (successfulUploads.isNotEmpty) {
      debugPrint('Uploaded ${successfulUploads.length} stored analytics events');
    }
  }

  // Private helper methods

  static Future<void> _startNewSession() async {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStartTime = DateTime.now();

    await trackEvent(
      eventName: 'session_start',
      category: 'lifecycle',
      parameters: {
        'session_id': _sessionId,
      },
    );
  }

  static Future<void> _storeEventLocally(Map<String, dynamic> event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEvents = prefs.getStringList('stored_analytics_events') ?? [];

      // Convert timestamp for storage
      final eventForStorage = Map<String, dynamic>.from(event);
      if (eventForStorage['timestamp'] is FieldValue) {
        eventForStorage['timestamp_string'] = DateTime.now().toIso8601String();
        eventForStorage.remove('timestamp');
      }

      storedEvents.add(jsonEncode(eventForStorage));

      // Keep only last 100 events to prevent storage bloat
      if (storedEvents.length > 100) {
        storedEvents.removeRange(0, storedEvents.length - 100);
      }

      await prefs.setStringList('stored_analytics_events', storedEvents);
    } catch (e) {
      debugPrint('Failed to store event locally: $e');
    }
  }

  static Future<Map<String, dynamic>> _getMemoryInfo() async {
    try {
      // Basic memory info (limited in Flutter)
      return {};
    } catch (e) {
      return {};
    }
  }

  static Map<String, dynamic> _analyzeEvents(List<Map<String, dynamic>> events) {
    final categories = <String, int>{};
    final eventTypes = <String, int>{};
    final screenViews = <String, int>{};

    for (final event in events) {
      final category = event['category'] as String? ?? 'unknown';
      final eventName = event['event_name'] as String? ?? 'unknown';
      final screenName = event['screen_name'] as String?;

      categories[category] = (categories[category] ?? 0) + 1;
      eventTypes[eventName] = (eventTypes[eventName] ?? 0) + 1;

      if (screenName != null) {
        screenViews[screenName] = (screenViews[screenName] ?? 0) + 1;
      }
    }

    return {
      'categories': categories,
      'event_types': eventTypes,
      'screen_views': screenViews,
    };
  }
}

/// Extension methods for easy analytics integration
extension AnalyticsExtensions on AnalyticsService {
  /// Quick event tracking (convenience method)
  static Future<void> log(String eventName, {Map<String, dynamic>? params}) async {
    await AnalyticsService.trackEvent(
      eventName: eventName,
      category: 'general',
      parameters: params,
    );
  }
}

/// Analytics-enabled widget wrapper
class AnalyticsTracker extends StatefulWidget {
  final Widget child;
  final String screenName;
  final Map<String, dynamic>? metadata;

  const AnalyticsTracker({
    super.key,
    required this.child,
    required this.screenName,
    this.metadata,
  });

  @override
  State<AnalyticsTracker> createState() => _AnalyticsTrackerState();
}

class _AnalyticsTrackerState extends State<AnalyticsTracker> {
  bool _hasTracked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasTracked && mounted) {
      AnalyticsService.trackScreenView(
        widget.screenName,
        parameters: widget.metadata,
      );
      _hasTracked = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Performance monitoring mixin
mixin PerformanceTracker {
  final Map<String, DateTime> _operationStartTimes = {};

  void startTiming(String operationId) {
    _operationStartTimes[operationId] = DateTime.now();
  }

  Future<void> endTiming(String operationId, {Map<String, dynamic>? metadata}) async {
    final startTime = _operationStartTimes.remove(operationId);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      await AnalyticsService.trackEvent(
        eventName: 'operation_completed',
        category: 'performance',
        parameters: {
          'operation_id': operationId,
          'duration_ms': duration.inMilliseconds,
          ...?metadata,
        },
      );
    }
  }
}

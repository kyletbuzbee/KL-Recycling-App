import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kl_recycling_app/core/services/firebase_service.dart';

/// Crash reporting service for collecting and reporting errors
class CrashReportingService {
  static const String _collectionName = 'crash_reports';
  static const String _diagnosticCollectionName = 'diagnostic_reports';
  static const Duration _throttleDuration = Duration(minutes: 5);
  static DateTime? _lastReportTime;

  static final FirebaseService _firebaseService = FirebaseService();

  /// Initialize the crash reporting service
  static Future<void> initialize() async {
    // Ensure Firebase is initialized
    await _firebaseService.initialize();
  }

  /// Report an error with optional context and additional information
  static Future<void> reportError({
    required Object error,
    required StackTrace? stackTrace,
    required String context,
    Map<String, dynamic>? additionalInfo,
    bool forceReport = false,
  }) async {
    // Throttle reports to avoid spam
    if (!forceReport && !_shouldReportError()) {
      return;
    }

    _lastReportTime = DateTime.now();

    final crashReport = {
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'context': context,
      'timestamp': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem,
      'platformVersion': Platform.operatingSystemVersion,
      'appVersion': await _getAppVersion(),
      'userId': await _getCurrentUserId(),
      'deviceInfo': await _getDeviceInfo(),
      'additionalInfo': additionalInfo ?? {},
    };

    try {
      await _firebaseService.firestore
          .collection(_collectionName)
          .add(crashReport);

      debugPrint('Crash report submitted: $context');

      // Also log to console for development
      if (kDebugMode) {
        debugPrint('[CRASH REPORT] $context');
        debugPrint('[ERROR] $error');
        if (stackTrace != null) {
          debugPrint('[STACK] $stackTrace');
        }
        if (additionalInfo != null) {
          debugPrint('[INFO] $additionalInfo');
        }
      }
    } catch (e) {
      debugPrint('Failed to submit crash report: $e');
      // Fallback: store locally for later upload
      await _storeLocally(crashReport);
    }
  }

  /// Send a user-generated diagnostic report
  static Future<void> sendDiagnosticReport(Map<String, dynamic> diagnosticInfo) async {
    final report = {
      'type': 'user_diagnostic',
      'timestamp': FieldValue.serverTimestamp(),
      'diagnosticInfo': diagnosticInfo,
      'userId': await _getCurrentUserId(),
      'platform': Platform.operatingSystem,
    };

    try {
      await _firebaseService.firestore
          .collection(_diagnosticCollectionName)
          .add(report);

      debugPrint('Diagnostic report sent by user');
    } catch (e) {
      debugPrint('Failed to send diagnostic report: $e');
      await _storeLocally(report);
    }
  }

  /// Upload any locally stored crash reports
  static Future<void> uploadPendingReports() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingReports = prefs.getStringList('pending_crash_reports') ?? [];

    if (pendingReports.isEmpty) return;

    final successfulUploads = <String>[];

    for (final reportJson in pendingReports) {
      try {
        final report = jsonDecode(reportJson) as Map<String, dynamic>;
        // Convert timestamp if present
        if (report.containsKey('timestamp_string')) {
          report['timestamp'] = Timestamp.fromDate(
            DateTime.parse(report['timestamp_string']),
          );
          report.remove('timestamp_string');
        }

        await _firebaseService.firestore
            .collection(_collectionName)
            .add(report);

        successfulUploads.add(reportJson);
      } catch (e) {
        debugPrint('Failed to upload pending report: $e');
      }
    }

    // Remove successfully uploaded reports
    pendingReports.removeWhere((report) => successfulUploads.contains(report));
    await prefs.setStringList('pending_crash_reports', pendingReports);

    if (successfulUploads.isNotEmpty) {
      debugPrint('Uploaded ${successfulUploads.length} pending crash reports');
    }
  }

  /// Get crash statistics for admin dashboard
  static Future<Map<String, dynamic>> getCrashStatistics({
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

      final reports = snapshot.docs.map((doc) => doc.data()).toList();

      // Analyze crash patterns
      final errorTypes = <String, int>{};
      final contexts = <String, int>{};
      final platforms = <String, int>{};

      for (final report in reports) {
        final error = report['error'] as String? ?? 'Unknown';
        final context = report['context'] as String? ?? 'Unknown';
        final platform = report['platform'] as String? ?? 'Unknown';

        // Simple error categorization
        final errorType = _categorizeError(error);
        errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;

        contexts[context] = (contexts[context] ?? 0) + 1;
        platforms[platform] = (platforms[platform] ?? 0) + 1;
      }

      return {
        'totalCrashes': reports.length,
        'errorTypes': errorTypes,
        'contexts': contexts,
        'platforms': platforms,
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      debugPrint('Failed to get crash statistics: $e');
      return {};
    }
  }

  /// Clear old crash reports (admin function)
  static Future<int> cleanupOldReports({int daysOld = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    try {
      final batch = _firebaseService.firestore.batch();

      final snapshot = await _firebaseService.firestore
          .collection(_collectionName)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Cleaned up ${snapshot.docs.length} old crash reports');
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Failed to cleanup crash reports: $e');
      return 0;
    }
  }

  // Private helper methods

  static bool _shouldReportError() {
    if (_lastReportTime == null) return true;
    return DateTime.now().difference(_lastReportTime!) > _throttleDuration;
  }

  static Future<String> _getAppVersion() async {
    try {
      // In a real app, use package_info_plus
      return '1.0.0'; // Placeholder
    } catch (e) {
      return 'unknown';
    }
  }

  static Future<String?> _getCurrentUserId() async {
    try {
      final user = _firebaseService.currentUser;
      return user?.uid;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      return {
        'locale': Platform.localeName,
        'numberOfProcessors': Platform.numberOfProcessors,
        'version': Platform.version,
        'pathSeparator': Platform.pathSeparator,
      };
    } catch (e) {
      return {};
    }
  }

  static Future<void> _storeLocally(Map<String, dynamic> report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingReports = prefs.getStringList('pending_crash_reports') ?? [];

      // Convert timestamp for storage
      final reportForStorage = Map<String, dynamic>.from(report);
      if (reportForStorage['timestamp'] is FieldValue) {
        reportForStorage['timestamp_string'] = DateTime.now().toIso8601String();
        reportForStorage.remove('timestamp');
      }

      pendingReports.add(jsonEncode(reportForStorage));

      // Keep only last 50 reports to prevent storage bloat
      if (pendingReports.length > 50) {
        pendingReports.removeRange(0, pendingReports.length - 50);
      }

      await prefs.setStringList('pending_crash_reports', pendingReports);
    } catch (e) {
      debugPrint('Failed to store crash report locally: $e');
    }
  }

  static String _categorizeError(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Network Error';
    } else if (errorLower.contains('firebase') || errorLower.contains('firestore')) {
      return 'Firebase Error';
    } else if (errorLower.contains('permission') || errorLower.contains('denied')) {
      return 'Permission Error';
    } else if (errorLower.contains('memory') || errorLower.contains('outofmemory')) {
      return 'Memory Error';
    } else if (errorLower.contains('ui') || errorLower.contains('widget')) {
      return 'UI Error';
    } else if (errorLower.contains('platform') || errorLower.contains('plugin')) {
      return 'Platform/Plugin Error';
    } else if (errorLower.contains('async') || errorLower.contains('future')) {
      return 'Async Error';
    } else if (errorLower.contains('null') && errorLower.contains('reference')) {
      return 'Null Reference Error';
    } else {
      return 'Generic Error';
    }
  }
}

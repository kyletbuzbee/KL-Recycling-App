import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/core/services/crash_reporting_service.dart';

/// Global error boundary widget that catches and reports Flutter errors
class AppErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorView;

  const AppErrorBoundary({
    super.key,
    required this.child,
    this.errorView,
  });

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Set up global Flutter error handler
    FlutterError.onError = _handleFlutterError;
    // Set up platform-specific error handling
    if (!kIsWeb) {
      PlatformDispatcher.instance.onError = _handlePlatformError;
    }
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    _handleError(details.exception, details.stack, 'Flutter Framework Error',
        context: details.context, details: details);
  }

  bool _handlePlatformError(Object error, StackTrace stack) {
    _handleError(error, stack, 'Platform Error');
    return true; // Prevent the error from propagating
  }

  void _handleError(Object error, StackTrace? stack, String errorType,
      {DiagnosticsNode? context, FlutterErrorDetails? details}) {
    // Report error to crash reporting service
    CrashReportingService.reportError(
      error: error,
      stackTrace: stack,
      context: errorType,
      additionalInfo: {
        'error_context': context?.toString(),
        'error_type': errorType,
        if (details != null) 'flutter_details': details.toString(),
      },
    );

    // Update state to show error UI
    if (mounted) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorView ?? const ErrorFallbackScreen();
    }

    // Use ErrorWidget to catch widget build errors
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _handleFlutterError(details);
      return widget.errorView ?? const ErrorFallbackScreen();
    };

    return widget.child;
  }
}

/// Fallback screen shown when errors occur
class ErrorFallbackScreen extends StatelessWidget {
  const ErrorFallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppColors.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We\'ve been notified and are working to fix this issue. Please try restarting the app.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app by popping to root or relaunching
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Restart App'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    // Collect diagnostic info and send report
                    final diagnosticInfo = await _collectDiagnosticInfo();
                    CrashReportingService.sendDiagnosticReport(diagnosticInfo);
                    // Show simple dialog instead of SnackBar since this screen has its own MaterialApp
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Report Sent'),
                        content: const Text('Diagnostic report has been sent successfully. Thank you!'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Send Diagnostic Report'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _collectDiagnosticInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    final info = {
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'platform': Platform.operatingSystem,
      'platform_version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Add basic platform info (device_info_plus not used to avoid dependencies)
    info.addAll({
      'dart_version': Platform.version,
      'number_of_processors': Platform.numberOfProcessors.toString(),
    });

    return info;
  }
}

/// Zone-based error boundary for handling async errors
class AsyncErrorBoundary {
  static void runZonedGuarded(void Function() body, void Function(Object, StackTrace) onError) {
    runZonedGuarded(
      () {
        WidgetsFlutterBinding.ensureInitialized();
        body();
      },
      (error, stackTrace) {
        CrashReportingService.reportError(
          error: error,
          stackTrace: stackTrace,
          context: 'Async Error',
        );
        onError(error, stackTrace);
      },
    );
  }
}

/// Builder pattern for creating error boundaries with custom configurations
class ErrorBoundaryBuilder {
  Widget? _errorView;

  ErrorBoundaryBuilder errorView(Widget errorView) {
    _errorView = errorView;
    return this;
  }

  ErrorBoundaryBuilder reportErrors(bool report) {
    return this;
  }

  ErrorBoundaryBuilder throttleDuration(Duration duration) {
    return this;
  }

  ErrorBoundaryBuilder context(String context) {
    return this;
  }

  Widget build(Widget child) {
    return AppErrorBoundary(
      child: child,
      errorView: _errorView,
    );
  }
}

/// Extension to easily wrap widgets with error boundaries
extension ErrorBoundaryExtension on Widget {
  Widget withErrorBoundary({
    Widget? errorView,
    bool reportErrors = true,
  }) {
    return AppErrorBoundary(
      child: this,
      errorView: errorView,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:kl_recycling_app/config/theme.dart';

class LottieAnimations {
  // Asset paths
  static const String _successCheckPath = 'assets/lottie/success_check.json';
  static const String _recyclingTruckPath = 'assets/lottie/recycling_truck.json';

  /// Shows a success check animation overlay
  static Future<void> showSuccessOverlay(BuildContext context, {
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onComplete,
  }) async {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppBorderRadius.extraLargeBorder,
              boxShadow: AppShadows.floating,
            ),
            child: Lottie.asset(
              _successCheckPath,
              width: 150,
              height: 150,
              repeat: false,
              onLoaded: (composition) {
                Future.delayed(duration, () {
                  overlayEntry?.remove();
                  onComplete?.call();
                });
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  /// Badge unlock celebration animation
  static Widget badgeUnlockAnimation({
    required String badgeTitle,
    required IconData badgeIcon,
    required Color badgeColor,
    VoidCallback? onComplete,
  }) {
    return _BadgeCelebrationWidget(
      badgeTitle: badgeTitle,
      badgeIcon: badgeIcon,
      badgeColor: badgeColor,
      onComplete: onComplete,
    );
  }

  /// Loading animation for data loading
  static Widget loadingAnimation({
    double size = 100,
    String? message,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          _recyclingTruckPath,
          width: size,
          height: size * 0.75,
          repeat: true,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.onSurfaceSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Points earned animation
  static Future<void> showPointsEarned(BuildContext context, {
    required int points,
    Duration duration = const Duration(seconds: 2),
    Offset? position,
  }) async {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position?.dy ?? MediaQuery.of(context).size.height * 0.3,
        left: position?.dx ?? MediaQuery.of(context).size.width * 0.2,
        right: MediaQuery.of(context).size.width * 0.2,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: AppBorderRadius.largeBorder,
                    boxShadow: AppShadows.large,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+$points points!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    await Future.delayed(duration);
    overlayEntry.remove();
  }

  /// Achievement popup for badge unlocks
  static Future<void> showAchievement(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) async {
    final overlayEntry = OverlayEntry(
      builder: (context) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: AnimationController(
            vsync: ScaffoldMessenger.of(context).context as TickerProvider,
            duration: const Duration(milliseconds: 500),
          )..forward(),
          curve: Curves.elasticOut,
        )),
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.9), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppBorderRadius.largeBorder,
                  boxShadow: AppShadows.floating,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: AppBorderRadius.mediumBorder,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => overlayEntry.remove(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Auto remove after 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  }

  /// Environmental impact visualization animation
  static Widget impactVisualization({
    required String impactType, // "trees", "energy", "co2"
    required int value,
    double size = 120,
  }) {
    IconData impactIcon;
    String unit;

    switch (impactType) {
      case 'trees':
        impactIcon = Icons.park;
        unit = 'trees saved';
        break;
      case 'energy':
        impactIcon = Icons.flash_on;
        unit = 'kWh saved';
        break;
      case 'co2':
        impactIcon = Icons.cloud_off;
        unit = 'kg CO₂ avoided';
        break;
      default:
        impactIcon = Icons.eco;
        unit = 'impact';
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            impactIcon,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
/// Badge celebration widget for unlock animations
class _BadgeCelebrationWidget extends StatefulWidget {
  final String badgeTitle;
  final IconData badgeIcon;
  final Color badgeColor;
  final VoidCallback? onComplete;

  const _BadgeCelebrationWidget({
    required this.badgeTitle,
    required this.badgeIcon,
    required this.badgeColor,
    this.onComplete,
  });

  @override
  State<_BadgeCelebrationWidget> createState() => _BadgeCelebrationWidgetState();
}

class _BadgeCelebrationWidgetState extends State<_BadgeCelebrationWidget> {
  bool showAnimation = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => showAnimation = false);
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: showAnimation ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🎉',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.badgeColor.withOpacity(0.1),
                  borderRadius: AppBorderRadius.extraLargeBorder,
                  border: Border.all(
                    color: widget.badgeColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.badgeColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      widget.badgeIcon,
                      size: 48,
                      color: widget.badgeColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'New Badge Unlocked!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: widget.badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.badgeTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Keep up the great work!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension to add Lottie to existing widgets
extension LottieExtensions on Widget {
  /// Wraps the widget in a Lottie-powered celebration effect
  Widget withCelebration({
    String message = 'Amazing!',
    Duration duration = const Duration(seconds: 2),
  }) {
    return _CelebrationWrapper(
      child: this,
      message: message,
      duration: duration,
    );
  }
}

class _CelebrationWrapper extends StatefulWidget {
  final Widget child;
  final String message;
  final Duration duration;

  const _CelebrationWrapper({
    required this.child,
    required this.message = 'Amazing!',
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<_CelebrationWrapper> createState() => _CelebrationWrapperState();
}

class _CelebrationWrapperState extends State<_CelebrationWrapper> {
  bool showCelebration = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) {
        setState(() => showCelebration = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (showCelebration)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/success_check.json',
                    width: 150,
                    height: 150,
                    repeat: false,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

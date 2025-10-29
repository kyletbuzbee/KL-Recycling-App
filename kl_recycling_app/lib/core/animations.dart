import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AppAnimations {
  // Staggered animation configurations
  static const Duration staggerDelay = Duration(milliseconds: 100);
  static const Duration staggerDuration = Duration(milliseconds: 400);

  // Common animation durations
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Ease curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve bounceOut = Curves.bounceOut;

  // Fade in animation for widgets
  static Widget fadeIn(Widget child, {
    Duration? delay,
    Duration? duration,
    Curve? curve,
  }) {
    return child.animate()
        .fadeIn(
          delay: delay ?? Duration.zero,
          duration: duration ?? normalAnimation,
          curve: curve ?? easeOut,
        );
  }

  // Slide in from bottom animation
  static Widget slideUp(Widget child, {
    Duration? delay,
    Duration? duration,
    Curve? curve,
  }) {
    return child.animate()
        .slideY(
          begin: 0.3,
          end: 0.0,
          delay: delay ?? Duration.zero,
          duration: duration ?? normalAnimation,
          curve: curve ?? Curves.easeOutCubic,
        ).fadeIn(
          delay: delay ?? Duration.zero,
          duration: duration ?? normalAnimation,
        );
  }

  // Scale animation
  static Widget scaleIn(Widget child, {
    Duration? delay,
    Duration? duration,
    Curve? curve,
  }) {
    return child.animate()
        .scale(
          delay: delay ?? Duration.zero,
          duration: duration ?? normalAnimation,
          curve: curve ?? Curves.elasticOut,
        );
  }

  // Bounce animation
  static Widget bounceIn(Widget child, {
    Duration? delay,
    Duration? duration,
  }) {
    return child.animate()
        .scale(
          begin: Offset(0.3, 0.3),
          end: Offset(1.0, 1.0),
          delay: delay ?? Duration.zero,
          duration: duration ?? slowAnimation,
          curve: bounceOut,
        ).fadeIn(
          delay: delay ?? Duration.zero,
          duration: quickAnimation,
        );
  }

  // Shimmer loading animation
  static Widget shimmer(Widget child, {
    Duration? duration,
  }) {
    return child.animate()
        .shimmer(
          duration: duration ?? const Duration(seconds: 2),
          delay: Duration.zero,
        );
  }

  // Rotate animation
  static Widget rotateIn(Widget child, {
    Duration? delay,
    Duration? duration,
  }) {
    return child.animate()
        .rotate(
          begin: -0.3,
          end: 0.0,
          delay: delay ?? Duration.zero,
          duration: duration ?? normalAnimation,
          curve: easeOut,
        ).scale(
          begin: Offset(0.8, 0.8),
          end: Offset(1.0, 1.0),
          delay: delay ?? Duration.zero,
          duration: duration ?? normalAnimation,
        );
  }
}

// Staggered list animation wrapper
class StaggeredAnimationList extends StatelessWidget {
  final List<Widget> children;
  final int index;
  final double horizontalOffset;
  final double verticalOffset;

  const StaggeredAnimationList({
    super.key,
    required this.children,
    this.index = 0,
    this.horizontalOffset = 0.0,
    this.verticalOffset = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: AppAnimations.staggerDuration,
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: horizontalOffset,
            verticalOffset: verticalOffset,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}

// Enhanced card animation wrapper
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final VoidCallback? onTap;

  const AnimatedCard({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.onTap,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: isPressed ? 0.95 : 1.0,
        duration: AppAnimations.quickAnimation,
        curve: Curves.elasticOut,
        child: widget.child.animate()
            .slideY(
              begin: 0.2,
              delay: widget.delay,
              duration: AppAnimations.normalAnimation,
            ).fadeIn(
              delay: widget.delay,
              duration: AppAnimations.normalAnimation,
            ),
      ),
    );
  }
}

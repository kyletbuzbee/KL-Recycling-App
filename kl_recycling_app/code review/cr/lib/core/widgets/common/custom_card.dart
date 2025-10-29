import 'package:flutter/material.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/core/animations.dart';

enum CardVariant {
  elevated,
  filled,
  outlined,
  gradient,
}

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final CardVariant variant;
  final Duration animationDelay;
  final bool enableAnimation;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.borderRadius,
    this.onTap,
    this.variant = CardVariant.elevated,
    this.animationDelay = Duration.zero,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = _buildCard(context);

    if (enableAnimation) {
      card = AppAnimations.slideUp(card, delay: animationDelay);
    }

    if (onTap != null) {
      card = AnimatedCard(
        delay: animationDelay,
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }

  Widget _buildCard(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(20);
    final effectiveMargin = margin ?? Theme.of(context).cardTheme.margin;
    final effectiveBorderRadius = borderRadius ?? AppBorderRadius.largeBorder;

    switch (variant) {
      case CardVariant.elevated:
        return Card(
          elevation: elevation ?? 2,
          margin: effectiveMargin,
          shape: RoundedRectangleBorder(
            borderRadius: effectiveBorderRadius,
          ),
          color: color ?? AppColors.surface,
          shadowColor: AppColors.primary.withValues(alpha: 0.15),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: effectiveBorderRadius,
              gradient: AppGradients.cardDepth,
            ),
            child: Padding(
              padding: effectivePadding,
              child: child,
            ),
          ),
        );

      case CardVariant.filled:
        return Container(
          margin: effectiveMargin,
          decoration: BoxDecoration(
            color: color ?? AppColors.surfaceOverlay,
            borderRadius: effectiveBorderRadius,
            boxShadow: [AppShadows.cardShadows],
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        );

      case CardVariant.outlined:
        return Container(
          margin: effectiveMargin,
          decoration: BoxDecoration(
            color: color ?? AppColors.surface,
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        );

      case CardVariant.gradient:
        return Container(
          margin: effectiveMargin,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: effectiveBorderRadius,
          boxShadow: [AppShadows.large],
          ),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        );
    }
  }
}

// Enhanced icon card with specific styling
class IconCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Duration animationDelay;

  const IconCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      variant: CardVariant.filled,
      animationDelay: animationDelay,
      onTap: onTap,
      color: backgroundColor ?? AppColors.surface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: AppBorderRadius.mediumBorder,
              boxShadow: [AppShadows.medium],
            ),
            child: Icon(
              icon,
              size: 28,
              color: iconColor ?? AppColors.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }
}

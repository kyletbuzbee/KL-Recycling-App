import 'package:flutter/material.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/core/widgets/common/custom_card.dart';

/// A wrapper around [CustomCard] that automatically applies the
/// standard themed background color for consistent surface styling.
///
/// This widget is designed to be a drop-in replacement for [CustomCard]
/// when you want a card that contrasts well with the main app background.
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      color: AppColors.surface,
      padding: padding,
      margin: margin,
      child: child,
    );
  }
}
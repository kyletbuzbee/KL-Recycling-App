import 'package:flutter/material.dart';

/// Reusable widget for App PNG icons with proper semantic labeling and accessibility
class AppIconTile extends StatelessWidget {
  final String assetPath;
  final String semanticLabel;
  final double width;
  final double height;
  final Color? color;

  const AppIconTile({
    required this.assetPath,
    required this.semanticLabel,
    this.width = 32,
    this.height = 32,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        color: color,
      ),
    );
  }
}

/// Specialized ElevatedButton icon widget for PNG icons
class AppIconButton extends StatelessWidget {
  final String assetPath;
  final String semanticLabel;
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  const AppIconButton({
    required this.assetPath,
    required this.semanticLabel,
    required this.onPressed,
    this.color,
    this.size = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Semantics(
        label: semanticLabel,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          color: color,
        ),
      ),
    );
  }
}

/// Specialized button with PNG icon and label
class AppIconTextButton extends StatelessWidget {
  final String assetPath;
  final String semanticLabel;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? textColor;
  final double iconSize;

  const AppIconTextButton({
    required this.assetPath,
    required this.semanticLabel,
    required this.label,
    required this.onPressed,
    this.iconColor,
    this.textColor,
    this.iconSize = 20,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Semantics(
        label: semanticLabel,
        child: Image.asset(
          assetPath,
          width: iconSize,
          height: iconSize,
          color: iconColor,
        ),
      ),
      label: Text(
        label,
        style: TextStyle(color: textColor),
      ),
    );
  }
}

/// Specialized ElevatedButton with PNG icon and label
class AppIconElevatedButton extends StatelessWidget {
  final String assetPath;
  final String semanticLabel;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double iconSize;
  final EdgeInsetsGeometry? padding;

  const AppIconElevatedButton({
    required this.assetPath,
    required this.semanticLabel,
    required this.label,
    required this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.foregroundColor,
    this.iconSize = 20,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Semantics(
        label: semanticLabel,
        child: Image.asset(
          assetPath,
          width: iconSize,
          height: iconSize,
          color: iconColor,
        ),
      ),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: padding,
      ),
    );
  }
}

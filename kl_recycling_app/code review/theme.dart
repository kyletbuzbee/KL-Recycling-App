import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Royal Blue palette
  static const Color primary = Color(0xFF0B3D91); // Royal Blue
  static const Color primaryLight = Color(0xFF4F7BFF); // Light Royal Blue
  static const Color primaryDark = Color(0xFF07265A); // Dark Royal Blue

  // Secondary colors - Electric Blue palette
  static const Color secondary = Color(0xFF3B82F6); // Electric Blue
  static const Color secondaryLight = Color(0xFF6BA2FF); // Light Electric Blue
  static const Color secondaryDark = Color(0xFF1E5AA8); // Dark Electric Blue

  // Accent colors
  static const Color accent = Color(0xFFFFFFFF); // White
  static const Color accentSecondary = Color(0xFFF8F9FA); // Light Grey

  // Background colors
  static const Color background = Color(0xFFF8F9FA); // Light Grey
  static const Color surface = Colors.white;
  static const Color surfaceOverlay = Color(0xFFFAFBFC);

  // Semantic colors
  static const Color error = Color(0xFFEF4444); // Error Red
  static const Color warning = Color(0xFFF59E0B); // Warning Amber
  static const Color success = Color(0xFF10B981); // Success Green
  static const Color info = Color(0xFF06B6D4); // Info Cyan

  // Text colors
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onSurface = Color(0xFF4A4A4A); // Slate Gray
  static const Color onSurfaceSecondary = Color(0xFF6B7280); // Light Slate Gray
  static const Color onBackground = Color(0xFF4A4A4A);
}

class AppGradients {
  // Primary gradient
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Hero section gradient
  static const LinearGradient heroBackground = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Soft gradient for overlays
  static LinearGradient softOverlay = LinearGradient(
    colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Card gradient for depth
  static const LinearGradient cardDepth = LinearGradient(
    colors: [Colors.white, Color(0xFFF8F9FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Button gradient
  static const LinearGradient buttonGlow = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppShadows {
  static const BoxShadow small = BoxShadow(
    color: Color(0x0F0B3D91),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow medium = BoxShadow(
    color: Color(0x1F0B3D91),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const BoxShadow large = BoxShadow(
    color: Color(0x29132D46),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  static const BoxShadow floating = BoxShadow(
    color: Color(0x33132D46),
    blurRadius: 32,
    offset: Offset(0, 16),
  );

  static const List<BoxShadow> cardShadows = [
    BoxShadow(
      color: Color(0x1F0B3D91),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0F0B3D91),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}

class AppBorderRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 24.0;

  static const BorderRadius smallBorder = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumBorder = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeBorder = BorderRadius.all(Radius.circular(large));
  static const BorderRadius extraLargeBorder = BorderRadius.all(Radius.circular(extraLarge));

  static const BorderRadius custom = BorderRadius.all(Radius.circular(16));
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.surface,

      colorScheme: const ColorScheme(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onSurface: AppColors.onSurface,
        onError: Colors.white,
        brightness: Brightness.light,
      ),

      textTheme: TextTheme(
        displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.onSurface, height: 1.1),
        displayMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onSurface, height: 1.2),
        displaySmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.onSurface, height: 1.2),
        headlineLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface, height: 1.3),
        headlineMedium: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.onSurface, height: 1.3),
        headlineSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface, height: 1.4),
        titleLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface, height: 1.4),
        titleMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurface, height: 1.4),
        bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.onSurface, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurface, height: 1.5),
        bodySmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.onSurfaceSecondary, height: 1.5),
      ).apply(
        fontFamily: null, // Use default font for now
        displayColor: AppColors.onSurface,
        bodyColor: AppColors.onSurface,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.mediumBorder),
          elevation: 0,
          shadowColor: Colors.transparent,
        ).copyWith(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return AppColors.primaryDark;
            }
            return AppColors.primary;
          }),
          elevation: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return 4;
            }
            return 2;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.mediumBorder),
          side: const BorderSide(color: AppColors.primary, width: 2),
          foregroundColor: AppColors.primary,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.largeBorder),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shadowColor: AppColors.primary.withOpacity(0.1),
        color: AppColors.surface,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.mediumBorder,
          borderSide: const BorderSide(color: AppColors.primaryLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.mediumBorder,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.mediumBorder,
          borderSide: BorderSide(color: AppColors.primaryLight.withOpacity(0.5)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          color: AppColors.onSurfaceSecondary,
          fontSize: 16,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}

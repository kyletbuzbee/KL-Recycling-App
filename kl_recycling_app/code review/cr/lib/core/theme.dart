/// Main theme file that exports all theming components
import 'package:flutter/material.dart';

/// Application Colors
/// Following Material Design 3 color system with accessibility compliance
class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF4169E1);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFA5D6A7);
  static const Color onPrimaryContainer = Color(0xFF1B5E20);

  // Secondary Colors - White and Grey
  static const Color secondary = Color(0xFF616161); // Grey secondary
  static const Color onSecondary = Color(0xFFFFFFFF); // White text on secondary
  static const Color secondaryContainer = Color(0xFFF5F5F5); // Light grey container
  static const Color onSecondaryContainer = Color(0xFF1C1B1F); // Dark grey text on container

  // Surface Colors
  static const Color surface = Color(0xFFFEFFFF);
  static const Color onSurface = Color(0xFF1D1B20);
  static const Color onSurfaceSecondary = Color(0xFF665F65);
  static const Color onSurfaceDisabled = Color(0xFF938F94);

  static const Color surfaceContainer = Color(0xFFF4F3F4);
  static const Color surfaceContainerHigh = Color(0xFFE8EAE4);

  // Error Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // Success/Info Colors
  static const Color success = Color(0xFF146C2E);
  static const Color info = Color(0xFF0061A6);
  static const Color warning = Color(0xFFA65100);

  // Loyalty Points Theme
  static const Color loyaltyBronze = Color(0xFF8D6E63);
  static const Color loyaltySilver = Color(0xFF9E9E9E);
  static const Color loyaltyGold = Color(0xFFFFC107);
  static const Color loyaltyPlatinum = Color(0xFFE8F5E8);

  // Recycling Categories
  static const Color ferrousMetals = Color(0xFF4A5568);
  static const Color nonFerrousMetals = Color(0xFFFF8C00);
  static const Color electronics = Color(0xFF6B46C1);
  static const Color construction = Color(0xFF2D3748);
  static const Color paper = Color(0xFF4299E1);
  static const Color plastics = Color(0xFF9F7AEA);
  static const Color glass = Color(0xFF48BB78);

  // Background Variants for Elevation
  static const Color backgroundPrimary = Color(0xFFFAFAFA);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color backgroundElevated = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Divider and Border Colors
  static const Color divider = Color(0xFFBDBDBD);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFF9E9E9E);

  // Legacy colors for compatibility
  static const Color oldPrimary = Color(0xFF4CAF50);
  static const Color oldAccent = Color(0xFF8BC34A);

  /// Get color based on recycling category
  static Color getRecyclingColor(String category) {
    switch (category.toLowerCase()) {
      case 'ferrous metals':
        return ferrousMetals;
      case 'non-ferrous metals':
        return nonFerrousMetals;
      case 'electronics':
        return electronics;
      case 'construction':
        return construction;
      case 'paper':
        return paper;
      case 'plastics':
        return plastics;
      case 'glass':
        return glass;
      default:
        return primary;
    }
  }

  /// Get loyalty color based on tier
  static Color getLoyaltyColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return loyaltyBronze;
      case 'silver':
        return loyaltySilver;
      case 'gold':
        return loyaltyGold;
      case 'platinum':
        return loyaltyPlatinum;
      default:
        return loyaltyBronze;
    }
  }

  // Legacy properties for compatibility
  static Color get primaryLight => primaryContainer;
  static Color get background => backgroundPrimary;
  static Color get surfaceOverlay => surfaceContainerHigh;
}

/// Application Border Radius
class AppBorderRadius {
  static const double none = 0.0;
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 12.0;
  static const double extraLarge = 16.0;
  static const double round = 24.0;

  static const BorderRadius zero = BorderRadius.zero;
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(large));
  static const BorderRadius extraLargeRadius = BorderRadius.all(Radius.circular(extraLarge));
  static const BorderRadius roundRadius = BorderRadius.all(Radius.circular(round));

  // Legacy properties for compatibility
  static BorderRadius get smallBorder => smallRadius;
  static BorderRadius get mediumBorder => mediumRadius;
  static BorderRadius get largeBorder => largeRadius;
  static BorderRadius get extraLargeBorder => extraLargeRadius;

  static BorderRadius circular(double radius) {
    return BorderRadius.all(Radius.circular(radius));
  }

  static BorderRadius horizontal({double left = medium, double right = medium}) {
    return BorderRadius.horizontal(
      left: Radius.circular(left),
      right: Radius.circular(right),
    );
  }

  static BorderRadius vertical({double top = medium, double bottom = medium}) {
    return BorderRadius.vertical(
      top: Radius.circular(top),
      bottom: Radius.circular(bottom),
    );
  }
}

/// Application Shadows
class AppShadows {
  static const BoxShadow small = BoxShadow(
    color: Color(0x1F000000),
    offset: Offset(0, 1),
    blurRadius: 3,
    spreadRadius: 0,
  );

  static const BoxShadow medium = BoxShadow(
    color: Color(0x24000000),
    offset: Offset(0, 2),
    blurRadius: 4,
    spreadRadius: 0,
  );

  static const BoxShadow large = BoxShadow(
    color: Color(0x29000000),
    offset: Offset(0, 4),
    blurRadius: 8,
    spreadRadius: 0,
  );

  static const BoxShadow extraLarge = BoxShadow(
    color: Color(0x2E000000),
    offset: Offset(0, 8),
    blurRadius: 16,
    spreadRadius: 0,
  );

  // Legacy shadows for compatibility
  static BoxShadow get cardShadows => small;
  static BoxShadow get floating => medium;

  static List<BoxShadow> elevation(double elevation) {
    if (elevation == 0) return [];
    if (elevation <= 1) return [small];
    if (elevation <= 2) return [medium];
    if (elevation <= 4) return [large];
    return [extraLarge];
  }
}

/// Application Gradients
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [AppColors.success, Color(0xFF4ADE80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surface = LinearGradient(
    colors: [AppColors.surface, AppColors.surfaceContainer],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Legacy gradients for compatibility
  static LinearGradient get heroBackground => LinearGradient(
    colors: [AppColors.primary.withOpacity(0.8), AppColors.primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get buttonGlow => LinearGradient(
    colors: [AppColors.primary.withOpacity(0.2), AppColors.primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardDepth => LinearGradient(
    colors: [AppColors.surface.withOpacity(0.95), AppColors.surfaceContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient loyaltyGradient(String tier) {
    final color = AppColors.getLoyaltyColor(tier);
    return LinearGradient(
      colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

/// Application Theme Class
class AppTheme {
  /// Light Theme - Following Material Design 3
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
    ),

    // Typography
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w500,
        height: 1.12,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w500,
        height: 1.12,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        height: 1.15,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.29,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.27,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.50,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.10,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.50,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.10,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.5,
      ),
    ),

    // Component Themes
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 4,
      shadowColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.mediumRadius,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.mediumRadius,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.smallRadius,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: AppBorderRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: AppColors.onSurfaceSecondary),
      hintStyle: const TextStyle(color: AppColors.textHint),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 0,
    ),

    // Additional settings
    scaffoldBackgroundColor: AppColors.backgroundPrimary,
    canvasColor: AppColors.backgroundPrimary,
  );

  /// Dark Theme - Following Material Design 3
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Color Scheme for Dark Theme
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      surface: Color(0xFF0F0F0F),
      onSurface: Color(0xFFE6E1E5),
      surfaceContainer: Color(0xFF2A2929),
      surfaceContainerHigh: Color(0xFF343434),
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
    ),

    // Text theme remains similar but adapted for dark
    textTheme: lightTheme.textTheme.apply(
      bodyColor: const Color(0xFFE6E1E5),
      displayColor: const Color(0xFFE6E1E5),
    ),

    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    canvasColor: const Color(0xFF0F0F0F),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1B1E),
      foregroundColor: Color(0xFFE6E1E5),
      elevation: 4,
      shadowColor: Color(0xFF1C1B1E),
      surfaceTintColor: Colors.transparent,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2929),
      border: OutlineInputBorder(
        borderRadius: AppBorderRadius.mediumRadius,
        borderSide: const BorderSide(color: Color(0xFF938F99)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.mediumRadius,
        borderSide: const BorderSide(color: Color(0xFF938F99)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: Color(0xFFCAC4D0)),
      hintStyle: const TextStyle(color: Color(0xFF938F99)),
    ),
  );

  /// Get theme based on brightness
  static ThemeData getTheme({Brightness? brightness}) {
    if (brightness == Brightness.dark) {
      return darkTheme;
    }
    return lightTheme;
  }
}

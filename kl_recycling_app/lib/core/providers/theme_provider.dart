import 'package:flutter/material.dart';
import 'package:kl_recycling_app/core/theme.dart';

/// Represents different app theme variants
enum AppThemeVariant {
  /// Standard theme with default colors
  standard,

  /// Premium theme with enhanced colors (could be used for loyalty tiers)
  premium,

  /// High contrast theme for accessibility
  highContrast,
}

/// Represents different color schemes for the app
enum ColorSchemeType {
  classic,    // Default KL Recycling colors
  premium,    // Enhanced colors for premium features
}

/// Core theme provider decoupled from specific business logic
class ThemeProvider extends ChangeNotifier {
  AppThemeVariant _currentVariant = AppThemeVariant.standard;
  ColorSchemeType _colorScheme = ColorSchemeType.classic;
  bool _isLoading = false;

  // Getters
  AppThemeVariant get currentVariant => _currentVariant;
  ColorSchemeType get colorScheme => _colorScheme;
  bool get isLoading => _isLoading;

  /// Updates the current theme variant
  void setVariant(AppThemeVariant variant) {
    if (_currentVariant == variant) return;
    _currentVariant = variant;
    notifyListeners();
  }

  /// Updates the color scheme type
  void setColorScheme(ColorSchemeType colorScheme) {
    if (_colorScheme == colorScheme) return;
    _colorScheme = colorScheme;
    notifyListeners();
  }

  /// Gets appropriate primary color based on current settings
  Color get primaryColor {
    switch (_colorScheme) {
      case ColorSchemeType.premium:
        return _currentVariant == AppThemeVariant.premium
            ? Colors.amber.shade700
            : AppColors.primary;
      case ColorSchemeType.classic:
        return AppColors.primary;
    }
  }

  /// Gets appropriate secondary color
  Color get secondaryColor {
    switch (_colorScheme) {
      case ColorSchemeType.premium:
        return _currentVariant == AppThemeVariant.premium
            ? Colors.amber.shade600
            : AppColors.secondary;
      case ColorSchemeType.classic:
        return AppColors.secondary;
    }
  }

  /// Creates a ColorScheme based on current settings
  ColorScheme getColorScheme() {
    final primary = primaryColor;
    final secondary = secondaryColor;
    final isDark = _currentVariant == AppThemeVariant.highContrast;

    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      secondary: secondary,
      surface: isDark ? Colors.grey.shade900 : AppColors.surface,
      onPrimary: isDark ? Colors.black87 : AppColors.onPrimary,
      onSecondary: isDark ? Colors.white : AppColors.onSecondary,
      onSurface: isDark ? Colors.white : AppColors.onSurface,
    );
  }

  /// Builds Material ThemeData for current configuration
  ThemeData get currentTheme {
    final colorScheme = getColorScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: colorScheme.onSurface, height: 1.1),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colorScheme.onSurface, height: 1.2),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: colorScheme.onSurface, height: 1.2),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface, height: 1.3),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface, height: 1.3),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface, height: 1.4),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface, height: 1.4),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface, height: 1.4),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.onSurface, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colorScheme.onSurface, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5),
      ).apply(
        fontFamily: null,
        displayColor: colorScheme.onSurface,
        bodyColor: colorScheme.onSurface,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primaryContainer;
            }
            return colorScheme.primary;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return 4;
            }
            return 2;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: colorScheme.primary, width: 2),
          foregroundColor: colorScheme.primary,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shadowColor: colorScheme.primary.withValues(alpha: 0.1),
        color: colorScheme.surface,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primaryContainer),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primaryContainer),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 16,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  /// Updates theme from loyalty tier (kept for backward compatibility but uses new decoupled approach)
  void updateFromLoyaltyTier(int points) {
    // Determine theme variant based on loyalty points
    if (points >= 5000) {
      setVariant(AppThemeVariant.premium);
      setColorScheme(ColorSchemeType.premium);
    } else if (points >= 2500) {
      setVariant(AppThemeVariant.standard);
      setColorScheme(ColorSchemeType.premium);
    } else {
      setVariant(AppThemeVariant.standard);
      setColorScheme(ColorSchemeType.classic);
    }
  }

  /// Toggles high contrast mode for accessibility
  void toggleHighContrast() {
    setVariant(
      _currentVariant == AppThemeVariant.highContrast
          ? AppThemeVariant.standard
          : AppThemeVariant.highContrast
    );
  }

  /// Sets loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

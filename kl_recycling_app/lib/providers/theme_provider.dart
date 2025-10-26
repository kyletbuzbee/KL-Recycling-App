import 'package:flutter/material.dart';
import 'package:kl_recycling_app/config/theme.dart';

/// Represents the different loyalty tiers with their associated colors
enum LoyaltyTierLevel {
  bronze,
  silver,
  gold,
  platinum;

  String get displayName {
    switch (this) {
      case LoyaltyTierLevel.bronze:
        return 'Bronze';
      case LoyaltyTierLevel.silver:
        return 'Silver';
      case LoyaltyTierLevel.gold:
        return 'Gold';
      case LoyaltyTierLevel.platinum:
        return 'Platinum';
    }
  }

  Color get primaryColor {
    switch (this) {
      case LoyaltyTierLevel.bronze:
        return AppColors.primary;
      case LoyaltyTierLevel.silver:
        return Colors.grey.shade600;
      case LoyaltyTierLevel.gold:
        return Colors.amber.shade700;
      case LoyaltyTierLevel.platinum:
        return Colors.white;
    }
  }

  Color get secondaryColor {
    switch (this) {
      case LoyaltyTierLevel.silver:
        return Colors.grey.shade400;
      case LoyaltyTierLevel.gold:
        return Colors.amber.shade600;
      case LoyaltyTierLevel.platinum:
        return Colors.grey.shade300;
      default:
        return AppColors.secondary;
    }
  }

  Color get onPrimaryColor {
    switch (this) {
      case LoyaltyTierLevel.platinum:
        return Colors.black87;
      default:
        return AppColors.onPrimary;
    }
  }

  Color get surfaceColor {
    switch (this) {
      case LoyaltyTierLevel.platinum:
        return Colors.grey.shade900;
      default:
        return AppColors.surface;
    }
  }

  /// Creates a ColorScheme for this tier level
  ColorScheme toColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: this == LoyaltyTierLevel.platinum ? Brightness.dark : Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      onPrimary: onPrimaryColor,
      onSecondary: onPrimaryColor,
      onSurface: onPrimaryColor == Colors.black87 ? Colors.white : Colors.black87,
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  LoyaltyTierLevel _currentTier = LoyaltyTierLevel.bronze;
  bool _isLoading = false;

  // Getters
  LoyaltyTierLevel get currentTier => _currentTier;
  ColorScheme get currentColorScheme => _currentTier.toColorScheme();
  bool get isLoading => _isLoading;

  /// Updates the current tier and notifies listeners
  void setTier(LoyaltyTierLevel tierLevel) {
    if (_currentTier == tierLevel) return;

    _currentTier = tierLevel;
    notifyListeners();
  }

  /// Gets tier from points
  LoyaltyTierLevel getTierFromPoints(int points) {
    if (points >= 5000) return LoyaltyTierLevel.platinum;
    if (points >= 2500) return LoyaltyTierLevel.gold;
    if (points >= 1000) return LoyaltyTierLevel.silver;
    return LoyaltyTierLevel.bronze;
  }

  /// Updates tier based on user points
  void updateTierFromPoints(int points) {
    final newTier = getTierFromPoints(points);
    setTier(newTier);
  }

  /// Builds Material ThemeData for the current tier
  ThemeData get currentTheme {
    final colorScheme = currentColorScheme;

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

  /// Sets loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

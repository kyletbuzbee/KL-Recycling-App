/// Reference object types for camera calibration and scale estimation
library;
import 'dart:math';

enum ReferenceObjectType {
  /// Coins for scale calibration
  coinQuarter,
  coinPenny,
  coinNickel,
  coinDime,

  /// US coins (aliases for consistency)
  usQuarter,
  usPenny,
  usNickel,
  usDime,

  /// Common reference objects
  rulerStandard,      // 6-inch ruler
  businessCard,       // Standard business card

  /// Custom objects
  customObject,       // User-defined reference object
}

/// Reference object data for calibration
class ReferenceObjectData {
  final String name;
  final String description;
  final Map<String, double> dimensions; // width, height, thickness in inches
  final double? weightGrams;

  const ReferenceObjectData({
    required this.name,
    required this.description,
    required this.dimensions,
    this.weightGrams,
  });

  double get width => dimensions['width'] ?? 0.0;
  double get height => dimensions['height'] ?? 0.0;
  double get thickness => dimensions['thickness'] ?? 0.1;
  double get diameter => dimensions['diameter'] ?? 0.0;

  /// Get the characteristic dimension for scale calculation
  double get scaleReference {
    if (diameter > 0) return diameter;
    return max(width, height);
  }
}

/// Predefined reference objects
const Map<ReferenceObjectType, ReferenceObjectData> referenceObjectData = {
  ReferenceObjectType.coinQuarter: ReferenceObjectData(
    name: 'Quarter Coin',
    description: 'US 25-cent coin',
    dimensions: {'diameter': 0.955, 'thickness': 0.069},
    weightGrams: 5.67,
  ),
  ReferenceObjectType.coinPenny: ReferenceObjectData(
    name: 'Penny Coin',
    description: 'US 1-cent coin',
    dimensions: {'diameter': 0.750, 'thickness': 0.059},
    weightGrams: 2.5,
  ),
  ReferenceObjectType.coinNickel: ReferenceObjectData(
    name: 'Nickel Coin',
    description: 'US 5-cent coin',
    dimensions: {'diameter': 0.835, 'thickness': 0.077},
    weightGrams: 5.0,
  ),
  ReferenceObjectType.coinDime: ReferenceObjectData(
    name: 'Dime Coin',
    description: 'US 10-cent coin',
    dimensions: {'diameter': 0.705, 'thickness': 0.053},
    weightGrams: 2.268,
  ),

  // Aliases for consistency
  ReferenceObjectType.usQuarter: ReferenceObjectData(
    name: 'US Quarter',
    description: 'US 25-cent coin',
    dimensions: {'diameter': 0.955, 'thickness': 0.069},
    weightGrams: 5.67,
  ),
  ReferenceObjectType.usPenny: ReferenceObjectData(
    name: 'US Penny',
    description: 'US 1-cent coin',
    dimensions: {'diameter': 0.750, 'thickness': 0.059},
    weightGrams: 2.5,
  ),
  ReferenceObjectType.usNickel: ReferenceObjectData(
    name: 'US Nickel',
    description: 'US 5-cent coin',
    dimensions: {'diameter': 0.835, 'thickness': 0.077},
    weightGrams: 5.0,
  ),
  ReferenceObjectType.usDime: ReferenceObjectData(
    name: 'US Dime',
    description: 'US 10-cent coin',
    dimensions: {'diameter': 0.705, 'thickness': 0.053},
    weightGrams: 2.268,
  ),

  ReferenceObjectType.rulerStandard: ReferenceObjectData(
    name: 'Standard Ruler',
    description: '6-inch plastic ruler',
    dimensions: {'width': 1.0, 'height': 6.0, 'thickness': 0.0625},
  ),

  ReferenceObjectType.businessCard: ReferenceObjectData(
    name: 'Business Card',
    description: 'Standard business card (3.5" x 2")',
    dimensions: {'width': 3.5, 'height': 2.0, 'thickness': 0.012},
  ),

  ReferenceObjectType.customObject: ReferenceObjectData(
    name: 'Custom Object',
    description: 'User-defined reference object',
    dimensions: {'width': 1.0}, // Placeholder
  ),
};

/// Camera calibration data using reference objects
class CalibrationData {
  final ReferenceObjectType objectType;
  final double pixelsWidth;
  final double pixelsHeight;
  final double realWorldWidth; // inches
  final double realWorldHeight; // inches
  final DateTime calibratedAt;
  final String? imagePath; // Optional image used for calibration

  const CalibrationData({
    required this.objectType,
    required this.pixelsWidth,
    required this.pixelsHeight,
    required this.realWorldWidth,
    required this.realWorldHeight,
    required this.calibratedAt,
    this.imagePath,
  });

  /// Calculate pixels per inch based on calibration
  double get pixelsPerInch => pixelsWidth / realWorldWidth;

  /// Scale factor for conversion
  double getInchFromPixels(double pixels) => pixels / pixelsPerInch;

  /// Factory method for common reference objects
  factory CalibrationData.fromReferenceObject(
    ReferenceObjectType type,
    double detectedPixelsWidth,
    double detectedPixelsHeight,
  ) {
    final objectData = referenceObjectData[type]!;
    return CalibrationData(
      objectType: type,
      pixelsWidth: detectedPixelsWidth,
      pixelsHeight: detectedPixelsHeight,
      realWorldWidth: objectData.scaleReference,
      realWorldHeight: objectData.dimensions.containsKey('thickness')
          ? objectData.dimensions['thickness']!
          : objectData.scaleReference,
      calibratedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectType': objectType.name,
      'pixelsWidth': pixelsWidth,
      'pixelsHeight': pixelsHeight,
      'realWorldWidth': realWorldWidth,
      'realWorldHeight': realWorldHeight,
      'calibratedAt': calibratedAt.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory CalibrationData.fromJson(Map<String, dynamic> json) {
    return CalibrationData(
      objectType: ReferenceObjectType.values.firstWhere(
        (e) => e.name == json['objectType'],
        orElse: () => ReferenceObjectType.coinQuarter,
      ),
      pixelsWidth: json['pixelsWidth'],
      pixelsHeight: json['pixelsHeight'],
      realWorldWidth: json['realWorldWidth'],
      realWorldHeight: json['realWorldHeight'] ?? 0.1, // fallback
      calibratedAt: DateTime.parse(json['calibratedAt']),
      imagePath: json['imagePath'],
    );
  }
}

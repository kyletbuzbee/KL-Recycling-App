import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

class AdvancedImageProcessor {
  final int _defaultInputSize = 224;
  final int _depthMapSize = 64;

  /// Process image for ML model input
  Future<Map<String, dynamic>> processImage(
    ui.Image image, {
    bool enhanceContrast = true,
    bool normalizeLighting = true,
    bool extractEdges = false,
  }) async {
    final results = <String, dynamic>{};
    final startTime = DateTime.now();

    try {
      // Convert ui.Image to processable format
      final processedImage = await _convertImage(image);
      
      // Step 1: Resize to standard input size
      final resizedImage = await _resizeImage(processedImage, _defaultInputSize, _defaultInputSize);
      results['resized'] = resizedImage;

      // Step 2: Contrast enhancement
      if (enhanceContrast) {
        final enhancedImage = _enhanceContrast(resizedImage);
        results['contrast_enhanced'] = enhancedImage;
      }

      // Step 3: Lighting normalization
      if (normalizeLighting) {
        final normalizedImage = _normalizeLighting(resizedImage);
        results['normalized'] = normalizedImage;
      }

      // Step 4: Edge extraction
      if (extractEdges) {
        final edges = _extractEdges(resizedImage);
        results['edges'] = edges;
      }

      // Calculate processing time
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      results['processing_time_ms'] = processingTime;

      return results;
    } catch (e) {
      results['error'] = e.toString();
      results['processing_time_ms'] = DateTime.now().difference(startTime).inMilliseconds;
      return results;
    }
  }

  /// Convert ui.Image to processable format
  Future<Map<String, dynamic>> _convertImage(ui.Image image) async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytes == null) throw Exception('Failed to convert image');

    return {
      'width': image.width,
      'height': image.height,
      'bytes': bytes.buffer.asUint8List(),
    };
  }

  /// Resize image to target dimensions
  Future<Map<String, dynamic>> _resizeImage(
    Map<String, dynamic> imageData,
    int targetWidth,
    int targetHeight,
  ) async {
    // Simplified resize - in a real implementation, you'd use image processing library
    final width = imageData['width'] as int;
    final height = imageData['height'] as int;
    final bytes = imageData['bytes'] as Uint8List;

    // Calculate scale factors
    final scaleX = targetWidth / width;
    final scaleY = targetHeight / height;

    // Create resized image data
    final resizedBytes = Uint8List(targetWidth * targetHeight * 4); // RGBA

    // Simple nearest-neighbor resize
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final srcX = (x / scaleX).round();
        final srcY = (y / scaleY).round();
        final srcIndex = (srcY * width + srcX) * 4;
        final destIndex = (y * targetWidth + x) * 4;

        if (srcIndex + 3 < bytes.length && destIndex + 3 < resizedBytes.length) {
          resizedBytes[destIndex] = bytes[srcIndex]; // R
          resizedBytes[destIndex + 1] = bytes[srcIndex + 1]; // G
          resizedBytes[destIndex + 2] = bytes[srcIndex + 2]; // B
          resizedBytes[destIndex + 3] = bytes[srcIndex + 3]; // A
        }
      }
    }

    return {
      'width': targetWidth,
      'height': targetHeight,
      'bytes': resizedBytes,
    };
  }

  /// Enhance image contrast using simplified algorithm
  Map<String, dynamic> _enhanceContrast(Map<String, dynamic> imageData) {
    final width = imageData['width'] as int;
    final height = imageData['height'] as int;
    final bytes = imageData['bytes'] as Uint8List;

    final enhancedBytes = Uint8List.fromList(bytes);

    // Simple contrast enhancement
    for (int i = 0; i < enhancedBytes.length; i += 4) {
      final r = enhancedBytes[i];
      final g = enhancedBytes[i + 1];
      final b = enhancedBytes[i + 2];

      // Calculate luminance
      final luminance = (0.299 * r + 0.587 * g + 0.114 * b).round();

      // Enhance contrast
      final enhanced = ((luminance - 128) * 1.2 + 128).round().clamp(0, 255);

      enhancedBytes[i] = enhanced;
      enhancedBytes[i + 1] = enhanced;
      enhancedBytes[i + 2] = enhanced;
    }

    return {
      'width': width,
      'height': height,
      'bytes': enhancedBytes,
    };
  }

  /// Normalize lighting conditions
  Map<String, dynamic> _normalizeLighting(Map<String, dynamic> imageData) {
    final width = imageData['width'] as int;
    final height = imageData['height'] as int;
    final bytes = imageData['bytes'] as Uint8List;

    final normalizedBytes = Uint8List.fromList(bytes);

    // Calculate global statistics
    double meanBrightness = 0.0;
    final pixels = <double>[];

    for (int i = 0; i < bytes.length; i += 4) {
      final r = bytes[i];
      final g = bytes[i + 1];
      final b = bytes[i + 2];
      final brightness = (r + g + b) / 3.0;
      pixels.add(brightness);
      meanBrightness += brightness;
    }
    meanBrightness /= pixels.length;

    // Calculate variance
    double variance = 0.0;
    for (final brightness in pixels) {
      variance += (brightness - meanBrightness) * (brightness - meanBrightness);
    }
    variance /= pixels.length;
    final stdDev = math.sqrt(variance);

    // Apply normalization
    for (int i = 0; i < normalizedBytes.length; i += 4) {
      final r = normalizedBytes[i];
      final g = normalizedBytes[i + 1];
      final b = normalizedBytes[i + 2];
      
      final brightness = (r + g + b) / 3.0;
      final normalizedBrightness = stdDev > 0 
          ? (brightness - meanBrightness) / (stdDev * 2) + 0.5
          : 0.5;
      final clampedBrightness = normalizedBrightness.clamp(0.0, 1.0) * 255;

      final newValue = clampedBrightness.round().clamp(0, 255);
      normalizedBytes[i] = newValue;
      normalizedBytes[i + 1] = newValue;
      normalizedBytes[i + 2] = newValue;
    }

    return {
      'width': width,
      'height': height,
      'bytes': normalizedBytes,
    };
  }

  /// Extract edges using simplified gradient
  Map<String, dynamic> _extractEdges(Map<String, dynamic> imageData) {
    final width = imageData['width'] as int;
    final height = imageData['height'] as int;
    final bytes = imageData['bytes'] as Uint8List;

    final edgeBytes = Uint8List.fromList(bytes);

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final index = (y * width + x) * 4;
        final leftIndex = (y * width + (x - 1)) * 4;
        final rightIndex = (y * width + (x + 1)) * 4;
        final upIndex = ((y - 1) * width + x) * 4;
        final downIndex = ((y + 1) * width + x) * 4;

        // Calculate gradients

        final leftLuma = (bytes[leftIndex] + bytes[leftIndex + 1] + bytes[leftIndex + 2]) / 3.0;
        final rightLuma = (bytes[rightIndex] + bytes[rightIndex + 1] + bytes[rightIndex + 2]) / 3.0;
        final upLuma = (bytes[upIndex] + bytes[upIndex + 1] + bytes[upIndex + 2]) / 3.0;
        final downLuma = (bytes[downIndex] + bytes[downIndex + 1] + bytes[downIndex + 2]) / 3.0;

        final gradX = (rightLuma - leftLuma).abs();
        final gradY = (downLuma - upLuma).abs();
        final magnitude = math.sqrt(gradX * gradX + gradY * gradY).round().clamp(0, 255);

        edgeBytes[index] = magnitude;
        edgeBytes[index + 1] = magnitude;
        edgeBytes[index + 2] = magnitude;
      }
    }

    return {
      'width': width,
      'height': height,
      'bytes': edgeBytes,
    };
  }







  /// Calculate bounding box of bright areas
  ({int x, int y, int width, int height}) _calculateBoundingBox(Uint8List bytes, int width, int height) {
    int minX = width, minY = height, maxX = 0, maxY = 0;
    bool found = false;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixelIndex = (y * width + x) * 4;
        final brightness = (bytes[pixelIndex] + bytes[pixelIndex + 1] + bytes[pixelIndex + 2]) / 3.0;
        
        if (brightness > 100) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
          found = true;
        }
      }
    }

    return found 
        ? (x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        : (x: 0, y: 0, width: width, height: height);
  }

  /// Calculate area of bright regions
  int _calculateArea(Uint8List bytes, int width, int height) {
    int area = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixelIndex = (y * width + x) * 4;
        final brightness = (bytes[pixelIndex] + bytes[pixelIndex + 1] + bytes[pixelIndex + 2]) / 3.0;
        if (brightness > 100) area++;
      }
    }
    return area;
  }

  /// Calculate perimeter of bright regions
  int _calculatePerimeter(Uint8List bytes, int width, int height) {
    int perimeter = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixelIndex = (y * width + x) * 4;
        final brightness = (bytes[pixelIndex] + bytes[pixelIndex + 1] + bytes[pixelIndex + 2]) / 3.0;
        
        if (brightness > 100) {
          bool isEdge = x == 0 || x == width - 1 || y == 0 || y == height - 1;
          
          if (!isEdge) {
            final neighbors = [
              ((y * width + (x - 1)) * 4),
              ((y * width + (x + 1)) * 4),
              (((y - 1) * width + x) * 4),
              (((y + 1) * width + x) * 4),
            ];

            for (final neighborIndex in neighbors) {
              if (neighborIndex >= 0 && neighborIndex + 2 < bytes.length) {
                final neighborBrightness = (bytes[neighborIndex] + bytes[neighborIndex + 1] + bytes[neighborIndex + 2]) / 3.0;
                if (neighborBrightness <= 100) {
                  isEdge = true;
                  break;
                }
              }
            }
          }

          if (isEdge) perimeter++;
        }
      }
    }
    return perimeter;
  }



  double _calculateAverageBrightness(Uint8List bytes, int width, int height) {
    int totalBrightness = 0;
    int pixelCount = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixelIndex = (y * width + x) * 4;
        final brightness = (bytes[pixelIndex] + bytes[pixelIndex + 1] + bytes[pixelIndex + 2]) / 3.0;
        totalBrightness += brightness.round();
        pixelCount++;
      }
    }

    return pixelCount > 0 ? totalBrightness / pixelCount / 255.0 : 0.5;
  }

  double _calculateContrast(Uint8List bytes, int width, int height) {
    final brightnesses = <int>[];

    for (int y = 0; y < height; y += 4) {
      for (int x = 0; x < width; x += 4) {
        final pixelIndex = (y * width + x) * 4;
        final brightness = (bytes[pixelIndex] + bytes[pixelIndex + 1] + bytes[pixelIndex + 2]) / 3.0;
        brightnesses.add(brightness.round());
      }
    }

    if (brightnesses.isEmpty) return 0.5;

    final mean = brightnesses.reduce((a, b) => a + b) / brightnesses.length;
    final variance = brightnesses.map((b) => (b - mean) * (b - mean)).reduce((a, b) => a + b) / brightnesses.length;

    return math.sqrt(variance) / 127.5;
  }

  double _calculateEntropy(Uint8List bytes, int width, int height) {
    final histogram = List<int>.filled(256, 0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixelIndex = (y * width + x) * 4;
        final brightness = (bytes[pixelIndex] + bytes[pixelIndex + 1] + bytes[pixelIndex + 2]) / 3.0;
        histogram[brightness.round().clamp(0, 255)]++;
      }
    }

    double entropy = 0.0;
    final totalPixels = width * height;

    for (final count in histogram) {
      if (count > 0) {
        final p = count / totalPixels;
        entropy -= p * math.log(p) / math.log(2.0);
      }
    }

    return entropy;
  }

  double _detectMetalObjects(Uint8List bytes, int width, int height) {
    int metalLikePixels = 0;
    int totalPixels = 0;

    for (int y = 0; y < height; y += 4) {
      for (int x = 0; x < width; x += 4) {
        final pixelIndex = (y * width + x) * 4;
        final r = bytes[pixelIndex];
        final g = bytes[pixelIndex + 1];
        final b = bytes[pixelIndex + 2];

        final isMetalLike = (math.max(r, math.max(g, b)) - math.min(r, math.min(g, b))) > 30 &&
                           ((r + g + b) / 3) > 80 &&
                           ((r + g + b) / 3) < 200;

        if (isMetalLike) metalLikePixels++;
        totalPixels++;
      }
    }

    return totalPixels > 0 ? metalLikePixels / totalPixels : 0.0;
  }

  double _calculateShapeRegularity(Uint8List bytes, int width, int height) {
    final bbox = _calculateBoundingBox(bytes, width, height);
    final area = _calculateArea(bytes, width, height);
    final expectedArea = bbox.width * bbox.height;

    return expectedArea > 0 ? math.min(area / expectedArea, 1.0) : 0.0;
  }

  double _detectDepthCues(Uint8List bytes, int width, int height) {
    int strongGradients = 0;
    int totalPixels = 0;

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final pixelIndex = (y * width + x) * 4;
        final rightIndex = (y * width + (x + 1)) * 4;
        final downIndex = ((y + 1) * width + x) * 4;

        final center = (bytes[pixelIndex] + bytes[pixelIndex + 1] + bytes[pixelIndex + 2]) / 3.0;
        final right = (bytes[rightIndex] + bytes[rightIndex + 1] + bytes[rightIndex + 2]) / 3.0;
        final down = (bytes[downIndex] + bytes[downIndex + 1] + bytes[downIndex + 2]) / 3.0;

        final gradX = (right - center).abs();
        final gradY = (down - center).abs();

        if (gradX > 50 || gradY > 50) strongGradients++;
        totalPixels++;
      }
    }

    return totalPixels > 0 ? strongGradients / totalPixels : 0.0;
  }


}

/// Image characteristics for ensemble optimization
class ImageCharacteristics {
  final bool hasClearMetalObjects;
  final bool hasDepthCues;
  final bool isRegularShape;
  final double imageClarity;
  final int estimatedObjectCount;

  ImageCharacteristics({
    this.hasClearMetalObjects = false,
    this.hasDepthCues = false,
    this.isRegularShape = false,
    this.imageClarity = 0.5,
    this.estimatedObjectCount = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'hasClearMetalObjects': hasClearMetalObjects,
      'hasDepthCues': hasDepthCues,
      'isRegularShape': isRegularShape,
      'imageClarity': imageClarity,
      'estimatedObjectCount': estimatedObjectCount,
    };
  }
}

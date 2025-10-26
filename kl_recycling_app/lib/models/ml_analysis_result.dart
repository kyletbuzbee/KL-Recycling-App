import 'package:cloud_firestore/cloud_firestore.dart';

/// ML analysis result model for storing AI/ML analysis data for business intelligence
class MlAnalysisResult {
  final String id;
  final String photoId;
  final String? userId; // Optional, for tracking if we add auth
  final List<DetectedMaterial> detectedMaterials;
  final AnalysisMetadata metadata;
  final QualityScore qualityScore;
  final Recommendations recommendations;
  final DateTime analyzedAt;
  final DateTime createdAt;
  final String deviceInfo;
  final GpsCoordinates? location;

  MlAnalysisResult({
    required this.id,
    required this.photoId,
    this.userId,
    required this.detectedMaterials,
    required this.metadata,
    required this.qualityScore,
    required this.recommendations,
    required this.analyzedAt,
    required this.createdAt,
    required this.deviceInfo,
    this.location,
  });

  factory MlAnalysisResult.fromMap(String id, Map<String, dynamic> map) {
    return MlAnalysisResult(
      id: id,
      photoId: map['photoId'] ?? '',
      userId: map['userId'],
      detectedMaterials: (map['detectedMaterials'] as List<dynamic>?)
          ?.map((m) => DetectedMaterial.fromMap(m as Map<String, dynamic>))
          .toList() ?? [],
      metadata: AnalysisMetadata.fromMap(map['metadata'] ?? {}),
      qualityScore: QualityScore.fromMap(map['qualityScore'] ?? {}),
      recommendations: Recommendations.fromMap(map['recommendations'] ?? {}),
      analyzedAt: (map['analyzedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deviceInfo: map['deviceInfo'] ?? 'unknown',
      location: map['location'] != null
          ? GpsCoordinates.fromMap(map['location'])
          : null,
    );
  }

  factory MlAnalysisResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MlAnalysisResult.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'photoId': photoId,
      'userId': userId,
      'detectedMaterials': detectedMaterials.map((m) => m.toMap()).toList(),
      'metadata': metadata.toMap(),
      'qualityScore': qualityScore.toMap(),
      'recommendations': recommendations.toMap(),
      'analyzedAt': Timestamp.fromDate(analyzedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'deviceInfo': deviceInfo,
      'location': location?.toMap(),
    };
  }

  // Helper methods for business intelligence
  List<String> get allDetectedMaterialTypes =>
      detectedMaterials.map((m) => m.materialType).toSet().toList();

  double get averageConfidence =>
      detectedMaterials.isEmpty
          ? 0.0
          : detectedMaterials.map((m) => m.confidence).reduce((a, b) => a + b) / detectedMaterials.length;

  bool get hasHighConfidenceDetection =>
      detectedMaterials.any((m) => m.confidence > 0.8);

  Map<String, dynamic> toBusinessSummary() {
    return {
      'analysisId': id,
      'date': analyzedAt,
      'location': location?.toSummary(),
      'materials': allDetectedMaterialTypes,
      'highConfidence': hasHighConfidenceDetection,
      'qualityRating': qualityScore.overallRating,
      'device': deviceInfo,
      'metadata': metadata.toBusinessData(),
    };
  }

  bool get isAccurate => qualityScore.overallRating >= 0.8;
  String get method => 'tensorflow_lite';
}

/// Individual detected material from ML analysis
class DetectedMaterial {
  final String materialType;
  final double confidence;
  final List<double> boundingBox; // [x, y, width, height] normalized coordinates
  final Map<String, dynamic> additionalData;

  DetectedMaterial({
    required this.materialType,
    required this.confidence,
    required this.boundingBox,
    this.additionalData = const {},
  });

  factory DetectedMaterial.fromMap(Map<String, dynamic> map) {
    return DetectedMaterial(
      materialType: map['materialType'] ?? 'unknown',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      boundingBox: List<double>.from(map['boundingBox'] ?? []),
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialType': materialType,
      'confidence': confidence,
      'boundingBox': boundingBox,
      'additionalData': additionalData,
    };
  }
}

/// Analysis metadata for business intelligence
class AnalysisMetadata {
  final String modelVersion;
  final int processingTimeMs;
  final Map<String, dynamic> modelParameters;
  final List<String> imageCharacteristics;

  AnalysisMetadata({
    required this.modelVersion,
    required this.processingTimeMs,
    this.modelParameters = const {},
    this.imageCharacteristics = const [],
  });

  factory AnalysisMetadata.fromMap(Map<String, dynamic> map) {
    return AnalysisMetadata(
      modelVersion: map['modelVersion'] ?? 'unknown',
      processingTimeMs: map['processingTimeMs'] ?? 0,
      modelParameters: Map<String, dynamic>.from(map['modelParameters'] ?? {}),
      imageCharacteristics: List<String>.from(map['imageCharacteristics'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modelVersion': modelVersion,
      'processingTimeMs': processingTimeMs,
      'modelParameters': modelParameters,
      'imageCharacteristics': imageCharacteristics,
    };
  }

  Map<String, dynamic> toBusinessData() {
    return {
      'modelVersion': modelVersion,
      'processingTimeSeconds': processingTimeMs / 1000,
      'imageQuality': imageCharacteristics,
      'parameters': modelParameters,
    };
  }
}

/// Quality assessment of the photo/analysis
class QualityScore {
  final double overallRating; // 0.0 to 1.0
  final double lightingQuality;
  final double imageClarity;
  final double subjectsInFrame;
  final String qualityDescription;

  QualityScore({
    required this.overallRating,
    required this.lightingQuality,
    required this.imageClarity,
    required this.subjectsInFrame,
    required this.qualityDescription,
  });

  factory QualityScore.fromMap(Map<String, dynamic> map) {
    return QualityScore(
      overallRating: (map['overallRating'] ?? 0.0).toDouble(),
      lightingQuality: (map['lightingQuality'] ?? 0.0).toDouble(),
      imageClarity: (map['imageClarity'] ?? 0.0).toDouble(),
      subjectsInFrame: (map['subjectsInFrame'] ?? 0.0).toDouble(),
      qualityDescription: map['qualityDescription'] ?? 'Not assessed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'overallRating': overallRating,
      'lightingQuality': lightingQuality,
      'imageClarity': imageClarity,
      'subjectsInFrame': subjectsInFrame,
      'qualityDescription': qualityDescription,
    };
  }
}

/// AI-generated recommendations for business insights
class Recommendations {
  final List<String> qualityImprovements;
  final List<String> businessInsights;
  final String overallAssessment;

  Recommendations({
    this.qualityImprovements = const [],
    this.businessInsights = const [],
    required this.overallAssessment,
  });

  factory Recommendations.fromMap(Map<String, dynamic> map) {
    return Recommendations(
      qualityImprovements: List<String>.from(map['qualityImprovements'] ?? []),
      businessInsights: List<String>.from(map['businessInsights'] ?? []),
      overallAssessment: map['overallAssessment'] ?? 'Not analyzed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'qualityImprovements': qualityImprovements,
      'businessInsights': businessInsights,
      'overallAssessment': overallAssessment,
    };
  }
}

/// GPS coordinates for location tracking
class GpsCoordinates {
  final double latitude;
  final double longitude;
  final double? accuracy;

  GpsCoordinates({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  factory GpsCoordinates.fromMap(Map<String, dynamic> map) {
    return GpsCoordinates(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      accuracy: map['accuracy']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    };
  }

  Map<String, dynamic> toSummary() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracy,
    };
  }
}

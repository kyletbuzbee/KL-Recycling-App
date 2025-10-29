enum MaterialType {
  steel,
  aluminum,
  copper,
  brass,
  zinc,
  stainless,
  other,
  unknown
}

enum PhotoQuality {
  poor,
  fair,
  good,
  excellent,
}

class PhotoEstimate {
  final String id;
  final String imagePath;
  final MaterialType materialType;
  final double estimatedWeight;
  final String notes;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double? estimatedValue;

  const PhotoEstimate({
    required this.id,
    required this.imagePath,
    required this.materialType,
    required this.estimatedWeight,
    required this.notes,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.estimatedValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'materialType': materialType.name,
      'estimatedWeight': estimatedWeight,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'estimatedValue': estimatedValue,
    };
  }

  factory PhotoEstimate.fromJson(Map<String, dynamic> json) {
    return PhotoEstimate(
      id: json['id'],
      imagePath: json['imagePath'],
      materialType: MaterialType.values.firstWhere(
        (e) => e.name == json['materialType'],
        orElse: () => MaterialType.unknown,
      ),
      estimatedWeight: json['estimatedWeight'],
      notes: json['notes'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      estimatedValue: json['estimatedValue'],
    );
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String address;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

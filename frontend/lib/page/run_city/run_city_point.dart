import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents one NFC location in the Run City experience.
class RunCityPoint {
  const RunCityPoint({
    required this.id,
    required this.name,
    required this.location,
    this.area,
    this.description,
    this.nfcId,
    this.isNFCEnabled = false,
    this.collected = false,
    this.collectedAt,
    this.coinsEarned,
  });

  final String id;
  final String name;
  final LatLng location;
  final String? area;
  final String? description;
  final String? nfcId;
  final bool isNFCEnabled;
  final bool collected;
  final DateTime? collectedAt;
  final int? coinsEarned;

  RunCityPoint copyWith({
    String? id,
    String? name,
    LatLng? location,
    String? area,
    String? description,
    String? nfcId,
    bool? isNFCEnabled,
    bool? collected,
    DateTime? collectedAt,
    int? coinsEarned,
  }) {
    return RunCityPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      area: area ?? this.area,
      description: description ?? this.description,
      nfcId: nfcId ?? this.nfcId,
      isNFCEnabled: isNFCEnabled ?? this.isNFCEnabled,
      collected: collected ?? this.collected,
      collectedAt: collectedAt ?? this.collectedAt,
      coinsEarned: coinsEarned ?? this.coinsEarned,
    );
  }

  factory RunCityPoint.fromUserMapJson(Map<String, dynamic> json) {
    return RunCityPoint(
      id: json['id'] as String,
      name: json['name'] as String,
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      area: json['area'] as String?,
      description: json['description'] as String?,
      nfcId: json['nfcId'] as String?,
      isNFCEnabled: (json['isNFCEnabled'] as bool?) ?? false,
      collected: (json['isCollected'] as bool?) ?? false,
      collectedAt: json['collectedAt'] != null
          ? DateTime.tryParse(json['collectedAt'] as String)
          : null,
    );
  }
}

class RunCityTrackPoint {
  const RunCityTrackPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toUtc().toIso8601String(),
        if (accuracy != null) 'accuracy': accuracy,
      };
}

class RunCityActivitySession {
  const RunCityActivitySession({
    required this.activityId,
    required this.startTime,
    required this.status,
  });

  final String activityId;
  final DateTime startTime;
  final String status;
}

class RunCityActivitySummary {
  const RunCityActivitySummary({
    required this.activityId,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationSeconds,
    required this.averageSpeedKmh,
    required this.route,
    required this.collectedLocations,
    required this.totalCoinsEarned,
  });

  final String activityId;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final int durationSeconds;
  final double averageSpeedKmh;
  final List<RunCityTrackPoint> route;
  final List<RunCityPoint> collectedLocations;
  final int totalCoinsEarned;
}

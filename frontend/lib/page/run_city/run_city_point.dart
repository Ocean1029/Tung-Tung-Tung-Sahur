import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

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

class RunCityUserProfile {
  const RunCityUserProfile({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.totalCoins = 0,
    this.totalDistanceKm = 0,
    this.totalTimeSeconds = 0,
    this.updatedAt,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final int totalCoins;
  final double totalDistanceKm;
  final int totalTimeSeconds;
  final DateTime? updatedAt;

  String get formattedTotalDistance {
    if (totalDistanceKm <= 0) {
      return '0 公里';
    }
    if (totalDistanceKm < 1) {
      return '${(totalDistanceKm * 1000).toStringAsFixed(0)} 公尺';
    }
    if (totalDistanceKm == totalDistanceKm.roundToDouble()) {
      return '${totalDistanceKm.toInt()} 公里';
    }
    return '${totalDistanceKm.toStringAsFixed(1)} 公里';
  }

  String get formattedTotalTime {
    if (totalTimeSeconds <= 0) {
      return '0 分鐘';
    }
    final hours = totalTimeSeconds ~/ 3600;
    final minutes = (totalTimeSeconds % 3600) ~/ 60;
    final seconds = totalTimeSeconds % 60;
    if (hours > 0) {
      return '${hours}小時${minutes}分';
    }
    if (minutes > 0) {
      return '${minutes}分${seconds}秒';
    }
    return '${seconds}秒';
  }
}

class RunCityBadge {
  const RunCityBadge({
    required this.id,
    required this.name,
    required this.pointIds,
    required this.collectedPointIds,
    required this.distanceMeters,
  });

  final String id;
  final String name;
  final List<String> pointIds;
  final List<String> collectedPointIds;
  final double distanceMeters;

  int get totalPoints => pointIds.length;
  int get collectedPoints => collectedPointIds.length;
  List<String> get remainingPointIds =>
      pointIds.where((id) => !collectedPointIds.contains(id)).toList();
  bool get isCompleted => remainingPointIds.isEmpty;
  double get completionRate =>
      totalPoints == 0 ? 0 : collectedPoints / totalPoints;
  double get distanceKm => distanceMeters / 1000;

  RunCityBadge copyWith({
    List<String>? collectedPointIds,
    double? distanceMeters,
  }) {
    return RunCityBadge(
      id: id,
      name: name,
      pointIds: pointIds,
      collectedPointIds: collectedPointIds ?? this.collectedPointIds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}

/// 活動列表項目（用於歷史紀錄）
class RunCityActivityItem {
  const RunCityActivityItem({
    required this.activityId,
    required this.date,
    required this.distance,
    required this.duration,
    required this.averageSpeed,
    required this.coinsEarned,
    required this.collectedLocationsCount,
  });

  final String activityId;
  final DateTime date;
  final double distance; // 公里
  final int duration; // 秒
  final double averageSpeed; // 公里/小時
  final int coinsEarned;
  final int collectedLocationsCount;

  factory RunCityActivityItem.fromJson(Map<String, dynamic> json) {
    return RunCityActivityItem(
      activityId: json['activityId'] as String,
      date: DateTime.parse(json['date'] as String).toUtc(),
      distance: (json['distance'] as num).toDouble(),
      duration: json['duration'] as int,
      averageSpeed: (json['averageSpeed'] as num).toDouble(),
      coinsEarned: json['coinsEarned'] as int,
      collectedLocationsCount: json['collectedLocationsCount'] as int,
    );
  }

  /// 格式化距離
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} 公尺';
    }
    // 如果距離是整數，不顯示小數點
    if (distance == distance.roundToDouble()) {
      return '${distance.toInt()} km';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  /// 格式化時間
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}小時${minutes}分';
    } else if (minutes > 0) {
      return '${minutes}分${seconds}秒';
    } else {
      return '${seconds}秒';
    }
  }

  /// 取得開始時間（date 就是開始時間）
  DateTime get startTime => date;

  /// 取得結束時間（開始時間 + duration）
  DateTime get endTime => date.add(Duration(seconds: duration));

  /// 格式化時間範圍（開始時間～結束時間）
  String get formattedTimeRange {
    final startFormat = DateFormat('HH:mm');
    final endFormat = DateFormat('HH:mm');
    return '${startFormat.format(startTime)}~${endFormat.format(endTime)}';
  }
}

import 'package:json_annotation/json_annotation.dart';
import 'package:town_pass/util/json_converter/datetime_converter.dart';

part 'run_city.g.dart';

/// Run City 用戶資料回應
@JsonSerializable(explicitToJson: true)
class RunCityUserDataResponse {
  @JsonKey(name: 'status')
  final int status;

  @JsonKey(name: 'message')
  final String? message;

  @JsonKey(name: 'data')
  final RunCityUserData data;

  const RunCityUserDataResponse({
    required this.status,
    this.message,
    required this.data,
  });

  factory RunCityUserDataResponse.fromJson(Map<String, dynamic> json) =>
      _$RunCityUserDataResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RunCityUserDataResponseToJson(this);
}

/// Run City 用戶資料
@JsonSerializable(explicitToJson: true)
class RunCityUserData {
  /// 用戶 ID
  @JsonKey(name: 'user_id')
  final String userId;

  /// 用戶姓名
  @JsonKey(name: 'name')
  final String name;

  /// 用戶頭貼 URL
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// 開通日期
  @DateTimeConverter()
  @JsonKey(name: 'activated_at')
  final DateTime? activatedAt;

  /// 累積行走距離（公里）
  @JsonKey(name: 'total_distance')
  final double totalDistance;

  /// 累積行走時間（秒）
  @JsonKey(name: 'total_time')
  final int totalTime;

  /// 已獲得金幣
  @JsonKey(name: 'total_coins')
  final int totalCoins;

  /// 最後更新時間
  @DateTimeConverter()
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const RunCityUserData({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.activatedAt,
    required this.totalDistance,
    required this.totalTime,
    required this.totalCoins,
    this.updatedAt,
  });

  factory RunCityUserData.fromJson(Map<String, dynamic> json) =>
      _$RunCityUserDataFromJson(json);

  Map<String, dynamic> toJson() => _$RunCityUserDataToJson(this);

  /// 格式化累積時間為小時:分鐘:秒
  String get formattedTotalTime {
    final hours = totalTime ~/ 3600;
    final minutes = (totalTime % 3600) ~/ 60;
    final seconds = totalTime % 60;
    
    if (hours > 0) {
      return '${hours}小時${minutes}分鐘${seconds}秒';
    } else if (minutes > 0) {
      return '${minutes}分鐘${seconds}秒';
    } else {
      return '${seconds}秒';
    }
  }

  /// 格式化累積距離（保留一位小數）
  String get formattedTotalDistance {
    return '${totalDistance.toStringAsFixed(1)} 公里';
  }
}


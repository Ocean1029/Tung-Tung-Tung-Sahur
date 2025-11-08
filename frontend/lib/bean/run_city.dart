import 'package:json_annotation/json_annotation.dart';
import 'package:town_pass/util/json_converter/datetime_string_converter.dart';

part 'run_city.g.dart';

/// Run City 用戶資料回應（符合後端 API 格式）
@JsonSerializable(explicitToJson: true)
class RunCityUserDataResponse {
  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'data')
  final RunCityUserData? data;

  @JsonKey(name: 'error')
  final RunCityError? error;

  const RunCityUserDataResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory RunCityUserDataResponse.fromJson(Map<String, dynamic> json) =>
      _$RunCityUserDataResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RunCityUserDataResponseToJson(this);
}

/// 錯誤回應格式
@JsonSerializable(explicitToJson: true)
class RunCityError {
  @JsonKey(name: 'code')
  final String code;

  @JsonKey(name: 'message')
  final String message;

  const RunCityError({
    required this.code,
    required this.message,
  });

  factory RunCityError.fromJson(Map<String, dynamic> json) =>
      _$RunCityErrorFromJson(json);

  Map<String, dynamic> toJson() => _$RunCityErrorToJson(this);
}

/// Run City 用戶資料（符合後端 API 格式）
@JsonSerializable(explicitToJson: true)
class RunCityUserData {
  /// 用戶 ID
  @JsonKey(name: 'userId')
  final String userId;

  /// 用戶姓名
  @JsonKey(name: 'name')
  final String name;

  /// 用戶 Email
  @JsonKey(name: 'email')
  final String? email;

  /// 用戶頭貼 URL
  @JsonKey(name: 'avatar')
  final String? avatar;

  /// 已獲得金幣
  @JsonKey(name: 'totalCoins')
  final int totalCoins;

  /// 建立時間
  @DateTimeStringConverter()
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  /// 最後更新時間
  @DateTimeStringConverter()
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  const RunCityUserData({
    required this.userId,
    required this.name,
    this.email,
    this.avatar,
    required this.totalCoins,
    this.createdAt,
    this.updatedAt,
  });

  factory RunCityUserData.fromJson(Map<String, dynamic> json) =>
      _$RunCityUserDataFromJson(json);

  Map<String, dynamic> toJson() => _$RunCityUserDataToJson(this);

  /// 取得頭貼 URL（兼容舊的 avatarUrl 欄位名）
  String? get avatarUrl => avatar;

  /// 取得開通日期（使用 createdAt）
  DateTime? get activatedAt => createdAt;
}


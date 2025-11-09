import 'package:json_annotation/json_annotation.dart';

/// DateTime Converter for ISO 8601 string format (e.g., "2024-06-03T00:00:00Z")
/// 後端傳入的時間都是 UTC (GMT+0)，自動轉換為 GMT+8
class DateTimeStringConverter implements JsonConverter<DateTime, String> {
  const DateTimeStringConverter();

  @override
  DateTime fromJson(String json) {
    // 後端傳入的是 UTC 時間（GMT+0），轉換為 GMT+8
    final utcTime = DateTime.parse(json).toUtc();
    return utcTime.add(const Duration(hours: 8));
  }

  @override
  String toJson(DateTime datetime) => datetime.toIso8601String();
}


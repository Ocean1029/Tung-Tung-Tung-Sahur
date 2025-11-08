import 'package:json_annotation/json_annotation.dart';

/// DateTime Converter for ISO 8601 string format (e.g., "2024-06-03T00:00:00Z")
class DateTimeStringConverter implements JsonConverter<DateTime, String> {
  const DateTimeStringConverter();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json);
  }

  @override
  String toJson(DateTime datetime) => datetime.toIso8601String();
}


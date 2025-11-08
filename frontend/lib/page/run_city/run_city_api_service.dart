import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:town_pass/page/run_city/run_city_point.dart';

class RunCityApiException implements Exception {
  const RunCityApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'RunCityApiException(statusCode: $statusCode, message: $message)';
}

class RunCityApiService extends GetxService {
  RunCityApiService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        baseUrl = baseUrl ??
            const String.fromEnvironment(
              'RUN_CITY_API_BASE_URL',
              defaultValue: 'https://api.townpass.dev',
            );

  final http.Client _httpClient;
  final String baseUrl;

  @override
  void onClose() {
    _httpClient.close();
    super.onClose();
  }

  Future<List<RunCityPoint>> fetchLocations({
    String? badge,
    int? page,
    int? limit,
  }) async {
    final response = await _get(
      '/api/locations',
      queryParameters: <String, String>{
        if (badge != null) 'badge': badge,
        if (page != null) 'page': '$page',
        if (limit != null) 'limit': '$limit',
      },
    );

    final data = response['data'] as List<dynamic>? ?? <dynamic>[];
    return data
        .map(
          (dynamic json) =>
              RunCityPoint.fromUserMapJson(json as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<List<RunCityPoint>> fetchUserLocations({
    required String userId,
    String? badge,
    String? bounds,
  }) async {
    final response = await _get(
      '/api/users/$userId/map',
      queryParameters: <String, String>{
        if (badge != null) 'badge': badge,
        if (bounds != null) 'bounds': bounds,
      },
    );

    final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final locations = data['locations'] as List<dynamic>? ?? <dynamic>[];
    return locations
        .map(
          (dynamic json) =>
              RunCityPoint.fromUserMapJson(json as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<RunCityPoint> createLocation({
    required String name,
    required double latitude,
    required double longitude,
    String? description,
    bool isNFCEnabled = false,
    String? nfcId,
  }) async {
    final response = await _post(
      '/api/locations',
      body: <String, dynamic>{
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        if (description != null) 'description': description,
        'isNFCEnabled': isNFCEnabled,
        if (nfcId != null) 'nfcId': nfcId,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return RunCityPoint.fromUserMapJson(data);
  }

  Future<RunCityPoint> updateLocation({
    required String locationId,
    required String name,
    required double latitude,
    required double longitude,
    String? description,
    bool? isNFCEnabled,
    String? nfcId,
  }) async {
    final response = await _patch(
      '/api/locations/$locationId',
      body: <String, dynamic>{
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        if (description != null) 'description': description,
        if (isNFCEnabled != null) 'isNFCEnabled': isNFCEnabled,
        if (nfcId != null) 'nfcId': nfcId,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return RunCityPoint.fromUserMapJson(data);
  }

  Future<void> deleteLocation(String locationId) async {
    await _delete('/api/locations/$locationId');
  }

  Future<RunCityActivitySession> startActivity({
    required String userId,
    required DateTime startTime,
    required LatLng startLocation,
  }) async {
    final response = await _post(
      '/api/users/$userId/activities/start',
      body: <String, dynamic>{
        'startTime': startTime.toUtc().toIso8601String(),
        'startLocation': {
          'latitude': startLocation.latitude,
          'longitude': startLocation.longitude,
        },
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return RunCityActivitySession(
      activityId: data['activityId'] as String,
      startTime: DateTime.parse(data['startTime'] as String).toUtc(),
      status: data['status'] as String,
    );
  }

  Future<void> trackActivity({
    required String userId,
    required String activityId,
    required List<RunCityTrackPoint> points,
  }) async {
    if (points.isEmpty) {
      return;
    }
    await _post(
      '/api/users/$userId/activities/$activityId/track',
      body: <String, dynamic>{
        'points': points.map((RunCityTrackPoint p) => p.toJson()).toList(),
      },
    );
  }

  Future<RunCityActivitySummary> endActivity({
    required String userId,
    required String activityId,
    required DateTime endTime,
    required LatLng endLocation,
  }) async {
    final response = await _post(
      '/api/users/$userId/activities/$activityId/end',
      body: <String, dynamic>{
        'endTime': endTime.toUtc().toIso8601String(),
        'endLocation': {
          'latitude': endLocation.latitude,
          'longitude': endLocation.longitude,
        },
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    final route = (data['route'] as List<dynamic>? ?? <dynamic>[])
        .map(
          (dynamic item) => RunCityTrackPoint(
            latitude: (item['latitude'] as num).toDouble(),
            longitude: (item['longitude'] as num).toDouble(),
            timestamp: DateTime.parse(item['timestamp'] as String).toUtc(),
          ),
        )
        .toList(growable: false);

    final collectedLocations =
        (data['collectedLocations'] as List<dynamic>? ?? <dynamic>[])
            .map(
              (dynamic item) => RunCityPoint(
                id: item['id'] as String,
                name: item['name'] as String,
                location: LatLng(
                  (item['latitude'] as num).toDouble(),
                  (item['longitude'] as num).toDouble(),
                ),
                coinsEarned: (item['coinsEarned'] as num?)?.toInt(),
                collected: true,
              ),
            )
            .toList(growable: false);

    return RunCityActivitySummary(
      activityId: data['activityId'] as String,
      startTime: DateTime.parse(data['startTime'] as String).toUtc(),
      endTime: DateTime.parse(data['endTime'] as String).toUtc(),
      distanceKm: (data['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (data['duration'] as num?)?.toInt() ?? 0,
      averageSpeedKmh: (data['averageSpeed'] as num?)?.toDouble() ?? 0,
      route: route,
      collectedLocations: collectedLocations,
      totalCoinsEarned: (data['totalCoinsEarned'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> collectLocation({
    required String userId,
    required String activityId,
    required String nfcId,
  }) async {
    await _post(
      '/api/users/$userId/activities/$activityId/collect/$nfcId',
    );
  }

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: <String, String>{
        if (queryParameters != null) ...queryParameters,
      },
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    final response = await _httpClient.get(uri);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    final response = await _httpClient.post(
      uri,
      headers: _jsonHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    final response = await _httpClient.patch(
      uri,
      headers: _jsonHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<void> _delete(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    final response = await _httpClient.delete(uri, headers: _jsonHeaders);
    _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final String body = response.body;
    if (statusCode < 200 || statusCode >= 300) {
      throw RunCityApiException(
        'Request failed with status $statusCode: $body',
        statusCode: statusCode,
      );
    }

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final success = decoded['success'] as bool?;
        if (success != null && !success) {
          final message = decoded['message'] as String? ??
              decoded['reason'] as String? ??
              'Unknown API error';
          throw RunCityApiException(message, statusCode: statusCode);
        }
        return decoded;
      }
      return <String, dynamic>{'data': decoded};
    } catch (error, stackTrace) {
      debugPrint(
        'RunCityApiService: failed to decode response ($statusCode): $error\n$stackTrace',
      );
      throw RunCityApiException(
        'Failed to decode response: $error',
        statusCode: statusCode,
      );
    }
  }

  Map<String, String> get _jsonHeaders => const <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}


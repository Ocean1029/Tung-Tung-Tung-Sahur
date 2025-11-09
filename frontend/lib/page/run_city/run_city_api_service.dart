import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:town_pass/page/run_city/run_city_point.dart';

class RunCityApiException implements Exception {
  const RunCityApiException(
    this.message, {
    this.code,
    this.statusCode,
  });

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() {
    if (code != null) {
      return '[$code] $message';
    }
    return 'RunCityApiException(statusCode: $statusCode, message: $message)';
  }
}

class RunCityApiService extends GetxService {
  static const bool useMockData = bool.fromEnvironment(
    'RUN_CITY_USE_MOCK_DATA',
    defaultValue: false,
  );

  RunCityApiService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        baseUrl = baseUrl ??
            const String.fromEnvironment(
              'RUN_CITY_API_BASE_URL',
              defaultValue: 'http://10.103.182.205:3000', // 使用 Mac IP，手機才能連接
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
  }) async {
    final response = await _patch(
      '/api/locations/$locationId',
      body: <String, dynamic>{
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
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
    // 將後端傳入的 UTC 時間（GMT+0）轉換為 GMT+8
    final startTimeUtc = DateTime.parse(data['startTime'] as String).toUtc();
    final startTimeGmt8 = startTimeUtc.add(const Duration(hours: 8));
    return RunCityActivitySession(
      activityId: data['activityId'] as String,
      startTime: startTimeGmt8,
      status: data['status'] as String,
    );
  }

  Future<double> trackActivity({
    required String userId,
    required String activityId,
    required List<RunCityTrackPoint> points,
  }) async {
    if (points.isEmpty) {
      return 0.0;
    }
    final response = await _post(
      '/api/users/$userId/activities/$activityId/track',
      body: <String, dynamic>{
        'points': points.map((RunCityTrackPoint p) => p.toJson()).toList(),
      },
    );
    // 後端會回傳 distance（已行走距離，單位：公尺）
    final distance = (response['data']?['distance'] as num?)?.toDouble() ?? 0.0;
    return distance;
  }

  Future<Map<String, dynamic>> collectNfcLocation({
    required String userId,
    required String activityId,
    required String nfcId,
  }) async {
    if (useMockData) {
      // 模擬成功回傳
      await Future.delayed(const Duration(milliseconds: 200));
      return {
        'success': true,
        'data': {
          'locationId': 'mock-location-id',
          'name': '模擬地點',
          'coinsEarned': 1,
          'totalCoins': 100,
          'isFirstCollection': true,
        }
      };
    }

    final response = await _post(
      '/api/users/$userId/activities/$activityId/collect/nfc',
      body: <String, dynamic>{
        'nfcId': nfcId,
      },
    );
    
    return response;
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
          (dynamic item) {
            // 將後端傳入的 UTC 時間（GMT+0）轉換為 GMT+8
            final timestampUtc = DateTime.parse(item['timestamp'] as String).toUtc();
            final timestampGmt8 = timestampUtc.add(const Duration(hours: 8));
            return RunCityTrackPoint(
              latitude: (item['latitude'] as num).toDouble(),
              longitude: (item['longitude'] as num).toDouble(),
              timestamp: timestampGmt8,
            );
          },
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
                area: item['area'] as String?, // 後端會傳 area，但可能為 null
                coinsEarned: (item['coinsEarned'] as num?)?.toInt(),
                collected: true,
              ),
            )
            .toList(growable: false);

    // 將後端傳入的 UTC 時間（GMT+0）轉換為 GMT+8
    final startTimeUtc = DateTime.parse(data['startTime'] as String).toUtc();
    final startTimeGmt8 = startTimeUtc.add(const Duration(hours: 8));
    final endTimeUtc = DateTime.parse(data['endTime'] as String).toUtc();
    final endTimeGmt8 = endTimeUtc.add(const Duration(hours: 8));
    return RunCityActivitySummary(
      activityId: data['activityId'] as String,
      startTime: startTimeGmt8,
      endTime: endTimeGmt8,
      distanceKm: (data['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (data['duration'] as num?)?.toInt() ?? 0,
      averageSpeedKmh: (data['averageSpeed'] as num?)?.toDouble() ?? 0,
      route: route,
      collectedLocations: collectedLocations,
      totalCoinsEarned: (data['totalCoinsEarned'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<RunCityActivityItem>> fetchActivities({
    required String userId,
    int? page,
    int? limit,
  }) async {
    if (useMockData) {
      return _getMockActivities();
    }

    final response = await _get(
      '/api/users/$userId/activities',
      queryParameters: <String, String>{
        if (page != null) 'page': '$page',
        if (limit != null) 'limit': '$limit',
      },
    );

    final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final activities = data['activities'] as List<dynamic>? ?? <dynamic>[];
    return activities
        .map(
          (dynamic json) =>
              RunCityActivityItem.fromJson(json as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<RunCityActivityDetail> fetchActivityDetail({
    required String userId,
    required String activityId,
    String? userName,
    String? userAvatar,
  }) async {
    if (useMockData) {
      return _getMockActivityDetail(activityId, userId: userId, userName: userName, userAvatar: userAvatar);
    }

    final response = await _get(
      '/api/users/$userId/activities/$activityId',
    );

    final data = response['data'] as Map<String, dynamic>;
    return RunCityActivityDetail.fromJson(
      data,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
    );
  }

  /// 獲取用戶的徽章列表
  /// GET /api/users/{userId}/badges
  Future<List<RunCityBadge>> fetchUserBadges({
    required String userId,
  }) async {
    if (useMockData) {
      return _getMockUserBadges();
    }

    final response = await _get('/api/users/$userId/badges');
    final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final badges = data['badges'] as List<dynamic>? ?? <dynamic>[];
    
    // 調試：打印第一個徽章的完整 JSON 數據
    if (badges.isNotEmpty) {
      debugPrint('第一個徽章的完整 JSON: ${badges.first}');
    }
    
    return badges
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final json = entry.value as Map<String, dynamic>;
          // 調試：打印每個徽章的 requiredLocationIds
          debugPrint('徽章 ${json['name']} 的 requiredLocationIds: ${json['requiredLocationIds']}');
          // 臨時方法：根據索引循環分配顏色（之後會由資料庫提供）
          final badgeColor = _getBadgeColor(index);
          return RunCityBadge.fromJson(json, badgeColor: badgeColor);
        })
        .toList(growable: false);
  }

  /// 獲取徽章顏色（根據索引循環使用三種顏色）- 臨時方法
  Color _getBadgeColor(int index) {
    final colors = [
      Color(0xFF76A732), // #76a732
      Color(0xFFFD8534), // #fd8534
      Color(0xFFF5BA49), // #f5ba49
    ];
    return colors[index % colors.length];
  }

  /// 獲取用戶徽章統計（包含已收集數量）
  /// GET /api/users/{userId}/badges
  Future<UserBadgeStats> fetchUserBadgeStats({
    required String userId,
  }) async {
    if (useMockData) {
      final badges = await _getMockUserBadges();
      final collectedCount = badges.where((b) => b.status == RunCityBadgeStatus.collected).length;
      return UserBadgeStats(
        collectedCount: collectedCount,
        totalCount: badges.length,
      );
    }

    final response = await _get('/api/users/$userId/badges');
    final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    
    return UserBadgeStats(
      collectedCount: data['collectedCount'] as int? ?? 0,
      totalCount: data['totalBadges'] as int? ?? 0,
    );
  }

  /// 獲取單個徽章詳情
  /// GET /api/users/{userId}/badges/{badgeId}
  Future<RunCityBadgeDetail> fetchUserBadgeDetail({
    required String userId,
    required String badgeId,
  }) async {
    if (useMockData) {
      return _getMockBadgeDetail(badgeId);
    }

    final response = await _get('/api/users/$userId/badges/$badgeId');
    final data = response['data'] as Map<String, dynamic>;
    return RunCityBadgeDetail.fromJson(data);
  }

  /// 獲取所有徽章列表
  /// GET /api/badges
  Future<List<RunCityBadge>> fetchAllBadges() async {
    if (useMockData) {
      return _getMockAllBadges();
    }

    final response = await _get('/api/badges');
    final data = response['data'] as List<dynamic>? ?? <dynamic>[];
    
    return data
        .map((dynamic json) => RunCityBadge.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Mock 活動詳情資料
  Future<RunCityActivityDetail> _getMockActivityDetail(
    String activityId, {
    String? userId,
    String? userName,
    String? userAvatar,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 先獲取活動列表，找到對應的活動信息
    final activities = await _getMockActivities();
    final activity = activities.firstWhere(
      (a) => a.activityId == activityId,
      orElse: () => activities.first, // 如果找不到，使用第一個
    );

    // 根據活動信息生成詳細數據
    final startTime = activity.date;
    final endTime = startTime.add(Duration(seconds: activity.duration));
    final distanceKm = activity.distance;
    final durationSeconds = activity.duration;
    final averageSpeedKmh = activity.averageSpeed;
    final coinsEarned = activity.coinsEarned;

    // 根據不同的 activityId 生成不同的路線和點位
    final centerLat = 25.0330;
    final centerLng = 121.5654;
    final route = <RunCityTrackPoint>[];
    
    // 根據 activityId 生成不同的路線模式
    int routePattern = 0;
    if (activityId == 'act_001') {
      routePattern = 1; // 環形路線
    } else if (activityId == 'act_002') {
      routePattern = 2; // 直線路線
    } else if (activityId == 'act_003') {
      routePattern = 3; // 曲折路線
    }

    // 生成路線點位
    final pointCount = (durationSeconds / 120).round().clamp(10, 30); // 每2分鐘一個點
    for (int i = 0; i < pointCount; i++) {
      double lat, lng;
      final progress = i / pointCount;
      
      switch (routePattern) {
        case 1: // 環形路線
          final radius = 0.002;
          final angle = progress * 2 * math.pi;
          lat = centerLat + radius * math.sin(angle);
          lng = centerLng + radius * math.cos(angle);
          break;
        case 2: // 直線路線
          lat = centerLat + progress * 0.003;
          lng = centerLng + progress * 0.003;
          break;
        case 3: // 曲折路線
          final radius = 0.0015;
          final angle = progress * 4 * math.pi; // 多繞幾圈
          lat = centerLat + radius * math.sin(angle) + progress * 0.002;
          lng = centerLng + radius * math.cos(angle) + progress * 0.002;
          break;
        default:
          final radius = 0.002;
          final angle = progress * 2 * math.pi;
          lat = centerLat + radius * math.sin(angle);
          lng = centerLng + radius * math.cos(angle);
      }
      
      route.add(
        RunCityTrackPoint(
          latitude: lat,
          longitude: lng,
          timestamp: startTime.add(Duration(seconds: i * (durationSeconds ~/ pointCount))),
        ),
      );
    }

    // 根據 collectedLocationsCount 生成點位紀錄
    final locationRecords = <RunCityActivityLocationRecord>[];
    final locationNames = ['安森東側涼亭', '台大體育館', '台大圖書館', '台大操場', '台大總圖'];
    final areas = ['臺北市 大安區', '臺北市 大安區', '臺北市 大安區', '臺北市 大安區', null];
    
    // 使用固定的種子確保每次生成的數據一致（基於 activityId）
    final random = math.Random(activityId.hashCode);
    
    for (int i = 0; i < activity.collectedLocationsCount; i++) {
      final locationIndex = i % locationNames.length;
      final collectTime = startTime.add(
        Duration(seconds: (i + 1) * (durationSeconds ~/ (activity.collectedLocationsCount + 1))),
      );
      
      // 根據路線計算點位位置
      final routeIndex = ((i + 1) * route.length / (activity.collectedLocationsCount + 1)).round();
      final routePoint = route[routeIndex.clamp(0, route.length - 1)];
      
      // 使用固定種子的隨機數，確保同一活動每次生成的數據一致
      locationRecords.add(
        RunCityActivityLocationRecord(
          locationId: 'loc_${activityId}_${i + 1}',
          locationName: locationNames[locationIndex],
          collectedAt: collectTime,
          latitude: routePoint.latitude + (random.nextDouble() - 0.5) * 0.0005,
          longitude: routePoint.longitude + (random.nextDouble() - 0.5) * 0.0005,
          area: areas[locationIndex],
        ),
      );
    }

    return RunCityActivityDetail(
      activityId: activityId,
      userId: userId ?? 'user_001',
      userName: userName ?? 'Ocean',
      userAvatar: userAvatar,
      startTime: startTime,
      endTime: endTime,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      averageSpeedKmh: averageSpeedKmh,
      route: route,
      locationRecords: locationRecords,
      totalCoinsEarned: coinsEarned,
    );
  }

  /// Mock 用戶徽章列表
  Future<List<RunCityBadge>> _getMockUserBadges() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final mockBadges = [
      RunCityBadge(
        badgeId: 'badge_001',
        name: '台大探險家',
        description: '收集完台大區域所有點位',
        area: '台大區域',
        imageUrl: 'https://example.com/badges/badge_001.png',
        status: RunCityBadgeStatus.collected,
        unlockedAt: DateTime.now().subtract(const Duration(days: 2)),
        progress: const RunCityBadgeProgress(collected: 2, total: 3, percentage: 67),
        // 使用 mock 地圖點的 ID：國立台灣大學、師大夜市、大安森林公園
        requiredLocationIds: ['mock-point-010', 'mock-point-011', 'mock-point-009'],
      ),
      RunCityBadge(
        badgeId: 'badge_002',
        name: '大安森林公園漫步者',
        description: '收集完大安森林公園區域所有點位',
        area: '大安森林公園',
        imageUrl: 'https://example.com/badges/badge_002.png',
        status: RunCityBadgeStatus.inProgress,
        unlockedAt: null,
        progress: const RunCityBadgeProgress(collected: 1, total: 2, percentage: 50),
        // 使用 mock 地圖點的 ID：大安森林公園、師大夜市
        requiredLocationIds: ['mock-point-009', 'mock-point-011'],
      ),
      RunCityBadge(
        badgeId: 'badge_003',
        name: '中正紀念堂探索者',
        description: '收集完中正紀念堂區域所有點位',
        area: '中正紀念堂',
        imageUrl: 'https://example.com/badges/badge_003.png',
        status: RunCityBadgeStatus.locked,
        unlockedAt: null,
        progress: const RunCityBadgeProgress(collected: 0, total: 3, percentage: 0),
        // 使用 mock 地圖點的 ID：台北車站、總統府、西門町
        requiredLocationIds: ['mock-point-001', 'mock-point-002', 'mock-point-003'],
      ),
    ];
    
    // 為每個徽章分配顏色（臨時方法）
    return mockBadges.asMap().entries.map((entry) {
      final index = entry.key;
      final badge = entry.value;
      final badgeColor = _getBadgeColor(index);
      return badge.copyWith(badgeColor: badgeColor);
    }).toList();
  }

  /// Mock 徽章詳情
  Future<RunCityBadgeDetail> _getMockBadgeDetail(String badgeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final allBadges = await _getMockUserBadges();
    final badge = allBadges.firstWhere(
      (b) => b.badgeId == badgeId,
      orElse: () => allBadges.first,
    );

    final requiredLocations = badge.requiredLocationIds?.map((locId) {
      final isCollected = badge.status == RunCityBadgeStatus.collected ||
          (badge.status == RunCityBadgeStatus.inProgress && 
           badge.requiredLocationIds!.indexOf(locId) < badge.progress!.collected);
      
      return RunCityBadgeLocation(
        locationId: locId,
        name: '${badge.area}點位${locId.split('_').last}',
        latitude: 25.0173 + math.Random().nextDouble() * 0.01,
        longitude: 121.5397 + math.Random().nextDouble() * 0.01,
        nfcId: 'nfc_$locId',
        isCollected: isCollected,
        collectedAt: isCollected ? DateTime.now().subtract(Duration(days: math.Random().nextInt(7))) : null,
      );
    }).toList(growable: false) ?? <RunCityBadgeLocation>[];

    return RunCityBadgeDetail(
      badge: badge,
      requiredLocations: requiredLocations,
    );
  }

  /// Mock 所有徽章列表
  Future<List<RunCityBadge>> _getMockAllBadges() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final mockBadges = [
      RunCityBadge(
        badgeId: 'badge_001',
        name: '台大探險家',
        description: '收集完台大區域所有點位',
        area: '台大區域',
        imageUrl: 'https://example.com/badges/badge_001.png',
        // 使用 mock 地圖點的 ID
        requiredLocationIds: ['mock-point-010', 'mock-point-011', 'mock-point-009'],
      ),
      RunCityBadge(
        badgeId: 'badge_002',
        name: '大安森林公園漫步者',
        description: '收集完大安森林公園區域所有點位',
        area: '大安森林公園',
        imageUrl: 'https://example.com/badges/badge_002.png',
        // 使用 mock 地圖點的 ID
        requiredLocationIds: ['mock-point-009', 'mock-point-011'],
      ),
    ];
    
    // 為每個徽章分配顏色（臨時方法）
    return mockBadges.asMap().entries.map((entry) {
      final index = entry.key;
      final badge = entry.value;
      final badgeColor = _getBadgeColor(index);
      return badge.copyWith(badgeColor: badgeColor);
    }).toList();
  }

  /// Mock 活動列表資料
  Future<List<RunCityActivityItem>> _getMockActivities() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final now = DateTime.now();
    
    // Mock 資料：符合 API Response 9 格式
    // date 欄位是開始時間，需要設定具體的時間（例如 10:00）
    final mockActivities = <RunCityActivityItem>[
      RunCityActivityItem(
        activityId: 'act_001',
        date: DateTime(now.year, now.month, now.day - 1, 10, 0), // 昨天 10:00
        distance: 3.5,
        duration: 1800, // 30 分鐘
        averageSpeed: 7.0,
        coinsEarned: 2,
        collectedLocationsCount: 2,
      ),
      RunCityActivityItem(
        activityId: 'act_002',
        date: DateTime(now.year, now.month, now.day - 2, 9, 0), // 2天前 09:00
        distance: 5.2,
        duration: 2400, // 40 分鐘
        averageSpeed: 7.8,
        coinsEarned: 3,
        collectedLocationsCount: 3,
      ),
      RunCityActivityItem(
        activityId: 'act_003',
        date: DateTime(now.year, now.month, now.day - 5, 14, 30), // 5天前 14:30
        distance: 2.1,
        duration: 1200, // 20 分鐘
        averageSpeed: 6.3,
        coinsEarned: 1,
        collectedLocationsCount: 1,
      ),
    ];
    
    return mockActivities;
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
    
    try {
      final response = await _httpClient
          .post(
      uri,
      headers: _jsonHeaders,
      body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw RunCityApiException(
                '請求超時，請檢查網路連接',
                code: 'TIMEOUT',
                statusCode: 408,
              );
            },
    );
    return _handleResponse(response);
    } on http.ClientException catch (e) {
      // 處理網路連接錯誤
      throw RunCityApiException(
        '網路連接失敗：${e.message}\n請確認：\n1. 後端伺服器正在運行\n2. iPhone 和 Mac 在同一網路\n3. Mac IP 地址正確',
        code: 'NETWORK_ERROR',
        statusCode: null,
      );
    } on SocketException catch (e) {
      throw RunCityApiException(
        '無法連接到伺服器：${e.message}\n請確認後端伺服器正在運行',
        code: 'CONNECTION_ERROR',
        statusCode: null,
      );
    } catch (e) {
      if (e is RunCityApiException) {
        rethrow;
      }
      throw RunCityApiException(
        '請求失敗：${e.toString()}',
        code: 'UNKNOWN_ERROR',
        statusCode: null,
      );
    }
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
            // 處理後端 API 錯誤格式
            final error = decoded['error'] as Map<String, dynamic>?;
            if (error != null) {
              final code = error['code'] as String? ?? 'UNKNOWN_ERROR';
              final message = error['message'] as String? ??
                  decoded['message'] as String? ??
                  decoded['reason'] as String? ??
                  'Unknown API error';
              throw RunCityApiException(
                message,
                code: code,
                statusCode: statusCode,
              );
            }
            // 如果沒有 error 物件，使用舊格式
            final message = decoded['message'] as String? ??
                decoded['reason'] as String? ??
                'Unknown API error';
            throw RunCityApiException(
              message,
              statusCode: statusCode,
            );
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


import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:town_pass/page/run_city/run_city_api_service.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/service/run_city_service.dart';

class RunCityController extends GetxController {
  RunCityController({
    RunCityApiService? apiService,
    AccountService? accountService,
    RunCityService? runCityService,
  })  : _apiService = apiService ?? Get.find<RunCityApiService>(),
        _accountService = accountService ?? Get.find<AccountService>(),
        _runCityService = runCityService ?? Get.find<RunCityService>();

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(25.033968, 121.564468),
    zoom: 12.5,
  );

  final RxBool isLoading = true.obs;
  final RxList<RunCityPoint> points = <RunCityPoint>[].obs;
  final RxList<Marker> markers = <Marker>[].obs;
  final RxList<Polyline> polylines = <Polyline>[].obs;
  final RxBool isTracking = false.obs;
  final RxList<LatLng> routePath = <LatLng>[].obs;
  final Rx<Duration> elapsed = Duration.zero.obs;
  final RxDouble totalDistanceMeters = 0.0.obs;
  final RxDouble averageSpeedKmh = 0.0.obs;
  final RxList<String> visitedPointIds = <String>[].obs;
  final RxnString errorMessage = RxnString();

  final Rxn<RunCityUserProfile> userProfile = Rxn<RunCityUserProfile>();
  final RxList<RunCityBadge> badges = <RunCityBadge>[].obs;
  final Rxn<RunCityBadge> selectedBadge = Rxn<RunCityBadge>();
  final RxBool isBadgePanelVisible = false.obs;
  static const int badgesPerPage = 3;
  final RxInt badgeStartIndex = 0.obs;

  final RunCityApiService _apiService;
  final AccountService _accountService;
  final RunCityService _runCityService;

  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionSubscription;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  BitmapDescriptor? _collectedMarkerIcon;
  BitmapDescriptor? _uncollectedMarkerIcon;
  BitmapDescriptor? _highlightMarkerIcon;
  final List<RunCityTrackPoint> _pendingTrackPoints = <RunCityTrackPoint>[];
  String? _currentActivityId;
  bool _isSendingTrackPoints = false;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  @override
  void onClose() {
    mapController?.dispose();
    _stopTrackingStream();
    super.onClose();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _loadMapPoints();
      await _loadUserProfile();
      _initializeBadges();
      _refreshBadgeProgress();
      await _updateMarkers();
    } catch (error) {
      errorMessage.value = '$error';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    await loadData();
  }

  Future<void> _loadMapPoints() async {
    await Future.delayed(const Duration(milliseconds: 280));
    final mockPoints = <RunCityPoint>[
      RunCityPoint(
        id: 'xinyi-01',
        name: '象山登山口',
        area: '信義區',
        location: const LatLng(25.02722, 121.576161),
        collected: true,
      ),
      RunCityPoint(
        id: 'xinyi-02',
        name: '信義國小操場',
        area: '信義區',
        location: const LatLng(25.034571, 121.5626),
      ),
      RunCityPoint(
        id: 'xinyi-03',
        name: '四四南村廣場',
        area: '信義區',
        location: const LatLng(25.03341, 121.56137),
      ),
      RunCityPoint(
        id: 'daan-01',
        name: '大安森林公園',
        area: '大安區',
        location: const LatLng(25.033024, 121.535154),
        collected: true,
      ),
      RunCityPoint(
        id: 'daan-02',
        name: '師大夜市入口',
        area: '大安區',
        location: const LatLng(25.026173, 121.528164),
      ),
      RunCityPoint(
        id: 'daan-03',
        name: '和平籃球場',
        area: '大安區',
        location: const LatLng(25.024912, 121.543005),
      ),
      RunCityPoint(
        id: 'zhongshan-01',
        name: '林森公園',
        area: '中山區',
        location: const LatLng(25.04507, 121.52599),
      ),
      RunCityPoint(
        id: 'zhongshan-02',
        name: '花博新生園區',
        area: '中山區',
        location: const LatLng(25.06972, 121.52533),
      ),
      RunCityPoint(
        id: 'songshan-01',
        name: '松山饒河夜市',
        area: '松山區',
        location: const LatLng(25.05042, 121.57672),
      ),
      RunCityPoint(
        id: 'songshan-02',
        name: '彩虹橋',
        area: '松山區',
        location: const LatLng(25.05183, 121.58052),
      ),
      RunCityPoint(
        id: 'shilin-01',
        name: '士林官邸花園',
        area: '士林區',
        location: const LatLng(25.09518, 121.52452),
      ),
      RunCityPoint(
        id: 'shilin-02',
        name: '陽明戲棚前廣場',
        area: '士林區',
        location: const LatLng(25.09583, 121.52694),
      ),
    ];

    points.assignAll(mockPoints);
  }

  Future<void> _loadUserProfile() async {
    final account = _accountService.account;
    if (account == null) {
      userProfile.value = null;
      return;
    }

    try {
      final data = await _runCityService.getUserData();
      userProfile.value = RunCityUserProfile(
        userId: data.userId,
        name: data.name,
        avatarUrl: data.avatarUrl,
        totalCoins: data.totalCoins,
        totalDistanceKm: (data.totalDistance ?? 0) / 1000,
        totalTimeSeconds: 5400,
        updatedAt: data.updatedAt,
      );
    } catch (_) {
      userProfile.value = RunCityUserProfile(
        userId: account.id,
        name: account.username,
        totalCoins: 0,
        totalDistanceKm: 0,
        totalTimeSeconds: 0,
      );
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void selectBadge(RunCityBadge? badge) {
    if (badge == null) {
      selectedBadge.value = null;
    } else if (selectedBadge.value?.id == badge.id) {
      selectedBadge.value = null;
    } else {
      selectedBadge.value = badge;
    }
    _ensureBadgeVisible(selectedBadge.value);
    _updateMarkers();
  }

  void toggleBadgePanel() {
    if (badges.isEmpty) {
      isBadgePanelVisible.value = false;
      return;
    }
    isBadgePanelVisible.toggle();
  }

  void closeBadgePanel() {
    if (isBadgePanelVisible.value) {
      isBadgePanelVisible.value = false;
    }
  }

  List<RunCityBadge> get sortedBadges {
    final sorted = badges.toList();
    sorted.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return sorted;
  }

  Future<void> updatePointCollected(String id, bool collected) async {
    final index = points.indexWhere((point) => point.id == id);
    if (index == -1) {
      return;
    }
    points[index] = points[index].copyWith(
      collected: collected,
      collectedAt:
          collected ? (points[index].collectedAt ?? DateTime.now()) : null,
    );
    _refreshBadgeProgress();
    await _updateMarkers();
  }

  Future<void> startTracking() async {
    if (isTracking.value) {
      return;
    }

    final granted = await _ensurePermissionReady();
    if (!granted) {
      return;
    }

    final userId = _accountService.account?.id;
    if (userId == null) {
      Get.snackbar(
        '無法開始紀錄',
        '尚未取得使用者資訊，請重新登入後再試',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
      );
      return;
    }

    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final currentLatLng = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );

      routePath.clear();
      polylines.clear();
      visitedPointIds.clear();
      totalDistanceMeters.value = 0;
      averageSpeedKmh.value = 0;
      elapsed.value = Duration.zero;
      _pendingTrackPoints.clear();

      final session = await _apiService.startActivity(
        userId: userId,
        startTime: DateTime.now().toUtc(),
        startLocation: currentLatLng,
      );
      _currentActivityId = session.activityId;

      isTracking.value = true;
      _stopwatch
        ..reset()
        ..start();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsed.value = _stopwatch.elapsed;
        if (_stopwatch.elapsed.inSeconds > 0) {
          final hours = _stopwatch.elapsed.inSeconds / 3600;
          averageSpeedKmh.value =
              hours > 0 ? (totalDistanceMeters.value / 1000) / hours : 0;
        }
      });

      final locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      );

      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(_onPositionUpdated);

      _onPositionUpdated(currentPosition);
      await _flushTrackPoints(force: true);
    } on RunCityApiException catch (error) {
      Get.snackbar(
        '無法開始紀錄',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
      );
    } catch (error) {
      debugPrint('RunCityController.startTracking error: $error');
      Get.snackbar(
        '無法開始紀錄',
        '請稍後再試',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
      );
    }
  }

  Future<void> stopTracking() async {
    if (!isTracking.value) {
      return;
    }

    isTracking.value = false;
    _stopwatch.stop();
    _timer?.cancel();
    _stopTrackingStream();

    final userId = _accountService.account?.id;
    final activityId = _currentActivityId;
    final endPoint = routePath.isNotEmpty ? routePath.last : null;

    await _flushTrackPoints(force: true);
    _pendingTrackPoints.clear();

    if (userId != null && activityId != null && endPoint != null) {
      try {
        final summary = await _apiService.endActivity(
          userId: userId,
          activityId: activityId,
          endTime: DateTime.now().toUtc(),
          endLocation: endPoint,
        );

        totalDistanceMeters.value = summary.distanceKm * 1000;
        elapsed.value = Duration(seconds: summary.durationSeconds);
        averageSpeedKmh.value = summary.averageSpeedKmh;
        visitedPointIds.assignAll(
          summary.collectedLocations.map((RunCityPoint point) => point.id),
        );
        _applyCollectedLocations(summary.collectedLocations);
        _refreshBadgeProgress();
      } on RunCityApiException catch (error) {
        Get.snackbar(
          '結束紀錄失敗',
          error.message,
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          backgroundColor: Colors.black87,
        );
        elapsed.value = _stopwatch.elapsed;
      } catch (error) {
        debugPrint('RunCityController.stopTracking error: $error');
        Get.snackbar(
          '結束紀錄失敗',
          '請稍後再試',
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          backgroundColor: Colors.black87,
        );
        elapsed.value = _stopwatch.elapsed;
      }
    } else {
      elapsed.value = _stopwatch.elapsed;
      if (_stopwatch.elapsed.inSeconds > 0) {
        final hours = _stopwatch.elapsed.inSeconds / 3600;
        averageSpeedKmh.value =
            hours > 0 ? (totalDistanceMeters.value / 1000) / hours : 0;
      }
    }

    _currentActivityId = null;
  }

  void clearRoute() {
    if (isTracking.value) {
      return;
    }
    routePath.clear();
    polylines.clear();
    visitedPointIds.clear();
    totalDistanceMeters.value = 0;
    averageSpeedKmh.value = 0;
    elapsed.value = Duration.zero;
    _pendingTrackPoints.clear();
    _currentActivityId = null;
  }

  Future<bool> _ensurePermissionReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        '無法開始紀錄',
        '請開啟定位服務後再試一次',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      Get.snackbar(
        '定位權限遭拒',
        '需要定位權限才能紀錄跑步路線',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
      );
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        '定位權限永久被拒',
        '請前往系統設定開啟定位權限',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
      );
      return false;
    }

    return true;
  }

  void _onPositionUpdated(Position position) {
    final currentPoint = LatLng(position.latitude, position.longitude);

    final trackPoint = RunCityTrackPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      accuracy: position.accuracy,
    );
    _pendingTrackPoints.add(trackPoint);

    if (routePath.isEmpty) {
      routePath.add(currentPoint);
      _updatePolyline();
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentPoint, 15),
      );
      _markVisitedPoints(currentPoint);
      return;
    }

    final last = routePath.last;
    final segmentDistance = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      currentPoint.latitude,
      currentPoint.longitude,
    );

    if (segmentDistance < 3) {
      return;
    }

    routePath.add(currentPoint);
    totalDistanceMeters.value += segmentDistance;
    _updatePolyline();
    _markVisitedPoints(currentPoint);
    _refreshBadgeProgress();

    if (isTracking.value) {
      mapController?.animateCamera(CameraUpdate.newLatLng(currentPoint));
    }

    _flushTrackPoints();
  }

  void _updatePolyline() {
    if (routePath.length < 2) {
      polylines.assignAll([]);
      return;
    }

    polylines.assignAll([
      Polyline(
        polylineId: const PolylineId('run-city-route'),
        points: routePath.toList(),
        color: const Color(0xFF5AB4C5),
        width: 6,
      ),
    ]);
  }

  void _markVisitedPoints(LatLng currentPoint) {
    final newlyVisitedIds = <String>[];
    for (final point in points) {
      if (visitedPointIds.contains(point.id)) {
        continue;
      }

      final distance = Geolocator.distanceBetween(
        point.location.latitude,
        point.location.longitude,
        currentPoint.latitude,
        currentPoint.longitude,
      );

      if (distance <= 60) {
        newlyVisitedIds.add(point.id);
      }
    }

    if (newlyVisitedIds.isEmpty) {
      return;
    }

    visitedPointIds.addAll(newlyVisitedIds);
  }

  void _initializeBadges() {
    if (points.isEmpty) {
      badges.clear();
      selectedBadge.value = null;
      isBadgePanelVisible.value = false;
      badgeStartIndex.value = 0;
      return;
    }

    final Map<String, List<RunCityPoint>> grouped = {};
    for (final point in points) {
      final area = point.area ?? '未知區域';
      grouped.putIfAbsent(area, () => <RunCityPoint>[]).add(point);
    }

    final generated = grouped.entries.map((entry) {
      final areaPoints = entry.value;
      final collectedIds =
          areaPoints.where((p) => p.collected).map((p) => p.id).toList();
      final pointIds = areaPoints.map((p) => p.id).toList();
      final reference = areaPoints.first.location;
      final distance = Geolocator.distanceBetween(
        initialCameraPosition.target.latitude,
        initialCameraPosition.target.longitude,
        reference.latitude,
        reference.longitude,
      );
      return RunCityBadge(
        id: entry.key,
        name: entry.key,
        pointIds: pointIds,
        collectedPointIds: collectedIds,
        distanceMeters: distance,
      );
    }).toList();

    generated.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    badges.assignAll(generated);

    selectedBadge.value ??= _findFirstWhereOrNull(
          generated,
          (badge) => !badge.isCompleted,
        ) ??
        (generated.isNotEmpty ? generated.first : null);

    _resetBadgeStartIndex();
    _ensureBadgeVisible(selectedBadge.value);
  }

  void _refreshBadgeProgress() {
    if (badges.isEmpty) {
      return;
    }

    final collectedIds = points
        .where((point) => point.collected)
        .map((point) => point.id)
        .toSet();
    final updated = badges.map((badge) {
      final collected = badge.pointIds
          .where((pointId) => collectedIds.contains(pointId))
          .toList();
      return badge.copyWith(collectedPointIds: collected);
    }).toList();

    badges.assignAll(updated);

    if (selectedBadge.value != null) {
      final currentId = selectedBadge.value!.id;
      final refreshed = _findFirstWhereOrNull(
        updated,
        (badge) => badge.id == currentId,
      );
      selectedBadge.value = refreshed;
    }

    _resetBadgeStartIndex();
    _ensureBadgeVisible(selectedBadge.value);
  }

  RunCityBadge? _findFirstWhereOrNull(
    Iterable<RunCityBadge> badges,
    bool Function(RunCityBadge) test,
  ) {
    for (final badge in badges) {
      if (test(badge)) {
        return badge;
      }
    }
    return null;
  }

  void _stopTrackingStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _flushTrackPoints({bool force = false}) async {
    if (_isSendingTrackPoints) {
      return;
    }
    if (_currentActivityId == null) {
      return;
    }
    if (_pendingTrackPoints.isEmpty) {
      return;
    }
    if (!force && _pendingTrackPoints.length < 5) {
      return;
    }

    final userId = _accountService.account?.id;
    if (userId == null) {
      return;
    }

    final pointsToSend = List<RunCityTrackPoint>.from(_pendingTrackPoints);
    _isSendingTrackPoints = true;
    try {
      await _apiService.trackActivity(
        userId: userId,
        activityId: _currentActivityId!,
        points: pointsToSend,
      );
      if (_pendingTrackPoints.length >= pointsToSend.length) {
        _pendingTrackPoints.removeRange(0, pointsToSend.length);
      } else {
        _pendingTrackPoints.clear();
      }
    } on RunCityApiException catch (error) {
      debugPrint(
          'RunCityController._flushTrackPoints API error: ${error.message}');
    } catch (error) {
      debugPrint('RunCityController._flushTrackPoints error: $error');
    } finally {
      _isSendingTrackPoints = false;
    }
  }

  void _applyCollectedLocations(List<RunCityPoint> collected) {
    if (collected.isEmpty) {
      return;
    }
    final collectedMap = {
      for (final point in collected) point.id: point,
    };

    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final updated = collectedMap[current.id];
      if (updated != null) {
        points[i] = current.copyWith(
          collected: true,
          collectedAt: updated.collectedAt ?? DateTime.now(),
          coinsEarned: updated.coinsEarned,
        );
      }
    }

    _refreshBadgeProgress();
    _updateMarkers();
  }

  Future<void> _ensureMarkerIcons() async {
    _collectedMarkerIcon ??= await _createCircleMarker(const Color(0xFFDBF1F5));
    _uncollectedMarkerIcon ??=
        await _createCircleMarker(const Color(0xFF5AB4C5));
    _highlightMarkerIcon ??= await _createCircleMarker(const Color(0xFF4CAF50));
  }

  Future<BitmapDescriptor> _createCircleMarker(Color fillColor) async {
    const double size = 68;
    const double borderWidth = 5;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    final ui.Paint borderPaint = ui.Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.fill;
    final ui.Paint fillPaint = ui.Paint()
      ..color = fillColor
      ..style = ui.PaintingStyle.fill;

    const ui.Offset center = ui.Offset(size / 2, size / 2);
    const double radius = size / 2;

    canvas.drawCircle(center, radius, borderPaint);
    canvas.drawCircle(center, radius - borderWidth, fillPaint);

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _updateMarkers() async {
    await _ensureMarkerIcons();
    final collectedIcon = _collectedMarkerIcon;
    final uncollectedIcon = _uncollectedMarkerIcon;
    final highlightIcon = _highlightMarkerIcon;

    if (collectedIcon == null || uncollectedIcon == null) {
      return;
    }

    final highlightIds =
        selectedBadge.value?.remainingPointIds.toSet() ?? <String>{};

    final nextMarkers = points.map((point) {
      final statusLabel = point.collected ? '已收集' : '待收集';
      final subtitle = (point.area?.isNotEmpty ?? false)
          ? '${point.area} · $statusLabel'
          : statusLabel;
      final isHighlight = highlightIds.contains(point.id);
      return Marker(
        markerId: MarkerId(point.id),
        position: point.location,
        infoWindow: InfoWindow(
          title: point.name,
          snippet: subtitle,
        ),
        icon: isHighlight
            ? (highlightIcon ?? collectedIcon)
            : point.collected
                ? collectedIcon
                : uncollectedIcon,
        anchor: const Offset(0.5, 0.5),
        zIndex: isHighlight
            ? 4
            : point.collected
                ? 3
                : 2,
      );
    }).toList();

    markers.assignAll(nextMarkers);
  }

  List<RunCityBadge?> get currentBadgeSlots {
    if (badges.isEmpty) {
      return List<RunCityBadge?>.filled(badgesPerPage, null);
    }
    final start = badgeStartIndex.value.clamp(0, _maxBadgeStartIndex);
    final items = <RunCityBadge?>[];
    for (var i = 0; i < badgesPerPage; i++) {
      final index = start + i;
      items.add(index < badges.length ? badges[index] : null);
    }
    return items;
  }

  bool get canPageBadgesLeft => badgeStartIndex.value > 0;
  bool get canPageBadgesRight => badgeStartIndex.value < _maxBadgeStartIndex;

  void pageBadgesLeft() {
    if (!canPageBadgesLeft) {
      return;
    }
    badgeStartIndex.value =
        (badgeStartIndex.value - 1).clamp(0, _maxBadgeStartIndex);
  }

  void pageBadgesRight() {
    if (!canPageBadgesRight) {
      return;
    }
    badgeStartIndex.value =
        (badgeStartIndex.value + 1).clamp(0, _maxBadgeStartIndex);
  }

  int get _maxBadgeStartIndex {
    if (badges.length <= badgesPerPage) {
      return 0;
    }
    return badges.length - badgesPerPage;
  }

  void _resetBadgeStartIndex() {
    if (badges.length <= badgesPerPage) {
      badgeStartIndex.value = 0;
      return;
    }
    final middleStart = ((badges.length - badgesPerPage) / 2).floor();
    badgeStartIndex.value = middleStart.clamp(0, _maxBadgeStartIndex);
  }

  void _ensureBadgeVisible(RunCityBadge? badge) {
    if (badge == null) {
      return;
    }
    final index = badges.indexWhere((element) => element.id == badge.id);
    if (index == -1) {
      return;
    }
    final start = badgeStartIndex.value;
    final end = start + badgesPerPage - 1;

    if (index < start) {
      badgeStartIndex.value = index.clamp(0, _maxBadgeStartIndex);
    } else if (index > end) {
      badgeStartIndex.value =
          (index - badgesPerPage + 1).clamp(0, _maxBadgeStartIndex);
    }
  }
}

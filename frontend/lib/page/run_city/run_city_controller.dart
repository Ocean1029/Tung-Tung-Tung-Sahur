import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:town_pass/bean/run_city.dart';
import 'package:town_pass/page/run_city/run_city_api_service.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/service/run_city_service.dart';
import 'run_city_point.dart';

class RunCityController extends GetxController {
  RunCityController({
    RunCityApiService? apiService,
    AccountService? accountService,
  })  : _apiService = apiService ?? Get.find<RunCityApiService>(),
        _accountService = accountService ?? Get.find<AccountService>();

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(25.033968, 121.564468), // Taipei City Hall MRT station
    zoom: 12.5,
  );

  // 地圖相關
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

  final RunCityApiService _apiService;
  final AccountService _accountService;

  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionSubscription;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  BitmapDescriptor? _collectedMarkerIcon;
  BitmapDescriptor? _uncollectedMarkerIcon;
  LatLng? _initialUserLocation; // 存儲用戶初始位置
  LatLng? _currentUserLocation; // 當前用戶位置
  final RxBool isUserLocationCentered = true.obs; // 用戶位置是否在地圖中心
  CameraPosition? _lastCameraPosition; // 上次的相機位置

  // 路線記錄相關
  final List<RunCityTrackPoint> _pendingTrackPoints = [];
  String? _currentActivityId;
  bool _isSendingTrackPoints = false;

  // 用戶資料相關
  final RunCityService _runCityService = Get.find<RunCityService>();
  final Rxn<RunCityUserData> userData = Rxn<RunCityUserData>();
  final RxnString errorMessage = RxnString();

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

  /// 載入資料（地圖點位和用戶資料）
  Future<void> loadData() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      // 先請求定位權限並獲取用戶當前位置
      await _requestLocationAndSetInitialPosition();
      
      // 並行載入地圖點位和用戶資料
      await Future.wait([
        _loadMapPoints(),
        _loadUserData(),
      ]);
    } on RunCityApiException catch (e) {
      // 處理 API 錯誤
      final errorText = e.code != null ? '${e.message} (${e.code})' : e.message;
      errorMessage.value = errorText;
    } catch (e) {
      errorMessage.value = '載入資料失敗：${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// 請求定位權限並設置初始位置
  Future<void> _requestLocationAndSetInitialPosition() async {
    try {
      final granted = await _ensurePermissionReady();
      if (!granted) {
        // 如果權限被拒絕，使用默認位置
        return;
      }

      // 獲取用戶當前位置
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      _initialUserLocation = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      _currentUserLocation = _initialUserLocation;

      // 如果地圖控制器已經初始化，立即定位到用戶位置
      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_initialUserLocation!, 15),
        );
        isUserLocationCentered.value = true;
      }
    } catch (e) {
      // 如果獲取位置失敗，使用默認位置（不顯示錯誤，因為這不是必須的）
      print('無法獲取用戶位置：$e');
    }
  }

  /// 載入地圖點位
  Future<void> _loadMapPoints() async {
    // TODO: Replace with repository/service fetch once backend is ready.
    // Mock points help us validate UI and interactions while APIs are under development.
    await Future.delayed(const Duration(milliseconds: 400));
    final mockPoints = <RunCityPoint>[
      RunCityPoint(
        id: 'xinyi-01',
        name: '象山登山口 NFC',
        area: '信義區',
        location: const LatLng(25.027220, 121.576161),
        collected: true,
      ),
      RunCityPoint(
        id: 'xinyi-02',
        name: '信義國小 NFC',
        area: '信義區',
        location: const LatLng(25.034571, 121.562600),
      ),
      RunCityPoint(
        id: 'daan-01',
        name: '大安森林公園 NFC',
        area: '大安區',
        location: const LatLng(25.033024, 121.535154),
        collected: true,
      ),
      RunCityPoint(
        id: 'daan-02',
        name: '師大夜市 NFC',
        area: '大安區',
        location: const LatLng(25.026173, 121.528164),
      ),
      RunCityPoint(
        id: 'zhongshan-01',
        name: '林森公園 NFC',
        area: '中山區',
        location: const LatLng(25.045070, 121.525990),
      ),
    ];

    points.assignAll(mockPoints);
    await _updateMarkers();
  }

  /// 載入用戶資料
  Future<void> _loadUserData() async {
    // 檢查用戶是否已登入
    if (_accountService.account == null) {
      throw Exception('請先登入以使用此功能');
    }

    try {
      // 從 Service 獲取用戶資料
      final data = await _runCityService.getUserData();
      userData.value = data;
    } on RunCityApiException {
      // 重新拋出 API 錯誤，讓 loadData 處理
      rethrow;
    } catch (e) {
      // 其他錯誤也重新拋出
      rethrow;
    }
  }

  /// 刷新資料
  Future<void> refresh() async {
    await loadData();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    
    // 如果已經獲取了用戶位置，立即定位到用戶位置
    if (_initialUserLocation != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_initialUserLocation!, 15),
      );
      isUserLocationCentered.value = true;
    }
  }

  /// 處理地圖相機移動
  void onCameraMove(CameraPosition position) {
    _lastCameraPosition = position;
    // 實時檢查地圖中心是否與用戶位置一致
    _checkIfUserLocationCentered();
  }

  /// 處理地圖相機移動完成（停止）
  void onCameraIdle() {
    // 地圖停止移動時再次確認狀態
    if (_lastCameraPosition != null) {
      _checkIfUserLocationCentered();
    }
  }

  /// 檢查用戶位置是否在地圖中心
  void _checkIfUserLocationCentered() {
    if (_currentUserLocation == null || _lastCameraPosition == null) {
      return;
    }

    final cameraCenter = _lastCameraPosition!.target;
    final userLocation = _currentUserLocation!;
    
    // 計算距離（米）
    final distance = Geolocator.distanceBetween(
      cameraCenter.latitude,
      cameraCenter.longitude,
      userLocation.latitude,
      userLocation.longitude,
    );

    // 如果距離小於 50 米，認為是居中的
    final threshold = 50.0; // 50 米
    final isCentered = distance < threshold;
    
    // 只在狀態改變時更新，避免不必要的重建
    if (isUserLocationCentered.value != isCentered) {
      isUserLocationCentered.value = isCentered;
    }
  }

  /// 將地圖移動到用戶當前位置
  Future<void> centerToUserLocation() async {
    if (mapController == null) {
      return;
    }

    // 總是重新獲取用戶當前位置
    try {
      final granted = await _ensurePermissionReady();
      if (!granted) {
        Get.snackbar(
          '無法定位',
          '需要定位權限才能使用此功能',
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          backgroundColor: Colors.black87,
        );
        return;
      }

      // 獲取最新的用戶當前位置
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final newUserLocation = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      
      // 更新當前用戶位置
      _currentUserLocation = newUserLocation;

      // 移動地圖到用戶最新位置
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(newUserLocation, 15),
      );
      
      // 更新相機位置記錄，以便後續檢查
      _lastCameraPosition = CameraPosition(
        target: newUserLocation,
        zoom: 15,
      );
      // 地圖移動過程中，onCameraMove 會持續檢查並更新狀態
      // 當移動完成時，onCameraIdle 會最終確認狀態
    } catch (e) {
      Get.snackbar(
        '無法獲取位置',
        '請檢查定位服務是否開啟',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.black87,
      );
    }
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
    await _updateMarkers();
  }

  Future<void> _updateMarkers() async {
    await _ensureMarkerIcons();
    final collectedIcon = _collectedMarkerIcon;
    final uncollectedIcon = _uncollectedMarkerIcon;

    if (collectedIcon == null || uncollectedIcon == null) {
      return;
    }

    final nextMarkers = points.map((point) {
      final statusLabel = point.collected ? '已收集' : '待收集';
      final subtitle = (point.area?.isNotEmpty ?? false)
          ? '${point.area} · $statusLabel'
          : statusLabel;
      return Marker(
        markerId: MarkerId(point.id),
        position: point.location,
        infoWindow: InfoWindow(
          title: point.name,
          snippet: subtitle,
        ),
        icon: point.collected ? collectedIcon : uncollectedIcon,
        anchor: const Offset(0.5, 0.5),
        zIndex: point.collected ? 2 : 1,
      );
    }).toList();

    markers.assignAll(nextMarkers);
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
    _currentUserLocation = currentPoint; // 更新當前用戶位置
    _checkIfUserLocationCentered(); // 檢查是否居中

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
      // Ignore jitter smaller than 3 meters.
      return;
    }

    routePath.add(currentPoint);
    totalDistanceMeters.value += segmentDistance;
    _updatePolyline();
    _markVisitedPoints(currentPoint);

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
    if (points.isEmpty) {
      return;
    }

    final newlyVisitedIds = <String>[];
    final newlyVisitedWithNfc = <RunCityPoint>[];

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
        if ((point.nfcId?.isNotEmpty ?? false) || point.isNFCEnabled) {
          newlyVisitedWithNfc.add(point);
        }
      }
    }

    if (newlyVisitedIds.isEmpty) {
      return;
    }

    visitedPointIds.addAll(newlyVisitedIds);

    final now = DateTime.now();
    for (var i = 0; i < points.length; i++) {
      if (newlyVisitedIds.contains(points[i].id)) {
        final coins = points[i].coinsEarned;
        points[i] = points[i].copyWith(
          collected: true,
          collectedAt: now,
          coinsEarned: coins,
        );
      }
    }
    _updateMarkers();

    for (final point in newlyVisitedWithNfc) {
      _collectLocation(point);
    }
  }

  void _stopTrackingStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void _collectLocation(RunCityPoint point) {
    // 注意：根據 API 規格，點位收集是在結束活動時自動處理的
    // 此方法保留作為佔位符，實際收集邏輯在 endActivity 回應中處理
    debugPrint('RunCityController._collectLocation: 點位 ${point.id} 將在結束活動時處理');
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

    _updateMarkers();
  }

  Future<void> _ensureMarkerIcons() async {
    _collectedMarkerIcon ??= await _createCircleMarker(const Color(0xFFDBF1F5));
    _uncollectedMarkerIcon ??=
        await _createCircleMarker(const Color(0xFF5AB4C5));
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
}

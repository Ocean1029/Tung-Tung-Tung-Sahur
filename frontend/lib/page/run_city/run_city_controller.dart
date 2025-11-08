import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'run_city_point.dart';

class RunCityController extends GetxController {
  RunCityController();

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(25.033968, 121.564468), // Taipei City Hall MRT station
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

  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionSubscription;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  BitmapDescriptor? _collectedMarkerIcon;
  BitmapDescriptor? _uncollectedMarkerIcon;

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

    // TODO: Replace with repository/service fetch once backend is ready.
    // Mock points help us validate UI and interactions while APIs are under development.
    await Future.delayed(const Duration(milliseconds: 400));
    final mockPoints = <RunCityPoint>[
      RunCityPoint(
        id: 'xinyi-01',
        name: '象山登山口 NFC',
        district: '信義區',
        location: const LatLng(25.027220, 121.576161),
        collected: true,
      ),
      RunCityPoint(
        id: 'xinyi-02',
        name: '信義國小 NFC',
        district: '信義區',
        location: const LatLng(25.034571, 121.562600),
      ),
      RunCityPoint(
        id: 'daan-01',
        name: '大安森林公園 NFC',
        district: '大安區',
        location: const LatLng(25.033024, 121.535154),
        collected: true,
      ),
      RunCityPoint(
        id: 'daan-02',
        name: '師大夜市 NFC',
        district: '大安區',
        location: const LatLng(25.026173, 121.528164),
      ),
      RunCityPoint(
        id: 'zhongshan-01',
        name: '林森公園 NFC',
        district: '中山區',
        location: const LatLng(25.045070, 121.525990),
      ),
    ];

    points.assignAll(mockPoints);
    await _updateMarkers();

    isLoading.value = false;
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> updatePointCollected(String id, bool collected) async {
    final index = points.indexWhere((point) => point.id == id);
    if (index == -1) {
      return;
    }
    points[index] = points[index].copyWith(collected: collected);
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
      return Marker(
        markerId: MarkerId(point.id),
        position: point.location,
        infoWindow: InfoWindow(
          title: point.name,
          snippet: '${point.district} · ${point.collected ? '已收集' : '待收集'}',
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

    routePath.clear();
    polylines.clear();
    visitedPointIds.clear();
    totalDistanceMeters.value = 0;
    averageSpeedKmh.value = 0;
    elapsed.value = Duration.zero;

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
  }

  Future<void> stopTracking() async {
    if (!isTracking.value) {
      return;
    }

    _stopwatch.stop();
    _timer?.cancel();
    _stopTrackingStream();

    elapsed.value = _stopwatch.elapsed;
    if (_stopwatch.elapsed.inSeconds > 0) {
      final hours = _stopwatch.elapsed.inSeconds / 3600;
      averageSpeedKmh.value =
          hours > 0 ? (totalDistanceMeters.value / 1000) / hours : 0;
    }

    isTracking.value = false;
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
    final newlyVisited = <String>[];
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
        newlyVisited.add(point.id);
      }
    }

    if (newlyVisited.isEmpty) {
      return;
    }

    visitedPointIds.addAll(newlyVisited);
  }

  void _stopTrackingStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _ensureMarkerIcons() async {
    _collectedMarkerIcon ??= await _createCircleMarker(const Color(0xFF93D4DF));
    _uncollectedMarkerIcon ??=
        await _createCircleMarker(const Color(0xFFF1F3F4));
  }

  Future<BitmapDescriptor> _createCircleMarker(Color fillColor) async {
    const double size = 96;
    const double borderWidth = 6;
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

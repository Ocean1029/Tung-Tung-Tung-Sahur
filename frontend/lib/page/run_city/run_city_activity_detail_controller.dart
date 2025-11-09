import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:town_pass/page/run_city/run_city_api_service.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/service/run_city_service.dart';

class RunCityActivityDetailController extends GetxController {
  final RunCityApiService _apiService = Get.find<RunCityApiService>();
  final AccountService _accountService = Get.find<AccountService>();
  final RunCityService _runCityService = Get.find<RunCityService>();

  final RxBool isLoading = false.obs;
  final Rxn<RunCityActivityDetail> activityDetail =
      Rxn<RunCityActivityDetail>();
  final RxnString errorMessage = RxnString();

  // 地圖相關
  GoogleMapController? mapController;
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;

  String? _userId;
  String? _activityId;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments is Map<String, dynamic>) {
      _activityId = arguments['activityId'] as String?;
      _userId = arguments['userId'] as String?;
    }
    if (_activityId != null && _userId != null) {
      loadActivityDetail();
    } else {
      errorMessage.value = '缺少必要參數';
    }
  }

  @override
  void onClose() {
    mapController?.dispose();
    super.onClose();
  }

  /// 載入活動詳情
  Future<void> loadActivityDetail() async {
    if (_userId == null || _activityId == null) {
      errorMessage.value = '缺少必要參數';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      // 獲取用戶信息（用於顯示頭像和姓名）
      String? userName;
      String? userAvatar;

      try {
        final userData = await _runCityService.getUserData();
        userName = userData.name;
        userAvatar = userData.avatarUrl;
      } catch (e) {
        // 如果獲取用戶資料失敗，使用 account service 的資料
        final account = _accountService.account;
        if (account != null) {
          // Account 可能沒有 name 欄位，使用 userId 作為備用
          userName = account.id;
        }
      }

      final detail = await _apiService.fetchActivityDetail(
        userId: _userId!,
        activityId: _activityId!,
        userName: userName,
        userAvatar: userAvatar,
      );
      activityDetail.value = detail;
      await _updateMap();
    } on RunCityApiException catch (e) {
      final errorText = e.code != null ? '${e.message} (${e.code})' : e.message;
      errorMessage.value = errorText;
    } catch (e) {
      errorMessage.value = '載入活動詳情失敗：${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// 更新地圖顯示
  BitmapDescriptor? _nodeMarkerIcon;

  Future<void> _updateMap() async {
    final detail = activityDetail.value;
    if (detail == null || detail.route.isEmpty) {
      return;
    }

    // 建立路線 Polyline
    final routePoints = detail.route
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    polylines
      ..clear()
      ..add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: const Color(0xFFFF853A), // 橙色
          width: 5,
        ),
      );
    polylines.refresh();

    // 建立所在地點紀錄節點 Marker（僅顯示此次活動刷到的點位）
    final locationRecords = detail.locationRecords;
    final markerIcon = await _getNodeMarkerIcon();
    final markerPoints = locationRecords.isNotEmpty
        ? locationRecords
            .map(
              (record) => LatLng(record.latitude, record.longitude),
            )
            .toList(growable: false)
        : routePoints;
    final newMarkers = markerPoints
        .asMap()
        .entries
        .map(
          (entry) => Marker(
            markerId: MarkerId('location_point_${entry.key}'),
            position: entry.value,
            icon: markerIcon,
            anchor: const Offset(0.5, 0.5),
          ),
        )
        .toSet();
    markers
      ..clear()
      ..addAll(newMarkers);
    markers.refresh();

    // 調整地圖視角以包含所有路線
    final boundsPoints = markerPoints.isNotEmpty ? markerPoints : routePoints;
    if (mapController != null && boundsPoints.isNotEmpty) {
      await _fitBounds(boundsPoints);
    }
  }

  /// 調整地圖視角以包含所有點位
  Future<void> _fitBounds(List<LatLng> points) async {
    if (points.isEmpty || mapController == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.001, minLng - 0.001),
          northeast: LatLng(maxLat + 0.001, maxLng + 0.001),
        ),
        100.0, // padding
      ),
    );
  }

  /// 地圖創建完成回調
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    unawaited(_updateMap());
  }

  /// 刷新資料
  Future<void> refresh() async {
    await loadActivityDetail();
  }

  Future<BitmapDescriptor> _getNodeMarkerIcon() async {
    if (_nodeMarkerIcon != null) {
      return _nodeMarkerIcon!;
    }

    const double markerDiameter = 50;
    const double borderWidth = 3.5;
    const double shadowBlurSigma = 7;
    const double shadowOffsetY = 5;
    final double canvasSize =
        markerDiameter + shadowBlurSigma * 2 + shadowOffsetY;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final center = ui.Offset(
      canvasSize / 2,
      markerDiameter / 2 + shadowBlurSigma,
    );

    final shadowPaint = ui.Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, shadowBlurSigma);
    canvas.drawCircle(
      center.translate(0, shadowOffsetY),
      markerDiameter / 2,
      shadowPaint,
    );

    final fillPaint = ui.Paint()..color = const Color(0xFF5AB4C5);
    canvas.drawCircle(center, markerDiameter / 2, fillPaint);

    final borderPaint = ui.Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(
      center,
      markerDiameter / 2 - borderWidth / 2,
      borderPaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.toInt(),
      (markerDiameter + shadowBlurSigma * 2 + shadowOffsetY).toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('無法產生節點圖示');
    }
    final Uint8List bytes = byteData.buffer.asUint8List();
    _nodeMarkerIcon = BitmapDescriptor.fromBytes(bytes);
    return _nodeMarkerIcon!;
  }
}

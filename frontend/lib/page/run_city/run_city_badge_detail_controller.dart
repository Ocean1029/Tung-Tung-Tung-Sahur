import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:town_pass/page/run_city/run_city_api_service.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';
import 'package:town_pass/service/account_service.dart';

class RunCityBadgeDetailController extends GetxController {
  final RunCityApiService _apiService = Get.find<RunCityApiService>();
  final AccountService _accountService = Get.find<AccountService>();

  final RxBool isLoading = true.obs;
  final Rxn<RunCityBadgeDetail> badgeDetail = Rxn<RunCityBadgeDetail>();
  final RxnString errorMessage = RxnString();

  late CameraPosition initialCameraPosition;
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Circle> circles = <Circle>{}.obs;
  GoogleMapController? mapController;
  BitmapDescriptor? _pointMarkerIcon;

  static const Color _pointColor = Color.fromRGBO(90, 180, 197, 1);
  static const String _mapStyleHidePoi = '''
[
  {
    "featureType": "poi",
    "stylers": [{ "visibility": "off" }]
  }
]
''';

  RunCityBadge? get badge => badgeDetail.value?.badge;
  List<RunCityBadgeLocation> get badgeLocations => badgeDetail.value?.requiredLocations ?? [];

  String get badgeDescription => badge?.description ?? '探索${badge?.name ?? ""}，完成所有指定地點即可獲得徽章。';

  List<RunCityBadgeLocation> get collectedLocations => badgeLocations
      .where((location) => location.isCollected)
      .toList();

  List<RunCityBadgeLocation> get pendingLocations => badgeLocations
      .where((location) => !location.isCollected)
      .toList();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? <String, dynamic>{};
    final badgeId = args['badgeId'] as String?;
    final badgeArg = args['badge'] as RunCityBadge?;

    if (badgeId == null && badgeArg == null) {
      Get.back();
      return;
    }

    loadBadgeDetail(badgeId ?? badgeArg!.badgeId);
  }

  Future<void> loadBadgeDetail(String badgeId) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final account = _accountService.account;
      if (account == null) {
        errorMessage.value = '請先登入';
        return;
      }

      final detail = await _apiService.fetchUserBadgeDetail(
        userId: account.id,
        badgeId: badgeId,
      );

      badgeDetail.value = detail;
    initialCameraPosition = _buildInitialCameraPosition();
      circles.clear();
      await _prepareMarkers();
    } catch (e) {
      errorMessage.value = '載入徽章詳情失敗：$e';
    } finally {
      isLoading.value = false;
    }
  }

  CameraPosition _buildInitialCameraPosition() {
    if (badgeLocations.isEmpty) {
      return const CameraPosition(
        target: LatLng(25.033968, 121.564468),
        zoom: 13,
      );
    }

    double latSum = 0;
    double lngSum = 0;
    for (final location in badgeLocations) {
      latSum += location.latitude;
      lngSum += location.longitude;
    }
    final center =
        LatLng(latSum / badgeLocations.length, lngSum / badgeLocations.length);

    return CameraPosition(
      target: center,
      zoom: _suggestZoom(badgeLocations),
    );
  }

  double _suggestZoom(List<RunCityBadgeLocation> locations) {
    if (locations.length <= 1) {
      return 15;
    }
    double maxDistance = 0;
    for (var i = 0; i < locations.length; i++) {
      for (var j = i + 1; j < locations.length; j++) {
        final distance = _haversineDistance(
          locations[i].location,
          locations[j].location,
        );
        maxDistance = max(maxDistance, distance);
      }
    }
    if (maxDistance < 0.5) {
      return 15.5;
    }
    if (maxDistance < 1) {
      return 14.5;
    }
    if (maxDistance < 3) {
      return 13.5;
    }
    return 12.5;
  }

  double _haversineDistance(LatLng a, LatLng b) {
    const earthRadiusKm = 6371;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final h = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  Future<void> _prepareMarkers() async {
    // 使用徽章的顏色，如果沒有則使用默認顏色
    final badgeColor = badge?.badgeColor ?? _pointColor;
    // 每次重新創建標記圖標，以確保使用正確的徽章顏色
    _pointMarkerIcon = await _createMarkerBitmap(
      diameter: 50,
      fillColor: badgeColor,
      borderColor: Colors.white,
      borderWidth: 4,
      shadowBlur: 8,
    );
    markers.assignAll(_buildMarkers());
    update(['badgeMap']);
  }

  Set<Marker> _buildMarkers() {
    if (badge == null) {
      return <Marker>{};
    }
    
    return badgeLocations.map((location) {
      return Marker(
        markerId: MarkerId(location.locationId),
        position: location.location,
        infoWindow: InfoWindow(
          title: location.name,
          snippet: badge?.area ?? '',
        ),
        icon: _pointMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(
              location.isCollected
                  ? BitmapDescriptor.hueAzure
                  : BitmapDescriptor.hueCyan,
            ),
        zIndex: 2,
      );
    }).toSet();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    controller.setMapStyle(_mapStyleHidePoi);
  }

  Future<void> focusOnLocation(RunCityBadgeLocation location) async {
    if (mapController == null) {
      return;
    }
    await mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(location.location, 15),
    );
  }

  Future<BitmapDescriptor> _createMarkerBitmap({
    required double diameter,
    required Color fillColor,
    required Color borderColor,
    double borderWidth = 2,
    double shadowBlur = 6,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = ui.Size(diameter, diameter);
    final center = Offset(diameter / 2, diameter / 2);

    if (shadowBlur > 0) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);
      canvas.drawCircle(
        center.translate(0, diameter * 0.05),
        diameter / 2 - borderWidth,
        shadowPaint,
      );
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, diameter / 2, borderPaint);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, diameter / 2 - borderWidth, fillPaint);

    final picture = recorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void shareBadge() {
    // TODO: wire up actual share logic when ready.
    Get.snackbar(
      '敬請期待',
      '分享功能即將推出',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }
}


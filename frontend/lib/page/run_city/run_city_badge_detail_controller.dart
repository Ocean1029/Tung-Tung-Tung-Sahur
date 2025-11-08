import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';

class RunCityBadgeDetailController extends GetxController {
  late final RunCityBadge badge;
  late final List<RunCityPoint> allPoints;

  late final List<RunCityPoint> badgePoints;
  late final CameraPosition initialCameraPosition;
  late Set<Marker> markers;
  late final Set<Circle> circles;
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

  String get badgeDescription =>
      _badgeDescriptions[badge.id] ?? '探索${badge.name}，完成所有指定地點即可獲得徽章。';

  List<RunCityPoint> get collectedPoints => badgePoints
      .where((point) => badge.collectedPointIds.contains(point.id))
      .toList();

  List<RunCityPoint> get pendingPoints => badgePoints
      .where((point) => !badge.collectedPointIds.contains(point.id))
      .toList();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? <String, dynamic>{};
    final badgeArg = args['badge'];
    final pointsArg = args['points'];

    if (badgeArg is! RunCityBadge || pointsArg is! List<RunCityPoint>) {
      Get.back();
      return;
    }

    badge = badgeArg;
    allPoints = pointsArg;
    badgePoints = allPoints
        .where(
          (point) => badge.pointIds.contains(point.id),
        )
        .toList(growable: false);

    initialCameraPosition = _buildInitialCameraPosition();
    circles = const <Circle>{};
    _prepareMarkers();
  }

  CameraPosition _buildInitialCameraPosition() {
    if (badgePoints.isEmpty) {
      return const CameraPosition(
        target: LatLng(25.033968, 121.564468),
        zoom: 13,
      );
    }

    double latSum = 0;
    double lngSum = 0;
    for (final point in badgePoints) {
      latSum += point.location.latitude;
      lngSum += point.location.longitude;
    }
    final center =
        LatLng(latSum / badgePoints.length, lngSum / badgePoints.length);

    return CameraPosition(
      target: center,
      zoom: _suggestZoom(badgePoints),
    );
  }

  double _suggestZoom(List<RunCityPoint> points) {
    if (points.length <= 1) {
      return 15;
    }
    double maxDistance = 0;
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final distance = _haversineDistance(
          points[i].location,
          points[j].location,
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
    _pointMarkerIcon ??= await _createMarkerBitmap(
      diameter: 50,
      fillColor: _pointColor,
      borderColor: Colors.white,
      borderWidth: 4,
      shadowBlur: 8,
    );
    markers = _buildMarkers();
    update(['badgeMap']);
  }

  Set<Marker> _buildMarkers() {
    final collectedIds = badge.collectedPointIds.toSet();
    return badgePoints.map((point) {
      final isCollected = collectedIds.contains(point.id);
      return Marker(
        markerId: MarkerId(point.id),
        position: point.location,
        infoWindow: InfoWindow(
          title: point.name,
          snippet: point.area ?? '',
        ),
        icon: _pointMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(
              isCollected
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

  Future<void> focusOnPoint(RunCityPoint point) async {
    if (mapController == null) {
      return;
    }
    await mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(point.location, 15),
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

const Map<String, String> _badgeDescriptions = <String, String>{
  '中正區': '穿梭中正區的特色地標，一次蒐集台北的歷史韻味。',
  '萬華區': '沿著舊城小巷探險，收集萬華的老味道。',
  '大同區': '環遊大稻埕河岸，感受古城的繁華風情。',
  '信義區': '走訪信義計畫區與山林步道，完成都會與自然的雙重任務。',
  '大安區': '漫步綠意與學區，一次收集台大周邊的經典地標。',
  '士林區': '夜市與文藝路線兼具，完成士林的探索挑戰。',
};

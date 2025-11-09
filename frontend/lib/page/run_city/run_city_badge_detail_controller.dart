import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/service/run_city_service.dart';

class RunCityBadgeDetailController extends GetxController {
  RunCityBadgeDetailController()
      : _accountService = Get.isRegistered<AccountService>()
            ? Get.find<AccountService>()
            : null,
        _runCityService = Get.isRegistered<RunCityService>()
            ? Get.find<RunCityService>()
            : null;

  late final RunCityBadge badge;
  late final List<RunCityPoint> allPoints;

  late final List<RunCityPoint> badgePoints;
  late final CameraPosition initialCameraPosition;
  late Set<Marker> markers;
  late final Set<Circle> circles;
  GoogleMapController? mapController;
  BitmapDescriptor? _pointMarkerIcon;
  final GlobalKey shareCardKey = GlobalKey();

  static const Color _pointColor = Color.fromRGBO(90, 180, 197, 1);
  static const String _mapStyleHidePoi = '''
[
  {
    "featureType": "poi",
    "stylers": [{ "visibility": "off" }]
  }
]
''';

  final AccountService? _accountService;
  final RunCityService? _runCityService;

  String? _userName;
  bool _isSharing = false;

  String get badgeDescription =>
      _badgeDescriptions[badge.id] ?? '探索${badge.name}，完成所有指定地點即可獲得徽章。';

  List<RunCityPoint> get collectedPoints => badgePoints
      .where((point) => badge.collectedPointIds.contains(point.id))
      .toList();

  List<RunCityPoint> get pendingPoints => badgePoints
      .where((point) => !badge.collectedPointIds.contains(point.id))
      .toList();

  String get shareUserName =>
      _userName?.isNotEmpty == true ? _userName! : 'Run City 玩家';
  bool get isSharing => _isSharing;

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
    markers = <Marker>{};
    _prepareMarkers();
    unawaited(_loadUserName());
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

  Future<bool> shareBadge() async {
    if (!badge.isCompleted || _isSharing) {
      return false;
    }

    try {
      _isSharing = true;
      update(['sharePreview']);
      final RenderRepaintBoundary boundary = await _obtainReadyBoundary();

      ui.Image image;
      try {
        image = await boundary.toImage(pixelRatio: 3);
      } catch (error, stack) {
        _logShareError('capture_image', error, stack);
        throw _ShareException(
          userMessage: '生成分享圖片時發生錯誤，請稍後再試',
          debugStep: 'capture_image',
          cause: error,
        );
      }

      ByteData? byteData;
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } catch (error, stack) {
        _logShareError('encode_image', error, stack);
        throw _ShareException(
          userMessage: '轉換分享圖片時發生錯誤，請稍後再試',
          debugStep: 'encode_image',
          cause: error,
        );
      }
      if (byteData == null) {
        throw _ShareException(
          userMessage: '無法產生分享圖片，請稍後再試',
          debugStep: 'encode_image_null',
        );
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      File file;
      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath =
            '${tempDir.path}/run_city_badge_${badge.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        file = File(filePath);
        await file.writeAsBytes(pngBytes, flush: true);
      } catch (error, stack) {
        _logShareError('write_file', error, stack);
        throw _ShareException(
          userMessage: '儲存分享圖片時發生錯誤，請檢查儲存空間後再試',
          debugStep: 'write_file',
          cause: error,
        );
      }

      try {
        final String shareText =
            '我完成了 ${badge.name} 徽章，收集了 ${badge.collectedPoints}/${badge.totalPoints} 個點位！#RunCity #TownPass';
        await Share.shareXFiles(
          [XFile(file.path)],
          text: shareText,
        );
      } catch (error, stack) {
        _logShareError('share_sheet', error, stack);
        throw _ShareException(
          userMessage: '開啟分享面板失敗，請確認是否允許分享權限或稍後再試',
          debugStep: 'share_sheet',
          cause: error,
        );
      }
      return true;
    } on _ShareException catch (shareError) {
      if (shareError.debugStep != null) {
        debugPrint(
          '[RunCityBadgeShare] step=${shareError.debugStep} badge=${badge.id} message=${shareError.userMessage} cause=${shareError.cause}',
        );
      }
      _showShareError(shareError.userMessage);
      return false;
    } finally {
      _isSharing = false;
      update(['sharePreview']);
    }
    return false;
  }

  Future<RenderRepaintBoundary> _obtainReadyBoundary() async {
    RenderRepaintBoundary? boundary;
    for (var attempt = 0; attempt < 8; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      boundary = shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw const _ShareException(
          userMessage: '找不到分享卡片，請重新進入頁面後再試',
          debugStep: 'locate_boundary',
        );
      }
      if (boundary.size.isEmpty) {
        throw const _ShareException(
          userMessage: '分享卡片尚未準備好，請稍後再試',
          debugStep: 'boundary_empty',
        );
      }
      if (!boundary.debugNeedsPaint) {
        return boundary;
      }
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    throw const _ShareException(
      userMessage: '分享畫面尚未渲染完成，請稍候片刻再試',
      debugStep: 'boundary_never_painted',
    );
  }

  Future<void> _loadUserName() async {
    try {
      final runCityService = _runCityService;
      if (runCityService != null) {
        final userData = await runCityService.getUserData();
        if (userData.name.isNotEmpty) {
          _userName = userData.name;
          return;
        }
      }
    } catch (_) {
      // ignore and fallback to account service
    }

    final accountService = _accountService;
    if (accountService?.account?.id != null) {
      _userName = accountService!.account!.id;
    }
  }

  void _showShareError(String message) {
    Get.snackbar(
      '分享失敗',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black.withOpacity(0.85),
      colorText: Colors.white,
    );
  }

  void _logShareError(String step, Object error, StackTrace stackTrace) {
    debugPrint(
      '[RunCityBadgeShare] step=$step badge=${badge.id} error=$error\n$stackTrace',
    );
  }
}

class _ShareException implements Exception {
  const _ShareException({
    required this.userMessage,
    this.debugStep,
    this.cause,
  });

  final String userMessage;
  final String? debugStep;
  final Object? cause;
}

const Map<String, String> _badgeDescriptions = <String, String>{
  '中正區': '穿梭中正區的特色地標，一次蒐集台北的歷史韻味。',
  '萬華區': '沿著舊城小巷探險，收集萬華的老味道。',
  '大同區': '環遊大稻埕河岸，感受古城的繁華風情。',
  '信義區': '走訪信義計畫區與山林步道，完成都會與自然的雙重任務。',
  '大安區': '漫步綠意與學區，一次收集台大周邊的經典地標。',
  '士林區': '夜市與文藝路線兼具，完成士林的探索挑戰。',
};

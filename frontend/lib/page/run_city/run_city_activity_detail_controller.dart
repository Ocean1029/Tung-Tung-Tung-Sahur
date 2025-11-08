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
  final Rxn<RunCityActivityDetail> activityDetail = Rxn<RunCityActivityDetail>();
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
      _updateMap();
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
  void _updateMap() {
    final detail = activityDetail.value;
    if (detail == null || detail.route.isEmpty) {
      return;
    }

    // 建立路線 Polyline
    final routePoints = detail.route.map((point) => LatLng(point.latitude, point.longitude)).toList();
    polylines.clear();
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: const Color(0xFFFF853A), // 橙色
        width: 5,
      ),
    );

    // 建立起點和終點 Marker
    final startPoint = detail.route.first;
    final endPoint = detail.route.last;
    markers.clear();
    markers.addAll({
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(startPoint.latitude, startPoint.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: LatLng(endPoint.latitude, endPoint.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    });

    // 調整地圖視角以包含所有路線
    if (mapController != null && routePoints.isNotEmpty) {
      _fitBounds(routePoints);
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
    _updateMap();
  }

  /// 刷新資料
  Future<void> refresh() async {
    await loadActivityDetail();
  }
}


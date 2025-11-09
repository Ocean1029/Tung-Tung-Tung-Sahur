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
  /// 
  /// 地圖顯示邏輯：優先使用 NFC 收集的位置繪製路線
  /// 1. 如果有 NFC 收集位置：使用 NFC 位置繪製（Demo 場景）
  /// 2. 如果沒有 NFC 收集位置但有 GPS 路線：使用 GPS 路線繪製（真實使用場景）
  /// 3. 兩種數據都保留，根據可用性自動選擇
  void _updateMap() {
    final detail = activityDetail.value;
    if (detail == null) {
      return;
    }

    // 判斷使用哪種數據源
    // 優先級：NFC locationRecords（Demo） > GPS route（真實使用）
    final hasNfcLocations = detail.locationRecords.isNotEmpty;
    final hasGpsRoute = detail.route.length >= 2;
    
    List<LatLng> routePoints;
    bool useNfcLocations = false;
    bool useGpsRoute = false;

    if (hasNfcLocations) {
      // 情況 1：有 NFC 收集位置（Demo 場景）- 優先使用 NFC 位置
      routePoints = detail.locationRecords
          .map((record) => LatLng(record.latitude, record.longitude))
          .toList();
      useNfcLocations = true;
    } else if (hasGpsRoute) {
      // 情況 2：沒有 NFC 收集位置但有 GPS 路線（真實使用場景）- 使用 GPS 路線
      routePoints = detail.route
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
      useGpsRoute = true;
    } else {
      // 情況 3：兩種都沒有，不顯示地圖
      return;
    }

    // 建立路線 Polyline
    polylines.clear();
    if (routePoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: const Color(0xFFFF853A), // 橙色
          width: 5,
        ),
      );
    }

    // 建立 Marker
    markers.clear();
    
    if (useNfcLocations) {
      // 使用 NFC 收集的位置作為 Marker（Demo 場景）
      for (int i = 0; i < detail.locationRecords.length; i++) {
        final record = detail.locationRecords[i];
        final position = LatLng(record.latitude, record.longitude);
        
        // 第一個點是起點（綠色），最後一個點是終點（紅色），其他是收集點（藍色）
        double markerHue;
        String markerId;
        if (i == 0) {
          markerHue = BitmapDescriptor.hueGreen; // 起點：綠色
          markerId = 'start';
        } else if (i == detail.locationRecords.length - 1) {
          markerHue = BitmapDescriptor.hueRed; // 終點：紅色
          markerId = 'end';
        } else {
          markerHue = BitmapDescriptor.hueBlue; // 收集點：藍色
          markerId = 'nfc_$i';
        }
        
        markers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
            infoWindow: InfoWindow(
              title: record.locationName,
              snippet: '${record.formattedTime}',
            ),
          ),
        );
      }
    } else if (useGpsRoute) {
      // 使用 GPS 路線的起點和終點（真實使用場景）
      final startPoint = routePoints.first;
      final endPoint = routePoints.last;
      markers.addAll({
        Marker(
          markerId: const MarkerId('start'),
          position: startPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('end'),
          position: endPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      });
    }

    // 調整地圖視角以包含所有路線和標記
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

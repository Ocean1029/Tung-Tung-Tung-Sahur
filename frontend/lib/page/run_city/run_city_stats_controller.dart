import 'package:get/get.dart';
import 'package:town_pass/bean/run_city.dart';
import 'package:town_pass/page/run_city/run_city_api_service.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';
import 'package:flutter/foundation.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/service/run_city_service.dart';

class RunCityStatsController extends GetxController {
  final RunCityService _runCityService = Get.find<RunCityService>();
  final RunCityApiService _apiService = Get.find<RunCityApiService>();
  final AccountService _accountService = Get.find<AccountService>();

  final RxBool isLoading = false.obs;
  final Rxn<RunCityUserData> userData = Rxn<RunCityUserData>();
  final RxList<RunCityActivityItem> activities = <RunCityActivityItem>[].obs;
  final RxList<RunCityBadge> badges = <RunCityBadge>[].obs;
  final RxBool areBadgesExpanded = false.obs;
  final RxList<RunCityPoint> badgePointsSource = <RunCityPoint>[].obs;
  final RxnString errorMessage = RxnString();

  /// 計算總時間（從活動列表中累加，單位：秒）
  int get totalTimeSeconds {
    return activities.fold<int>(0, (sum, activity) => sum + activity.duration);
  }

  /// 格式化總時間
  String get formattedTotalTime {
    final hours = totalTimeSeconds ~/ 3600;
    final minutes = (totalTimeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours} 時 ${minutes} 分';
    }
    return '${minutes} 分';
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  /// 載入用戶資料和活動列表
  Future<void> loadData() async {
    // 檢查用戶是否已登入
    if (_accountService.account == null) {
      errorMessage.value = '請先登入以使用此功能';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final userId = _accountService.account!.id;
      // 並行載入用戶資料和活動列表
      await Future.wait([
        _loadUserData(),
        _loadActivities(userId),
        _loadBadges(userId),
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

  /// 載入用戶資料
  Future<void> _loadUserData() async {
    final data = await _runCityService.getUserData();
    userData.value = data;
  }

  /// 載入活動列表（獲取所有記錄）
  Future<void> _loadActivities(String userId) async {
    // 後端 API 最大 limit 為 100，需要分頁加載所有記錄
    final allItems = <RunCityActivityItem>[];
    int currentPage = 1;
    const limit = 100; // 後端允許的最大值
    bool hasMore = true;
    
    while (hasMore) {
      final items = await _apiService.fetchActivities(
        userId: userId,
        page: currentPage,
        limit: limit,
      );
      
      allItems.addAll(items);
      
      // 如果返回的記錄數少於 limit，說明已經是最後一頁
      if (items.length < limit) {
        hasMore = false;
      } else {
        currentPage++;
      }
    }
    
    activities.assignAll(allItems);
  }

  Future<void> _loadBadges(String userId) async {
    try {
      final userBadges = await _apiService.fetchUserBadges(userId: userId);
      // 根據狀態排序：進行中 > 已收集 > 未解鎖
      userBadges.sort((a, b) {
        final statusOrder = {
          RunCityBadgeStatus.inProgress: 0,
          RunCityBadgeStatus.collected: 1,
          RunCityBadgeStatus.locked: 2,
        };
        final aOrder = statusOrder[a.status] ?? 3;
        final bOrder = statusOrder[b.status] ?? 3;
        return aOrder.compareTo(bOrder);
      });
      badges.assignAll(userBadges);
      areBadgesExpanded.value = false;
    } catch (e) {
      if (kDebugMode) {
        print('載入徽章失敗: $e');
      }
      badges.clear();
    }
  }

  /// 刷新資料
  Future<void> refresh() async {
    await loadData();
  }

  void toggleBadgeExpansion() {
    if (badges.length <= 3) {
      return;
    }
    areBadgesExpanded.toggle();
  }
}


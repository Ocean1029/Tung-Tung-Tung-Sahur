import 'package:get/get.dart';
import 'package:town_pass/page/run_city/run_city_api_service.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';
import 'package:town_pass/page/run_city/run_city_controller.dart';
import 'package:town_pass/service/account_service.dart';

class RunCityStatsController extends GetxController {
  final RunCityController _runCityController = Get.find<RunCityController>();
  final RunCityApiService _apiService = Get.find<RunCityApiService>();
  final AccountService _accountService = Get.find<AccountService>();

  final RxBool isLoading = false.obs;
  final Rxn<RunCityUserProfile> userProfile = Rxn<RunCityUserProfile>();
  final RxList<RunCityActivityItem> activities = <RunCityActivityItem>[].obs;
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
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  void onInit() {
    super.onInit();
    _syncUserProfile();
    ever<RunCityUserProfile?>(_runCityController.userProfile, (_) {
      _syncUserProfile();
    });
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
      if (_runCityController.userProfile.value == null &&
          !_runCityController.isLoading.value) {
        await _runCityController.loadData();
        _syncUserProfile();
      }
      await _loadActivities(userId);
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

  /// 載入活動列表
  Future<void> _loadActivities(String userId) async {
    final items = await _apiService.fetchActivities(userId: userId);
    activities.assignAll(items);
  }

  /// 刷新資料
  Future<void> refresh() async {
    final account = _accountService.account;
    if (account == null) {
      errorMessage.value = '請先登入以使用此功能';
      return;
    }
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _runCityController.refresh();
      _syncUserProfile();
      await _loadActivities(account.id);
    } on RunCityApiException catch (e) {
      final errorText = e.code != null ? '${e.message} (${e.code})' : e.message;
      errorMessage.value = errorText;
    } catch (e) {
      errorMessage.value = '載入資料失敗：${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void _syncUserProfile() {
    userProfile.value = _runCityController.userProfile.value;
  }

  int get totalBadges => _runCityController.badges.length;

  int get collectedBadges =>
      _runCityController.badges.where((badge) => badge.isCompleted).length;
}


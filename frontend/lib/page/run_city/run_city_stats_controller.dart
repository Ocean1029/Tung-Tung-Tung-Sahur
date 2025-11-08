import 'package:get/get.dart';
import 'package:town_pass/bean/run_city.dart';
import 'package:town_pass/page/run_city/run_city_api_service.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/service/run_city_service.dart';

class RunCityStatsController extends GetxController {
  final RunCityService _runCityService = Get.find<RunCityService>();
  final RunCityApiService _apiService = Get.find<RunCityApiService>();
  final AccountService _accountService = Get.find<AccountService>();

  final RxBool isLoading = false.obs;
  final Rxn<RunCityUserData> userData = Rxn<RunCityUserData>();
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

  /// 載入活動列表
  Future<void> _loadActivities(String userId) async {
    final items = await _apiService.fetchActivities(userId: userId);
    activities.assignAll(items);
  }

  /// 刷新資料
  Future<void> refresh() async {
    await loadData();
  }
}


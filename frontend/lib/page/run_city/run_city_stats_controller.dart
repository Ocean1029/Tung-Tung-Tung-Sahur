import 'package:get/get.dart';
import 'package:town_pass/bean/run_city.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/service/run_city_service.dart';

class RunCityStatsController extends GetxController {
  final RunCityService _runCityService = Get.find<RunCityService>();
  final AccountService _accountService = Get.find<AccountService>();

  final RxBool isLoading = false.obs;
  final Rxn<RunCityUserData> userData = Rxn<RunCityUserData>();
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  /// 載入用戶資料
  Future<void> loadData() async {
    // 檢查用戶是否已登入
    if (_accountService.account == null) {
      errorMessage.value = '請先登入以使用此功能';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      // 從 Service 獲取用戶資料
      final data = await _runCityService.getUserData();
      userData.value = data;
    } catch (e) {
      errorMessage.value = '載入資料失敗：${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新資料
  Future<void> refresh() async {
    await loadData();
  }
}


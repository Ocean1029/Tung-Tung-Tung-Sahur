import 'package:get/get.dart';

class RunCityController extends GetxController {
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    // TODO: 載入資料
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;
  }
}


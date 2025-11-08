import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:town_pass/bean/run_city.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/service/account_service.dart';

class RunCityService extends GetxService {
  // 設定是否使用 Mock Data（後端串接後改為 false）
  static const bool useMockData = true;

  // 後端 API 基礎 URL（後端串接時使用）
  static const String baseUrl = 'https://your-backend-api.com/api';

  final AccountService _accountService = Get.find<AccountService>();

  /// 初始化用戶的 run_city 資料（首次進入時調用）
  Future<void> initializeUserData() async {
    if (useMockData) {
      // Mock 模式下不需要初始化
      return;
    }

    final account = _accountService.account;
    if (account == null) {
      throw Exception('用戶未登入');
    }

    try {
      // TODO: 後端串接後實作
      // 調用後端 API 初始化用戶資料
      // 後端會檢查該用戶是否已有資料，如果沒有則創建初始資料
      // final response = await http.post(
      //   Uri.parse('$baseUrl/run-city/initialize'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer ${token}', // 如果需要認證
      //   },
      //   body: jsonEncode({
      //     'user_id': account.id,
      //   }),
      // );
      //
      // if (response.statusCode != 200 && response.statusCode != 201) {
      //   throw Exception('初始化失敗');
      // }
    } catch (e) {
      // 如果初始化失敗，記錄錯誤但不中斷流程
      print('初始化用戶資料失敗: $e');
    }
  }

  /// 獲取用戶的 Run City 資料
  Future<RunCityUserData> getUserData() async {
    if (useMockData) {
      return _getMockUserData();
    } else {
      // 確保用戶資料已初始化
      await initializeUserData();
      return _getApiUserData();
    }
  }

  // ========== Mock Data 方法 ==========

  Future<RunCityUserData> _getMockUserData() async {
    try {
      // 模擬網路延遲
      await Future.delayed(const Duration(milliseconds: 500));

      final String mockData = await rootBundle.loadString(
        Assets.mockData.runCity,
      );
      final jsonData = jsonDecode(mockData);
      final response = RunCityUserDataResponse.fromJson(jsonData);
      return response.data;
    } catch (e) {
      throw Exception('載入 Mock 資料失敗: $e');
    }
  }

  // ========== 真實 API 方法（後端串接時使用）==========

  Future<RunCityUserData> _getApiUserData() async {
    // TODO: 後端串接後實作
    // import 'package:http/http.dart' as http;
    //
    // final account = _accountService.account;
    // if (account == null) {
    //   throw Exception('用戶未登入');
    // }
    //
    // try {
    //   final response = await http.get(
    //     Uri.parse('$baseUrl/run-city/user-data?user_id=${account.id}'),
    //     headers: {
    //       'Content-Type': 'application/json',
    //       // 'Authorization': 'Bearer ${token}', // 如果需要認證
    //     },
    //   );
    //
    //   if (response.statusCode == 200) {
    //     final jsonData = jsonDecode(response.body);
    //     final userDataResponse = RunCityUserDataResponse.fromJson(jsonData);
    //     return userDataResponse.data;
    //   } else {
    //     throw Exception('獲取用戶資料失敗: ${response.statusCode}');
    //   }
    // } catch (e) {
    //   throw Exception('獲取用戶資料錯誤: $e');
    // }

    throw UnimplementedError('API not implemented yet');
  }
}


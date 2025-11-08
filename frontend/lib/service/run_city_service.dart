import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:town_pass/bean/run_city.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/page/run_city/run_city_api_service.dart';
import 'package:town_pass/service/account_service.dart';

class RunCityService extends GetxService {
  // 可透過 --dart-define=RUN_CITY_USE_MOCK_DATA=true 啟用 Mock 模式
  static const bool useMockData = bool.fromEnvironment(
    'RUN_CITY_USE_MOCK_DATA',
    defaultValue: false,
  );

  final AccountService _accountService = Get.find<AccountService>();
  final RunCityApiService _apiService = Get.find<RunCityApiService>();

  /// 初始化用戶的 run_city 資料（首次進入時調用）
  Future<void> initializeUserData() async {
    if (useMockData) {
      // Mock 模式下不需要初始化
      return;
    }

    // 後端會在首次獲取用戶資料時自動初始化，不需要單獨的初始化端點
    // 如果後續需要，可以在這裡添加初始化邏輯
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
      
      if (!response.success || response.data == null) {
        throw Exception('Mock 資料格式錯誤');
      }
      
      return response.data!;
    } catch (e) {
      throw Exception('載入 Mock 資料失敗: $e');
    }
  }

  // ========== 真實 API 方法（後端串接時使用）==========

  Future<RunCityUserData> _getApiUserData() async {
    final account = _accountService.account;
    if (account == null) {
      throw Exception('用戶未登入');
    }

    try {
      // 使用 RunCityApiService 的 baseUrl 來構建完整的 API URL
      final baseUrl = _apiService.baseUrl;
      final normalizedBase = baseUrl.endsWith('/') 
          ? baseUrl.substring(0, baseUrl.length - 1) 
          : baseUrl;
      final uri = Uri.parse('$normalizedBase/api/users/${account.id}/profile');
      
      final response = await http.get(
        uri,
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('獲取用戶資料失敗: ${response.statusCode}');
      }

      final jsonData = jsonDecode(response.body);
      final apiResponse = RunCityUserDataResponse.fromJson(jsonData);
      
      // 處理錯誤回應
      if (!apiResponse.success || apiResponse.data == null) {
        final error = apiResponse.error;
        if (error != null) {
          throw RunCityApiException(
            error.message,
            code: error.code,
            statusCode: response.statusCode,
          );
        }
        throw Exception('獲取用戶資料失敗');
      }

      return apiResponse.data!;
    } on RunCityApiException {
      rethrow;
    } catch (e) {
      throw Exception('獲取用戶資料錯誤: $e');
    }
  }
}


import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:town_pass/service/device_service.dart';

class NFCService extends GetxService {
  // 後端 API 基礎 URL
  // ⚠️ 重要：在真機上不能使用 localhost，必須使用 Mac 的 IP 地址！
  // 請將下面的 IP 改為你的 Mac 的 IP 地址（例如：10.103.176.218）
  final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.103.176.218:3000', // TODO: 改為你的 Mac IP
  );

  final DeviceService _deviceService = Get.find<DeviceService>();

  /// 發送 NFC 讀取結果到後端
  Future<bool> sendNFCRead({
    required String nfcId,
    String? tagType,
  }) async {
    try {
      final deviceInfoMap = <String, String>{};

      if (Platform.isIOS && _deviceService.iosDeviceInfo != null) {
        final iosInfo = _deviceService.iosDeviceInfo!;
        deviceInfoMap['platform'] = 'iOS';
        deviceInfoMap['model'] = iosInfo.model;
        deviceInfoMap['osVersion'] = iosInfo.systemVersion;
      } else if (Platform.isAndroid && _deviceService.androidDeviceInfo != null) {
        final androidInfo = _deviceService.androidDeviceInfo!;
        deviceInfoMap['platform'] = 'Android';
        deviceInfoMap['model'] = '${androidInfo.brand} ${androidInfo.model}';
        deviceInfoMap['osVersion'] = androidInfo.version.release;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/nfc/read'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nfcId': nfcId,
          'tagType': tagType,
          'timestamp': DateTime.now().toIso8601String(),
          'deviceInfo': deviceInfoMap,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('發送 NFC 數據失敗: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('發送 NFC 數據時發生錯誤: $e');
      return false;
    }
  }
}


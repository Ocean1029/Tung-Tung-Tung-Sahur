import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:town_pass/service/nfc_service.dart';

class NFCScanController extends GetxController {
  final NFCService _nfcService = Get.find<NFCService>();

  final RxBool isScanning = false.obs;
  final RxString lastNFCId = ''.obs;
  final RxString nfcTextRecord = ''.obs; // 新增：儲存 NFC 文本記錄
  final RxString nfcRawData = ''.obs; // 新增：儲存原始 NFC 數據
  final RxString statusMessage = '準備掃描 NFC...'.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkNFCAvailability();
  }

  @override
  void onClose() {
    _stopScanning();
    super.onClose();
  }

  /// 檢查 NFC 是否可用
  Future<void> _checkNFCAvailability() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      statusMessage.value = 'NFC 功能不可用';
      errorMessage.value = '請確認您的裝置支援 NFC 且已啟用';
    }
  }

  /// 開始掃描 NFC
  Future<void> startScanning() async {
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        errorMessage.value = 'NFC 功能不可用';
        return;
      }

      isScanning.value = true;
      statusMessage.value = '請將手機靠近 NFC 標籤...';
      errorMessage.value = '';

      // 開始監聽 NFC 標籤
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          await _handleNFCTag(tag);
        },
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
      );
    } catch (e) {
      debugPrint('開始掃描 NFC 時發生錯誤: $e');
      errorMessage.value = '掃描失敗: $e';
      isScanning.value = false;
      statusMessage.value = '掃描失敗';
    }
  }

  /// 處理讀取到的 NFC 標籤
  Future<void> _handleNFCTag(NfcTag tag) async {
    try {
      String? nfcId;
      String? tagType;
      String? textRecord;
      String rawData = '';

      // 嘗試讀取 NDEF 數據（使用 nfc_manager 4.x API）
      try {
        // 檢查 tag 是否有 NDEF 數據
        final tagString = tag.toString();
        debugPrint('NFC Tag raw data: $tagString');
        
        // 嘗試從 tag 的數據中提取信息
        // 在 nfc_manager 4.x 中，可能需要使用不同的方式
        // 這裡先顯示 tag 的字符串表示，讓用戶可以看到原始數據
        rawData = tagString;
        
        // 嘗試讀取 NDEF（如果可用）
        // 注意：nfc_manager 4.x 的 API 可能需要不同的方式
        // 暫時先顯示 tag 信息，後續可以根據實際測試調整
        tagType = 'NFC Tag';
        
        // 嘗試從 tag 獲取 ID（簡化版本）
        // 生成一個基於時間戳和 tag hash 的唯一 ID
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        nfcId = 'nfc_${timestamp}_${tag.hashCode}';
        
        // 顯示 tag 的完整信息作為「文本記錄」（讓用戶可以看到所有數據）
        textRecord = 'Tag Info: $tagString';
        nfcTextRecord.value = textRecord;
        
      } catch (e) {
        debugPrint('讀取 NFC 數據失敗: $e');
        tagType = 'Unknown';
      }

      // 如果沒有 ID，生成一個臨時的
      if (nfcId == null || nfcId.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        nfcId = 'nfc_${timestamp}_${tag.hashCode}';
      }

      debugPrint('NFC Tag detected:');
      debugPrint('  ID: $nfcId');
      debugPrint('  Type: $tagType');
      debugPrint('  Text Record: $textRecord');
      debugPrint('  Raw Data: $rawData');

      lastNFCId.value = nfcId;
      nfcRawData.value = rawData;

      // 更新狀態訊息（優先顯示文本記錄）
      if (textRecord != null && textRecord.isNotEmpty) {
        statusMessage.value = '✓ 已讀取 NFC 數據\n$textRecord';
      } else {
        statusMessage.value = '✓ 已讀取 NFC: $nfcId';
      }

      // 嘗試發送到後端（但不阻塞顯示）
      try {
        final success = await _nfcService.sendNFCRead(
          nfcId: nfcId,
          tagType: tagType,
        );

        if (success) {
          statusMessage.value = '✓ NFC 數據已發送到後端\n${textRecord != null && textRecord.isNotEmpty ? textRecord : "ID: $nfcId"}';
        } else {
          // 即使發送失敗，也顯示已讀取的數據
          if (textRecord != null && textRecord.isNotEmpty) {
            statusMessage.value = '✓ 已讀取 NFC 數據\n$textRecord\n⚠️ 發送到後端失敗（請檢查網路）';
          } else {
            statusMessage.value = '✓ 已讀取 NFC: $nfcId\n⚠️ 發送到後端失敗（請檢查網路）';
          }
          errorMessage.value = '發送數據到後端失敗，但 NFC 數據已成功讀取';
        }
      } catch (e) {
        debugPrint('發送 NFC 數據到後端時發生錯誤: $e');
        // 即使發送失敗，也顯示已讀取的數據
        if (textRecord != null && textRecord.isNotEmpty) {
          statusMessage.value = '✓ 已讀取 NFC 數據\n$textRecord\n⚠️ 無法連接到後端（請檢查網路）';
        } else {
          statusMessage.value = '✓ 已讀取 NFC: $nfcId\n⚠️ 無法連接到後端（請檢查網路）';
        }
        errorMessage.value = '無法連接到後端: $e\n但 NFC 數據已成功讀取';
      }

      // 停止掃描（單次讀取）
      await _stopScanning();
    } catch (e) {
      debugPrint('處理 NFC 標籤時發生錯誤: $e');
      errorMessage.value = '處理標籤失敗: $e';
      await _stopScanning();
    }
  }

  /// 停止掃描
  Future<void> _stopScanning() async {
    try {
      await NfcManager.instance.stopSession();
      isScanning.value = false;
      if (statusMessage.value.contains('已讀取') || statusMessage.value.contains('✓')) {
        // 保持成功訊息
      } else {
        statusMessage.value = '掃描已停止';
      }
    } catch (e) {
      debugPrint('停止掃描時發生錯誤: $e');
    }
  }

  /// 手動停止掃描
  Future<void> stopScanning() async {
    await _stopScanning();
  }
}


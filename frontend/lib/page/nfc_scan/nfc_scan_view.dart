import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/page/nfc_scan/nfc_scan_controller.dart';
import 'package:town_pass/util/tp_colors.dart';

class NFCScanView extends StatelessWidget {
  const NFCScanView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NFCScanController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC 掃描'),
      ),
      body: Obx(() => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // NFC 圖示
                Icon(
                  Icons.nfc,
                  size: 120,
                  color: controller.isScanning.value
                      ? TPColors.primary500
                      : TPColors.grayscale400,
                ),
                const SizedBox(height: 32),

                // 狀態訊息
                Text(
                  controller.statusMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // 錯誤訊息
                if (controller.errorMessage.value.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),

                // 顯示 NFC 數據
                if (controller.lastNFCId.value.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  
                  // NFC 文本記錄（優先顯示）
                  if (controller.nfcTextRecord.value.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.text_fields, 
                                size: 16, 
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'NFC 文本記錄:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.nfcTextRecord.value,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // NFC ID
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TPColors.grayscale50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TPColors.grayscale200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NFC ID:',
                          style: TextStyle(
                            fontSize: 12,
                            color: TPColors.grayscale600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.lastNFCId.value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // 掃描按鈕
                ElevatedButton(
                  onPressed: controller.isScanning.value
                      ? null
                      : () => controller.startScanning(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TPColors.primary500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: controller.isScanning.value
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('掃描中...'),
                          ],
                        )
                      : const Text(
                          '開始掃描 NFC',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                // 停止按鈕
                if (controller.isScanning.value) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => controller.stopScanning(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('停止掃描'),
                  ),
                ],
              ],
            ),
          )),
    );
  }
}


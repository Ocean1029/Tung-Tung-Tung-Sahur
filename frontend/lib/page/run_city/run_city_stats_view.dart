import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/page/run_city/run_city_stats_controller.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class RunCityStatsView extends GetView<RunCityStatsController> {
  const RunCityStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TPAppBar(title: '累積統計'),
      body: Obx(() {
        // 檢查用戶是否登入
        if (Get.find<AccountService>().account == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TPText(
                  '請先登入以使用此功能',
                  style: TPTextStyles.bodyRegular,
                  color: TPColors.grayscale600,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: const TPText('返回'),
                ),
              ],
            ),
          );
        }

        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.value != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TPText(
                  controller.errorMessage.value ?? '發生錯誤',
                  style: TPTextStyles.bodyRegular,
                  color: TPColors.red500,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refresh(),
                  child: const TPText('重試'),
                ),
              ],
            ),
          );
        }

        final userData = controller.userData.value;
        if (userData == null) {
          return const Center(
            child: TPText(
              '無資料',
              style: TPTextStyles.bodyRegular,
              color: TPColors.grayscale600,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 統計資料區塊
              _buildStatsSection(userData),
            ],
          ),
        );
      }),
    );
  }

  /// 建立統計資料區塊
  Widget _buildStatsSection(userData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TPColors.primary50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TPText(
            '累積統計',
            style: TPTextStyles.h3SemiBold,
            color: TPColors.grayscale900,
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            icon: Icons.monetization_on,
            label: '累積金幣',
            value: '${userData.totalCoins}',
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  /// 建立統計項目
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: isFullWidth
          ? Row(
              children: [
                Icon(icon, color: TPColors.primary500, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TPText(
                        label,
                        style: TPTextStyles.caption,
                        color: TPColors.grayscale600,
                      ),
                      const SizedBox(height: 4),
                      TPText(
                        value,
                        style: TPTextStyles.h3SemiBold,
                        color: TPColors.grayscale900,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: TPColors.primary500, size: 24),
                const SizedBox(height: 8),
                TPText(
                  label,
                  style: TPTextStyles.caption,
                  color: TPColors.grayscale600,
                ),
                const SizedBox(height: 4),
                TPText(
                  value,
                  style: TPTextStyles.h3SemiBold,
                  color: TPColors.grayscale900,
                ),
              ],
            ),
    );
  }
}


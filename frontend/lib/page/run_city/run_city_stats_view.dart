import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/page/run_city/run_city_stats_controller.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_cached_network_image.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class RunCityStatsView extends GetView<RunCityStatsController> {
  const RunCityStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TPAppBar(title: '個人資訊'),
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

        final profile = controller.userProfile.value;
        if (profile == null) {
          return const Center(
            child: TPText(
              '無資料',
              style: TPTextStyles.bodyRegular,
              color: TPColors.grayscale600,
            ),
          );
        }

        return Container(
          color: TPColors.runCityBackground,
          child: RefreshIndicator(
            onRefresh: () => controller.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 個人簡介區塊
                _buildUserProfileCard(
                  profile,
                  collectedBadges: controller.collectedBadges,
                  totalBadges: controller.totalBadges,
                ),
                const SizedBox(height: 16),
                // 徽章區塊（預留位置）
                _buildBadgeSection(),
                const SizedBox(height: 16),
                // 運動紀錄區塊
                _buildActivityRecordsSection(),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// 建立個人簡介區塊（無陰影）
  Widget _buildUserProfileCard(
    RunCityUserProfile profile, {
    required int collectedBadges,
    required int totalBadges,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頭貼（約70x70像素）
          if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
            ClipOval(
              child: TPCachedNetworkImage(
                imageUrl: profile.avatarUrl!,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                borderRadius: 0,
              ),
            )
          else
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: TPColors.grayscale200,
                shape: BoxShape.circle,
              ),
              child: Assets.svg.user.svg(),
            ),
          const SizedBox(width: 16),
          // 右側所有內容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 姓名（18-20pt）
                TPText(
                  profile.name,
                  style: TPTextStyles.titleSemiBold,
                  color: TPColors.grayscale900,
                ),
                const SizedBox(height: 8),
                // 金幣和徽章
                Row(
                  children: [
                    // 金幣（藍色點點，約10x10像素）
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: TPColors.runCityBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TPText(
                      'x ${profile.totalCoins}',
                      style: TPTextStyles.bodyRegular,
                      color: TPColors.grayscale900,
                    ),
                    const SizedBox(width: 16),
                    // 徽章（六角形，約10x10像素，暫時顯示 x 10）
                    Icon(
                      Icons.hexagon,
                      size: 10,
                      color: const Color(0xFF8B9A5B), // 橄欖綠色
                    ),
                    const SizedBox(width: 4),
                    TPText(
                      'x $collectedBadges/$totalBadges',
                      style: TPTextStyles.bodyRegular,
                      color: TPColors.grayscale900,
                    ),
                  ],
                ),
                // 分隔線
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: TPColors.grayscale200,
                  ),
                ),
                // 總時間和總距離
                Row(
                  children: [
                    Expanded(
                      child: _buildTotalStatItem(
                        icon: Icons.access_time,
                        label: '總時間',
                        value: controller.formattedTotalTime,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTotalStatItem(
                        icon: Icons.straighten,
                        label: '總距離',
                        value: profile.formattedTotalDistance,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建立總統計項目（灰字標籤 + 藍字數值）
  Widget _buildTotalStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: TPColors.runCityGray,
            ),
            const SizedBox(width: 4),
            TPText(
              label,
              style: TPTextStyles.caption,
              color: TPColors.runCityGray,
            ),
          ],
        ),
        const SizedBox(height: 6),
        TPText(
          value,
          style: TPTextStyles.h2SemiBold.copyWith(
            fontSize: 24,
          ),
          color: TPColors.runCityBlue,
        ),
      ],
    );
  }

  /// 建立徽章區塊（預留位置，未來實作）
  Widget _buildBadgeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const TPText(
            '我的徽章',
            style: TPTextStyles.h3SemiBold,
            color: TPColors.grayscale900,
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: TPColors.grayscale400,
          ),
        ],
      ),
    );
  }

  /// 建立運動紀錄區塊（表格格式）
  Widget _buildActivityRecordsSection() {
    return Obx(() {
      final activities = controller.activities;
      return Container(
        decoration: BoxDecoration(
          color: TPColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Padding(
              padding: const EdgeInsets.all(20),
              child: const TPText(
                '運動紀錄',
                style: TPTextStyles.h3SemiBold,
                color: TPColors.grayscale900,
              ),
            ),
            // 表格
            if (activities.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: TPText(
                    '尚無歷史紀錄',
                    style: TPTextStyles.bodyRegular,
                    color: TPColors.grayscale600,
                  ),
                ),
              )
              else
              Column(
                children: [
                  // 表頭
                  _buildTableHeader(),
                  // 資料列
                  ...activities.asMap().entries.map((entry) {
                    final index = entry.key;
                    final activity = entry.value;
                    final isLast = index == activities.length - 1;
                    return _buildTableRow(activity, isLast: isLast);
                  }),
                ],
              ),
          ],
        ),
      );
    });
  }

  /// 建立表格表頭
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TPColors.runCityTableHeader,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TPText(
              '日期',
              style: TPTextStyles.bodySemiBold,
              color: TPColors.grayscale900,
            ),
          ),
          Expanded(
            flex: 2,
            child: TPText(
              '時間',
              style: TPTextStyles.bodySemiBold,
              color: TPColors.grayscale900,
            ),
          ),
          Expanded(
            flex: 2,
            child: TPText(
              '距離',
              style: TPTextStyles.bodySemiBold,
              color: TPColors.grayscale900,
            ),
          ),
          Expanded(
            flex: 1,
            child: TPText(
              '金幣',
              style: TPTextStyles.bodySemiBold,
              color: TPColors.grayscale900,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立表格資料列
  Widget _buildTableRow(activity, {required bool isLast}) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final dateStr = dateFormat.format(activity.date);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: TPColors.grayscale200,
            width: isLast ? 0 : 1,
          ),
        ),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TPText(
                dateStr,
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale900,
              ),
            ),
            Expanded(
              flex: 2,
              child: TPText(
                activity.formattedTimeRange,
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale900,
              ),
            ),
            Expanded(
              flex: 2,
              child: TPText(
                activity.formattedDistance,
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale900,
              ),
            ),
            Expanded(
              flex: 1,
              child: TPText(
                '${activity.coinsEarned}',
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale900,
              ),
            ),
          ],
        ),
      ),
    );
  }

}


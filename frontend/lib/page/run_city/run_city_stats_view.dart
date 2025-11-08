import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/page/run_city/run_city_stats_controller.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_cached_network_image.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_route.dart';
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

        return Container(
          color: TPColors.runCityBackground,
          child: RefreshIndicator(
            onRefresh: () => controller.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 個人簡介區塊
                _buildUserProfileCard(userData),
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
  Widget _buildUserProfileCard(userData) {
    return Container(
      padding: const EdgeInsets.all(16), // 白色容器padding 16px
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(16), // 圓角16px
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一區：圖片、名字、金幣
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8), // avatar左側與白色方框相距24px (16px padding + 8px = 24px)，姓名與上方白框距離24px (16px padding + 8px = 24px)
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // 垂直置中
              children: [
                // 頭貼 64×64
                if (userData.avatarUrl != null && userData.avatarUrl!.isNotEmpty)
                  ClipOval(
                    child: TPCachedNetworkImage(
                      imageUrl: userData.avatarUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                    ),
                  )
                else
                  ClipOval(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: TPColors.grayscale200,
                        shape: BoxShape.circle,
                      ),
                      child: Assets.svg.logoIconTpe.svg(
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                // 右側：名字和金幣
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 姓名 16px
                      TPText(
                        userData.name,
                        style: TPTextStyles.titleSemiBold.copyWith(fontSize: 16),
                        color: TPColors.grayscale950,
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
                          // 金幣數字 14px
                          TPText(
                            'x ${userData.totalCoins}',
                            style: TPTextStyles.bodyRegular.copyWith(fontSize: 14),
                            color: TPColors.grayscale950,
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
                            'x 10',
                            style: TPTextStyles.bodyRegular.copyWith(fontSize: 14),
                            color: TPColors.grayscale950,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          // 第二區：總距離和總時間
          _buildTotalStatsRow(
            distanceValue: userData.formattedTotalDistance,
            timeValue: controller.formattedTotalTime,
          ),
        ],
      ),
    );
  }

  /// 建立總統計行（兩個統計項目，先顯示總距離，再顯示總時間）
  Widget _buildTotalStatsRow({
    required String timeValue,
    required String distanceValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8), // 白色容器邊框到icon為24px (16px padding + 8px = 24px)
      child: Row(
        children: [
          _buildTotalStatItem(
            icon: Icons.straighten,
            label: '距離',
            value: distanceValue,
            fontSize: 24, // 藍色字 24px
            iconSize: 20, // icon 20×20
            labelFontSize: 14, // 標題 14px
          ),
          const SizedBox(width: 8), // 文字到下一個icon是8px
          _buildTotalStatItem(
            icon: Icons.access_time,
            label: '時間',
            value: timeValue,
            fontSize: 24, // 藍色字 24px
            iconSize: 20, // icon 20×20
            labelFontSize: 14, // 標題 14px
          ),
        ],
      ),
    );
  }

  /// 建立總統計項目（icon 在左，標題和數值在右）
  Widget _buildTotalStatItem({
    required IconData icon,
    required String label,
    required String value,
    required double fontSize,
    required double iconSize,
    required double labelFontSize,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon 在左側 20×20
        Icon(
          icon,
          size: iconSize,
          color: TPColors.runCityGray,
        ),
        const SizedBox(width: 8), // icon到文字是8px
        // 標題和數值在右側（垂直排列）
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題（灰字）14px
            TPText(
              label,
              style: TPTextStyles.h3Regular.copyWith(fontSize: labelFontSize),
              color: TPColors.runCityGray,
            ),
            const SizedBox(height: 4),
            // 數值（藍字，大且粗，不換行）24px
            TPText(
              value,
              style: TPTextStyles.h2SemiBold.copyWith(
                fontSize: fontSize,
              ),
              color: TPColors.runCityBlue,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ],
        ),
      ],
    );
  }

  /// 建立徽章區塊（預留位置，未來實作）
  Widget _buildBadgeSection() {
    return Container(
      padding: const EdgeInsets.all(16), // 白色容器padding 16px
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(16), // 圓角16px
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8), // 與左邊的白色方匡距離為24px (16px padding + 8px = 24px)
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TPText(
              '我的徽章',
              style: TPTextStyles.h3SemiBold.copyWith(fontSize: 14), // 14px
              color: TPColors.grayscale400,
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: TPColors.grayscale400,
            ),
          ],
        ),
      ),
    );
  }

  /// 建立運動紀錄區塊（表格格式）
  Widget _buildActivityRecordsSection() {
    return Obx(() {
      final activities = controller.activities;
      return Container(
        padding: const EdgeInsets.all(16), // 白色容器padding 16px
        decoration: BoxDecoration(
          color: TPColors.white,
          borderRadius: BorderRadius.circular(16), // 圓角16px
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題 14px，與下方表格12px間距，與左邊的白色方匡距離為24px
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12), // 與左邊的白色方匡距離為24px (16px padding + 8px = 24px)，與下方表格12px
              child: TPText(
                '運動紀錄',
                style: TPTextStyles.h3SemiBold.copyWith(fontSize: 14), // 14px
                color: TPColors.grayscale400,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0), // 表格與左側白匡為16px（使用容器的padding）
                child: Column(
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
          topLeft: Radius.circular(16), // 圓角16px
          topRight: Radius.circular(16), // 圓角16px
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TPText(
              '日期',
              style: TPTextStyles.caption,
              color: TPColors.grayscale400,
            ),
          ),
          Expanded(
            flex: 2,
            child: TPText(
              '時間',
              style: TPTextStyles.caption,
              color: TPColors.grayscale400,
            ),
          ),
          Expanded(
            flex: 2,
            child: TPText(
              '距離',
              style: TPTextStyles.caption,
              color: TPColors.grayscale400,
            ),
          ),
          Expanded(
            flex: 1,
            child: TPText(
              '金幣',
              style: TPTextStyles.caption,
              color: TPColors.grayscale400,
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
    final accountService = Get.find<AccountService>();
    final userId = accountService.account?.id ?? '';

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          TPRoute.runCityActivityDetail,
          arguments: {
            'activityId': activity.activityId,
            'userId': userId,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null // 最後一行不要有橫線
              : Border(
                  bottom: BorderSide(
                    color: TPColors.grayscale200,
                    width: 1,
                  ),
                ),
          borderRadius: isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(16), // 圓角16px
                  bottomRight: Radius.circular(16), // 圓角16px
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
                  style: TPTextStyles.bodyRegular.copyWith(fontSize: 12),
                  color: TPColors.grayscale950,
                ),
              ),
              Expanded(
                flex: 2,
                child: TPText(
                  activity.formattedTimeRange,
                  style: TPTextStyles.bodyRegular.copyWith(fontSize: 12),
                  color: TPColors.grayscale950,
                ),
              ),
              Expanded(
                flex: 2,
                child: TPText(
                  activity.formattedDistance,
                  style: TPTextStyles.bodyRegular.copyWith(fontSize: 12),
                  color: TPColors.grayscale950,
                ),
              ),
              Expanded(
                flex: 1,
                child: TPText(
                  '${activity.coinsEarned}',
                  style: TPTextStyles.bodyRegular.copyWith(fontSize: 12),
                  color: TPColors.grayscale950,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}


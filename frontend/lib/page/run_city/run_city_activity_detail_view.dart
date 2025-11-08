import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/page/run_city/run_city_activity_detail_controller.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_cached_network_image.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class RunCityActivityDetailView extends GetView<RunCityActivityDetailController> {
  const RunCityActivityDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TPAppBar(title: '運動紀錄'),
      body: Obx(() {
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

        final detail = controller.activityDetail.value;
        if (detail == null) {
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
                // 統一的白色背景容器，包含所有區塊
                Container(
                  decoration: BoxDecoration(
                    color: TPColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16), // 白色容器padding 16px
                  child: Column(
                    children: [
                      // 活動摘要區塊（姓名、日期時間、距離時間）
                      _buildActivitySummarySection(detail),
                      // 地圖區塊
                      _buildMapSection(detail),
                      // 點位紀錄區塊
                      _buildLocationRecordsSection(detail),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// 建立活動摘要區塊（姓名、日期時間、距離時間）
  Widget _buildActivitySummarySection(detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 用戶資訊
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 8), // avatar左側與白色方框相距24px (16px padding + 8px = 24px)，姓名與上方白框距離24px (16px padding + 8px = 24px)
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 垂直置中
            children: [
              // 頭像 64×64
              if (detail.userAvatar != null && detail.userAvatar!.isNotEmpty)
                ClipOval(
                  child: TPCachedNetworkImage(
                    imageUrl: detail.userAvatar!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    borderRadius: 0,
                  ),
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: TPColors.grayscale200,
                    shape: BoxShape.circle,
                  ),
                  child: Assets.svg.user.svg(),
                ),
              const SizedBox(width: 16),
              // 姓名和日期時間
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 姓名 16px
                    TPText(
                      detail.userName,
                      style: TPTextStyles.titleSemiBold.copyWith(fontSize: 16),
                      color: TPColors.grayscale950,
                    ),
                    const SizedBox(height: 8),
                    // 日期時間 14px
                    TPText(
                      detail.formattedDateTimeRange,
                      style: TPTextStyles.bodyRegular.copyWith(fontSize: 14),
                      color: TPColors.grayscale950,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 距離和時間統計
        _buildTotalStatsRow(
          distanceValue: detail.formattedDistance,
          timeValue: detail.formattedDuration,
        ),
      ],
    );
  }

  /// 建立總統計行（兩個統計項目，統一縮放）
  Widget _buildTotalStatsRow({
    required String distanceValue,
    required String timeValue,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: Padding(
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
        ),
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

  /// 建立地圖區塊
  Widget _buildMapSection(detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16), // 地圖與上下的文字距離16px
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: TPColors.grayscale200,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Obx(() {
            return GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(25.0330, 121.5654),
                zoom: 15,
              ),
              onMapCreated: controller.onMapCreated,
              markers: controller.markers.toSet(),
              polylines: controller.polylines.toSet(),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            );
          }),
        ),
      ),
    );
  }

  /// 建立點位紀錄區塊
  Widget _buildLocationRecordsSection(detail) {
    final records = detail.locationRecords;
    // 按照 collectedAt 時間排序（最早的在最上面）
    final sortedRecords = List<RunCityActivityLocationRecord>.from(records)
      ..sort((a, b) => a.collectedAt.compareTo(b.collectedAt));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題 14px，與下方表格12px間距
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12), // 「點位紀錄」左側與白色方框相距24px (16px padding + 8px = 24px)，與下方表格12px
          child: TPText(
            '點位紀錄',
            style: TPTextStyles.h3SemiBold.copyWith(fontSize: 14), // 字體大小14px
            color: TPColors.grayscale400, // #91A0A8
          ),
        ),
        // 表格
        if (sortedRecords.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: TPText(
                '尚無點位紀錄',
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale600,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0), // 表格使用白色容器的padding
            child: Column(
              children: [
                // 表頭
                _buildLocationTableHeader(),
                // 資料列（從最早到最晚）
                ...sortedRecords.asMap().entries.map((entry) {
                  final index = entry.key;
                  final record = entry.value;
                  final isLast = index == sortedRecords.length - 1;
                  return _buildLocationTableRow(record, isLast: isLast);
                }),
              ],
            ),
          ),
        // 底部 padding
        const SizedBox(height: 16),
      ],
    );
  }

  /// 建立點位紀錄表格表頭
  Widget _buildLocationTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: TPColors.runCityTableHeader,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TPText(
              '點位名稱',
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
              '位置',
              style: TPTextStyles.caption,
              color: TPColors.grayscale400,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立點位紀錄表格資料列
  Widget _buildLocationTableRow(record, {required bool isLast}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null // 最後一列不需要底部邊框
            : Border(
                bottom: BorderSide(
                  color: TPColors.grayscale200,
                  width: 1,
                ),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TPText(
                record.locationName,
                style: TPTextStyles.bodyRegular.copyWith(fontSize: 12),
                color: TPColors.grayscale950,
              ),
            ),
            Expanded(
              flex: 2,
              child: TPText(
                record.formattedTime,
                style: TPTextStyles.bodyRegular.copyWith(fontSize: 12),
                color: TPColors.grayscale950,
              ),
            ),
            Expanded(
              flex: 2,
              child: TPText(
                record.formattedLocation,
                style: TPTextStyles.bodyRegular.copyWith(fontSize: 12),
                color: TPColors.grayscale950,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


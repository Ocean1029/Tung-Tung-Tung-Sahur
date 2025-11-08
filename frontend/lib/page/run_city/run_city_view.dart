import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/page/run_city/run_city_controller.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_cached_network_image.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_route.dart';
import 'package:town_pass/util/tp_text.dart';

class RunCityView extends GetView<RunCityController> {
  const RunCityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TPAppBar(title: '跑城市'),
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

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: RunCityController.initialCameraPosition,
              markers: controller.markers.toSet(),
              polylines: controller.polylines.toSet(),
              onMapCreated: controller.onMapCreated,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              },
            ),
            // 用戶資料卡片（可點擊，覆蓋在地圖上方）
            if (controller.userData.value != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    Get.toNamed(TPRoute.runCityStats);
                  },
                  child: _buildUserProfileCard(controller.userData.value!),
                ),
              ),
            
            // 本次跑步紀錄卡片（如果有路線）
            if (!controller.isTracking.value && controller.routePath.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 140,
                child: _buildSummaryCard(
                  distanceMeters: controller.totalDistanceMeters.value,
                  elapsed: controller.elapsed.value,
                  averageSpeedKmh: controller.averageSpeedKmh.value,
                  visitedCount: controller.visitedPointIds.length,
                ),
              ),
            // 追蹤控制按鈕
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: _buildTrackingControls(),
            ),
          ],
        );
      }),
    );
  }

  /// 建立用戶資料卡片
  Widget _buildUserProfileCard(userData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: TPColors.grayscale200.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 頭貼
          if (userData.avatarUrl != null && userData.avatarUrl!.isNotEmpty)
            ClipOval(
              child: TPCachedNetworkImage(
                imageUrl: userData.avatarUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                borderRadius: 0, // ClipOval 會處理圓形，不需要 borderRadius
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: TPColors.grayscale200,
                shape: BoxShape.circle,
              ),
              child: Assets.svg.user.svg(),
            ),
          const SizedBox(width: 16),
          // 用戶資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TPText(
                  userData.name,
                  style: TPTextStyles.h2SemiBold,
                  color: TPColors.grayscale900,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 20,
                      color: TPColors.primary500,
                    ),
                    const SizedBox(width: 4),
                    TPText(
                      'x ${userData.totalCoins}',
                      style: TPTextStyles.h3SemiBold,
                      color: TPColors.grayscale900,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 右側箭頭指示可點擊
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: TPColors.grayscale400,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard({
    required int collectedCount,
    required int totalCount,
  }) {
    final remainingCount = totalCount - collectedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: TPColors.grayscale900.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TPText(
            'NFC 跑點進度',
            style: TPTextStyles.h3SemiBold,
            color: TPColors.grayscale900,
          ),
          const SizedBox(height: 8),
          TPText(
            '已收集 $collectedCount / $totalCount 個點位 · 剩餘 $remainingCount 個',
            style: TPTextStyles.bodyRegular,
            color: TPColors.grayscale600,
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              _LegendIndicator(
                color: TPColors.primary500,
                label: '已收集',
              ),
              SizedBox(width: 16),
              _LegendIndicator(
                color: TPColors.orange500,
                label: '未收集',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingControls() {
    return Center(
      child: Obx(() {
        final isTracking = controller.isTracking.value;
        return GestureDetector(
          onTap: () {
            if (isTracking) {
              controller.stopTracking();
            } else {
              controller.startTracking();
            }
          },
          child: Container(
            width: isTracking ? 96 : 88,
            height: isTracking ? 96 : 88,
            decoration: BoxDecoration(
              color: isTracking ? TPColors.red400 : TPColors.primary500,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: TPText(
              isTracking ? '結束' : 'GO',
              style: TPTextStyles.h2SemiBold,
              color: TPColors.white,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard({
    required double distanceMeters,
    required Duration elapsed,
    required double averageSpeedKmh,
    required int visitedCount,
  }) {
    final distanceKm = distanceMeters / 1000;
    final formattedDistance = distanceKm >= 1
        ? '${distanceKm.toStringAsFixed(2)} km'
        : '${distanceMeters.toStringAsFixed(0)} m';
    final formattedDuration = _formatDuration(elapsed);
    final formattedSpeed = averageSpeedKmh.isNaN
        ? '0 km/h'
        : '${averageSpeedKmh.toStringAsFixed(1)} km/h';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TPText(
                      '本次跑步紀錄',
                      style: TPTextStyles.h3SemiBold,
                      color: TPColors.grayscale900,
                    ),
                    const SizedBox(height: 4),
                    TPText(
                      '經過 $visitedCount 個點位',
                      style: TPTextStyles.bodyRegular,
                      color: TPColors.grayscale600,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: TPColors.grayscale400),
                onPressed: controller.clearRoute,
                tooltip: '清除紀錄',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                label: '距離',
                value: formattedDistance,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: '時間',
                value: formattedDuration,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: '平均速度',
                value: formattedSpeed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _LegendIndicator extends StatelessWidget {
  const _LegendIndicator({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        TPText(
          label,
          style: TPTextStyles.bodyRegular,
          color: TPColors.grayscale700,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: TPColors.primary50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TPText(
              label,
              style: TPTextStyles.caption,
              color: TPColors.grayscale500,
            ),
            const SizedBox(height: 6),
            TPText(
              value,
              style: TPTextStyles.h3SemiBold,
              color: TPColors.grayscale900,
            ),
          ],
        ),
      ),
    );
  }
}

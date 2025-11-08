import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/page/run_city/run_city_controller.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_cached_network_image.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_route.dart';
import 'package:town_pass/util/tp_text.dart';

const _badgeCompletedColor = Color(0xFF76A732);
const _badgeBaseColor = Color(0xFF76A732);
const double _badgeCloseButtonSize = 26;

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
              onCameraMove: controller.onCameraMove,
              onCameraIdle: controller.onCameraIdle,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
            ),
            // 用戶資料卡片（可點擊，覆蓋在地圖上方）
            if (controller.userProfile.value != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    Get.toNamed(TPRoute.runCityStats);
                  },
                  child: _buildUserProfileCard(controller.userProfile.value!),
                ),
              ),
            Obx(() {
              if (!controller.isBadgePanelVisible.value) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: controller.closeBadgePanel,
                  child: const SizedBox.shrink(),
                ),
              );
            }),
            Obx(() {
              if (!controller.isBadgePanelVisible.value) {
                return const SizedBox.shrink();
              }
              return Positioned(
                left: 16,
                right: 16,
                bottom: 120,
                child: _buildBadgePanel(context),
              );
            }),
            // 本次跑步紀錄卡片（如果有路線）
            if (!controller.isTracking.value && controller.routePath.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 360,
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
            Positioned(
              right: 32,
              bottom: 40,
              child: _buildBadgeToggleButton(),
            ),
          ],
        );
      }),
    );
  }

  /// 建立用戶資料卡片
  Widget _buildUserProfileCard(userData) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24), // 上下12px，左右24px
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // 陰影顏色
            offset: const Offset(0, 4), // X:0, Y:4
            blurRadius: 4, // blur:4
            spreadRadius: 0, // Spread:0
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 垂直置中
        children: [
          // 頭貼 64×64，與白框左側距離24px（使用padding），上下距離12px（使用padding）
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
          const SizedBox(width: 16), // 圖片與右側文字距離16px
          // 用戶資訊（垂直置中）
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 名字 16px
                TPText(
                  userData.name,
                  style: TPTextStyles.titleSemiBold.copyWith(fontSize: 16),
                  color: TPColors.grayscale950,
                ),
                const SizedBox(height: 8), // 名字與金幣資訊之間間距8px
                // 金幣資訊
                Row(
                  children: [
                    // Icon 20×20
                    Icon(
                      Icons.monetization_on,
                      size: 20,
                      color: TPColors.runCityBlue,
                    ),
                    const SizedBox(width: 8), // icon與文字之間8px
                    // 金幣數量數字 14px
                    TPText(
                      'x ${userData.totalCoins}',
                      style: TPTextStyles.bodyRegular.copyWith(fontSize: 14),
                      color: TPColors.grayscale950,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 右側箭頭指示可點擊，與白框右側間距24px（使用padding）
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: TPColors.grayscale400,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgePanel(BuildContext context) {
    return Obx(() {
      final badges = controller.sortedBadges;
      final selected = controller.selectedBadge.value;

      if (badges.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: TPColors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: TPColors.grayscale300.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: _badgeCloseButtonSize + 14),
                _BadgeArrowButton(
                  icon: Icons.chevron_left,
                  isEnabled: controller.canPageBadgesLeft,
                  onTap: controller.pageBadgesLeft,
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(RunCityController.badgesPerPage, (i) {
                  final badge = controller.currentBadgeSlots.length > i
                      ? controller.currentBadgeSlots[i]
                      : null;
                  final isSelected = badge != null && selected?.id == badge.id;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: i == 1 ? 12 : 6,
                      ),
                      child: badge != null
                          ? _BadgePreview(
                              badge: badge,
                              isSelected: isSelected,
                              onTap: () => controller.selectBadge(badge),
                            )
                          : const _BadgePlaceholder(),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: _badgeCloseButtonSize + 14),
                _BadgeArrowButton(
                  icon: Icons.chevron_right,
                  isEnabled: controller.canPageBadgesRight,
                  onTap: controller.pageBadgesRight,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTrackingControls() {
    return Obx(() {
      final isTracking = controller.isTracking.value;
      final goButtonWidth = isTracking ? 96.0 : 88.0;
      final positionButtonWidth = 54.0;
      final spacing = 50.0;
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左側空白，用於平衡布局
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 位置按鈕（位於 GO 按鈕左側 50px 處）
                Obx(() => GestureDetector(
                  onTap: () {
                    controller.centerToUserLocation();
                  },
                  child: Container(
                    width: positionButtonWidth,
                    height: positionButtonWidth,
                    decoration: BoxDecoration(
                      color: TPColors.white,
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
                    child: SvgPicture.asset(
                      'assets/svg/position.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        controller.isUserLocationCentered.value
                            ? const Color(0xFF5AB4C5) // 居中時為藍色
                            : const Color(0xFF475259), // 未居中時為灰色
                        BlendMode.srcIn,
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                )),
                SizedBox(width: spacing), // GO 按鈕左邊距離 50px
              ],
            ),
          ),
          // GO 按鈕（位於螢幕水平正中）
          GestureDetector(
            onTap: () {
              if (isTracking) {
                controller.stopTracking();
              } else {
                controller.startTracking();
              }
            },
            child: Container(
              width: goButtonWidth,
              height: goButtonWidth,
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
          ),
          // 右側空白，用於平衡布局
          Expanded(
            child: Container(),
          ),
        ],
      );
    });
  }

  Widget _buildBadgeToggleButton() {
    return Obx(() {
      final hasBadges = controller.badges.isNotEmpty;
      final backgroundColor = TPColors.white;

      return Opacity(
        opacity: hasBadges ? 1 : 0.4,
        child: GestureDetector(
          onTap: hasBadges ? controller.toggleBadgePanel : null,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset(
                'assets/svg/badge_icon.svg',
                colorFilter: const ColorFilter.mode(
                  _badgeBaseColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      );
    });
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

class _BadgePreview extends StatelessWidget {
  const _BadgePreview({
    required this.badge,
    required this.isSelected,
    required this.onTap,
  });

  final RunCityBadge badge;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final collectedCount = badge.collectedPoints;
    final totalCount = badge.totalPoints;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: _badgeCompletedColor,
                      width: 3,
                    )
                  : null,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/svg/badge_icon.svg',
                width: 40,
                height: 40,
                colorFilter: const ColorFilter.mode(
                  _badgeCompletedColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 66,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                TPText(
                  badge.name,
                  style: TPTextStyles.caption,
                  color: isSelected
                      ? const Color(0xFF5AB4C5)
                      : TPColors.grayscale900,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: TPColors.grayscale200, width: 1),
                  ),
                  child: TPText.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: collectedCount.toString(),
                          style: const TextStyle(color: TPColors.primary500),
                        ),
                        TextSpan(
                          text: '/$totalCount',
                          style: const TextStyle(color: TPColors.grayscale400),
                        ),
                      ],
                      style: TPTextStyles.caption,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeArrowButton extends StatelessWidget {
  const _BadgeArrowButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 22,
            color: isEnabled ? TPColors.grayscale500 : TPColors.grayscale300,
          ),
        ),
      ),
    );
  }
}

class _BadgePlaceholder extends StatelessWidget {
  const _BadgePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.25,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TPColors.grayscale100,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: TPColors.grayscale100,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 44,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: TPColors.grayscale200, width: 1),
            ),
          ),
        ],
      ),
    );
  }
}

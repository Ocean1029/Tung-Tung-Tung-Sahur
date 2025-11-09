import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/page/run_city/run_city_badge_detail_controller.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class RunCityBadgeDetailView extends GetView<RunCityBadgeDetailController> {
  const RunCityBadgeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TPAppBar(title: 'Run City'),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value != null) {
          return Center(child: Text(controller.errorMessage.value ?? ''));
        }
        if (controller.badgeLocations.isEmpty) {
          return _buildEmptyState();
        }
        return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TPColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BadgeHeader(controller: controller),
                    const SizedBox(height: 16),
                    _BadgeMap(controller: controller),
                    const SizedBox(height: 16),
                    _BadgeLocationsTable(controller: controller),
                  ],
                ),
              ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TPText(
            '此徽章尚無點位資料',
            style: TPTextStyles.bodyRegular,
            color: TPColors.grayscale500,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: Get.back,
            child: const TPText('返回'),
          )
        ],
      ),
    );
  }
}

class _BadgeHeader extends StatelessWidget {
  const _BadgeHeader({required this.controller});

  final RunCityBadgeDetailController controller;

  @override
  Widget build(BuildContext context) {
    final badge = controller.badge;
    if (badge == null) {
      return const SizedBox.shrink();
    }
    final collected = controller.collectedLocations.length;
    final total = badge.totalPoints;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Assets.svg.badgeIcon.svg(
          width: 60,
          height: 60,
          colorFilter: ColorFilter.mode(
            badge.badgeColor ?? const Color(0xFF76A732),
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TPText(
                      badge.name,
                      style: TPTextStyles.h3SemiBold,
                      color: TPColors.grayscale900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _BadgeProgressChip(collected: collected, total: total),
                ],
              ),
              const SizedBox(height: 4),
              TPText(
                controller.badgeDescription,
                style: TPTextStyles.bodyRegular,
                color: TPColors.grayscale500,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: controller.shareBadge,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: TPColors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.ios_share, color: TPColors.primary500),
          ),
        ),
      ],
    );
  }
}

class _BadgeMap extends StatelessWidget {
  const _BadgeMap({required this.controller});

  final RunCityBadgeDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GetBuilder<RunCityBadgeDetailController>(
          id: 'badgeMap',
          builder: (ctrl) {
            return Container(
              height: 220,
              decoration: BoxDecoration(
                color: TPColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: GoogleMap(
                initialCameraPosition: ctrl.initialCameraPosition,
                markers: ctrl.markers,
                circles: ctrl.circles,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
                polylines: const <Polyline>{},
                onMapCreated: ctrl.onMapCreated,
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TPText(
                '點位資訊',
                style: TPTextStyles.caption.copyWith(fontSize: 14),
                color: TPColors.grayscale500,
              ),
              TPText(
                '點按可顯示詳細位置',
                style: TPTextStyles.caption.copyWith(fontSize: 14),
                color: TPColors.grayscale400,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _BadgeLocationsTable extends StatelessWidget {
  const _BadgeLocationsTable({required this.controller});

  final RunCityBadgeDetailController controller;

  @override
  Widget build(BuildContext context) {
    final locations = controller.badgeLocations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: TPColors.grayscale100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: TPText(
                    '點位名稱',
                    style: TPTextStyles.caption,
                    color: TPColors.grayscale500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: TPText(
                  '狀態',
                  style: TPTextStyles.caption,
                  color: TPColors.grayscale500,
                ),
              ),
              SizedBox(width: 24),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...locations.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final location = entry.value;
            final isLast = index == locations.length - 1;
            return _LocationRow(
              location: location,
              isCollected: location.isCollected,
              onTap: () => controller.focusOnLocation(location),
              showDivider: !isLast,
            );
          },
        ),
      ],
    );
  }
}

class _LocationRow extends StatefulWidget {
  const _LocationRow({
    required this.location,
    required this.isCollected,
    required this.onTap,
    required this.showDivider,
  });

  final RunCityBadgeLocation location;
  final bool isCollected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  State<_LocationRow> createState() => _LocationRowState();
}

class _LocationRowState extends State<_LocationRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final statusText = widget.isCollected ? '已完成' : '待收集';
    final statusBackground =
        widget.isCollected ? const Color(0xFFDBF1F5) : const Color(0xFF5AB4C5);

    return Column(
      children: [
        Container(
          decoration: widget.showDivider
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: TPColors.grayscale200, width: 1),
                  ),
                )
              : null,
          child: InkWell(
            onTap: () {
              widget.onTap();
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: TPText(
                            widget.location.name,
                            style:
                                TPTextStyles.bodyRegular.copyWith(fontSize: 13),
                            color: TPColors.grayscale900,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TPText(
                              statusText,
                              style: TPTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: TPColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: TPColors.grayscale400,
                      ),
                    ],
                  ),
                  if (_expanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TPText(
                          widget.location.nfcId ?? '未指定',
                          style: TPTextStyles.bodyRegular.copyWith(
                            fontSize: 12,
                            color: TPColors.grayscale500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeProgressChip extends StatelessWidget {
  const _BadgeProgressChip({
    required this.collected,
    required this.total,
  });

  final int collected;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB7CBD4), width: 1),
      ),
      child: TPText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$collected',
              style: const TextStyle(color: Color(0xFF5AB4C5)),
            ),
            const TextSpan(
              text: '/',
              style: TextStyle(color: Color(0xFF91A0A8)),
            ),
            TextSpan(
              text: '$total',
              style: const TextStyle(color: Color(0xFF91A0A8)),
            ),
          ],
          style: TPTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

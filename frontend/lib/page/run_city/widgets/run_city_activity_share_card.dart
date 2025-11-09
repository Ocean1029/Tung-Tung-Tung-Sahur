import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class RunCityActivityShareCard extends StatelessWidget {
  const RunCityActivityShareCard({
    super.key,
    required this.userName,
    required this.dateTimeRange,
    required this.distanceText,
    required this.durationText,
    required this.coinsText,
    this.mapSnapshot,
  });

  final String userName;
  final String dateTimeRange;
  final String distanceText;
  final String durationText;
  final String coinsText;
  final Uint8List? mapSnapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 393,
      height: 753,
      decoration: BoxDecoration(
        color: TPColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              top: -48,
              bottom: 96,
              child: _buildMapBackground(),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _buildBrandBadge(
                child: SvgPicture.asset(
                  'assets/svg/logo_townpass.svg',
                  width: 92,
                  height: 49,
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: _buildBrandBadge(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/svg/run_city_logo.svg',
                      width: 48,
                      height: 32,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        TPText(
                          'RUN',
                          style: TPTextStyles.bodySemiBold,
                          color: TPColors.grayscale700,
                        ),
                        SizedBox(height: 2),
                        TPText(
                          'CITY',
                          style: TPTextStyles.bodySemiBold,
                          color: TPColors.grayscale700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              left: 14,
              right: 14,
              child: _buildUserRecordCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBackground() {
    if (mapSnapshot == null || mapSnapshot!.isEmpty) {
      return Container(color: TPColors.runCityBackground);
    }
    return Image.memory(
      mapSnapshot!,
      fit: BoxFit.cover,
    );
  }

  Widget _buildBrandBadge({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildUserRecordCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: TPColors.grayscale200,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: TPText(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'R',
                  style: TPTextStyles.h2SemiBold.copyWith(fontSize: 20),
                  color: TPColors.grayscale500,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TPText(
                      userName,
                      style: TPTextStyles.h3SemiBold.copyWith(fontSize: 15),
                      color: TPColors.grayscale900,
                    ),
                    const SizedBox(height: 6),
                    TPText(
                      dateTimeRange,
                      style: TPTextStyles.bodySemiBold.copyWith(fontSize: 13),
                      color: TPColors.grayscale600,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.straighten,
                label: '距離',
                value: distanceText,
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.access_time,
                label: '時間',
                value: durationText,
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.emoji_events,
                label: '金幣',
                value: coinsText,
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: TPColors.runCityGray),
              const SizedBox(width: 6),
              TPText(
                label,
                style: TPTextStyles.bodySemiBold.copyWith(fontSize: 12),
                color: TPColors.runCityGray,
              ),
            ],
          ),
          const SizedBox(height: 4),
          TPText(
            value,
            style: TPTextStyles.h2SemiBold.copyWith(fontSize: 20),
            color: TPColors.runCityBlue,
          ),
        ],
      ),
    );
  }
}

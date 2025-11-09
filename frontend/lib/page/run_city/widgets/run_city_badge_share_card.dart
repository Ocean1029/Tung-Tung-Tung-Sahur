import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:town_pass/gen/fonts.gen.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class RunCityBadgeShareCard extends StatelessWidget {
  const RunCityBadgeShareCard({
    super.key,
    required this.badgeName,
    required this.badgeDescription,
    required this.collectedPoints,
    required this.totalPoints,
    required this.userName,
    required this.completedAt,
    this.badgeColor = TPColors.orange500,
  });

  final String badgeName;
  final String badgeDescription;
  final int collectedPoints;
  final int totalPoints;
  final String userName;
  final DateTime completedAt;
  final Color badgeColor;

  String get _formattedDate => DateFormat('yyyy/MM/dd').format(completedAt);

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
              child: Container(color: TPColors.runCityBackground),
            ),
            Positioned.fill(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildBadgeInfo(),
                    const SizedBox(height: 40),
                    _buildStatsCard(),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/svg/logo_townpass.svg',
          width: 92,
          height: 49,
        ),
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: TPColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TPColors.grayscale200, width: 1.5),
              ),
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(
                'assets/svg/run_city_logo.svg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'RUN\nCITY',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: FontFamily.pingFangTC,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: TPColors.grayscale700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadgeInfo() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 288,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment.topCenter,
            radius: 1.1,
            colors: [
              TPColors.runCityBackground,
              TPColors.white,
            ],
            stops: [0.2, 1],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BadgeIcon(color: badgeColor),
            const SizedBox(height: 24),
            TPText(
              badgeName,
              style: TPTextStyles.h2SemiBold,
              color: TPColors.grayscale950,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TPText(
              badgeDescription,
              style: TPTextStyles.bodySemiBold,
              color: TPColors.grayscale400,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 288,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: TPColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TPText(
              _formattedDate,
              style: TPTextStyles.bodySemiBold,
              color: TPColors.grayscale400,
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TPText(
                  userName,
                  style: TPTextStyles.bodySemiBold,
                  color: TPColors.grayscale950,
                ),
                const Spacer(),
                TPText.rich(
                  TextSpan(
                    style: TPTextStyles.h3SemiBold.copyWith(
                      fontSize: 18,
                      color: TPColors.grayscale700,
                    ),
                    children: [
                      const TextSpan(text: '收集了 '),
                      TextSpan(
                        text: '$collectedPoints',
                        style: TPTextStyles.h2SemiBold.copyWith(
                          fontSize: 20,
                          color: TPColors.primary500,
                        ),
                      ),
                      const TextSpan(text: ' 個點位'),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Align(
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/svg/badge_icon.svg',
          width: 72,
          height: 72,
          colorFilter: ColorFilter.mode(
            color,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

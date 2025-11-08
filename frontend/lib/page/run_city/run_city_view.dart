import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/page/run_city/run_city_controller.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_text.dart';

class RunCityView extends GetView<RunCityController> {
  const RunCityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TPAppBar(title: '跑城市'),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 歡迎區塊
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: TPColors.primary50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TPText(
                    '探索城市跑步路線',
                    style: TPTextStyles.h2SemiBold,
                    color: TPColors.grayscale900,
                  ),
                  SizedBox(height: 8),
                  TPText(
                    '發現台北市最適合跑步的路線與活動',
                    style: TPTextStyles.bodyRegular,
                    color: TPColors.grayscale700,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 功能區塊
            const TPText(
              '功能',
              style: TPTextStyles.h3SemiBold,
              color: TPColors.grayscale900,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              title: '跑步路線',
              description: '查看推薦的跑步路線',
              onTap: () {
                // TODO: 導航到路線頁面
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              title: '活動資訊',
              description: '查看城市跑步活動',
              onTap: () {
                // TODO: 導航到活動頁面
              },
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              title: '記錄跑步',
              description: '記錄您的跑步記錄',
              onTap: () {
                // TODO: 導航到記錄頁面
              },
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TPColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: TPColors.grayscale200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TPText(
                    title,
                    style: TPTextStyles.h3SemiBold,
                    color: TPColors.grayscale900,
                  ),
                  const SizedBox(height: 4),
                  TPText(
                    description,
                    style: TPTextStyles.bodyRegular,
                    color: TPColors.grayscale600,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: TPColors.grayscale400,
            ),
          ],
        ),
      ),
    );
  }
}


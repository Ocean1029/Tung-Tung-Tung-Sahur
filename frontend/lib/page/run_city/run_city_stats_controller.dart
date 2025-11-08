import 'package:get/get.dart';
import 'package:town_pass/bean/run_city.dart';
import 'package:town_pass/page/run_city/run_city_api_service.dart';
import 'package:town_pass/page/run_city/run_city_point.dart';
import 'package:town_pass/page/run_city/run_city_mock_data.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/service/run_city_service.dart';

class RunCityStatsController extends GetxController {
  final RunCityService _runCityService = Get.find<RunCityService>();
  final RunCityApiService _apiService = Get.find<RunCityApiService>();
  final AccountService _accountService = Get.find<AccountService>();

  final RxBool isLoading = false.obs;
  final Rxn<RunCityUserData> userData = Rxn<RunCityUserData>();
  final RxList<RunCityActivityItem> activities = <RunCityActivityItem>[].obs;
  final RxList<RunCityBadge> badges = <RunCityBadge>[].obs;
  final RxBool areBadgesExpanded = false.obs;
  final RxList<RunCityPoint> badgePointsSource = <RunCityPoint>[].obs;
  final RxnString errorMessage = RxnString();

  /// 計算總時間（從活動列表中累加，單位：秒）
  int get totalTimeSeconds {
    return activities.fold<int>(0, (sum, activity) => sum + activity.duration);
  }

  /// 格式化總時間
  String get formattedTotalTime {
    final hours = totalTimeSeconds ~/ 3600;
    final minutes = (totalTimeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  /// 載入用戶資料和活動列表
  Future<void> loadData() async {
    // 檢查用戶是否已登入
    if (_accountService.account == null) {
      errorMessage.value = '請先登入以使用此功能';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final userId = _accountService.account!.id;
      // 並行載入用戶資料和活動列表
      await Future.wait([
        _loadUserData(),
        _loadActivities(userId),
        _loadBadges(userId),
      ]);
    } on RunCityApiException catch (e) {
      // 處理 API 錯誤
      final errorText = e.code != null ? '${e.message} (${e.code})' : e.message;
      errorMessage.value = errorText;
    } catch (e) {
      errorMessage.value = '載入資料失敗：${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// 載入用戶資料
  Future<void> _loadUserData() async {
    final data = await _runCityService.getUserData();
    userData.value = data;
  }

  /// 載入活動列表
  Future<void> _loadActivities(String userId) async {
    final items = await _apiService.fetchActivities(userId: userId);
    activities.assignAll(items);
  }

  Future<void> _loadBadges(String userId) async {
    late final List<RunCityPoint> userPoints;
    if (RunCityService.useMockData) {
      userPoints = mockRunCityPoints.toList(growable: false);
    } else {
      userPoints = await _apiService.fetchUserLocations(userId: userId);
    }

    badgePointsSource.assignAll(userPoints);
    final generatedBadges = _generateBadges(userPoints);
    generatedBadges.sort((a, b) {
      final completionCompare = (a.isCompleted ? 0 : 1).compareTo(b.isCompleted ? 0 : 1);
      if (completionCompare != 0) {
        return completionCompare;
      }
      return a.id.compareTo(b.id);
    });

    badges.assignAll(generatedBadges);
    areBadgesExpanded.value = false;
  }

  List<RunCityBadge> _generateBadges(List<RunCityPoint> points) {
    if (points.isEmpty) {
      return <RunCityBadge>[];
    }

    final Map<String, List<RunCityPoint>> groupedByArea = <String, List<RunCityPoint>>{};
    for (final point in points) {
      final area = point.area ?? '未分類';
      groupedByArea.putIfAbsent(area, () => <RunCityPoint>[]).add(point);
    }

    return groupedByArea.entries.map((entry) {
      final collected = entry.value.where((p) => p.collected).map((p) => p.id).toList();
      final allIds = entry.value.map((p) => p.id).toList();
      return RunCityBadge(
        id: entry.key,
        name: entry.key,
        pointIds: allIds,
        collectedPointIds: collected,
        distanceMeters: 0,
      );
    }).toList();
  }

  /// 刷新資料
  Future<void> refresh() async {
    await loadData();
  }

  void toggleBadgeExpansion() {
    if (badges.length <= 3) {
      return;
    }
    areBadgesExpanded.toggle();
  }
}


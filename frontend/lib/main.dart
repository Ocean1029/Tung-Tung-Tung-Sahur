import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/page/run_city/run_city_api_service.dart';
import 'package:town_pass/service/account_service.dart';
import 'package:town_pass/service/device_service.dart';
import 'package:town_pass/service/geo_locator_service.dart';
import 'package:town_pass/service/notification_service.dart';
import 'package:town_pass/service/package_service.dart';
import 'package:town_pass/service/shared_preferences_service.dart';
import 'package:town_pass/service/nfc_service.dart';
import 'package:town_pass/service/run_city_service.dart';
import 'package:town_pass/service/subscription_service.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/tp_route.dart';

const _transparentStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // FlutterNativeSplash.preserve(
  //   widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
  // );

  await initServices();

  SystemChrome.setSystemUIOverlayStyle(_transparentStatusBar);

  runApp(const MyApp());
}

Future<void> initServices() async {
  await Get.putAsync<AccountService>(() async => await AccountService().init());
  await Get.putAsync<DeviceService>(() async => await DeviceService().init());
  await Get.putAsync<PackageService>(() async => await PackageService().init());
  await Get.putAsync<SharedPreferencesService>(
      () async => await SharedPreferencesService().init());
  await Get.putAsync<GeoLocatorService>(
      () async => await GeoLocatorService().init());
  await Get.putAsync<NotificationService>(
      () async => await NotificationService().init());

  Get.put<SubscriptionService>(SubscriptionService());
  Get.put<RunCityApiService>(RunCityApiService());
  Get.put<RunCityService>(RunCityService());
  Get.put<NFCService>(NFCService());
  
  // 設置 Deep Link 處理
  _setupDeepLinkHandler();
}

void _setupDeepLinkHandler() {
  const MethodChannel channel = MethodChannel('com.yu.townpass/deep_link');
  
  channel.setMethodCallHandler((call) async {
    if (call.method == 'handleDeepLink') {
      final String? url = call.arguments as String?;
      if (url != null) {
        _handleDeepLink(url);
      }
    }
  });
}

// NFC ID 到地名的硬編碼映射
final Map<String, String> _nfcLocationMap = {
  'nfc_001': '國立臺灣大學圖書館',
  // 可以在這裡添加更多映射
};

void _handleDeepLink(String url) {
  try {
    final uri = Uri.parse(url);
    
    // 處理 runcity:// 開頭的 URL
    if (uri.scheme == 'runcity') {
      print('收到 Deep Link: $url');
      
      // 解析參數（例如 runcity://nfc?tag=nfc_001）
      final tagId = uri.queryParameters['tag'] ?? uri.queryParameters['id'];
      
      // 根據 host 或 path 決定跳轉到哪個頁面
      String targetRoute;
      
      // 解析路由：runcity://[page] 或 runcity:///[page]
      final page = uri.host.isEmpty ? uri.path.replaceFirst('/', '') : uri.host;
      
      // 路由映射
      switch (page.toLowerCase()) {
        case 'nfc':
        case 'nfc_scan':
          targetRoute = TPRoute.nfcScan;
          break;
        case 'runcity':
        case 'run_city':
          targetRoute = TPRoute.runCity;
          break;
        case 'home':
        case 'main':
          targetRoute = TPRoute.main;
          break;
        case 'account':
          targetRoute = TPRoute.account;
          break;
        case 'setting':
          targetRoute = TPRoute.setting;
          break;
        case 'message':
          targetRoute = TPRoute.message;
          break;
        case 'qr':
        case 'qr_code_scan':
          targetRoute = TPRoute.qrCodeScan;
          break;
        case '':
        case '/':
          // 默認跳轉到首頁
          targetRoute = TPRoute.main;
          break;
        default:
          // 未知路由，跳轉到首頁
          print('未知路由: $page，跳轉到首頁');
          targetRoute = TPRoute.main;
      }
      
      // 執行跳轉
      // 使用 Future.microtask 確保在 Widget 樹構建完成後再跳轉
      Future.microtask(() async {
        // 先跳轉到目標頁面
        Get.offAllNamed(targetRoute);
        
        // 如果有 tag ID 且目標是 runcity 頁面，顯示成功提示
        if (tagId != null && targetRoute == TPRoute.runCity) {
          // 等待頁面載入完成
          await Future.delayed(const Duration(milliseconds: 500));
          
          // 獲取地點名稱
          final locationName = _nfcLocationMap[tagId] ?? tagId;
          
          // 顯示成功提示
          _showCollectionSuccessDialog(locationName);
        }
      });
      print('跳轉到: $targetRoute${tagId != null ? " (tag: $tagId)" : ""}');
    }
  } catch (e) {
    print('處理 Deep Link 失敗: $e');
  }
}

void _showCollectionSuccessDialog(String locationName) {
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "收集成功!" 文字
            const Text(
              '收集成功!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: TPColors.primary500, // 使用主題色
              ),
            ),
            const SizedBox(height: 32),
            // 勾選圖標
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: TPColors.primary500,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 32),
            // 地點名稱
            Text(
              locationName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  
  // 3 秒後自動關閉
  Future.delayed(const Duration(seconds: 3), () {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Town Pass',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: TPColors.grayscale50,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: TPColors.white,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: TPColors.primary500),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0.0,
          iconTheme: IconThemeData(size: 56),
          actionsIconTheme: IconThemeData(size: 56),
        ),
        actionIconTheme: ActionIconThemeData(
          backButtonIconBuilder: (_) => Semantics(
            excludeSemantics: true,
            child: Assets.svg.iconArrowLeft.svg(width: 24, height: 24),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: TPRoute.main,
      onInit: () {
        NotificationService.requestPermission();
      },
      getPages: TPRoute.page,
    );
  }
}

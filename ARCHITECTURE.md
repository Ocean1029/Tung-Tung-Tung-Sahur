# Town Pass 專案架構說明

## 📁 專案結構概覽

```
TownPass/
├── lib/                          # 主要程式碼目錄
│   ├── main.dart                 # 應用程式入口點
│   ├── bean/                     # 資料模型 (Data Models)
│   ├── gen/                      # 自動生成的檔案 (Assets, Fonts)
│   ├── page/                     # 所有頁面 (Views)
│   ├── service/                  # 服務層 (Business Logic)
│   └── util/                     # 工具類別和共用元件
├── assets/                       # 靜態資源
│   ├── image/                    # 圖片資源
│   ├── svg/                      # SVG 圖示
│   └── mock_data/                # 測試資料
└── ios/android/                  # 原生平台設定
```

---

## 🏗️ 架構模式

### 使用 GetX 狀態管理框架
- **View**: UI 介面 (StatelessWidget 或 GetView)
- **Controller**: 業務邏輯和狀態管理 (GetxController)
- **Service**: 服務層，處理資料存取和外部 API

### 程式碼組織原則
1. **分層架構**: View → Controller → Service
2. **單一職責**: 每個檔案負責一個明確的功能
3. **可重用元件**: `util/` 目錄存放共用 UI 元件

---

## 🗺️ 應用程式流程

### 1. 應用程式啟動 (`main.dart`)
```dart
main() → initServices() → MyApp → GetMaterialApp
```

### 2. 主要導航結構 (`MainView`)
```
MainView (底部導航欄)
├── 服務 (CityServiceView)      - index 0
├── 首頁 (HomeView)              - index 1
├── 優惠 (PerkView)              - index 2
└── 帳務 (BillView)              - index 3
```

### 3. 路由系統 (`lib/util/tp_route.dart`)
- 所有頁面路由定義在這裡
- 使用 GetX 的命名路由系統
- 支援參數傳遞和深度連結

---

## 📱 頁面結構說明

### 主要頁面位置 (`lib/page/`)

#### 底部導航欄頁面
1. **服務頁面** (`city_service/`)
   - `city_service_view.dart` - 主要服務列表頁面
   - 包含「我的服務」、「官方服務」、「熱門服務」
   - 可點擊進入各項服務功能

2. **首頁** (`home/`)
   - `home_view.dart` - 首頁內容
   - 包含新聞橫幅、活動資訊、城市新聞、訂閱服務

3. **優惠頁面** (`perk/`)
   - `perk_view.dart` - 優惠券/優惠資訊

4. **帳務頁面** (`bill/`)
   - `bill_view.dart` - 帳單管理

#### 其他功能頁面
- `account/` - 帳戶設定
- `message/` - 訊息中心
- `setting/` - 應用設定
- `qr_code_scan/` - QR Code 掃描
- `online_police/` - 警政報案系統
- ... 等等

---

## 🎯 如何開發新功能

### 範例：添加一個「天氣查詢」功能

#### 步驟 1: 建立頁面檔案

在 `lib/page/` 下建立新目錄：
```
lib/page/weather/
├── weather_view.dart          # UI 介面
└── weather_controller.dart    # 業務邏輯 (如果需要狀態管理)
```

#### 步驟 2: 建立 View 檔案 (`weather_view.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';

class WeatherView extends StatelessWidget {
  const WeatherView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TPAppBar(title: '天氣查詢'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('天氣查詢功能'),
            ElevatedButton(
              onPressed: () {
                // 功能邏輯
              },
              child: const Text('查詢天氣'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 步驟 3: 如果需要 Controller (`weather_controller.dart`)
```dart
import 'package:get/get.dart';

class WeatherController extends GetxController {
  final RxString weather = '未知'.obs;
  
  void fetchWeather() {
    // 獲取天氣資料的邏輯
    weather.value = '晴天';
  }
}
```

#### 步驟 4: 在路由中註冊 (`lib/util/tp_route.dart`)
```dart
// 1. 添加路由常數
abstract class TPRoute {
  // ... 其他路由
  static const String weather = '/weather';
}

// 2. 在 page 列表中註冊
static final List<GetPage> page = [
  // ... 其他頁面
  GetPage(
    name: weather,
    page: () => const WeatherView(),
    binding: BindingsBuilder(() {
      Get.put<WeatherController>(WeatherController());
    }),
  ),
];
```

#### 步驟 5: 在適當位置添加入口

**選項 A: 在服務頁面添加**
編輯 `lib/page/city_service/city_service_view.dart`，在適當位置添加：
```dart
// 在 ListView 中添加一個卡片或按鈕
GestureDetector(
  onTap: () => Get.toNamed(TPRoute.weather),
  child: TPCard(
    child: Row(
      children: [
        Assets.svg.iconWeather.svg(), // 如果有圖示
        const SizedBox(width: 16),
        const Text('天氣查詢'),
      ],
    ),
  ),
)
```

**選項 B: 在「我的服務」中顯示**
編輯 `lib/page/city_service/model/my_service_model.dart`，添加新的服務項目

**選項 C: 在首頁添加**
編輯 `lib/page/home/home_view.dart`，在適當位置添加入口

---

## 🔧 重要元件說明

### UI 元件 (`lib/util/`)
- `tp_app_bar.dart` - 統一的 AppBar 元件
- `tp_button.dart` - 按鈕元件
- `tp_card.dart` - 卡片元件
- `tp_text.dart` - 文字元件
- `tp_colors.dart` - 顏色定義
- `tp_route.dart` - 路由管理

### 服務層 (`lib/service/`)
- `account_service.dart` - 帳戶相關服務
- `device_service.dart` - 裝置資訊服務
- `geo_locator_service.dart` - 定位服務
- `notification_service.dart` - 通知服務
- `shared_preferences_service.dart` - 本地儲存服務

### 資料模型 (`lib/bean/`)
- 使用 `json_serializable` 自動生成序列化程式碼
- 例如：`account.dart`, `activity.dart`, `message.dart`

---

## 📝 開發新功能的完整流程

### 1. 規劃功能
- 決定功能要放在哪裡（服務頁面、首頁、獨立頁面等）
- 設計 UI 和用戶流程

### 2. 建立檔案結構
```
lib/page/[功能名稱]/
├── [功能名稱]_view.dart
├── [功能名稱]_controller.dart (如果需要)
└── widget/ (如果需要子元件)
    └── [子元件]_widget.dart
```

### 3. 實作 View
- 使用 `TPAppBar` 作為頂部導航
- 使用 `TPColors` 定義顏色
- 使用 `TPText` 定義文字樣式
- 使用 `TPCard` 作為卡片容器

### 4. 實作 Controller (如果需要)
- 繼承 `GetxController`
- 使用 `Rx` 變數管理狀態
- 實作業務邏輯方法

### 5. 註冊路由
- 在 `TPRoute` 中添加路由常數
- 在 `page` 列表中註冊頁面
- 設定 binding (如果需要 Controller)

### 6. 添加入口
- 在適當的頁面添加導航連結
- 使用 `Get.toNamed(TPRoute.xxx)` 進行導航

### 7. 測試功能
- 測試 UI 顯示
- 測試導航流程
- 測試業務邏輯

---

## 🎨 設計規範

### 顏色使用
- 使用 `TPColors` 中定義的顏色常數
- 不要直接使用 `Color(0xFF...)` 這種硬編碼

### 文字樣式
- 使用 `TPText` 元件
- 使用 `TPTextStyles` 定義的樣式
- 例如：`TPTextStyles.h1SemiBold`, `TPTextStyles.bodyRegular`

### 間距
- 使用統一的間距值（8, 16, 24, 32 等）
- 保持視覺一致性

---

## 📚 參考範例

### 簡單頁面範例
參考：`lib/page/online_police/online_police_view.dart`
- 靜態內容頁面
- 使用卡片展示功能
- 外部連結和撥打電話

### 複雜頁面範例
參考：`lib/page/city_service/city_service_view.dart`
- 多個 Widget 組合
- 使用 Controller 管理狀態
- 動態列表展示

### 掃描功能範例
參考：`lib/page/qr_code_scan/qr_code_scan_view.dart`
- 使用第三方套件 (`mobile_scanner`)
- 相機權限處理
- 複雜的 UI 覆蓋層

---

## 🚀 常用開發命令

```bash
# 安裝依賴
flutter pub get

# 生成程式碼 (bean 類別)
flutter pub run build_runner build

# 運行應用程式
flutter run

# 清理建置
flutter clean
```

---

## 📌 注意事項

1. **路由命名**: 使用 kebab-case (例如: `/weather-query`)
2. **檔案命名**: 使用 snake_case (例如: `weather_view.dart`)
3. **類別命名**: 使用 PascalCase (例如: `WeatherView`)
4. **狀態管理**: 簡單頁面可用 StatelessWidget，複雜頁面使用 GetX Controller
5. **資源引用**: 使用 `Assets.svg.xxx.svg()` 引用 SVG，使用 `Assets.image.xxx` 引用圖片

---

## 🔗 相關資源

- [GetX 文件](https://pub.dev/packages/get)
- [Flutter 文件](https://flutter.dev/docs)
- 專案路由定義: `lib/util/tp_route.dart`
- 底部導航配置: `lib/util/tp_bottom_navigation_factory.dart`




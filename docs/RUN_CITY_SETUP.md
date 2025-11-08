# Run City 功能設置指南

## ✅ 已完成的工作

1. ✅ 在 `my_service_model.dart` 中添加 `runCity` enum
2. ✅ 創建頁面檔案：
   - `lib/page/run_city/run_city_view.dart` - UI 介面
   - `lib/page/run_city/run_city_controller.dart` - 業務邏輯
3. ✅ 在路由中註冊 (`lib/util/tp_route.dart`)
4. ✅ 設定導航連結 (`destinationUrl: 'local://run_city'`)

## ⏳ 您需要完成的事項

### 1. 添加 SVG Icon 檔案

**檔案位置**：
```
frontend/assets/svg/icon_run_city.svg
```

**檔案命名規則**：
- 檔案名稱：使用 `snake_case` → `icon_run_city.svg`
- 程式碼引用：使用 `camelCase` → `Assets.svg.iconRunCity.svg()`

**步驟**：
1. 準備 SVG 圖檔（建議尺寸：24x24 或 48x48）
2. 將檔案命名為 `icon_run_city.svg`
3. 放在 `frontend/assets/svg/` 目錄下

### 2. 重新生成 Assets

執行以下命令重新生成 Assets（這樣程式碼才能找到新的 SVG）：

```bash
cd frontend
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 驗證設置

執行以下命令檢查是否有錯誤：

```bash
flutter analyze
```

## 📁 檔案結構

```
frontend/
├── assets/
│   └── svg/
│       └── icon_run_city.svg          # ⏳ 您需要添加這個檔案
├── lib/
│   ├── page/
│   │   └── run_city/
│   │       ├── run_city_view.dart     # ✅ 已創建
│   │       ├── run_city_controller.dart # ✅ 已創建
│   │       └── README.md              # ✅ 說明文件
│   ├── page/
│   │   └── city_service/
│   │       └── model/
│   │           └── my_service_model.dart # ✅ 已更新
│   └── util/
│       └── tp_route.dart              # ✅ 已更新
```

## 🎯 功能說明

### 當前功能

「跑城市」功能已創建基本 UI，包含：

1. **歡迎區塊** - 顯示功能介紹
2. **功能卡片**：
   - 跑步路線
   - 活動資訊
   - 記錄跑步

### 後續開發

您可以在 `run_city_view.dart` 和 `run_city_controller.dart` 中繼續開發：

- 實作跑步路線列表
- 實作活動資訊展示
- 實作跑步記錄功能
- 添加地圖整合（如果需要）
- 添加 GPS 定位功能（如果需要）

## 🔍 如何測試

1. **確保 SVG 檔案已添加**
   ```bash
   ls frontend/assets/svg/icon_run_city.svg
   ```

2. **重新生成 Assets**
   ```bash
   cd frontend
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **運行應用程式**
   ```bash
   flutter run
   ```

4. **測試流程**
   - 進入「服務」頁面
   - 在「我的服務」中找到「跑城市」
   - 點擊進入功能頁面
   - 確認 UI 正常顯示

## 📝 注意事項

1. **SVG 檔案必須存在**：如果沒有添加 SVG 檔案，程式碼會報錯（`iconRunCity` 未定義）
2. **必須執行 build_runner**：添加 SVG 後必須執行 `build_runner` 才能使用
3. **路由已設置**：使用 `local://run_city` 會自動導航到新頁面

## 🐛 常見問題

### Q: 編譯錯誤 "iconRunCity isn't defined"
**A**: 您需要：
1. 確認 SVG 檔案已放在正確位置
2. 執行 `flutter pub run build_runner build --delete-conflicting-outputs`

### Q: 點擊服務沒有反應
**A**: 檢查：
1. `destinationUrl` 是否為 `'local://run_city'`
2. 路由是否已正確註冊
3. 執行 `flutter clean` 後重新運行

### Q: 如何修改服務標題或描述？
**A**: 編輯 `lib/page/city_service/model/my_service_model.dart` 中的 `MyServiceItemId.runCity` 項目

## 📚 相關文件

- [專案架構說明](../../docs/ARCHITECTURE.md)
- [如何開發新功能](../../chathistory/cursor_repo.md#如何開發新功能)
- [Run City 功能說明](./lib/page/run_city/README.md)


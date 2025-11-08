# Run City 功能說明

## 📁 檔案位置

- `run_city_view.dart` - UI 介面
- `run_city_controller.dart` - 業務邏輯與狀態管理

## 🎨 SVG Icon 檔案位置

**重要**: 您需要將 SVG icon 檔案放在以下位置：

```
frontend/assets/svg/icon_run_city.svg
```

### 檔案命名規則

- **檔案名稱**: 使用 `snake_case`，例如：`icon_run_city.svg`
- **程式碼引用**: 使用 `camelCase`，例如：`Assets.svg.iconRunCity.svg()`

### 步驟

1. 準備 SVG 圖檔（建議尺寸：24x24 或 48x48）
2. 將檔案命名為 `icon_run_city.svg`
3. 放在 `frontend/assets/svg/` 目錄下
4. 執行以下命令重新生成 Assets：

```bash
cd frontend
flutter pub run build_runner build --delete-conflicting-outputs
```

## ✅ 已完成的工作

1. ✅ 在 `my_service_model.dart` 中添加 `runCity` enum
2. ✅ 創建頁面檔案 (`run_city_view.dart` 和 `run_city_controller.dart`)
3. ✅ 在路由中註冊 (`tp_route.dart`)
4. ✅ 設定導航連結 (`destinationUrl: 'local://run_city'`)

## 📝 待完成事項

1. ⏳ **添加 SVG icon 檔案** (`icon_run_city.svg`)
2. ⏳ 執行 `build_runner` 生成 Assets
3. ⏳ 實作具體功能（跑步路線、活動資訊、記錄跑步等）

## 🔍 如何測試

1. 確保 SVG 檔案已添加並執行 `build_runner`
2. 運行應用程式：`flutter run`
3. 進入「服務」頁面
4. 在「我的服務」中找到「跑城市」服務
5. 點擊進入功能頁面

## 📚 相關文件

- [專案架構說明](../../../../docs/ARCHITECTURE.md)
- [如何開發新功能](../../../../chathistory/cursor_repo.md#如何開發新功能)


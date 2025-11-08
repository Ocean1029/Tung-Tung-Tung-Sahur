# iOS Simulator 啟動超時問題排除指南

## 問題描述
錯誤訊息：`Failed to launch iOS Simulator: Error: Emulator didn't connect within 60 seconds`

## 常見原因
1. **模擬器啟動過慢** - 首次啟動或系統資源不足
2. **模擬器進程卡住** - 之前的進程沒有正確關閉
3. **模擬器狀態異常** - 模擬器損壞或配置錯誤
4. **Xcode 快取問題** - 需要清理快取
5. **系統資源不足** - 記憶體或 CPU 使用率過高

## 解決方案（按順序嘗試）

### 1. 清理模擬器進程
```bash
# 關閉所有模擬器進程
killall -9 Simulator
killall -9 com.apple.CoreSimulator.CoreSimulatorService

# 或者重啟模擬器服務
sudo killall -9 com.apple.CoreSimulator.CoreSimulatorService
```

### 2. 重啟模擬器
```bash
# 打開模擬器應用程式
open -a Simulator

# 等待模擬器完全啟動後，再運行 Flutter 應用
```

### 3. 重置模擬器
```bash
# 列出所有設備
xcrun simctl list devices

# 刪除有問題的模擬器（替換 DEVICE_ID）
xcrun simctl delete DEVICE_ID

# 或者重置特定模擬器
xcrun simctl erase DEVICE_ID
```

### 4. 清理 Flutter 和 Xcode 快取
```bash
cd frontend

# 清理 Flutter 建置快取
flutter clean

# 清理 iOS 建置資料
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/Podfile.lock

# 重新安裝依賴
flutter pub get
cd ios && pod install && cd ..
```

### 5. 檢查並修復模擬器
```bash
# 檢查模擬器狀態
xcrun simctl list devices

# 啟動模擬器（手動）
xcrun simctl boot "iPhone 16 Pro"

# 檢查模擬器日誌
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Simulator"'
```

### 6. 增加超時時間（臨時解決方案）
如果使用 VS Code 或 Cursor，可以在設定中增加超時時間：
- 打開設定（Settings）
- 搜尋 `flutter.launchTimeout`
- 將值從 60 秒增加到 120 秒或更高

### 7. 使用命令行直接啟動
```bash
cd frontend

# 先啟動模擬器
open -a Simulator

# 等待模擬器完全啟動（約 30-60 秒）

# 然後運行 Flutter
flutter run
```

### 8. 檢查系統資源
```bash
# 檢查記憶體使用情況
vm_stat

# 檢查 CPU 使用情況
top -l 1 | grep "CPU usage"

# 如果資源不足，關閉其他應用程式
```

### 9. 更新 Xcode 和模擬器
```bash
# 檢查 Xcode 版本
xcodebuild -version

# 更新 Xcode（通過 App Store）
# 然後更新命令行工具
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### 10. 重新安裝模擬器運行時
```bash
# 列出可用的運行時
xcrun simctl runtime list

# 如果缺少運行時，通過 Xcode 下載：
# Xcode > Settings > Platforms > 下載 iOS Simulator Runtime
```

## 推薦的完整重置流程

如果以上方法都無效，執行完整重置：

```bash
# 1. 停止所有模擬器進程
killall -9 Simulator
killall -9 com.apple.CoreSimulator.CoreSimulatorService

# 2. 清理 Flutter 專案
cd frontend
flutter clean
rm -rf ios/Pods ios/.symlinks ios/Podfile.lock
rm -rf ios/Flutter/Flutter.framework ios/Flutter/Flutter.podspec

# 3. 重新獲取依賴
flutter pub get

# 4. 重新安裝 CocoaPods
cd ios
pod deintegrate
pod install
cd ..

# 5. 手動啟動模擬器
open -a Simulator

# 6. 等待模擬器完全啟動（看到主畫面）

# 7. 運行 Flutter 應用
flutter run
```

## 預防措施

1. **定期清理**：定期執行 `flutter clean` 和清理 Pods
2. **關閉未使用的模擬器**：避免同時運行多個模擬器
3. **保持更新**：定期更新 Xcode 和 Flutter
4. **監控資源**：確保有足夠的記憶體和 CPU 資源

## 如果問題持續存在

1. 檢查 Xcode 日誌：`~/Library/Logs/CoreSimulator/`
2. 檢查 Flutter 日誌：`flutter doctor -v`
3. 嘗試使用不同的模擬器設備
4. 考慮使用實體 iOS 設備進行測試

## 相關資源

- [Flutter iOS 設定指南](https://docs.flutter.dev/get-started/install/macos#ios-setup)
- [Xcode Simulator 文件](https://developer.apple.com/documentation/xcode/simulator)
- [Flutter 故障排除](https://docs.flutter.dev/troubleshoot)


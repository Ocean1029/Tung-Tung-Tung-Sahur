# 手機 Build 配置指南

當你想要在手機上 build 並連接後端數據庫時，需要進行以下配置。

## 📋 前置條件

1. **確保後端服務正在運行**
   ```bash
   cd /Users/yu/Desktop/projects/Tung-Tung-Tung-Sahur
   make dev  # 啟動後端和數據庫服務
   ```

2. **確保數據庫已初始化**
   ```bash
   make prisma-push  # 創建數據庫表
   make seed         # 填充測試數據
   ```

3. **確保手機和 Mac 在同一網絡下**
   - 手機和 Mac 必須連接到同一個 Wi-Fi 網絡

## 🔍 獲取 Mac 的 IP 地址

在終端執行以下命令獲取 Mac 的 IP 地址：

```bash
ipconfig getifaddr en0
```

或者：

```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

常見的 IP 地址格式：
- `192.168.x.x`（家庭網絡）
- `172.20.x.x`（熱點網絡）
- `10.x.x.x`（企業網絡）

## 🔧 配置 API URL

### 方法 1：使用代碼中的默認值（已配置）

代碼中已經設置了默認 IP 地址：
- `RunCityApiService`: `http://172.20.10.3:3000`
- `NFCService`: `http://172.20.10.3:3000`

**如果 Mac IP 改變了**，需要更新以下文件：
- `frontend/lib/page/run_city/run_city_api_service.dart`（第 41 行）
- `frontend/lib/service/nfc_service.dart`（第 14 行）

### 方法 2：使用環境變數（推薦）

在 build 時傳遞環境變數，這樣不需要修改代碼：

#### iOS Build

```bash
cd frontend

# Debug build
flutter build ios --debug \
  --dart-define=RUN_CITY_API_BASE_URL=http://172.20.10.3:3000 \
  --dart-define=API_BASE_URL=http://172.20.10.3:3000

# Release build
flutter build ios --release \
  --dart-define=RUN_CITY_API_BASE_URL=http://172.20.10.3:3000 \
  --dart-define=API_BASE_URL=http://172.20.10.3:3000
```

#### Android Build

```bash
cd frontend

# Debug build
flutter build apk --debug \
  --dart-define=RUN_CITY_API_BASE_URL=http://172.20.10.3:3000 \
  --dart-define=API_BASE_URL=http://172.20.10.3:3000

# Release build
flutter build apk --release \
  --dart-define=RUN_CITY_API_BASE_URL=http://172.20.10.3:3000 \
  --dart-define=API_BASE_URL=http://172.20.10.3:3000
```

#### 直接運行到手機

```bash
cd frontend

# iOS
flutter run --dart-define=RUN_CITY_API_BASE_URL=http://172.20.10.3:3000 \
  --dart-define=API_BASE_URL=http://172.20.10.3:3000

# Android
flutter run --dart-define=RUN_CITY_API_BASE_URL=http://172.20.10.3:3000 \
  --dart-define=API_BASE_URL=http://172.20.10.3:3000
```

## 🚀 完整 Build 流程

### iOS

```bash
cd frontend

# 0. 如果遇到 build 錯誤，先清理（可選）
./clean-xcode.sh

# 1. 獲取依賴
flutter pub get

# 2. 生成代碼
flutter packages pub run build_runner build

# 3. 安裝 CocoaPods
cd ios
pod install
cd ..

# 4. Build（替換 172.20.10.3 為你的 Mac IP）
flutter build ios --release \
  --dart-define=RUN_CITY_API_BASE_URL=http://172.20.10.3:3000 \
  --dart-define=API_BASE_URL=http://172.20.10.3:3000

# 5. 在 Xcode 中打開並安裝到手機
open ios/Runner.xcworkspace
```

**在 Xcode 中 Build：**
1. 打開 `ios/Runner.xcworkspace`（**不是** `.xcodeproj`）
2. 選擇你的 iPhone 設備（不是 Simulator）
3. 點擊 **Run** 按鈕或按 `Command + R`
4. 如果遇到簽名問題，參考 `docs/XCODE_SIGNING_FIX.md`

### Android

```bash
cd frontend

# 1. 獲取依賴
flutter pub get

# 2. 生成代碼
flutter packages pub run build_runner build

# 3. Build（替換 172.20.10.3 為你的 Mac IP）
flutter build apk --release \
  --dart-define=RUN_CITY_API_BASE_URL=http://172.20.10.3:3000 \
  --dart-define=API_BASE_URL=http://172.20.10.3:3000

# 4. APK 文件位置
# build/app/outputs/flutter-apk/app-release.apk
```

## 🔍 驗證連接

1. **檢查後端服務是否運行**
   ```bash
   curl http://localhost:3000/api/health
   ```

2. **從手機瀏覽器測試**
   - 在手機瀏覽器中打開：`http://172.20.10.3:3000/api/health`
   - 應該能看到健康檢查回應

3. **檢查防火牆設置**
   - Mac 系統偏好設置 → 安全性與隱私 → 防火牆
   - 確保允許 Node.js 或 Docker 的連接

## ⚠️ 常見問題

### 1. Xcode Build 錯誤：database is locked

**錯誤訊息**：
```
unable to attach DB: error: accessing build database "...": database is locked
Possibly there are two concurrent builds running in the same filesystem location.
```

**原因**：
- 多個 Xcode 實例同時運行
- 之前的 build 進程沒有正確關閉
- DerivedData 目錄被鎖定

**解決方案**：

**方法 1：使用清理腳本（推薦）**
```bash
cd frontend
./clean-xcode.sh
```

**方法 2：手動清理**
```bash
# 1. 關閉所有 Xcode 實例
killall Xcode

# 2. 清理 DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 3. 清理 Flutter 緩存
cd frontend
flutter clean

# 4. 重新安裝依賴
flutter pub get
cd ios
pod install
cd ..

# 5. 重新打開 Xcode
open ios/Runner.xcworkspace
```

**方法 3：在 Xcode 中清理**
1. 打開 Xcode
2. 選單：**Product** → **Clean Build Folder** (Shift + Command + K)
3. 關閉 Xcode
4. 重新打開專案

### 2. 手機無法連接到後端

**原因**：Mac IP 地址改變或手機不在同一網絡

**解決方案**：
- 重新獲取 Mac IP：`ipconfig getifaddr en0`
- 更新代碼中的 IP 或重新 build 時傳遞新的 IP
- 確保手機和 Mac 連接到同一個 Wi-Fi

### 3. 連接被拒絕

**原因**：後端服務未運行或防火牆阻擋

**解決方案**：
- 確認後端服務運行：`docker compose ps`
- 檢查防火牆設置
- 嘗試從手機瀏覽器訪問 `http://[Mac IP]:3000/api/health`

### 4. 數據庫連接錯誤

**原因**：後端無法連接到數據庫

**解決方案**：
- 確認數據庫容器運行：`docker compose ps db`
- 確認數據庫已初始化：`make prisma-push`
- 檢查後端日誌：`docker compose logs backend-dev`

## 📝 注意事項

1. **IP 地址會改變**：每次連接到不同的 Wi-Fi 網絡時，Mac IP 可能會改變
2. **生產環境**：生產環境應該使用固定的域名或 IP，而不是開發機器的 IP
3. **安全性**：開發環境使用 HTTP 是可以的，但生產環境應該使用 HTTPS

## 🔄 快速更新 IP 的腳本

創建一個腳本自動獲取 IP 並 build：

```bash
#!/bin/bash
# build-mobile.sh

cd frontend

# 獲取 Mac IP
MAC_IP=$(ipconfig getifaddr en0)

if [ -z "$MAC_IP" ]; then
  echo "❌ 無法獲取 Mac IP 地址"
  exit 1
fi

echo "📱 使用 Mac IP: $MAC_IP"
echo "🚀 開始 build..."

# iOS
flutter build ios --release \
  --dart-define=RUN_CITY_API_BASE_URL=http://$MAC_IP:3000 \
  --dart-define=API_BASE_URL=http://$MAC_IP:3000

echo "✅ Build 完成！"
```


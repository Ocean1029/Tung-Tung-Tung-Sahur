# 問題排查指南

## 手機無法讀取數據庫數據

### 問題描述
手機可以連接到 `http://172.20.10.3:3000/api/health`，但應用中沒有顯示數據庫數據。

### 可能原因和解決方案

#### 1. API URL 配置不正確

**檢查點：**
- 前端代碼中的默認 API URL 是否正確
- Build 時是否傳遞了正確的環境變數

**解決方案：**

**方法 1：更新代碼中的默認值**
檢查並更新以下文件中的 IP 地址：
- `frontend/lib/page/run_city/run_city_api_service.dart`（第 43 行）
- `frontend/lib/service/nfc_service.dart`（第 14 行）

**方法 2：使用環境變數 Build**
```bash
cd frontend

# iOS
flutter build ios --release \
  --dart-define=RUN_CITY_API_BASE_URL=http://172.20.10.3:3000 \
  --dart-define=API_BASE_URL=http://172.20.10.3:3000

# Android
flutter build apk --release \
  --dart-define=RUN_CITY_API_BASE_URL=http://172.20.10.3:3000 \
  --dart-define=API_BASE_URL=http://172.20.10.3:3000
```

**方法 3：使用便捷腳本**
```bash
cd frontend
./build-mobile.sh
```

#### 2. 後端服務未運行或無法訪問

**檢查步驟：**
```bash
# 1. 檢查後端服務是否運行
docker compose ps backend-dev

# 2. 從 Mac 測試 API
curl http://localhost:3000/api/health

# 3. 從手機瀏覽器測試（替換為你的 Mac IP）
# 打開：http://172.20.10.3:3000/api/health
```

**解決方案：**
```bash
# 啟動後端服務
make dev
```

#### 3. 數據庫未初始化

**檢查步驟：**
```bash
# 檢查數據庫是否有數據
curl http://localhost:3000/api/locations | jq '.count'
```

**解決方案：**
```bash
# 初始化數據庫
make prisma-push
make seed
```

#### 4. 前端使用 Mock Data

**檢查點：**
- 檢查 `RunCityService.useMockData` 是否為 `true`
- 檢查 build 時是否設置了 `RUN_CITY_USE_MOCK_DATA=true`

**解決方案：**
確保 build 時**不**傳遞 `RUN_CITY_USE_MOCK_DATA=true`：
```bash
# ❌ 錯誤：會使用 Mock Data
flutter build ios --dart-define=RUN_CITY_USE_MOCK_DATA=true

# ✅ 正確：使用真實 API
flutter build ios --dart-define=RUN_CITY_API_BASE_URL=http://172.20.10.3:3000
```

#### 5. 網絡連接問題

**檢查步驟：**
1. 確認手機和 Mac 連接到同一個 Wi-Fi 網絡
2. 確認 Mac 防火牆允許連接
3. 從手機瀏覽器訪問 `http://172.20.10.3:3000/api/health`

**解決方案：**
- Mac 系統偏好設置 → 安全性與隱私 → 防火牆
- 確保允許 Node.js 或 Docker 的連接

#### 6. IP 地址改變

**問題：** Mac IP 地址可能會改變（例如連接到不同的 Wi-Fi）

**解決方案：**
```bash
# 1. 重新獲取 Mac IP
ipconfig getifaddr en0

# 2. 更新代碼中的 IP 或重新 build
# 更新 run_city_api_service.dart 和 nfc_service.dart 中的 IP
# 然後重新 build
```

### 完整排查流程

1. **檢查後端服務**
   ```bash
   curl http://localhost:3000/api/health
   ```

2. **檢查數據庫數據**
   ```bash
   curl http://localhost:3000/api/locations | jq '.count'
   ```

3. **檢查手機網絡連接**
   - 從手機瀏覽器訪問：`http://172.20.10.3:3000/api/health`
   - 應該看到 JSON 回應

4. **檢查前端配置**
   - 確認代碼中的 IP 地址正確
   - 確認 build 時使用了正確的環境變數

5. **重新 Build**
   ```bash
   cd frontend
   ./build-mobile.sh
   ```

6. **檢查應用日誌**
   - 在 Xcode 中查看 Console 輸出
   - 查找 API 請求錯誤

### 常見錯誤訊息

#### "Failed to load data"
- **原因：** API URL 不正確或後端未運行
- **解決：** 檢查 API URL 配置和後端服務狀態

#### "Network error"
- **原因：** 手機無法連接到 Mac
- **解決：** 確認手機和 Mac 在同一網絡，檢查防火牆設置

#### "Empty data"
- **原因：** 數據庫未初始化或 API 返回空數據
- **解決：** 運行 `make seed` 填充數據

### 調試技巧

1. **添加日誌輸出**
   在 `run_city_api_service.dart` 中添加：
   ```dart
   print('API Base URL: $baseUrl');
   print('Fetching from: $baseUrl/api/locations');
   ```

2. **使用 Charles Proxy 或 Proxyman**
   - 監控手機的網絡請求
   - 查看實際發送的 API URL

3. **檢查 Xcode Console**
   - 查看應用運行時的日誌
   - 查找錯誤訊息

### 快速檢查清單

- [ ] 後端服務正在運行 (`docker compose ps`)
- [ ] 數據庫已初始化 (`make seed`)
- [ ] Mac IP 地址正確 (`ipconfig getifaddr en0`)
- [ ] 前端代碼中的 IP 已更新
- [ ] Build 時使用了正確的環境變數
- [ ] 手機和 Mac 在同一網絡
- [ ] 防火牆允許連接
- [ ] 從手機瀏覽器可以訪問 API


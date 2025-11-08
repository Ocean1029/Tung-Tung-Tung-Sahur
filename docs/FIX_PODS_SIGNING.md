# 修復 Pods Privacy Extensions 簽名問題

當你看到多個 Pods 的 privacy extensions 要求簽名時，需要在 Xcode 中為它們配置簽名。

---

## 🚀 快速解決方案

### 步驟 1：在 Xcode 中打開 Pods Project

1. **打開 Xcode**（確保已打開 `Runner.xcworkspace`）

2. **在左側導航器中找到 Pods**：
   - 應該會看到 **Pods** 專案（黃色圖示）
   - 如果看不到，點擊左側導航器最上方的專案圖示，展開所有專案

3. **展開 Pods 專案**：
   - 點擊 **Pods**（黃色圖示）
   - 應該會看到多個 targets

### 步驟 2：為每個 Privacy Extension 配置簽名

對於每個出現錯誤的 privacy extension：

1. **找到對應的 target**：
   - `device_info_plus-device_info_plus_privacy`
   - `flutter_inappwebview_ios-flutter_inappwebview_ios_privacy`
   - 以及其他類似的 privacy extensions

2. **選擇 target**：
   - 在 Pods 專案下，點擊對應的 target

3. **切換到 Signing & Capabilities 標籤**

4. **配置簽名**：
   - ✅ 勾選 **"Automatically manage signing"**
   - 在 **Team** 下拉選單中，選擇你的 Apple ID（與 Runner target 相同的 Team）
   - 確認 Bundle Identifier 正確

5. **重複步驟 2-4** 為所有出現錯誤的 privacy extensions

---

## ⚡ 快速方法：批量設置

### 方法 A：使用 Xcode 的批量編輯

1. **在 Xcode 中**：
   - 選擇 Pods 專案（黃色圖示）
   - 選擇 **Pods** target（不是 Runner）

2. **切換到 Signing & Capabilities**

3. **配置所有 targets**：
   - 雖然不能直接批量設置，但可以：
     - 先設置 Pods target 的簽名
     - 然後為每個 privacy extension 單獨設置

### 方法 B：使用腳本自動設置（推薦）

執行以下命令來批量設置所有 Pods targets 的簽名：

```bash
cd /Users/yu/Desktop/projects/Tung-Tung-Tung-Sahur/frontend/ios

# 這個腳本會自動為所有 Pods targets 設置簽名
# 注意：需要先知道你的 Team ID
```

**或者手動在 Xcode 中設置**（更可靠）：

---

## 📝 詳細步驟（手動設置）

### 1. 打開 Xcode

```bash
cd frontend
open ios/Runner.xcworkspace
```

### 2. 找到所有需要設置的 Targets

在左側導航器中，展開 **Pods** 專案，找到以下 targets：

- `device_info_plus-device_info_plus_privacy`
- `flutter_inappwebview_ios-flutter_inappwebview_ios_privacy`
- 以及其他任何顯示簽名錯誤的 targets

### 3. 為每個 Target 設置簽名

對於每個 target：

1. **點擊 target 名稱**

2. **切換到 Signing & Capabilities 標籤**

3. **設置簽名**：
   - ✅ 勾選 "Automatically manage signing"
   - 選擇 Team（與 Runner target 相同的 Team）
   - 確認 Bundle Identifier 正確

4. **如果 Bundle Identifier 顯示錯誤**：
   - Xcode 可能會自動修正
   - 或手動修改為唯一的標識符

### 4. 確認 Runner Target 的簽名

確保 **Runner** target 的簽名也正確：

1. **選擇 Runner 專案**（藍色圖示）
2. **選擇 Runner target**
3. **Signing & Capabilities**：
   - ✅ "Automatically manage signing" 已勾選
   - Team 已選擇
   - Bundle Identifier: `com.yu.townpass`

---

## 🔍 檢查清單

完成後，確認：

- [ ] Runner target 簽名正確
- [ ] `device_info_plus-device_info_plus_privacy` 簽名正確
- [ ] `flutter_inappwebview_ios-flutter_inappwebview_ios_privacy` 簽名正確
- [ ] 所有其他 privacy extensions 簽名正確
- [ ] 所有 targets 都使用相同的 Team

---

## 🐛 如果還是有問題

### 問題 1：找不到某些 Targets

**解決方法：**
- 確認 Pods 專案已展開
- 確認已打開 `Runner.xcworkspace`（不是 `Runner.xcodeproj`）
- 嘗試重新安裝 Pods：
  ```bash
  cd frontend/ios
  pod install
  ```

### 問題 2：無法選擇 Team

**解決方法：**
1. 確認已在 Xcode Settings → Accounts 中登入 Apple ID
2. 確認 Runner target 的 Team 已選擇
3. 嘗試重新登入 Apple ID

### 問題 3：Bundle Identifier 衝突

**解決方法：**
- Xcode 通常會自動修正
- 或手動修改為唯一的標識符

---

## 💡 為什麼需要設置這些？

iOS 17+ 引入了 Privacy Extensions，這些是獨立的 targets，需要單獨簽名：

- `device_info_plus-device_info_plus_privacy` - 處理設備資訊的隱私權限
- `flutter_inappwebview_ios-flutter_inappwebview_ios_privacy` - 處理 WebView 的隱私權限

每個 extension 都需要：
- 自己的 Bundle Identifier
- 自己的簽名證書
- 與主 App 相同的 Team

---

## ✅ 完成後

設置完成後：

1. **清理構建**：
   - Product → Clean Build Folder（`Shift + Command + K`）

2. **重新運行**：
   - 選擇你的 iPhone
   - 點擊 Run（`Command + R`）

3. **應該可以成功編譯和安裝了！** 🎉


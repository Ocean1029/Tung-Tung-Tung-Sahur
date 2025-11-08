# Xcode 簽名問題解決方案

當你看到以下錯誤時：
- "No Accounts: Add a new account in Accounts settings"
- "No profiles for 'com.example.townpass' were found"

這表示 Xcode 需要配置開發者帳號和簽名設定。

---

## 🚀 快速解決方案

### 步驟 1：在 Xcode 中登入 Apple ID

1. **打開 Xcode**

2. **打開 Preferences**：
   - 選單：**Xcode** → **Settings**（或 **Preferences**）
   - 或按快捷鍵：`Command + ,`

3. **切換到 Accounts 標籤**

4. **點擊左下角的「+」號**

5. **選擇「Apple ID」**

6. **輸入你的 Apple ID 和密碼**
   - 可以使用任何 Apple ID（免費）
   - 不需要付費的開發者帳號
   - 點擊「Sign In」

7. **等待登入完成**
   - 應該會看到你的 Apple ID 出現在列表中

---

### 步驟 2：配置專案簽名

1. **在 Xcode 中打開專案**：
   ```bash
   cd frontend
   open ios/Runner.xcworkspace
   ```

2. **選擇專案**：
   - 在左側導航器中，點擊最上方的 **Runner**（藍色圖示）

3. **選擇 Target**：
   - 在中間區域，選擇 **Runner**（在 TARGETS 下）

4. **切換到 Signing & Capabilities 標籤**

5. **啟用自動簽名**：
   - ✅ 勾選 **"Automatically manage signing"**

6. **選擇 Team**：
   - 在 **Team** 下拉選單中，選擇你的 Apple ID
   - 應該會顯示為 "Your Name (Personal Team)" 或類似

7. **確認 Bundle Identifier**：
   - 應該顯示為 `com.example.townpass`
   - 如果顯示錯誤，Xcode 可能會自動修正

8. **等待 Xcode 處理**：
   - Xcode 會自動創建簽名證書和配置文件
   - 可能需要幾秒鐘

---

### 步驟 3：確認設定

1. **檢查 Signing & Capabilities**：
   - ✅ "Automatically manage signing" 已勾選
   - ✅ Team 已選擇（顯示你的 Apple ID）
   - ✅ Bundle Identifier 正確
   - ✅ Provisioning Profile 已自動創建

2. **如果看到警告**：
   - 點擊警告訊息
   - 按照提示操作（通常是點擊 "Fix Issue"）

---

### 步驟 4：重新嘗試運行

1. **選擇你的 iPhone**（在裝置選擇器中）

2. **點擊 Run**（或 `Command + R`）

3. **等待編譯和安裝**

---

## 🐛 常見問題

### 問題 1：無法登入 Apple ID

**解決方法：**
1. 確認網路連接正常
2. 確認 Apple ID 和密碼正確
3. 如果使用兩步驟驗證，需要輸入驗證碼
4. 嘗試在瀏覽器中登入 Apple ID 確認帳號正常

### 問題 2：選擇 Team 後出現錯誤

**錯誤訊息：**
- "Failed to create provisioning profile"
- "No valid 'aps-environment' entitlement"

**解決方法：**
1. **清除舊的配置文件**：
   - Xcode → Settings → Accounts
   - 選擇你的 Apple ID
   - 點擊 "Download Manual Profiles"
   - 然後刪除所有配置文件

2. **重新選擇 Team**：
   - 回到 Signing & Capabilities
   - 取消勾選 "Automatically manage signing"
   - 重新勾選 "Automatically manage signing"
   - 重新選擇 Team

3. **清理專案**：
   ```bash
   cd frontend/ios
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

### 問題 3：Bundle Identifier 衝突

**錯誤訊息：**
- "An App ID with Identifier 'com.example.townpass' is not available"
- "The app identifier cannot be registered to your development team because it is not available"

**解決方法：**
1. **修改 Bundle Identifier**：
   - 在 Signing & Capabilities 中
   - 將 Bundle Identifier 改為唯一的，例如：
     - `com.yourname.townpass`（已自動修改為 `com.yu.townpass`）
     - `com.yourname.tungtungtungsahur`

2. **✅ 已自動修改**：
   - Bundle Identifier 已從 `com.example.townpass` 改為 `com.yu.townpass`
   - 請在 Xcode 中重新選擇 Team 並嘗試 Run

3. **或者使用 Xcode 建議的 Identifier**：
   - Xcode 可能會自動建議一個可用的 Identifier

### 問題 4：一直要求輸入鑰匙圈密碼

**情況：**
- macOS 一直彈出提示：「codesign 想存取鑰匙圈中的密碼」
- 輸入密碼後還是繼續彈出

**解決方法：**

1. **確認密碼正確**：
   - 輸入的是你的 **Mac 登入密碼**（不是 Apple ID 密碼）
   - 這是你的 Mac 使用者帳號密碼

2. **點擊「永遠允許」而不是「允許」**：
   - 如果只點擊「允許」，每次編譯都會要求輸入密碼
   - 點擊「永遠允許」可以永久授權，之後就不會再問了

3. **如果密碼正確但還是無法授權**：
   ```bash
   # 重置鑰匙圈權限
   security unlock-keychain ~/Library/Keychains/login.keychain-db
   ```

4. **或者手動授權 codesign**：
   - 打開「鑰匙圈存取」（Keychain Access）
   - 搜尋「Apple Development」
   - 找到你的開發者證書
   - 雙擊打開 → 存取控制 → 允許所有應用程式存取此項目

5. **如果還是不行，嘗試重新登入 Apple ID**：
   - Xcode → Settings → Accounts
   - 移除你的 Apple ID
   - 重新登入

### 問題 5：多個 Pods Privacy Extensions 需要簽名

**錯誤訊息：**
- "Signing for 'device_info_plus-device_info_plus_privacy' requires a development team"
- "Signing for 'flutter_inappwebview_ios-flutter_inappwebview_ios_privacy' requires a development team"
- 多個類似的錯誤

**解決方法：**

👉 **詳細指南：** 查看 [`FIX_PODS_SIGNING.md`](./FIX_PODS_SIGNING.md)

**快速步驟：**

1. **在 Xcode 中**：
   - 展開 **Pods** 專案（黃色圖示）
   - 找到每個出現錯誤的 privacy extension target

2. **為每個 target 設置簽名**：
   - 選擇 target
   - Signing & Capabilities
   - ✅ 勾選 "Automatically manage signing"
   - 選擇 Team（與 Runner target 相同）

3. **常見的 privacy extensions**：
   - `device_info_plus-device_info_plus_privacy`
   - `flutter_inappwebview_ios-flutter_inappwebview_ios_privacy`
   - 以及其他類似的 targets

4. **完成後清理並重新運行**：
   - Product → Clean Build Folder
   - 重新 Run

### 問題 6：Framework 代碼簽名錯誤

**錯誤訊息：**
- "Failed to verify code signature of ... image_picker_ios.framework"
- "No code signature found"

**解決方法：**

1. **使用修復腳本（推薦）**：
   ```bash
   cd frontend/ios
   bash fix_code_signing.sh
   ```

2. **或手動修復**：
   ```bash
   cd frontend
   flutter clean
   cd ios
   rm -rf Pods Podfile.lock
   pod install --repo-update
   ```

3. **在 Xcode 中**：
   - Product → Clean Build Folder（`Shift + Command + K`）
   - 重新打開專案
   - 確認 Signing & Capabilities 設定正確
   - 重新 Run

4. **如果還是不行**：
   - 確認 Podfile 的 post_install 腳本已更新（已自動更新）
   - 確認所有 Pods 都使用自動簽名
   - 嘗試刪除 DerivedData：
     ```bash
     rm -rf ~/Library/Developer/Xcode/DerivedData/*
     ```

### 問題 6：iPhone 上顯示「未受信任的開發者」

**解決方法：**
1. **在 iPhone 上**：
   - 設定 → 一般 → VPN 與裝置管理
   - 找到你的開發者帳號（顯示為你的名字）
   - 點擊「信任 [你的名字]」
   - 確認信任

2. **重新安裝 App**：
   - 在 Xcode 中重新 Run

---

## 💡 使用免費 Apple ID 的限制

使用免費的 Apple ID（Personal Team）有一些限制：

- ✅ 可以安裝到自己的 iPhone
- ✅ 可以開發和測試 App
- ⚠️ App 會在 7 天後過期（需要重新安裝）
- ⚠️ 無法發布到 App Store
- ⚠️ 無法使用某些進階功能（如 Push Notifications）

**對於測試 NFC 功能來說，免費帳號完全足夠！**

---

## 📝 完整步驟檢查清單

- [ ] 在 Xcode Settings → Accounts 中登入 Apple ID
- [ ] 在專案設定中選擇 Runner target
- [ ] 切換到 Signing & Capabilities 標籤
- [ ] 勾選 "Automatically manage signing"
- [ ] 選擇你的 Team（Apple ID）
- [ ] 確認 Bundle Identifier 正確
- [ ] 確認 Provisioning Profile 已創建
- [ ] 選擇 iPhone 作為目標裝置
- [ ] 點擊 Run
- [ ] 如果 iPhone 顯示「未受信任」，在 iPhone 上信任開發者

---

## 🎉 完成！

完成以上步驟後，應該就可以成功部署 App 到 iPhone 了！

如果還有問題，請檢查：
1. Xcode Console 的錯誤訊息
2. iPhone 是否已信任開發者
3. iPhone 的 iOS 版本是否符合 App 要求（iOS 15.5+）


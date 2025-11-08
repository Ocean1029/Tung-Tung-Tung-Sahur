# NFC 功能完整指南

## 📋 目录

- [方案概述](#方案概述)
- [快速开始](#快速开始)
- [URL Scheme 配置](#url-scheme-配置)
- [NFC Tag 设置](#nfc-tag-设置)
- [测试步骤](#测试步骤)
- [添加更多地点](#添加更多地点)
- [故障排除](#故障排除)

---

## 🎯 方案概述

### 当前使用的方案：URL Scheme

**工作原理：**
1. NFC tag 写入 URL Scheme：`runcity://runcity?tag=nfc_001`
2. iPhone 感应到 tag → iOS 自动识别 URL Scheme
3. 自动打开 App（如果已安装）
4. App 解析 URL → 跳转到对应页面
5. 显示成功提示对话框（如果包含 tag 参数）

### ✅ 优点

- ✅ **不需要付费账号**（免费 Apple ID 即可）
- ✅ **不需要 NFC Capability**（不需要 Xcode Capability）
- ✅ **不需要 Entitlements**（不需要特殊权限）
- ✅ **不需要 VM**（直接在本机 Mac 开发）
- ✅ **自动打开 App**（用户体验好）
- ✅ **可以传递参数**（例如 tag ID）
- ✅ **可以显示成功提示**（自动显示地点名称）

### ⚠️ 限制

- ❌ **需要 App 已安装**（如果未安装会显示错误）
- ❌ **无法跳转到 App Store**（URL Scheme 不支持）

---

## 🚀 快速开始

### 步骤 1：确保后端服务器运行（可选）

**注意：** 如果只是测试 URL Scheme 跳转和成功提示，**不需要后端服务器**。

如果需要后端功能，启动服务器：

```bash
cd /Users/yu/Desktop/projects/Tung-Tung-Tung-Sahur/backend
bash scripts/start-nfc-server.sh
```

**确认输出：**
```
Server listening on 0.0.0.0:3000
Network access: http://10.103.176.218:3000
```

**重要：** 服务器已配置为监听所有网络接口（`0.0.0.0`），允许从 iPhone 访问。

### 步骤 2：安装 App 到 iPhone

在 Xcode 中：
1. 打开 `frontend/ios/Runner.xcworkspace`
2. 选择你的 iPhone
3. 点击 Run（`Command + R`）
4. 确认 App 已安装

### 步骤 3：准备 NFC Tag

使用 **NFC Tools App**（App Store 免费下载）将 tag 写入：

```
runcity://runcity?tag=nfc_001
```

### 步骤 4：测试

1. 用 iPhone 靠近 NFC tag
2. App 应该自动打开
3. 跳转到运动之都页面
4. 显示成功提示对话框（"收集成功!" + "國立臺灣大學圖書館"）

---

## 🔧 URL Scheme 配置

### 已配置的 URL Scheme

**Scheme 名称：** `runcity://`

**配置文件：**
- `frontend/ios/Runner/Info.plist` - URL Scheme 注册
- `frontend/ios/Runner/AppDelegate.swift` - URL Scheme 处理
- `frontend/lib/main.dart` - Deep Link 路由和成功提示

### 支持的页面路由

| URL | 跳转页面 | 说明 |
|-----|---------|------|
| `runcity://` | 首页 | 默认跳转到首页 |
| `runcity://nfc` | NFC 扫描页面 | 跳转到 NFC 扫描功能 |
| `runcity://runcity` | 运动之都页面 | 跳转到运动之都功能 |
| `runcity://runcity?tag=nfc_001` | 运动之都页面 + 显示成功提示 | 跳转并显示"國立臺灣大學圖書館"成功提示 |
| `runcity://home` | 首页 | 跳转到首页 |
| `runcity://account` | 账户页面 | 跳转到账户设置 |
| `runcity://setting` | 设置页面 | 跳转到设置 |
| `runcity://message` | 消息页面 | 跳转到消息列表 |
| `runcity://qr` | QR 码扫描 | 跳转到 QR 码扫描 |

### 支持的参数

| 参数名 | 说明 | 示例 |
|--------|------|------|
| `tag` 或 `id` | NFC tag ID | `runcity://runcity?tag=nfc_001` |

---

## 📱 NFC Tag 设置

### 使用 NFC Tools App

1. **下载 NFC Tools**（App Store 免费）
2. **打开 App** → 选择 "Write"（写入）
3. **选择 "Add a record"** → 选择 "URL/URI"
4. **输入 URL**：
   ```
   runcity://runcity?tag=nfc_001
   ```
5. **点击 "Write"** → 将 iPhone 靠近 NFC tag
6. **完成！**

### NFC Tag 写入示例

**基本跳转：**
```
runcity://runcity                → 打开运动之都页面
runcity://nfc                    → 打开 NFC 扫描页面
```

**带参数（显示成功提示）：**
```
runcity://runcity?tag=nfc_001    → 打开运动之都页面并显示成功提示
```

---

## 🧪 测试步骤

### 方法 1：在 Safari 中测试（推荐）

1. **打开 iPhone Safari**
2. **在地址栏输入**：
   ```
   runcity://runcity?tag=nfc_001
   ```
3. **点击前往**
4. **应该会**：
   - 自动打开 App
   - 跳转到运动之都页面
   - 显示成功提示对话框

### 方法 2：使用 NFC Tag 测试

1. **准备 NFC Tag**（使用 NFC Tools 写入 URL）
2. **用 iPhone 靠近 tag**
3. **应该会**：
   - 自动打开 App
   - 跳转到对应页面
   - 显示成功提示（如果有 tag 参数）

---

## 📍 添加更多地点

### 编辑 NFC ID 映射

编辑 `frontend/lib/main.dart` 中的 `_nfcLocationMap`：

```dart
final Map<String, String> _nfcLocationMap = {
  'nfc_001': '國立臺灣大學圖書館',
  'nfc_002': '另一個地點名稱',
  'nfc_003': '第三個地點名稱',
  // 添加更多...
};
```

### 使用新的 NFC ID

在 NFC tag 中写入：
```
runcity://runcity?tag=nfc_002
```

App 会自动显示对应的地点名称。

---

## 🎨 成功提示对话框

### 显示内容

当 URL Scheme 包含 `tag` 参数且跳转到 `runcity` 页面时，会自动显示成功提示：

- ✅ **"收集成功!"** 文字（青绿色）
- ✅ **勾选图标**（圆形，青绿色背景）
- ✅ **地点名称**（例如："國立臺灣大學圖書館"）
- ✅ **3 秒后自动关闭**（或点击关闭）

### 样式

- 白色卡片背景
- 圆角设计
- 居中显示
- 可点击关闭或自动关闭

---

## 🐛 故障排除

### 问题 1：App 没有自动打开

**可能原因：**
- App 未安装
- URL Scheme 配置错误
- iOS 版本不支持

**解决方法：**
1. 确认 App 已安装
2. 检查 `Info.plist` 中的 URL Scheme 配置
3. 尝试手动测试：在 Safari 中输入 `runcity://runcity`

### 问题 2：App 打开了但没有跳转到正确页面

**可能原因：**
- URL 格式错误
- 路由配置错误

**解决方法：**
1. 检查 URL 格式是否正确
2. 查看 Xcode Console 的日志
3. 确认路由映射是否正确

### 问题 3：没有显示成功提示

**可能原因：**
- URL 中没有 `tag` 参数
- tag ID 不在映射表中
- 页面加载时间过长

**解决方法：**
1. 确认 URL 包含 `tag` 参数：`runcity://runcity?tag=nfc_001`
2. 确认 tag ID 在 `_nfcLocationMap` 中
3. 查看 Xcode Console 的日志

### 问题 4：显示 "找不到 App 可開啟"

**可能原因：**
- App 未安装
- URL Scheme 配置错误

**解决方法：**
1. 确认 App 已安装
2. 重新安装 App
3. 检查 `Info.plist` 配置

---

## 📝 技术细节

### URL Scheme 处理流程

1. **iOS 识别 URL Scheme**
   - iPhone 感应到 NFC tag
   - iOS 解析 URL Scheme
   - 查找已注册的 App

2. **App 接收 URL**
   - `AppDelegate.swift` 的 `application(_:open:options:)` 方法接收 URL
   - 通过 MethodChannel 传递给 Flutter

3. **Flutter 处理 URL**
   - `main.dart` 中的 `_handleDeepLink` 解析 URL
   - 提取页面路由和参数
   - 执行页面跳转

4. **显示成功提示**
   - 如果包含 `tag` 参数且跳转到 `runcity` 页面
   - 查找地点名称
   - 显示成功提示对话框

### 文件结构

```
frontend/
├── ios/Runner/
│   ├── Info.plist              # URL Scheme 注册
│   └── AppDelegate.swift       # URL Scheme 处理
└── lib/
    └── main.dart               # Deep Link 路由和成功提示
```

---

## ✅ 检查清单

完成配置后，确认：

- [ ] URL Scheme 已在 `Info.plist` 中注册
- [ ] `AppDelegate.swift` 已处理 URL Scheme
- [ ] `main.dart` 中的路由映射正确
- [ ] NFC ID 映射表已配置
- [ ] App 已安装到 iPhone
- [ ] 后端服务器正在运行（如果需要后端功能）

---

## 🎉 完成！

现在你可以：
1. ✅ 使用 NFC tag 自动打开 App
2. ✅ 跳转到特定页面
3. ✅ 显示成功提示和地点名称
4. ✅ 不需要付费账号
5. ✅ 不需要复杂的配置

**开始使用吧！** 🚀


# What is Town Pass?

Town Pass is an open-source project developed by the Taipei City Government. With the growth of smart cities, the demand for digitalization in city management and citizen services continues to rise. As we enter a new digital era, our goal is to involve citizens in the process, combining third-party expertise and innovation to make digital life in Taipei more convenient.

Town Pass is not just an application; it is an open community project. Through open-source, every citizen can participate in the ideation, development, and optimization of the application. This not only enhances citizen engagement and satisfaction but also leverages collective intelligence to continuously improve the application, making it truly serve the people. Furthermore, we hope that various municipalities can widely adopt the open-source framework of Town Pass, integrate it with their existing municipal service systems, and quickly have their own applications to enhance digital governance.

Open source is a key driver of technological progress and social development. Through open-source, Town Pass will become an ever-evolving platform, attracting developers from all backgrounds to contribute. We welcome experts to submit code, report issues, provide suggestions, and even develop new features and creative ideas, working together to perfect Town Pass as we advance toward a smart city.

# Getting Started

We highly recommend to read through our [document](https://tpe-guideline.web.app/en/docs/) for more detail.

Here are some quick setup guide.

## Requirement

- [Flutter](https://docs.flutter.dev/get-started/install) or [FVM](https://fvm.app/documentation/getting-started/installation)
- [XCode](https://developer.apple.com/xcode/) (for iOS)
- [Android SDK](https://developer.android.com/studio/index.html) (for Android, with or without Android Studio)

## Quick Start (從 GitHub 拉下代碼後)

### 必須執行的指令（按順序）

```bash
# 1. 進入 frontend 目錄
cd frontend

# 2. 安裝 Flutter 依賴
flutter pub get

# 3. 生成代碼（如果需要）
flutter packages pub run build_runner build

# 4. iOS 專用：安裝 CocoaPods 依賴
cd ios
pod install
cd ..

# 5. 運行應用
flutter run


open ios/Runner.xcworkspace
```

### iOS 開發注意事項

- **首次設置或更新依賴後**：必須執行 `pod install`
- **如果遇到簽名錯誤**：在 Xcode 中打開 `ios/Runner.xcworkspace`，設置你的 Development Team
- **如果遇到模組找不到**：清理 Xcode 緩存（Product > Clean Build Folder）

## Build the Project

1. Get the packages project needed:

   ``` bash
   flutter pub get
   ```

2. Generate additional needed dart code for the project.

   ``` bash
   flutter packages pub run build_runner build
   ```

3. You are all set now, Run the project from your IDE or the through the command line:

   ``` bash
   flutter run
   ```

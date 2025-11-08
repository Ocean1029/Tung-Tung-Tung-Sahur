#!/bin/bash

# 修復 iOS 代碼簽名問題的腳本

set -e

echo "🔧 開始修復代碼簽名問題..."
echo ""

# 進入 iOS 目錄
cd "$(dirname "$0")"

echo "1️⃣ 清理 Flutter 構建緩存..."
flutter clean

echo ""
echo "2️⃣ 清理 CocoaPods..."
rm -rf Pods
rm -rf Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo ""
echo "3️⃣ 重新獲取 Flutter 依賴..."
cd ..
flutter pub get

echo ""
echo "4️⃣ 重新安裝 CocoaPods 依賴..."
cd ios
pod deintegrate || true
pod install --repo-update

echo ""
echo "5️⃣ 清理 Xcode 構建緩存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo ""
echo "✅ 完成！現在請："
echo "1. 在 Xcode 中關閉專案（如果已打開）"
echo "2. 重新打開：open ios/Runner.xcworkspace"
echo "3. 確認 Signing & Capabilities 設定正確"
echo "4. 選擇你的 iPhone 並點擊 Run"
echo ""


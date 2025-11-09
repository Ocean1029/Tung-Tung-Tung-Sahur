#!/bin/bash
# Xcode 清理腳本 - 解決 "database is locked" 錯誤

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Xcode 清理腳本${NC}"
echo ""

# 1. 關閉所有 Xcode 實例
echo -e "${YELLOW}1️⃣ 檢查並關閉 Xcode 實例...${NC}"
if pgrep -x "Xcode" > /dev/null; then
  echo "發現 Xcode 正在運行，正在關閉..."
  killall Xcode 2>/dev/null || true
  sleep 2
  echo -e "${GREEN}✅ Xcode 已關閉${NC}"
else
  echo -e "${GREEN}✅ Xcode 未運行${NC}"
fi

# 2. 關閉 Simulator
echo ""
echo -e "${YELLOW}2️⃣ 檢查並關閉 Simulator...${NC}"
if pgrep -x "Simulator" > /dev/null; then
  echo "發現 Simulator 正在運行，正在關閉..."
  killall Simulator 2>/dev/null || true
  sleep 1
  echo -e "${GREEN}✅ Simulator 已關閉${NC}"
else
  echo -e "${GREEN}✅ Simulator 未運行${NC}"
fi

# 3. 清理 Flutter build 緩存
echo ""
echo -e "${YELLOW}3️⃣ 清理 Flutter build 緩存...${NC}"
cd "$(dirname "$0")"
flutter clean
echo -e "${GREEN}✅ Flutter 緩存已清理${NC}"

# 4. 清理 Xcode DerivedData
echo ""
echo -e "${YELLOW}4️⃣ 清理 Xcode DerivedData...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo -e "${GREEN}✅ DerivedData 已清理${NC}"

# 5. 清理 Xcode 模組緩存
echo ""
echo -e "${YELLOW}5️⃣ 清理 Xcode 模組緩存...${NC}"
rm -rf ~/Library/Developer/Xcode/Archives/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
echo -e "${GREEN}✅ Xcode 緩存已清理${NC}"

# 6. 清理 CocoaPods
echo ""
echo -e "${YELLOW}6️⃣ 清理 CocoaPods...${NC}"
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
echo -e "${GREEN}✅ CocoaPods 已清理${NC}"

# 7. 重新安裝依賴
echo ""
echo -e "${YELLOW}7️⃣ 重新安裝依賴...${NC}"
cd ..
flutter pub get
cd ios
pod install
cd ..
echo -e "${GREEN}✅ 依賴已重新安裝${NC}"

echo ""
echo -e "${GREEN}🎉 清理完成！${NC}"
echo ""
echo "現在可以："
echo "  1. 重新打開 Xcode: open ios/Runner.xcworkspace"
echo "  2. 或使用 Flutter: flutter run"
echo ""


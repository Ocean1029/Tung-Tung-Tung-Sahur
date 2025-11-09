#!/bin/bash
# 手機 Build 腳本
# 自動獲取 Mac IP 並 build Flutter 應用

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}📱 手機 Build 腳本${NC}"
echo ""

# 獲取 Mac IP 地址
echo "🔍 正在獲取 Mac IP 地址..."
MAC_IP=$(ipconfig getifaddr en0)

if [ -z "$MAC_IP" ]; then
  # 嘗試其他接口
  MAC_IP=$(ipconfig getifaddr en1)
fi

if [ -z "$MAC_IP" ]; then
  echo -e "${RED}❌ 無法獲取 Mac IP 地址${NC}"
  echo "請手動設置 IP 地址："
  echo "  export MAC_IP=你的IP地址"
  exit 1
fi

echo -e "${GREEN}✅ 找到 Mac IP: ${MAC_IP}${NC}"
echo ""

# 檢查後端服務是否運行
echo "🔍 檢查後端服務..."
if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
  echo -e "${GREEN}✅ 後端服務正在運行${NC}"
else
  echo -e "${YELLOW}⚠️  後端服務未運行，請先執行: make dev${NC}"
  read -p "是否繼續 build? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo ""

# 選擇平台
echo "請選擇 build 平台："
echo "1) iOS"
echo "2) Android"
echo "3) 兩個都 build"
read -p "請輸入選項 (1-3): " platform

case $platform in
  1)
    echo -e "${GREEN}🚀 開始 iOS build...${NC}"
    flutter build ios --release \
      --dart-define=RUN_CITY_API_BASE_URL=http://$MAC_IP:3000 \
      --dart-define=API_BASE_URL=http://$MAC_IP:3000
    echo -e "${GREEN}✅ iOS build 完成！${NC}"
    echo "在 Xcode 中打開: open ios/Runner.xcworkspace"
    ;;
  2)
    echo -e "${GREEN}🚀 開始 Android build...${NC}"
    flutter build apk --release \
      --dart-define=RUN_CITY_API_BASE_URL=http://$MAC_IP:3000 \
      --dart-define=API_BASE_URL=http://$MAC_IP:3000
    echo -e "${GREEN}✅ Android build 完成！${NC}"
    echo "APK 位置: build/app/outputs/flutter-apk/app-release.apk"
    ;;
  3)
    echo -e "${GREEN}🚀 開始 iOS build...${NC}"
    flutter build ios --release \
      --dart-define=RUN_CITY_API_BASE_URL=http://$MAC_IP:3000 \
      --dart-define=API_BASE_URL=http://$MAC_IP:3000
    echo -e "${GREEN}✅ iOS build 完成！${NC}"
    echo ""
    echo -e "${GREEN}🚀 開始 Android build...${NC}"
    flutter build apk --release \
      --dart-define=RUN_CITY_API_BASE_URL=http://$MAC_IP:3000 \
      --dart-define=API_BASE_URL=http://$MAC_IP:3000
    echo -e "${GREEN}✅ Android build 完成！${NC}"
    echo ""
    echo "iOS: 在 Xcode 中打開: open ios/Runner.xcworkspace"
    echo "Android APK: build/app/outputs/flutter-apk/app-release.apk"
    ;;
  *)
    echo -e "${RED}❌ 無效的選項${NC}"
    exit 1
    ;;
esac

echo ""
echo -e "${GREEN}🎉 完成！${NC}"
echo ""
echo "📝 重要提示："
echo "  - 確保手機和 Mac 連接到同一個 Wi-Fi 網絡"
echo "  - Mac IP: $MAC_IP"
echo "  - 後端 URL: http://$MAC_IP:3000"
echo "  - 如果 IP 改變，需要重新 build"


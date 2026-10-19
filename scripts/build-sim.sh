#!/usr/bin/env bash
# 老 Mac 上的「第二意见」构建 —— macOS Monterey 12.7.6 + Xcode 14.2
#
# 定位：CI（Xcode 16）是主证据；这个脚本只在关键节点用来确认
#       「Xcode 14.2 也还能编译」，避免代码用到 14.2 之后的 Swift 语法而不自知。
# 注意：只构建模拟器版、不签名。真机安装与归档请用 Xcode 图形界面操作。
#
# 用法：
#   ./scripts/build-sim.sh              # 默认 iPhone 14
#   ./scripts/build-sim.sh "iPhone SE (3rd generation)"

set -euo pipefail
cd "$(dirname "$0")/.."

DEST="${1:-iPhone 14}"

echo "== 工具链 =="
xcodebuild -version
echo
echo "== 目标模拟器：$DEST =="
echo

xcodebuild \
  -project Yimengqian/Yimengqian.xcodeproj \
  -scheme Yimengqian \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=$DEST" \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build 2>&1 | tee build.log

echo
echo "产物：build/DerivedData/Build/Products/Debug-iphonesimulator/Yimengqian.app"
echo "日志：build.log"

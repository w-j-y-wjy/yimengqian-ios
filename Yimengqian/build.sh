#!/bin/bash
# ============================================================
# 一梦千年 iOS —— 命令行构建脚本（macOS Monterey 12.x + Xcode 14.2）
# 用法：
#   ./build.sh            # 构建 iOS 模拟器版本
#   ./build.sh device     # 构建真机版本（需先在 Xcode 里配置好签名 Team）
#   ./build.sh archive    # 归档（生成 .xcarchive，可进一步导出 ipa）
# ============================================================
set -e
cd "$(dirname "$0")"

SCHEME="Yimengqian"
PROJECT="Yimengqian.xcodeproj"
MODE="${1:-simulator}"

echo "==> 一梦千年 iOS 构建 (模式: $MODE)"

case "$MODE" in
  simulator)
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
      -configuration Debug \
      -destination 'generic/platform=iOS Simulator' \
      -derivedDataPath build/DerivedData \
      build
    echo "✅ 模拟器构建完成。"
    echo "   产物位置: build/DerivedData/Build/Products/Debug-iphonesimulator/Yimengqian.app"
    echo "   也可直接用 Xcode 打开工程后 ⌘R 运行。"
    ;;
  device)
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
      -configuration Debug \
      -destination 'generic/platform=iOS' \
      -derivedDataPath build/DerivedData \
      -allowProvisioningUpdates \
      build
    echo "✅ 真机构建完成（请确保已在 Xcode 的 Signing 里选择开发团队）。"
    ;;
  archive)
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
      -configuration Release \
      -destination 'generic/platform=iOS' \
      -archivePath build/Yimengqian.xcarchive \
      -allowProvisioningUpdates \
      archive
    echo "✅ 归档完成: build/Yimengqian.xcarchive"
    echo "   后续可在 Xcode → Organizer 中导出 ipa，或运行:"
    echo "   xcodebuild -exportArchive -archivePath build/Yimengqian.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath build/ipa"
    ;;
  *)
    echo "❌ 未知模式: $MODE（可用: simulator / device / archive）"
    exit 1
    ;;
esac

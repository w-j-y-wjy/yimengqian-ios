# 一梦千年 · iOS 版

《一梦千年》古典文化沉浸式体验 App 的 **iOS 原生源码**（SwiftUI + Xcode 工程）。
由安卓工作区（React + Capacitor H5 原型）按完整开发工作流忠实移植而来，输出目录为 `ios/Yimengqian`。

> 详细转换说明见 [docs/转换架构说明.md](docs/转换架构说明.md)。

---

## 一、工程概览

| 项 | 值 |
|----|----|
| 工程名 | Yimengqian |
| 架构 | SwiftUI + MVVM（ObservableObject / EnvironmentObject） |
| 开发环境 | macOS Monterey 12.x + Xcode 14.2（Swift 5） |
| 最低系统 | iOS 15.0 |
| Bundle ID | com.yimeng.qiannian |
| 显示名 | 一梦千年 |
| 屏幕数 | 25 个页面（设计稿截图 + 热区交互引擎） |
| 数据层 | 朝代 / 人物 / 诗词 / 古物 / 活动 / 印章 / 对话 全部内嵌（`Models/ContentData.swift`） |
| 状态层 | `State/AppStore.swift`（对应 Web 的 AppContext + localStorage，UserDefaults 持久化） |

## 二、目录结构

```
Yimengqian/
├── Yimengqian.xcodeproj/          # Xcode 工程（tools/generate_pbxproj.mjs 自动生成）
└── Yimengqian/
    ├── App/                        # 应用入口与根视图
    │   ├── YimengqianApp.swift     # @main
    │   └── RootView.swift          # 路由栈 + 转场 + Toast
    ├── Config/
    │   └── ScreensConfig.swift     # 25 屏热区配置（自动生成，含坐标校准）
    ├── Models/
    │   ├── DomainModels.swift      # 领域模型
    │   └── ContentData.swift       # 内容数据
    ├── State/
    │   ├── StorageKeys.swift       # 存储键
    │   └── AppStore.swift          # 全局状态
    ├── Engine/
    │   ├── Router.swift            # 路由栈
    │   ├── ActionExecutor.swift    # 15 种热区动作
    │   └── ToastCenter.swift       # Toast
    ├── Views/
    │   ├── HotspotScreenView.swift # 截图 + 热区层引擎
    │   ├── SpecialScreens.swift    # 特殊页逻辑（任务结算/重置）
    │   └── ToastView.swift
    ├── Utilities/
    │   ├── Theme.swift             # 设计系统
    │   └── Helpers.swift           # 资源加载等
    ├── Content/
    │   ├── Screens/                # 25 张页面设计稿（ASCII 文件名，如 splash.png）
    │   └── Reference/              # 25 张内容参考图
    ├── Assets.xcassets/            # AppIcon / AccentColor / LaunchBackground
    └── Info.plist
```

## 三、macOS Monterey 12.7.6 构建与运行指南

> 你的系统是 macOS Monterey 12.7.6，**最高只能安装 Xcode 14.2**（Xcode 14.3+ 要求 macOS 13，Xcode 15+ 要求 macOS 13/14）。
> 本工程格式（objectVersion 56 / Xcode 14.0 兼容 / Swift 5 / 最低 iOS 15）正是为 Xcode 14.2 准备的，可直接打开编译。

### 第 0 步：确认 Xcode
打开"终端"，输入：

```bash
xcodebuild -version
```

- 若显示 `Xcode 14.2`（Build version 14C18）：直接进入第 2 步。
- 若未安装 Xcode：App Store 搜索"Xcode"（Monterey 会提供 14.2），或到
  [Apple 开发者下载中心](https://developer.apple.com/download/all/) 下载 Xcode 14.2 并安装。
  首次打开按提示安装额外组件。

### 第 1 步：把源码拷到 Mac
- 用 U 盘 / 微信文件传输 / 网盘把 **`ios\Yimengqian` 整个文件夹**（或 `一梦千年-iOS源码.zip`）拷贝到 Mac 任意目录，例如 `~/Desktop/一梦千年-iOS/`。
- 目录内应有：`Yimengqian.xcodeproj`、`Yimengqian/`、`build.sh`、`README.md`、`docs/`、`tools/`。

### 第 2 步：打开工程
双击 `Yimengqian.xcodeproj`（或在终端 `cd` 到该目录后 `open Yimengqian.xcodeproj`）。
工程自带共享 Scheme（Yimengqian），无需额外配置。

### 第 3 步：模拟器运行（推荐，无需任何账号）
1. 顶部工具栏选择模拟器，如 **iPhone 14**（Xcode 14.2 自带 iOS 16.x 模拟器；也可在 Xcode → Settings → Components 下载 iOS 15.x 运行时）。
2. 按 **⌘R**。
3. 首次构建约 1–3 分钟（打包约 110MB 图片资源），之后很快。

> 启动后流程：启动页 → 点「入梦」→ 引导 → 偏好测试 → 身份 → 首页 → 各模块。
> 启动页**连点 5 下**重置全部数据（对应安卓版 `?reset=1`）；页面**连点 3 下**显示热区调试框。

### 第 4 步：真机运行（可选，需要 Apple ID）
1. 顶部选到你的 iPhone（数据线连接，手机信任此电脑）。
2. 工程导航 → TARGETS → Yimengqian → **Signing & Capabilities**：勾选 **Automatically manage signing**，**Team** 选你的 Apple ID（Xcode → Settings → Accounts 添加，免费账号即可）。
3. ⌘R 运行。首次真机运行后，到 iPhone **设置 → 通用 → VPN 与设备管理** 信任开发者证书。

> 注意：免费个人账号签名 **每 7 天需重新签名**（重连电脑 ⌘R 即可）；正式参赛演示建议用付费开发者账号（¥688/年，有效期 1 年）。

### 第 5 步（可选）：命令行构建
```bash
cd ~/Desktop/一梦千年-iOS/Yimengqian
./build.sh            # 构建模拟器版（产物在 build/DerivedData/.../Yimengqian.app）
./build.sh device     # 构建真机版（需先在第 4 步配置好签名）
./build.sh archive    # 归档，可进一步导出 ipa
```
若提示无执行权限，先执行 `chmod +x build.sh`。

### 常见问题排查
| 现象 | 解决办法 |
|------|----------|
| `Signing for "Yimengqian" requires a development team` | 第 4 步 Signing 里选择 Team（仅模拟器运行可忽略） |
| 真机安装后闪退/提示未受信任 | 手机 设置 → 通用 → VPN 与设备管理 → 信任开发者证书 |
| `Unable to boot ... simulator` | Xcode → Settings → Components 重装模拟器运行时 |
| 编译报找不到字体（Font.custom） | 无害：iOS 自动回退系统字体（见第五节） |
| 构建报文件打不开 | 检查文件夹是否完整拷贝（Content 下 Screens、Reference 各 25 张图） |
| 图片资源中文名在 zip 传输/解压时丢失（Screens 目录变空） | 本版本已将 `Resources/` 改名 `Content/`（避开 bundle 保留目录名，该保留名会触发 codesign/安装器误报）、将截图文件名改为 ASCII；请用最新完整包传输，不要用旧包 |
| `CodeSign failed ... code object is not signed at all / In subcomponent: AppIcon60x60@2x.png` | 旧式多尺寸图标集会触发 macOS 12 + Xcode 14.2 的 codesign 校验失败；本版本已改为**现代单图标格式**（AppIcon.appiconset 的 Contents.json 仅含 1 条 `universal` 1024 条目）。若从旧版本升级，请用新包里的 `AppIcon.appiconset` 覆盖 |
| 换新图标包后**仍**报 `AppIcon60x60@2x.png`（In subcomponent 不变） | 机器级问题：旧 Xcode 安装损坏导致 codesign 异常。**根治：重装 Xcode 14.2**（从官方 xip 解压替换 /Applications/Xcode.app）。期间曾临时添加"模拟器免签名"配置，但 iOS 16 模拟器会拒绝完全无签名的 App（误导性报错 `CFBundleVersion`），**该配置已移除**，请以最新工程为准 |

## 四、使用说明（与安卓版一致）

- **启动**：进入启动页，点击「入梦」。
- **首次入梦**：世界观介绍 → 偏好测试 → 古典身份 → 首页。
- **古城线**：首页 → 朝代选择（北宋·汴京）→ 汴京地图 → 东坡茶坊 → 苏轼人物 → 茶坊对谈 → 任务奖励。
- **诗境线**：首页 → 诗境 → 江雪诗境 → 赏析 → 意象 → 诗境卡。
- **古物线**：古物识趣 → 青花瓷识别（模拟）→ 纹样详解。
- **雅集线**：雅集活动 → 飞花令（答对 A 过关）→ 春日雅士印章。
- **我的**：收藏（筛选/编辑模拟）、千年梦册、个人中心。
- **调试功能**：页面三连击显示热区红框（DEBUG）；启动页五连击重置全部数据（对应 Web `?reset=1`）。

## 五、设计系统

新中式 · 宋画美学（宣纸米白 / 墨黑 / 朱砂红 / 淡砂金），色板与字体定义集中在 `Utilities/Theme.swift`，
与安卓版 `src/styles/global.css` 的 token 完全对齐：

| Token | 值 |
|-------|-----|
| paper / paperLight / paperDark | #F5F0E8 / #FAF6EF / #E8E0D0 |
| ink / inkLight / inkMuted | #2C2416 / #5A4E3C / #8A7E6C |
| vermilion / Dark / Light | #C23C2A / #A03020 / #D4564A |
| gold / goldLight / goldBorder | #C9A96E / #E0CC9A / #D4B882 |
| greenInk / blueInk | #4A6741 / #3A5A7C |

> **字体（重要）**：`Utilities/Theme.swift` 使用 iOS 系统自带中文衬线字体 —— 标题 `KaitiSC-Bold`（楷体）、正文 `SongtiSC-Regular`（宋体），无需捆绑字体文件即可在模拟器/真机上正常显示宋楷效果。若某个字体名在个别系统版本不可用，会静默回退系统字体，不影响运行。

### 可选：捆绑 Noto Serif SC 字体（追求与设计稿完全一致的标题字形）
1. 从 [Google Fonts / Noto Serif SC](https://fonts.google.com/noto/specimen/Noto+Serif+SC) 下载 `NotoSerifSC-Regular.ttf`、`NotoSerifSC-SemiBold.ttf`，放入 `Yimengqian/Resources/fonts/`（文件夹引用会自动打包）。
2. 在 `Info.plist` 增加：
   ```xml
   <key>UIAppFonts</key>
   <array>
       <string>Resources/fonts/NotoSerifSC-Regular.ttf</string>
       <string>Resources/fonts/NotoSerifSC-SemiBold.ttf</string>
   </array>
   ```
3. 把 `Theme.swift` 中标题字体名改为 `NotoSerifSC-SemiBold`（正文保持 `SongtiSC-Regular` 即可）。

## 六、内容与状态覆盖矩阵

| 模块 | 页面 | 状态键（UserDefaults） | 状态 |
|------|------|------------------------|------|
| 启动 | 启动页 | onboardingComplete / onboardingSkipped | ✅ |
| 引导 | 梦境初启 / 偏好测试 / 身份结果 | preferenceScene·Content·Dynasty·Mood | ✅ |
| 首页 | 首页 | — | ✅ |
| 古城 | 朝代选择 / 汴京地图 / 茶坊 | currentCity / bianjingProgress | ✅ |
| 古人 | 苏轼人物 / 茶坊对谈 / 任务完成 | dialogueTopic / teaDialogueCompleted / teaRewardClaimed / cultureValue / stampDongpo / sushiLetter | ✅ |
| 诗境 | 诗境首页 / 江雪 / 赏析 / 意象 / 诗境卡 | jiangxuePlaying / jiangxueStyle / favoriteJiangxue / selectedImagery / poetryCardStyle·Layout·Seal / poetryCardCount / jiangxueCardCreated | ✅ |
| 古物 | 古物识趣 / 识别结果 / 纹样详解 | favoriteArtifact / favoriteArtifactPattern / artifactCompleted | ✅ |
| 雅集 | 雅集首页 / 飞花令 / 印章 | feihualingAnswer / feihualingCompleted / springStampClaimed / petalCount / yaValue | ✅ |
| 我的 | 收藏 / 千年梦册 / 个人中心 | favoriteFilter / dreambookOpened / snapshot | ✅ |

数据内容（`Models/ContentData.swift`）：朝代 4、人物 2、诗词 4+意象 4、古物 4、活动 5、飞花令题 3、印章 4、汴京地点 6、每日诗词 5、对谈主题 3。

## 七、再生成工具（可选）

`tools/` 下有两个 Node 脚本，仅在修改安卓源配置后需要重新生成：

```bash
node tools/generate_screens_swift.mjs   # screens.ts + hotspot-overrides.json → ScreensConfig.swift
node tools/generate_pbxproj.mjs         # 扫描源码目录 → project.pbxproj
```

已生成的产物可直接使用，无需重新运行。

## 八、后续可扩展方向

1. 将热区引擎逐步替换为原生 SwiftUI 页面（`Models/ContentData.swift` 数据已就绪）。
2. 接入真实 AI 对话 / 图像识别 API。
3. 增加分享（UIActivityViewController）与语音朗读（AVSpeechSynthesizer）。
4. 接入更多朝代与城市。

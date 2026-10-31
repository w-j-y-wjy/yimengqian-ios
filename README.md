# 一梦千年 · iOS

25 张设计稿整屏铺底 + 百分比热区引擎 + 原生 SwiftUI 叠层/详情页的古典文化沉浸式 App（SwiftUI，最低 iOS 16）。

> 热区点得动、跳得对、能落地真实功能；做不了的**如实标注**，不假装。

## 关键事实

| 项 | 值 |
|---|---|
| 设计稿屏数 | **25 屏**（`Content/Screens/*.png`，852×1846） |
| 热区 | **330 个**（百分比矩形，定义在 `Config/ScreensConfig.swift`） |
| 动作类型 | **18 种**（`Engine/ActionExecutor.swift`） |
| 原生路由 | **23 类**（`Config/NativeRoutes.swift`），68 个静态目标 |
| needs | **0**（原江雪播放键已改真朗读） |
| 最低系统 | **iOS 16.0**（NavigationStack / scrollDismissesKeyboard 需要 16），Bundle ID `com.yimeng.qiannian` |
| 代码基线 | `main` @ `09828da`（第 31–32 轮） |

## 截图

设计稿即运行画面（热区透明覆盖其上），仓库内直接可看：

| 屏 | 文件 |
|---|---|
| 首页 | [`Yimengqian/Yimengqian/Content/Screens/home.png`](Yimengqian/Yimengqian/Content/Screens/home.png) |
| 诗境首页 | [`poetry-home.png`](Yimengqian/Yimengqian/Content/Screens/poetry-home.png) |
| 江雪诗境 | [`jiangxue-scene.png`](Yimengqian/Yimengqian/Content/Screens/jiangxue-scene.png) |
| 个人中心 | [`profile.png`](Yimengqian/Yimengqian/Content/Screens/profile.png) |

其余 21 屏同目录；真机/模拟器实拍（含叠层与原生页）见 GitHub Actions 每次运行的 artifact：
日常目检下 **`review-thumbs-<run_number>`**（900px JPEG，约 5 MB，快）；需要像素级比对再下
`build-evidence-<run_number>`（`splash.png` + `overlay-*.png` + `sweep/*.png` + `build.log`，160+ MB，保留 7 天）。

## 构建

**本机是 Windows，没有 Xcode —— 编译全部靠 GitHub Actions。** 本地只能跑结构检查与预览器。

| 目的 | 做法 |
|---|---|
| 编译验证 + 25 屏扫屏 | 推 `main` 自动触发 [`ios-build.yml`](.github/workflows/ios-build.yml)；macOS 15 runner、免签名模拟器编译、逐屏截图 |
| 真机包（未签名 IPA） | Actions → 真机包（未签名 IPA）→ Run workflow → 下 artifact `device-ipa-unsigned`；[`ios-device-ipa.yml`](.github/workflows/ios-device-ipa.yml) |
| 结构快检（免费 ubuntu） | [`static-check.yml`](.github/workflows/static-check.yml)，秒级拦下"新文件没进 pbxproj""route 写错" |
| 在 Mac 上本地编译 | `Yimengqian/build.sh`（模拟器/真机/归档三分支），需 Xcode 14.2+ |

> 真机包装好后需自签（未签名）：Xcode → Signing & Capabilities 选 Team，或 `codesign` + 描述文件。免费 Apple ID 签名 7 天过期。

## 使用

启动页 → 「入梦」→ 世界观 → 偏好测试 → 古典身份 → 首页 → 各模块。

| 手势 | 效果 |
|---|---|
| 页面三连击（3 秒内） | 显示/隐藏热区红框与标签（对应 Web `?debug=1`） |
| 启动页五连击 | 弹确认后重置全部数据（对应 Web `?reset=1`） |

两条主线可验：**古城线** 首页 → 朝代 → 汴京 → 茶坊 → 苏轼 → 对谈；**诗境线** 诗境 → 江雪 → 赏析 → 意象 → 诗境卡（保存后「我的作品」出真卡面）。

## 常用命令

```powershell
cd ios
node scripts/static-check.mjs              # 结构检查：18 通过 / 1 已知警告 / 0 失败
node ..\_overhaul\metrics.mjs              # 330 热区 | 11 纯提示 | 120 指向原生 | needs 0
node tools/generate_screens_swift.mjs      # 重新生成 ScreensConfig.swift（改了热区配置才需要）
node tools/preview.mjs                     # 本地浏览器预览 25 屏 + 热区（Windows 可用）
node tools/add-swift-to-pbxproj.mjs Engine/Foo.swift   # 新 Swift 文件登记进 pbxproj 四处
```

> 生成器默认找 `../安卓/一梦千年App`，本机实际目录是 `安卓\一梦千年-App`，重跑前先设：
> `$env:YIMENG_ANDROID = 'D:\wij\桌面\移动应用比赛\安卓\一梦千年-App'`

> 生成物不要手改：`ScreensConfig.swift` 会被 `generate_screens_swift.mjs` 覆盖。要改热区请编辑 `tools/hotspot-overrides.ios.json` / `hotspot-additions.ios.json`。

## 诚实边界

**真的（可在真机验证）**

| 能力 | 实现 |
|---|---|
| 系统语音朗读 | `Engine/SpeechCenter.swift`（`AVSpeechSynthesizer`，zh-CN）；江雪/鸟鸣涧/静夜思三处喇叭 + 江雪播放键都真出声 |
| 飞花令判题 | `checkAnswer` 真判对错；第 1 题支持双答案 `correctAnswers: ["A","C"]` |
| 收藏数据闭环 | 收藏/取消 → 计数、进度条、等级、四格统计全部联动 |
| 诗境卡卡面 | 保存时冻结 `PoetryCard`，作品页重绘真卡面（诗句/题注/画风/版式/印章），可分享/删除 |
| 闪光灯 | `Engine/TorchCenter.swift` 用 `AVCaptureDevice.torchMode` 真开关 |
| 头像 | `Engine/AvatarStore.swift`：PHPicker 选图 → 居中裁方 → 512px PNG 存 Documents；个人中心的圆按实测几何 (171.5, 369.5)/r=108 覆盖，不会错位 |
| 相册选图 | 系统 `PHPickerViewController`，无需相册权限声明；器物首页「相册上传」进页面即弹 |
| 拍摄识别 | 系统相机（`UIImagePickerController(.camera)`，需 `NSCameraUsageDescription`）；无摄像头设备如实说明并给相册退路 |
| 器物识别 | `Engine/ArtifactRecognizer.swift`：Vision 特征指纹 + 颜色直方图，与本机 4 件参照器物做**离线**相似度排序；相似度不足时明说「未能可靠识别」 |
| 器物报告 | `Engine/ArtifactProfile.swift` 把「名称·朝代·属性·简介·纹样·寓意·时代风格·纹样图」八项凑齐，三层降级：命中参照库 → 用库里真数据；未命中且有 key → DeepSeek 视觉模型生成；都没有 → 本地推断（只写主色与器形近似度，朝代写「待考」）。报告顶部标来源，纹样图优先用**你照片里裁出的局部** |
| 最近足迹 | 进首页/汴京/茶坊/城池详情都会记一笔；「我的」底部三张卡与 `/native/list/footprints` 同源，可空态、可去重 |
| AI 本地规则 | `Engine/AIBridge.swift` 未配 key 时走本地规则引擎（模板 + 意象库 + 押韵校验） |

**模拟 / 未做**

| 项 | 现状 |
|---|---|
| 器物识别精度 | 参照库只有工程里那 4 张器物插画，**不是训练过的器物分类器**；给的是相对相似度排序，不是"识别准确率" |
| 器物报告准确性 | 命中参照库的八项是真数据；未命中时由 DeepSeek 视觉模型（`deepseek-flash`）看图生成，**会出错**——界面标「在线识别 · 仅供参考」，器物命名与断代以实物考据为准 |
| 江雪视频 | 无视频素材，播放键用朗读替代（有声音，无画面） |
| 四画风原图 | 工程只有一张江雪图；四种画风是 Core Image **滤镜风格化**，不是 AI 生成的同构图原图 |
| AI 在线生成 | 两条通道共用 `Engine/AIBridge.swift`。文本（题注/对谈/意象）与视觉（古物识趣报告）都只在配了 key 时联网；key 来源：Info.plist `YimengAIKey` ＞ 环境变量 `YIMENG_AI_KEY`。仓库里**永远留空**，真机包由 `.github/workflows/ios-device-ipa.yml` 用 `secrets.YIMENG_AI_KEY` 临时写入 |
| 位图里的静态状态栏 | 25 屏顶部烤着 `9:41`，而系统状态栏被全局隐藏（另有 22 个原生页本来就没状态栏）。改它要给 25 张图重新对齐全部像素叠层，本轮未做 |

> 三条硬原则：不把规则引擎说成语言模型、断网演示不塞联网功能、没有评测集不报准确率。

## 链接

- [09-大整改结论](../ios优化方案/09-大整改结论.md) —— 交付数字、22 类原生路由、第 27–30 轮整改、剩余缺口
- [06-热区修改手册](../ios优化方案/06-热区修改手册.md) —— 热区坐标怎么改、编辑器怎么用
- [项目结构与构建](docs/项目结构与构建.md) · [转换架构说明](docs/转换架构说明.md)

> 前两条在 `ios/` 仓库**之外**（本机同级目录 `ios优化方案/`），本地可点，GitHub 网页上不可点；后两条在仓库内。

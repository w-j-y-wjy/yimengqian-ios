// NativePhotoPickView.swift
//
// 「古物识趣」的取图 + 识别页（相册上传 / 拍摄识别 / 结果页的相册入口）。
//
// 2026-10-27 重做，原因有两个真问题：
// 1) 器物首页的「相册上传」热区原本是 `delayedNavigate → /artifact/result`，
//    点了只弹一句「已选择相册上传模拟」再跳到**别人写死的结果页** —— 等于没接；
//    「拍摄识别」同理。结果页里的「相册」按钮反而是唯一能真的选图的地方，
//    于是用户看到的就是"旁边的相册上传没有用，示例体验里倒能用"。
// 2) 选完图之后只有一句"识物模型待接入"，没有任何真实输出。
//
// 现在：
// - `album`  → 进页面即弹系统相册（PHPicker，无需相册权限）
// - `camera` → 进页面即拉起系统相机；模拟器/无摄像头设备如实说明并给相册退路
// - `manual` → 结果页那颗「相册」按钮，不抢焦点，由用户自己点
// - 取到图后调用 ArtifactRecognizer（Vision 特征指纹 + 颜色直方图）做**本地比对**，
//   给出相似度排序；相似度不够就明说「未能可靠识别」，不硬猜。
//
// 诚实边界：参照库只有工程里那几件器物插画，这不是训练出来的器物分类器。

import SwiftUI
import PhotosUI
import UIKit

struct ArtifactRecognizeView: View {
    /// album / camera / manual
    let source: String

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var toast: ToastCenter

    @State private var picked: UIImage?
    @State private var matches: [ArtifactMatch] = []
    @State private var isAnalyzing = false
    @State private var sheet: CaptureSource?
    @State private var didAutoPresent = false
    /// 八项器物报告（库 / 在线模型 / 本地推断，由 ArtifactProfileBuilder 保证有值）
    @State private var profile: ArtifactProfile?
    /// 报告正在生成（在线识别时这一步要 4–15 秒，必须有独立的进度文案）
    @State private var isDescribing = false
    /// CI 截图用的演示开关，正常使用不会触发
    @State private var didRunDemo = false

    private enum CaptureSource: String, Identifiable {
        case album, camera
        var id: String { rawValue }
    }

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("识别古物")
                        .font(.custom("KaitiSC-Bold", size: 26))
                        .foregroundColor(Theme.ink)
                    Text(sourceHint)
                        .font(.custom("SongtiSC-Regular", size: 12.5))
                        .foregroundColor(Theme.inkMuted)
                        .lineSpacing(3)

                    // 有报告时不再单独显示原图：报告里已经有一张同样的照片，
                    // 两张叠着排会让人以为选了两张（CI 截图复现过）。
                    if let picked = picked, profile == nil {
                        Image(uiImage: picked)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 210)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 0.8)
                            )
                    }

                    if isAnalyzing || isDescribing {
                        progressBlock
                    }

                    if let profile = profile {
                        profileBlock(profile)
                        if !matches.isEmpty {
                            matchesDetail
                        }
                    } else if !matches.isEmpty {
                        resultBlock
                    }

                    sourceButtons

                    if picked == nil && !isAnalyzing {
                        referenceRow
                        howToSteps
                        exampleRow
                    }

                    disclaimer

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 96)
            }

            topBar
        }
        .sheet(item: $sheet) { target in
            switch target {
            case .album:
                PhotoPicker { image in
                    sheet = nil
                    handle(image)
                }
            case .camera:
                CameraPicker { image in
                    sheet = nil
                    handle(image)
                }
            }
        }
        .onAppear {
            runDemoIfNeeded()
            autoPresentIfNeeded()
        }
    }

    // MARK: - 文案

    private var sourceHint: String {
        switch source {
        case "camera":
            return cameraAvailable
                ? "对准器物整体，尽量避开杂乱背景；拍完先在本机比对，再生成八项器物报告。"
                : "这台设备没有可用的摄像头（模拟器不支持拍摄）。可以先用相册里的照片试一次。"
        case "album":
            return "从相册选一张器物照片，选完先在本机比对，再生成八项器物报告。"
        default:
            return "选一张器物的照片，或者直接拍一张。比对全部在本机完成；只有未命中参照库且配置了 AI 通道时，才会把压过的照片发出去生成文案。"
        }
    }

    // MARK: - 结果

    private var resultBlock: some View {
        let top = matches[0]
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Rectangle().fill(Theme.vermilion).frame(width: 3, height: 13)
                Text(top.confident ? "比对结果" : "未能可靠识别")
                    .font(.custom("KaitiSC-Bold", size: 15))
                    .foregroundColor(Theme.ink)
            }
            if !top.confident {
                Text("相似度都不高。下面是本地参照库里最接近的几件，仅供参考。")
                    .font(.custom("SongtiSC-Regular", size: 11.5))
                    .foregroundColor(Theme.inkMuted)
            }

            ForEach(Array(matches.prefix(3).enumerated()), id: \.element.id) { pair in
                matchRow(pair.element, rank: pair.offset)
            }

            if top.confident {
                HStack(spacing: 10) {
                    Button(action: { router.navigate(route: "/native/artifact/\(top.id)") }) {
                        Text("查看详情")
                            .font(.custom("SongtiSC-Regular", size: 14))
                            .foregroundColor(Theme.paperLight)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Capsule().fill(Theme.vermilion))
                    }
                    .buttonStyle(PressableStyle())

                    Button(action: { toggleFavorite(top) }) {
                        HStack(spacing: 5) {
                            Image(systemName: isFavorite(top) ? "star.fill" : "star")
                                .font(.system(size: 12, weight: .semibold))
                            Text(isFavorite(top) ? "已收藏" : "收藏")
                                .font(.custom("SongtiSC-Regular", size: 14))
                        }
                        .foregroundColor(Theme.vermilion)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .overlay(Capsule().strokeBorder(Theme.vermilion.opacity(0.7), lineWidth: 1))
                    }
                    .buttonStyle(PressableStyle())
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - 报告与进度

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(Theme.vermilion)
                Text(progressText)
                    .font(.custom("SongtiSC-Regular", size: 13))
                    .foregroundColor(Theme.inkLight)
            }
            if !isAnalyzing && AIBridge.shared.hasKey {
                Text("在线识别通常需要 4–15 秒；断网或超时会自动回落到本地推断，不会卡住。")
                    .font(.custom("SongtiSC-Regular", size: 10.5))
                    .foregroundColor(Theme.inkMuted)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }

    private var progressText: String {
        if isAnalyzing { return "正在比对本地参照器物…" }
        return AIBridge.shared.hasKey ? "正在生成器物报告（在线识别）…" : "正在生成器物报告…"
    }

    /// 八项报告。这是本页的主角：选完图先给报告，比对明细退居其后。
    private func profileBlock(_ p: ArtifactProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Rectangle().fill(Theme.vermilion).frame(width: 3, height: 13)
                Text("器物报告")
                    .font(.custom("KaitiSC-Bold", size: 15))
                    .foregroundColor(Theme.ink)
                Spacer(minLength: 0)
                if profile != nil {
                    Button(action: { self.profile = nil }) {
                        Text("收起")
                            .font(.custom("SongtiSC-Regular", size: 11))
                            .foregroundColor(Theme.inkMuted)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            ArtifactProfileView(profile: p, onOpenLibrary: { id in
                router.navigate(route: "/native/artifact/\(id)")
            })
        }
    }

    /// 比对明细：报告之下的一条次要信息，保留"为什么给出这个结果"的可解释性
    private var matchesDetail: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Rectangle().fill(Theme.goldBorder).frame(width: 3, height: 12)
                Text("视觉比对明细 · \(ContentData.artifacts.count) 件参照")
                    .font(.custom("KaitiSC-Bold", size: 13))
                    .foregroundColor(Theme.inkLight)
            }
            ForEach(Array(matches.prefix(3).enumerated()), id: \.element.id) { pair in
                matchRow(pair.element, rank: pair.offset)
            }
        }
    }

    private func matchRow(_ match: ArtifactMatch, rank: Int) -> some View {
        HStack(spacing: 10) {
            thumbnail(match.image)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(match.name)
                        .font(.custom("KaitiSC-Bold", size: 15))
                        .foregroundColor(Theme.ink)
                    Text("\(match.dynasty) · \(match.type)")
                        .font(.custom("SongtiSC-Regular", size: 10.5))
                        .foregroundColor(Theme.inkMuted)
                }
                HStack(spacing: 6) {
                    Capsule()
                        .fill(Theme.barTrack)
                        .frame(width: 96, height: 4)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(rank == 0 && match.confident ? Theme.vermilion : Theme.goldBorder)
                                .frame(width: 96 * CGFloat(max(0.04, min(1, match.score))), height: 4)
                        }
                    Text(match.bandText)
                        .font(.custom("SongtiSC-Regular", size: 10.5))
                        .foregroundColor(Theme.inkMuted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.paperLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.goldBorder.opacity(0.45), lineWidth: 0.8)
        )
    }

    @ViewBuilder
    private func thumbnail(_ path: String, side: CGFloat = 54) -> some View {
        if let img = AssetLoader.image(path) {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: side, height: side)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.paperWarm)
                .frame(width: side, height: side)
        }
    }

    // MARK: - 取图按钮

    private var sourceButtons: some View {
        HStack(spacing: 10) {
            Button(action: { sheet = .album }) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle").font(.system(size: 13, weight: .semibold))
                    Text(picked == nil ? "从相册选择" : "换一张")
                        .font(.custom("SongtiSC-Regular", size: 14))
                }
                .foregroundColor(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Capsule().fill(Theme.paperLight))
                .overlay(Capsule().strokeBorder(Theme.goldBorder.opacity(0.6), lineWidth: 0.8))
            }
            .buttonStyle(PressableStyle())

            if cameraAvailable {
                Button(action: { sheet = .camera }) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera").font(.system(size: 13, weight: .semibold))
                        Text("拍摄识别")
                            .font(.custom("SongtiSC-Regular", size: 14))
                    }
                    .foregroundColor(Theme.paperLight)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Theme.vermilion))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    /// 本机参照库：把要比对的 4 件器物直接摆出来。
    /// 这一块不是为了好看 —— 它让"识别"这件事变得可解释：用户看得到比对基准，
    /// 也就明白为什么结果只可能是这 4 件里的一件，而不会以为是通用识物模型。
    private var referenceRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Rectangle().fill(Theme.vermilion).frame(width: 3, height: 13)
                Text("本机参照库 · \(ContentData.artifacts.count) 件")
                    .font(.custom("KaitiSC-Bold", size: 15))
                    .foregroundColor(Theme.ink)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ContentData.artifacts) { artifact in
                        Button(action: { router.navigate(route: "/native/artifact/\(artifact.id)") }) {
                            VStack(alignment: .leading, spacing: 5) {
                                thumbnail(artifact.image, side: 96)
                                    .frame(width: 96, height: 96)
                                Text(artifact.name)
                                    .font(.custom("SongtiSC-Regular", size: 11))
                                    .foregroundColor(Theme.inkLight)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .frame(width: 96, alignment: .leading)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    /// 三步说明：写"会发生什么"，比写"请对准器物"有用
    private var howToSteps: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Rectangle().fill(Theme.vermilion).frame(width: 3, height: 13)
                Text("怎么用")
                    .font(.custom("KaitiSC-Bold", size: 15))
                    .foregroundColor(Theme.ink)
            }
            ForEach(Array(Self.steps.enumerated()), id: \.offset) { pair in
                HStack(alignment: .top, spacing: 8) {
                    Text(verbatim: "\(pair.offset + 1)")
                        .font(.custom("SongtiSC-Regular", size: 11))
                        .foregroundColor(Theme.paperLight)
                        .frame(width: 17, height: 17)
                        .background(Circle().fill(Theme.vermilion.opacity(0.85)))
                    Text(pair.element)
                        .font(.custom("SongtiSC-Regular", size: 12.5))
                        .foregroundColor(Theme.inkLight)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    /// 没照片也能先看结果长什么样（走原本的示例结果页，页面上有「示例体验」的牌子）
    private var exampleRow: some View {
        Button(action: { router.navigate(route: "/artifact/result") }) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles").font(.system(size: 12, weight: .semibold))
                Text("先看一份示例结果")
                    .font(.custom("SongtiSC-Regular", size: 13.5))
            }
            .foregroundColor(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Capsule().fill(Theme.paperLight))
            .overlay(Capsule().strokeBorder(Theme.goldBorder.opacity(0.55), lineWidth: 0.8))
        }
        .buttonStyle(PressableStyle())
    }

    private static let steps: [String] = [
        "拍下或选一张器物照片（整体入镜更准）",
        "在本机与 4 件参照器物比对视觉特征",
        "生成器物报告：名称、朝代、属性、简介、纹样、寓意、时代风格、纹样图",
        "报告顶部标出来源：本机参照库 / 在线识别 / 本地推断",
    ]

    private var disclaimer: some View {
        Text(disclaimerText)
            .font(.custom("SongtiSC-Regular", size: 10.5))
            .foregroundColor(Theme.inkMuted.opacity(0.9))
            .lineSpacing(2)
            .padding(.top, 2)
    }

    private var disclaimerText: String {
        let local = "在本机与 \(ArtifactRecognizer.shared.referenceCount) 件参照器物做视觉特征比对（Vision 特征指纹 + 颜色分布），不联网、不上传照片。"
        if AIBridge.shared.hasKey {
            return "识别分两层：\(local)命中参照库就用库里的真数据；未命中才把照片压到长边 768 后发给 DeepSeek 视觉模型生成八项文案。生成内容仅供参考，器物命名与断代以实物考据为准。"
        }
        return "识别方式：\(local)当前未配置 AI 通道，因此只做比对与本地推断，不做断代推测。"
    }

    // MARK: - 顶栏

    private var topBar: some View {
        HStack {
            Button(action: { router.closeNative() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                    Text("返回").font(.custom("SongtiSC-Regular", size: 14))
                }
                .foregroundColor(Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Theme.paperLight))
                .overlay(Capsule().strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 0.8))
            }
            .buttonStyle(PressableStyle())
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 54)
    }

    // MARK: - 行为

    /// 相册/拍摄入口"一进来就弹"：让首页那颗按钮真的等于"打开相册"。
    /// 用一个小延时而不是直接在 onAppear 里弹 —— 视图还没进窗口时 present 会被系统忽略。
    private func autoPresentIfNeeded() {
        guard !didAutoPresent else { return }
        didAutoPresent = true
        switch source {
        case "album":
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { sheet = .album }
        case "camera":
            if cameraAvailable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { sheet = .camera }
            }
        default:
            break
        }
    }

    private func handle(_ image: UIImage) {
        picked = image
        matches = []
        profile = nil
        isAnalyzing = true
        ArtifactRecognizer.shared.recognize(image) { result in
            isAnalyzing = false
            matches = result
            if result.first?.confident == true {
                Haptics.tap()
            }
            buildProfile(image: image, matches: result)
        }
    }

    /// 报告生成：库命中是同步的（几十毫秒），在线识别要等网络。
    /// 两条路都保证有回调，所以界面上不会出现"转完圈什么都没有"。
    private func buildProfile(image: UIImage, matches: [ArtifactMatch]) {
        isDescribing = true
        ArtifactProfileBuilder.shared.build(image: image, matches: matches) { result in
            isDescribing = false
            profile = result
            if result.source == .remote {
                Haptics.tap()
            }
        }
    }

    /// CI 截图用：`-demoRecognize qinghua-ping` 把库图当作"刚拍到的照片"跑完整流程；
    /// 传 `generic` 则用一张与器物无关的图（人物画像，视觉特征差得远，必走"未命中"分支）。
    /// 正式使用时 UserDefaults 里没有这个键，不会触发。
    private func runDemoIfNeeded() {
        guard !didRunDemo, let token = UserDefaults.standard.string(forKey: "demoRecognize") else { return }
        didRunDemo = true
        let path: String? = ContentData.artifacts.first(where: { $0.id == token })?.image
            ?? (token == "generic" ? "ArtApp/character-sushi.jpg" : nil)
        guard let assetPath = path, let image = AssetLoader.image(assetPath) else { return }
        didAutoPresent = true
        handle(image)
    }

    private func isFavorite(_ match: ArtifactMatch) -> Bool {
        store.isFavorite(type: .artifact, itemId: match.id)
    }

    private func toggleFavorite(_ match: ArtifactMatch) {
        let added = store.toggleFavorite(type: .artifact, itemId: match.id)
        store.applyReward(RewardRule(culture: added ? 5 : -5))
        toast.show(added ? "已收藏「\(match.name)」" : "已取消收藏")
    }
}

/// PHPicker 的 SwiftUI 桥接：单选、只取图片
struct PhotoPicker: UIViewControllerRepresentable {
    let onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let controller = PHPickerViewController(configuration: config)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onPick: (UIImage) -> Void
        init(onPick: @escaping (UIImage) -> Void) { self.onPick = onPick }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage else { return }
                DispatchQueue.main.async { self.onPick(image) }
            }
        }
    }
}

/// 系统相机（拍照即取图）。模拟器没有相机 → 调用方先判断 isSourceTypeAvailable(.camera)。
/// 为什么用 UIImagePickerController 而不是自绘取景框：系统相机自带对焦/曝光/快门，
/// 在真机上更稳，也不会因为自绘预览层算错方向把照片拍歪。
struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage { onCapture(image) }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

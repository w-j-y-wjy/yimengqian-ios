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

                    if let picked = picked {
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

                    if isAnalyzing {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(Theme.vermilion)
                            Text("正在比对本地参照器物…")
                                .font(.custom("SongtiSC-Regular", size: 13))
                                .foregroundColor(Theme.inkLight)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                    }

                    if !matches.isEmpty {
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
        .onAppear(perform: autoPresentIfNeeded)
    }

    // MARK: - 文案

    private var sourceHint: String {
        switch source {
        case "camera":
            return cameraAvailable
                ? "对准器物整体，尽量避开杂乱背景；拍完会在本机做特征比对。"
                : "这台设备没有可用的摄像头（模拟器不支持拍摄）。可以先用相册里的照片试一次。"
        case "album":
            return "从相册选一张器物照片，选完会在本机做特征比对。"
        default:
            return "选一张器物的照片，或者直接拍一张。比对全部在本机完成，不联网。"
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
        "得到最接近的几件，点开看详情与纹样",
    ]

    private var disclaimer: some View {
        Text("识别方式：在本机与 \(ArtifactRecognizer.shared.referenceCount) 件参照器物做视觉特征比对（Vision 特征指纹 + 颜色分布），不联网、不上传照片。相似度是相对排序，不是训练模型给出的概率。")
            .font(.custom("SongtiSC-Regular", size: 10.5))
            .foregroundColor(Theme.inkMuted.opacity(0.9))
            .lineSpacing(2)
            .padding(.top, 2)
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
        isAnalyzing = true
        ArtifactRecognizer.shared.recognize(image) { result in
            isAnalyzing = false
            matches = result
            if result.first?.confident == true {
                Haptics.tap()
            }
        }
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

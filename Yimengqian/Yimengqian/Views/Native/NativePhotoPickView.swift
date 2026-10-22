// NativePhotoPickView.swift
//
// 器物识别的「相册」入口 —— 之前只弹「闪光灯模拟」/跳回器物首页，等于没接。
//
// 这里接系统相册选择器（PHPickerViewController，iOS 14+，不需要相册权限声明）：
// 选一张图 → 取回来 → 直接进识别结果页。真实识别（物体检测）需要模型，
// 当前没有，所以**不假装识别出具体器物**，而是把选中的图显示出来并说明「识别能力待接入」。
//
// 为什么这样更诚实：把任意一张照片说成「青花缠枝莲纹瓶」是假结论；
// 显示用户选的图 + 明确说明，才是可用且不误导的最小闭环。

import SwiftUI
import PhotosUI

struct NativePhotoPickView: View {
    @EnvironmentObject private var router: Router

    @State private var picked: UIImage?
    @State private var isPicking = false

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("从相册识别")
                    .font(.custom("KaitiSC-Bold", size: 26))
                    .foregroundColor(Theme.ink)
                    .padding(.top, 96)

                Text("选一张器物的照片。当前版本只会显示你选中的照片，自动识物能力待接入模型。")
                    .font(.custom("SongtiSC-Regular", size: 12.5))
                    .foregroundColor(Theme.inkMuted)
                    .lineSpacing(3)

                if let picked = picked {
                    Image(uiImage: picked)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 0.8)
                        )
                    Text("已选择这张照片 · 识物模型待接入")
                        .font(.custom("SongtiSC-Regular", size: 12))
                        .foregroundColor(Theme.inkMuted)
                }

                Button(action: { isPicking = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle").font(.system(size: 15, weight: .semibold))
                        Text(picked == nil ? "选择照片" : "重新选择")
                            .font(.custom("SongtiSC-Regular", size: 15))
                    }
                    .foregroundColor(Theme.paperWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(Theme.vermilion))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)

            topBar
        }
        .sheet(isPresented: $isPicking) {
            PhotoPicker { image in
                picked = image
                isPicking = false
            }
        }
    }

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
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 54)
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
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage else { return }
                DispatchQueue.main.async { self.onPick(image) }
            }
        }
    }
}

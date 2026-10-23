// AvatarStore.swift
//
// 用户头像 —— 从「头像画在位图里、改不了」变成「可以真的选一张图换掉」。
//
// 实现要点：
// 1) 用 PHPickerViewController 选图（iOS 14+，**不需要相册权限声明**）；
// 2) 存成 PNG 落到 Documents/avatar.png，只在 UserDefaults 里存**文件名**。
//    不存绝对路径：iOS 沙盒路径每次安装都会变，存绝对路径下次启动就失效（踩过这坑）。
// 3) 个人中心的圆形头像位有像素叠层（ProfileLayer.avatarImage），
//    这里只负责"存取与裁剪"，渲染交给视图层。
// 4) 换头像后圆形外的纸纹和其它元素都保持位图原样 —— 只盖住那个圆。

import UIKit
import SwiftUI
// PHPicker* 全部定义在 PhotosUI 里：只 import UIKit 会报 "cannot find type PHPickerViewController"。
// NativePhotoPickView 之所以没踩到，是因为它本来就 import 了 PhotosUI。
import PhotosUI

enum AvatarStore {
    /// Documents 下的固定文件名（覆盖写，不累积占位文件）
    private static let fileName = "avatar.png"

    /// 头像文件的绝对路径（沙盒路径每次启动重新算，所以不能缓存）
    static var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName)
    }

    /// 当前是否有用户自选头像
    static var hasCustomAvatar: Bool {
        guard let url = fileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// 读取用户头像；没有就返回 nil（调用方回落到位图里的默认头像）
    static func load() -> UIImage? {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// 保存选中的图：先**居中裁成正方形**再存。
    /// 为什么要裁：头像位是个圆，直接存原图会在圆里显示成压扁/偏移的脸；
    /// 按短边居中裁切是 iOS 通讯录、微信等一致的做法。
    @discardableResult
    static func save(_ image: UIImage) -> Bool {
        let side = min(image.size.width, image.size.height)
        let origin = CGPoint(x: (image.size.width - side) / 2, y: (image.size.height - side) / 2)
        let cropped: UIImage
        if let cg = image.cgImage?.cropping(to: CGRect(origin: CGPoint(x: origin.x * image.scale,
                                                                      y: origin.y * image.scale),
                                                       size: CGSize(width: side * image.scale,
                                                                    height: side * image.scale))) {
            cropped = UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
        } else {
            cropped = image
        }
        // 统一缩放到 512px，避免把 4000px 的原图塞进 UserDefaults 沙盒
        let target: CGFloat = 512
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: target, height: target))
        let resized = renderer.image { _ in
            cropped.draw(in: CGRect(x: 0, y: 0, width: target, height: target))
        }
        guard let url = fileURL, let data = resized.pngData() else { return false }
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// 清除自选头像（恢复设计稿形象）
    static func clear() {
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

/// PHPicker 的 SwiftUI 桥接：单选、只取图片。
/// 与 NativePhotoPickView 里那份的区别：那份用于"器物识别"，这份用于"换头像"，
/// 两者职责不同，合并会让调用方被迫处理无关状态。
struct AvatarPicker: UIViewControllerRepresentable {
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

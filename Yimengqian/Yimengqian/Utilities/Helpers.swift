// Helpers.swift
//
// 来源：由 React 原型 ImageScreen 的图片加载与热区点击反馈需求拆分而来，
//       适配 iOS bundle 的资源打包方式。
// 用途：AssetLoader 从 bundle 加载屏幕背景图（兼容文件夹引用打包的两种路径形态）；
//       Haptics 提供热区点击的轻触反馈。
//
// 字体为回退策略，可不依赖（详见 Theme.swift 文件头说明）。

import UIKit

enum AssetLoader {
    /// 设计稿是 2 MB 级大图，单张解码约 6 MiB。
    /// 用 NSCache 而不是静态字典：系统内存告警时会自动回收，
    /// 再叠加数量/体积上限，避免"访遍 25 屏 ≈ 150 MiB 常驻"。
    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 8
        c.totalCostLimit = 64 * 1024 * 1024   // 64 MiB
        return c
    }()

    /// 加载 bundle 内图片：资源以文件夹引用（folder reference）打包，路径形如 Content/Screens/xxx.png。
    /// 兼容两种打包结果：bundle 根下 "Screens/xxx.png" 或 "Content/Screens/xxx.png"。
    static func image(_ bundlePath: String) -> UIImage? {
        let key = bundlePath as NSString
        if let img = cache.object(forKey: key) { return img }
        let candidates = Self.candidates(for: bundlePath)
        for p in candidates {
            if let img = UIImage(contentsOfFile: p) {
                // cost 按解码后的位图字节数估算：像素宽 × 像素高 × 4（RGBA）
                let pixelsW = img.size.width * img.scale
                let pixelsH = img.size.height * img.scale
                let cost = Int(pixelsW * pixelsH * 4)
                cache.setObject(img, forKey: key, cost: cost)
                return img
            }
        }
        return nil
    }

    private static func candidates(for bundlePath: String) -> [String] {
        let base = Bundle.main.resourceURL ?? Bundle.main.bundleURL
        var out: [String] = []
        let trimmed = bundlePath.hasPrefix("/") ? String(bundlePath.dropFirst()) : bundlePath
        out.append(base.appendingPathComponent(trimmed).path)                 // Screens/x.png
        out.append(base.appendingPathComponent("Content").appendingPathComponent(trimmed).path) // Content/Screens/x.png
        return out
    }
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}

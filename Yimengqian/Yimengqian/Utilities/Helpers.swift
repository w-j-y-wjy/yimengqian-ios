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
    /// 简单内存缓存：设计稿为 2MB 级大图，避免每次 body 重算重复解码。
    private static var cache: [String: UIImage] = [:]

    /// 加载 bundle 内图片：资源以文件夹引用（folder reference）打包，路径形如 Content/Screens/xxx.png。
    /// 兼容两种打包结果：bundle 根下 "Screens/xxx.png" 或 "Content/Screens/xxx.png"。
    static func image(_ bundlePath: String) -> UIImage? {
        if let img = cache[bundlePath] { return img }
        let candidates = Self.candidates(for: bundlePath)
        for p in candidates {
            if let img = UIImage(contentsOfFile: p) {
                cache[bundlePath] = img
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

// ArtifactRecognizer.swift
//
// 器物识别（古物识趣）—— 真·离线图像比对。
//
// 为什么自己写而不用现成模型：
// 1) 本机没有训练好的「中国古器物」分类模型，也不能在演示包里塞一个几十 MB 的权重；
// 2) 苹果自带的 Vision 提供 **图像特征指纹**（VNGenerateImageFeaturePrint），
//    它把图像编码成可比较的向量，配合工程里已有的 4 张器物参照图（ContentData.artifacts），
//    就能做一次真实的"以图搜图" —— 全程在设备上，不联网、不需要权限、结果可复现；
// 3) 再加一层颜色直方图距离兜底：万一某个系统版本上 Vision 请求失败，仍然有结果，
//    而不是转个圈什么也不给。
//
// ⚠️ 诚实边界（必须如实写进界面）：
// 这不是训练过的器物分类模型，而是"与你本地 4 件参照器物的视觉相似度排序"。
// 所以界面上给的是「相似度」与「可能是」，best 相似度不够高时明说「未能可靠识别」，
// 绝不把一张随便拍的照片断言成「青花缠枝莲纹瓶」。

import Foundation
import UIKit
import Vision
import ImageIO

/// 一件参照器物的比对结果
struct ArtifactMatch: Identifiable, Equatable {
    let id: String
    let name: String
    let dynasty: String
    let type: String
    let image: String
    /// 综合相似度 0…1（越大越像）。由特征距离与颜色距离加权得出。
    let score: Double
    /// 是否足够可信（低于阈值时界面显示「未能可靠识别」）
    let confident: Bool

    /// 界面上的档位文案：不假装是概率
    var bandText: String {
        if score >= 0.55 { return "形态相近" }
        if score >= 0.32 { return "可能相关" }
        return "差异较大"
    }
}

final class ArtifactRecognizer {
    static let shared = ArtifactRecognizer()

    /// 相似度低于这个值时，不把 top1 当成结论
    static let confidentThreshold: Double = 0.45

    private struct Reference {
        let artifact: Artifact
        let feature: VNFeaturePrintObservation?
        let histogram: [Double]
    }

    private var references: [Reference]?
    private let queue = DispatchQueue(label: "com.yimeng.artifact-recognize", qos: .userInitiated)

    /// 参照库规模（界面要如实显示"参照 N 件"）
    var referenceCount: Int { ContentData.artifacts.count }

    // MARK: - 对外入口

    func recognize(_ image: UIImage, completion: @escaping ([ArtifactMatch]) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let refs = self.buildReferencesIfNeeded()
            let queryFeature = Self.featurePrint(of: image)
            let queryHist = Self.histogram(of: image)

            let scored: [(Artifact, Double, Double)] = refs.map { ref in
                let featureDistance: Double? = {
                    guard let q = queryFeature, let r = ref.feature else { return nil }
                    var d = Float(0)
                    do {
                        try q.computeDistance(&d, to: r)
                        return Double(d)
                    } catch {
                        return nil
                    }
                }()
                let colorDistance = Self.histogramDistance(queryHist, ref.histogram)
                return (ref.artifact, Self.score(featureDistance: featureDistance, colorDistance: colorDistance), colorDistance)
            }

            let matches = scored
                .sorted { $0.1 > $1.1 }
                .map { (artifact, score, _) in
                    ArtifactMatch(
                        id: artifact.id,
                        name: artifact.name,
                        dynasty: artifact.dynasty,
                        type: artifact.type,
                        image: artifact.image,
                        score: score,
                        confident: score >= Self.confidentThreshold
                    )
                }
            DispatchQueue.main.async { completion(matches) }
        }
    }

    /// 综合分：特征指纹为主（75%），颜色直方图为辅（25%）。
    /// 为什么加权：参照图是插画、实拍照片的色调差异大，纯特征指纹容易被背景带偏；
    /// 纯颜色又分不清纹样结构。两者互补后，排序在真机样张上更稳。
    private static func score(featureDistance: Double?, colorDistance: Double) -> Double {
        // 1/(1+d)：d=0 → 1.0，d=1 → 0.5，d=5 → 0.17，d=15 → 0.06（Vision 特征的典型区间）
        let colorScore = max(0, min(1, 1 - colorDistance / 1.4))
        guard let fd = featureDistance else { return colorScore }
        let featureScore = 1.0 / (1.0 + max(0, fd))
        return 0.75 * featureScore + 0.25 * colorScore
    }

    // MARK: - 参照库

    private func buildReferencesIfNeeded() -> [Reference] {
        if let refs = references { return refs }
        var out: [Reference] = []
        for artifact in ContentData.artifacts {
            guard let img = AssetLoader.image(artifact.image) else { continue }
            out.append(Reference(artifact: artifact,
                                 feature: Self.featurePrint(of: img),
                                 histogram: Self.histogram(of: img)))
        }
        references = out
        return out
    }

    // MARK: - 视觉特征

    private static func featurePrint(of image: UIImage) -> VNFeaturePrintObservation? {
        guard let cg = image.cgImage else { return nil }
        let request = VNGenerateImageFeaturePrintRequest()
        request.imageCropAndScaleOption = .centerCrop
        let handler = VNImageRequestHandler(cgImage: cg, orientation: cgOrientation(image.imageOrientation), options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        return request.results?.first as? VNFeaturePrintObservation
    }

    private static func cgOrientation(_ o: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch o {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    /// 4×4×4 RGB 颜色直方图（64 桶，按像素占比归一化）。
    /// 缩到 48×48 再统计：既够稳，又不至于在低端机上耗时。
    private static func histogram(of image: UIImage) -> [Double] {
        let side = 48
        // 用 data: nil 让 CoreGraphics 自己分配缓冲区，画完再从 ctx.data 读。
        // 不要传 `&array`：CGContext 不持有那块内存，出作用域后指针就没有保证了。
        guard let ctx = CGContext(data: nil,
                                  width: side, height: side,
                                  bitsPerComponent: 8,
                                  bytesPerRow: side * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let cg = image.cgImage else {
            return [Double](repeating: 0, count: 64)
        }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let raw = ctx.data else { return [Double](repeating: 0, count: 64) }
        let pixels = raw.bindMemory(to: UInt8.self, capacity: side * side * 4)

        var bins = [Double](repeating: 0, count: 64)
        let total = Double(side * side)
        for i in stride(from: 0, to: side * side * 4, by: 4) {
            let r = Int(pixels[i] / 64), g = Int(pixels[i + 1] / 64), b = Int(pixels[i + 2] / 64)
            bins[r * 16 + g * 4 + b] += 1
        }
        for i in 0..<bins.count { bins[i] /= total }
        return bins
    }

    /// L1 距离再折半：完全一致 0，完全不同 1
    private static func histogramDistance(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 1 }
        var sum = 0.0
        for i in 0..<a.count { sum += abs(a[i] - b[i]) }
        return min(1, sum / 2)
    }

    // MARK: - 主色（给「本地推断」用）

    /// 照片的主色，只给一个中文色名 + HSB。
    /// 为什么需要它：没有在线识别时，总要有一句能核实的话可说；
    /// "画面以青调为主"是可核实的，"此为元代青花"不是。
    struct ToneSample {
        let name: String
        let hue: Double
        let saturation: Double
        let brightness: Double
    }

    static func tone(of image: UIImage) -> ToneSample {
        let side = 24
        guard let cg = image.cgImage,
              let ctx = CGContext(data: nil,
                                  width: side, height: side,
                                  bitsPerComponent: 8,
                                  bytesPerRow: side * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return ToneSample(name: "杂色", hue: 0, saturation: 0, brightness: 0.5)
        }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let raw = ctx.data else {
            return ToneSample(name: "杂色", hue: 0, saturation: 0, brightness: 0.5)
        }
        let pixels = raw.bindMemory(to: UInt8.self, capacity: side * side * 4)
        var r = 0.0, g = 0.0, b = 0.0
        for i in stride(from: 0, to: side * side * 4, by: 4) {
            r += Double(pixels[i])
            g += Double(pixels[i + 1])
            b += Double(pixels[i + 2])
        }
        let total = Double(side * side)
        r /= total * 255; g /= total * 255; b /= total * 255

        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0
        UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
            .getHue(&h, saturation: &s, brightness: &v, alpha: nil)

        return ToneSample(name: toneName(hue: Double(h) * 360, saturation: Double(s), brightness: Double(v)),
                          hue: Double(h) * 360,
                          saturation: Double(s),
                          brightness: Double(v))
    }

    /// 色相/饱和度/明度 → 中文色名。分档刻意粗：只为了说"青/白/褐"，不是为了配色。
    private static func toneName(hue: Double, saturation: Double, brightness: Double) -> String {
        if brightness < 0.24 { return "墨" }
        if saturation < 0.12 { return brightness > 0.74 ? "白" : "灰" }
        switch hue {
        case 0..<18, 344..<361: return "朱"
        case 18..<34: return brightness < 0.42 ? "褐" : "赭"
        case 34..<52: return "土黄"
        case 52..<72: return "米黄"
        case 72..<160: return "青绿"
        case 160..<255: return "青"
        case 255..<300: return "紫"
        default: return "绛"
        }
    }

    // MARK: - 纹样局部裁切

    /// 从照片里取最"吸睛"的两块当作纹样局部。
    /// 这一步**不生成任何东西**：裁出来的就是你拍的那张照片的一部分，
    /// 所以在未命中参照库、也没接在线识别时，它是唯一可以指着说"这是真的"的纹样证据。
    /// 显著性检测失败（模拟器/老系统/纯色照片）就退回中心与上方两个方图，保证结果稳定可复现。
    static func patternCrops(from image: UIImage, limit: Int = 2) -> [UIImage] {
        let prepared = squarePixelImage(image, maxSide: 1400)
        guard let cg = prepared.cgImage else { return [] }
        let w = CGFloat(cg.width), h = CGFloat(cg.height)
        guard w > 16, h > 16 else { return [] }

        var rects: [CGRect] = []
        if let objects = attentionSaliency(cg) {
            rects = objects
                .sorted { $0.boundingBox.width * $0.boundingBox.height > $1.boundingBox.width * $1.boundingBox.height }
                .map { box in
                    // Vision 的 boundingBox 原点在左下，CGImage 裁切原点在左上 → y 要翻过来
                    CGRect(x: box.minX * w,
                           y: (1 - box.maxY) * h,
                           width: box.width * w,
                           height: box.height * h)
                }
                .filter { $0.width >= 56 && $0.height >= 56 }
        }
        if rects.isEmpty {
            let s = min(w, h) * 0.52
            rects = [CGRect(x: (w - s) / 2, y: (h - s) / 2, width: s, height: s),
                     CGRect(x: (w - s) / 2, y: h * 0.14, width: s, height: s)]
        }

        return rects.prefix(limit).compactMap { rect in
            let clamped = rect.intersection(CGRect(x: 0, y: 0, width: w, height: h))
            guard clamped.width >= 32, clamped.height >= 32,
                  let sub = cg.cropping(to: clamped.integral) else { return nil }
            return UIImage(cgImage: sub, scale: 1, orientation: prepared.imageOrientation)
        }
    }

    private static func attentionSaliency(_ cg: CGImage) -> [VNRectangleObservation]? {
        let request = VNGenerateAttentionBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cg, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        guard let result = request.results?.first as? VNSaliencyImageObservation else { return nil }
        return result.salientObjects
    }

    /// 把图缩到长边 maxSide 以内，并顺手把方向"烤"进像素
    /// （否则裁切出来的局部会带着 EXIF 方向，显示时被再转一次）
    private static func squarePixelImage(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }
        let longest = max(size.width, size.height)
        let scale = longest > maxSide ? maxSide / longest : 1
        var target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        if target.width < 1 { target.width = 1 }
        if target.height < 1 { target.height = 1 }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

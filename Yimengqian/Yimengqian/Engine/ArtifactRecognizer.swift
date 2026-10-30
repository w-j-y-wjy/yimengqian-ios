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
    /// 综合相似度 0…1（越大越像）。由「结构相关」与「色彩分布」两路得出，见 score(...)
    let score: Double
    /// 是否足够可信（低于阈值时界面显示「未能可靠识别」）
    let confident: Bool

    /// 界面上的档位文案：不假装是概率。
    /// 阈值按新的分数刻度定（自比对≈0.95+，干扰图≈0.2–0.5），见 ArtifactScoreProbe 的实测矩阵。
    var bandText: String {
        if score >= 0.86 { return "高度一致" }
        if score >= 0.70 { return "形态相近" }
        if score >= 0.50 { return "仅略相似" }
        return "差异较大"
    }
}

final class ArtifactRecognizer {
    static let shared = ArtifactRecognizer()

    /// 相似度低于这个值时，不把 top1 当成结论。
    /// 0.86 是按 ArtifactScoreProbe 实测矩阵定的（自比对 > 0.9，干扰图 < 0.6）。
    static let confidentThreshold: Double = 0.86

    /// top1 必须比 top2 至少高这么多，才算"认出来了"（Lowe 式比值检验）。
    /// 只有"分数够高"不够：参照库 4 件同属一类画风时，所有分数会被一起抬高，
    /// 这时"比第二名高多少"才是真正有判别力的量。
    static let marginThreshold: Double = 0.06

    private struct Reference {
        let artifact: Artifact
        let signature: Signature
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
            let query = Self.signature(of: image)

            let scored: [(Artifact, Double)] = refs.map { ref in
                let s = query.map { Self.score(query: $0, ref: ref.signature) } ?? 0
                return (ref.artifact, s)
            }

            let sorted = scored.sorted { $0.1 > $1.1 }
            let topScore: Double = sorted.first?.1 ?? 0
            let secondScore: Double = sorted.count > 1 ? sorted[1].1 : 0
            let distinct: Bool = (topScore - secondScore) >= Self.marginThreshold

            let matches = sorted.enumerated().map { index, item -> ArtifactMatch in
                let artifact = item.0
                let score = item.1
                return ArtifactMatch(
                    id: artifact.id,
                    name: artifact.name,
                    dynasty: artifact.dynasty,
                    type: artifact.type,
                    image: artifact.image,
                    score: score,
                    confident: index == 0 && score >= Self.confidentThreshold && distinct
                )
            }
            DispatchQueue.main.async { completion(matches) }
        }
    }

    /// 同步打分，只给自检探针用（ArtifactScoreProbe）。
    /// 返回分数 + 两路分量，方便从矩阵里看清"是结构像还是颜色像"。
    func probeDetails(_ image: UIImage) -> [(name: String, score: Double, structure: Double, color: Double)] {
        var out: [(name: String, score: Double, structure: Double, color: Double)] = []
        queue.sync {
            let refs = self.buildReferencesIfNeeded()
            guard let query = Self.signature(of: image) else { return }
            var rows: [(name: String, score: Double, structure: Double, color: Double)] = []
            for ref in refs {
                let st = Self.structureSimilarity(query.structure, ref.signature.structure)
                let co = Self.colorSimilarity(query.color, ref.signature.color)
                rows.append((name: ref.artifact.name, score: 0.55 * st + 0.45 * co, structure: st, color: co))
            }
            out = rows.sorted { $0.score > $1.score }
        }
        return out
    }

    // MARK: - 打分

    static func score(query: Signature, ref: Signature) -> Double {
        let st = structureSimilarity(query.structure, ref.structure)
        let co = colorSimilarity(query.color, ref.color)
        return 0.55 * st + 0.45 * co
    }

    // MARK: - 参照库

    private func buildReferencesIfNeeded() -> [Reference] {
        if let refs = references { return refs }
        var out: [Reference] = []
        for artifact in ContentData.artifacts {
            guard let img = AssetLoader.image(artifact.image),
                  let sig = Self.signature(of: img) else { continue }
            out.append(Reference(artifact: artifact, signature: sig))
        }
        references = out
        return out
    }

    // MARK: - 图像签名（自己算，不用 Vision 特征指纹）

    /// 16×16 灰度（已 z-score 归一化）+ 4×4 网格平均色（48 维）。
    ///
    /// 为什么不再用 `VNGenerateImageFeaturePrint`：实测它的距离在这套素材上**完全塌缩** ——
    /// 4 件参照互相之间、以及苏轼画像、山水诗意图、活动图，距离全都落在 0.00–0.02，
    /// 于是任何一张国风图都能拿到 90%+ 的"相似度"。它不是坏，是不适合"跨画风比器物"。
    /// 自己算的两路更诚实：灰度相关系数管构图（花瓶竖轮廓 vs 人物半身像），
    /// 4×4 色块管配色（青白 vs 赭褐），两者都不会因为"同为纸本插画"就一起塌到 0.9。
    struct Signature {
        let structure: [Float]
        let color: [Float]
    }

    static func signature(of image: UIImage) -> Signature? {
        let side = 16
        let block = 4
        guard let cg = image.cgImage,
              let ctx = CGContext(data: nil,
                                  width: side, height: side,
                                  bitsPerComponent: 8,
                                  bytesPerRow: side * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let raw = ctx.data else { return nil }
        let px = raw.bindMemory(to: UInt8.self, capacity: side * side * 4)

        // 灰度 → z-score：把"整体明暗"这个共同项扣掉，留下的才是构图
        var gray = [Float](repeating: 0, count: side * side)
        for y in 0..<side {
            for x in 0..<side {
                let i = (y * side + x) * 4
                gray[y * side + x] = 0.299 * Float(px[i]) + 0.587 * Float(px[i + 1]) + 0.114 * Float(px[i + 2])
            }
        }
        let count = Float(side * side)
        let mean = gray.reduce(0, +) / count
        let variance = gray.reduce(Float(0)) { $0 + ($1 - mean) * ($1 - mean) } / count
        let sd = max(0.5, sqrt(variance))
        let normalized = gray.map { ($0 - mean) / sd }

        // 4×4 色块
        var color = [Float](repeating: 0, count: 48)
        for by in 0..<4 {
            for bx in 0..<4 {
                var r: Float = 0, g: Float = 0, b: Float = 0
                for y in 0..<block {
                    for x in 0..<block {
                        let i = ((by * block + y) * side + (bx * block + x)) * 4
                        r += Float(px[i]); g += Float(px[i + 1]); b += Float(px[i + 2])
                    }
                }
                let n = Float(block * block) * 255
                let idx = (by * 4 + bx) * 3
                color[idx] = r / n
                color[idx + 1] = g / n
                color[idx + 2] = b / n
            }
        }
        return Signature(structure: normalized, color: color)
    }

    /// 结构相似度：z-score 归一化后向量的平均点积 = Pearson 相关系数，截到 0…1
    static func structureSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0
        for i in 0..<a.count { dot += a[i] * b[i] }
        let corr = dot / Float(a.count)
        return Double(max(0, min(1, corr)))
    }

    /// 色彩相似度：4×4 色块的平均绝对差，差到 0.20 就算完全不同
    static func colorSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var sum: Float = 0
        for i in 0..<a.count { sum += abs(a[i] - b[i]) }
        let meanDiff = sum / Float(a.count)
        return Double(max(0, min(1, 1 - meanDiff / 0.20)))
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
            // 逐条显式写类型：链式 sorted/map/filter 里混着 CGFloat 运算，
            // 会触发 "unable to type-check this expression in reasonable time"（已在 CI 复现一次）。
            var boxes: [VNRectangleObservation] = objects
            boxes.sort { lhs, rhs in
                let areaL: CGFloat = lhs.boundingBox.width * lhs.boundingBox.height
                let areaR: CGFloat = rhs.boundingBox.width * rhs.boundingBox.height
                return areaL > areaR
            }
            for box in boxes {
                let bb: CGRect = box.boundingBox
                let x: CGFloat = bb.minX * w
                // Vision 的 boundingBox 原点在左下，CGImage 裁切原点在左上 → y 要翻过来
                let y: CGFloat = (1 - bb.maxY) * h
                let bw: CGFloat = bb.width * w
                let bh: CGFloat = bb.height * h
                guard bw >= 56, bh >= 56 else { continue }
                rects.append(CGRect(x: x, y: y, width: bw, height: bh))
            }
        }
        if rects.isEmpty {
            let s = min(w, h) * 0.52
            rects = [CGRect(x: (w - s) / 2, y: (h - s) / 2, width: s, height: s),
                     CGRect(x: (w - s) / 2, y: h * 0.14, width: s, height: s)]
        }

        // 逐条裁切，同样显式写类型（理由同上：链式闭包会让类型检查爆炸）
        var out: [UIImage] = []
        let bounds = CGRect(x: 0, y: 0, width: w, height: h)
        for rect in rects.prefix(limit) {
            let clamped: CGRect = rect.intersection(bounds)
            guard clamped.width >= 32, clamped.height >= 32 else { continue }
            let pixelRect: CGRect = clamped.integral
            guard let sub: CGImage = cg.cropping(to: pixelRect) else { continue }
            out.append(UIImage(cgImage: sub, scale: 1, orientation: prepared.imageOrientation))
        }
        return out
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

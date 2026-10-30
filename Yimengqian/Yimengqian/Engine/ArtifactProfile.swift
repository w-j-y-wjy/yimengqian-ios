// ArtifactProfile.swift
//
// 「古物识趣」的八项器物报告 —— 按青花瓷详页的模板组织：
//   器物名称 / 朝代 / 属性 / 简介 / 纹样 / 寓意 / 时代风格 / 纹样图
//
// 为什么要新建这一层，而不是继续用 NativeDetailContent：
// 详情页（/native/artifact/<id>）只能渲染**库里已有的 4 件**，数据来自 ContentData；
// 而这里要面对的是**用户随手拍的一张照片**，内容必须先被生成出来，然后才谈得上排版。
// 所以本文件只做两件事：定义报告的八项结构，以及决定这八项从哪来。
//
// 三条来源，优先级从高到低（也是"三层降级"）：
// 1) .library    —— 本地 Vision 比对命中参照库（相似度 ≥ 0.45）。直接用库里的真数据，
//                   不联网、不花钱、零幻觉。这是最可信的一档，界面标「本机参照库」。
// 2) .remote     —— 没命中且配置了 AI 通道（DeepSeek 视觉）。让模型看图写文案，
//                   界面标「在线识别 · DeepSeek」，并保留把握度。
// 3) .localInfer —— 没命中也没 key（或网络失败）。只写能核实的东西：主色、器形近似度，
//                   纹样明确写「待考」。界面标「本地推断」，绝不编朝代。
//
// 为什么坚持第三层：比赛现场的 Wi-Fi 不可控，接口也可能临时抽风。
// 只要第三层在，断网时页面立刻有内容；反过来把功能全押在网络上，一断就是白屏。

import Foundation
import UIKit

/// 一份器物报告
struct ArtifactProfile {
    /// 器物名称
    var name: String = ""
    /// 朝代（把握不足时为「待考」）
    var dynasty: String = ""
    /// 属性：类别 · 器形 · 用途
    var kind: String = ""
    /// 简介
    var intro: String = ""
    /// 纹样名
    var patternName: String = ""
    /// 纹样结构
    var patternText: String = ""
    /// 寓意
    var symbol: String = ""
    /// 时代风格
    var eraStyle: String = ""
    /// 把握度 0…1（本地命中时是相似度；在线时是模型自评；本地推断时为 nil）
    var certainty: Double? = nil
    /// 内容来源
    var source: Source = .localInfer
    /// 用户拍的那张照片
    var photo: UIImage? = nil
    /// 纹样图：库里实物纹样图 / 照片局部裁切 / 程序化纹样
    var patternImages: [PatternImage] = []
    /// 兜底原因（例如"在线识别超时"），界面在来源角标后原样显示
    var failureNote: String? = nil

    enum Source: Equatable {
        case library
        case remote
        case localInfer

        var label: String {
            switch self {
            case .library: return "本机参照库"
            case .remote: return "在线识别 · DeepSeek"
            case .localInfer: return "本地推断"
            }
        }

        /// 是否属于"生成"内容 —— 界面要加「仅供参考」
        var isGenerated: Bool { self != .library }
    }

    struct PatternImage: Identifiable {
        let id = UUID()
        /// 位图（库图 / 照片裁切）
        let image: UIImage?
        /// 没有位图时，用 PatternPainter 按纹样名程序化绘制
        let painted: String?
        let caption: String
    }
}

// MARK: - 从本地参照库构造

extension ArtifactProfile {
    /// 命中参照库：八项全部取库里的真数据，一个字都不生成
    static func library(_ a: Artifact, score: Double) -> ArtifactProfile {
        var p = ArtifactProfile()
        p.name = a.name
        p.dynasty = a.dynasty
        p.kind = [a.type, a.shape, a.usage].filter { !$0.isEmpty }.joined(separator: " · ")
        p.intro = a.description
        if let pd = a.patternDetail {
            p.patternName = pd.name
            p.patternText = pd.structure
            p.symbol = pd.symbolism
            p.eraStyle = pd.eraStyle
        } else {
            p.patternName = a.pattern
            p.patternText = "纹样名记为「\(a.pattern)」，但本机知识库尚未收录这件器物的纹样结构、寓意与时代风格。此处只陈述资料缺口，不做补写。"
        }
        p.certainty = score
        p.source = .library
        return p
    }

    /// 库图（纹样大图 + 要素图）+ 用户照片里的局部
    static func libraryImages(_ a: Artifact, crops: [UIImage]) -> [PatternImage] {
        var out: [PatternImage] = []
        if let pd = a.patternDetail, !pd.image.isEmpty, let img = AssetLoader.image(pd.image) {
            out.append(PatternImage(image: img, painted: nil, caption: "\(pd.name) · 参照纹样图"))
        }
        if let pd = a.patternDetail {
            for element in pd.elements where !element.image.isEmpty {
                if let img = AssetLoader.image(element.image) {
                    out.append(PatternImage(image: img, painted: nil, caption: "\(element.name) · \(element.description)"))
                }
            }
            // 要素图缺失时（其余 3 件器物的纹样没有配图），按纹样名画一张示意图，
            // 而不是留一块空白 —— PatternPainter 是工程里已有的程序化绘制器。
            if out.isEmpty, let painter = painterName(for: pd.name) {
                out.append(PatternImage(image: nil, painted: painter, caption: "\(pd.name) · 程序化示意（非实物纹样图）"))
            }
        }
        for (i, crop) in crops.enumerated() {
            out.append(PatternImage(image: crop, painted: nil, caption: "你照片中的局部 \(i + 1)"))
        }
        return out
    }

    /// PatternPainter 认识哪几种纹样名
    static func painterName(for pattern: String) -> String? {
        let known = ["缠枝牡丹", "缠枝菊花", "缠枝灵芝", "缠枝莲"]
        return known.first(where: { pattern.contains($0) })
    }
}

// MARK: - 从模型返回的 JSON 构造

extension ArtifactProfile {
    /// 解析模型返回的 JSON。解析不出 name 就返回 nil —— 交给调用方走兜底。
    static func remote(fromJSON raw: String) -> ArtifactProfile? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // JSON 模式下 API 可能把非 JSON 内容替换成空格，此时 content 会是一串空白
        guard !trimmed.isEmpty,
              let start = trimmed.firstIndex(of: "{"),
              let end = trimmed.lastIndex(of: "}"),
              start < end else { return nil }
        let body = String(trimmed[start...end])
        guard let data = body.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        func text(_ key: String) -> String {
            if let s = obj[key] as? String {
                return s.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let n = obj[key] as? NSNumber {
                return n.stringValue
            }
            return ""
        }

        var p = ArtifactProfile()
        p.name = text("name")
        guard !p.name.isEmpty else { return nil }
        p.dynasty = text("dynasty")
        p.kind = text("kind")
        p.intro = text("intro")
        p.patternName = text("patternName")
        p.patternText = text("patternText")
        p.symbol = text("symbol")
        p.eraStyle = text("eraStyle")

        if let n = obj["certainty"] as? NSNumber {
            p.certainty = n.doubleValue
        } else if let s = obj["certainty"] as? String, let d = Double(s) {
            p.certainty = d
        }
        p.source = .remote
        return p
    }
}

// MARK: - 本地推断（无 key / 网络失败）

extension ArtifactProfile {
    /// 没有在线能力时的诚实版报告：只写"从这张照片能核实的东西"，
    /// 朝代一定写「待考」，纹样名只在与参照库足够接近时才给"疑为"。
    static func localInfer(image: UIImage,
                           matches: [ArtifactMatch],
                           crops: [UIImage],
                           note: String? = nil) -> ArtifactProfile {
        let tone = ArtifactRecognizer.tone(of: image)
        let top = matches.first

        var p = ArtifactProfile()
        p.source = .localInfer
        p.failureNote = note

        if let top = top {
            // 不把"最接近的那件"写进器物名：没过比值检验就只是画风相近，
            // 说成「疑似青花缠枝莲纹瓶」会让人以为认出来了。
            p.name = "疑似\(tone.name)调器物"
            p.kind = "类别待辨 · 主色\(tone.name)"
            // 不写百分比：这个分数是相对排序，不是概率，写"93%"只会让人以为有 93% 的把握
            p.intro = "本地未接通在线识别，因此不给出器名与年代的结论。从照片本身能核实的是：画面以\(tone.name)调为主。本机参照库中最接近的是「\(top.name)」（\(top.bandText)），但它与第二名的差距不到判定门槛，所以不采信为结论。若需完整的命名、断代与释义，可在设置里配置 AI 通道后重试。"
        } else {
            p.name = "疑似\(tone.name)调器物"
            p.kind = "类别待辨 · 主色\(tone.name)"
            p.intro = "本地未接通在线识别，也没有可比对的参照器物。从照片本身能核实的是：画面以\(tone.name)调为主。若需完整的命名、断代与释义，可在设置里配置 AI 通道后重试。"
        }
        p.dynasty = "待考"

        // 为什么不在这里"借"参照库的纹样资料：比对没过比值检验，说明它只是画风相近，
        // 并不真的是同一件器物（实测苏轼画像对青花瓶有 93% 的相似度）。
        // 这时候把「缠枝莲纹」写上去就是编，宁可写「待考」。
        p.patternName = "待考"
        p.patternText = "未接通在线识别时，纹样题材不做推测。下面的纹样图取自你照片里纹理最集中的两处局部，可作为观察依据。"
        p.symbol = "寓意须先确认纹样题材，本地不做推测。"
        p.eraStyle = "时代风格须先确认年代与窑口，本地不做推测。"

        for (i, crop) in crops.enumerated() {
            p.patternImages.append(PatternImage(image: crop, painted: nil, caption: "你照片中的局部 \(i + 1)"))
        }
        return p
    }
}

// MARK: - 装配入口

/// 唯一入口：交给它照片 + 本地比对结果，它保证回调一份内容非空的报告。
final class ArtifactProfileBuilder {
    static let shared = ArtifactProfileBuilder()

    private let queue = DispatchQueue(label: "com.yimeng.artifact-profile", qos: .userInitiated)
    /// 最近一份报告（设置页/调试用，不参与渲染）
    private(set) var latest: ArtifactProfile?

    private init() {}

    /// - Parameters:
    ///   - image: 用户拍/选的照片
    ///   - matches: ArtifactRecognizer 的本地比对结果（可为空）
    ///   - completion: 主线程回调，永远有值
    func build(image: UIImage, matches: [ArtifactMatch], completion: @escaping (ArtifactProfile) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            // 纹样局部裁切不管走哪条分支都要用，先算好（纯本机，几毫秒）
            let crops = ArtifactRecognizer.patternCrops(from: image)

            // 第一层：命中参照库
            if let top = matches.first, top.confident,
               let artifact = ContentData.artifacts.first(where: { $0.id == top.id }) {
                var p = ArtifactProfile.library(artifact, score: top.score)
                p.photo = image
                p.patternImages = ArtifactProfile.libraryImages(artifact, crops: crops)
                self.finish(p, completion)
                return
            }

            // 第二层：在线视觉模型（没 key 直接跳过）
            guard AIBridge.shared.hasKey else {
                var p = ArtifactProfile.localInfer(image: image, matches: matches, crops: crops,
                                                   note: "未配置 AI 通道")
                p.photo = image
                self.finish(p, completion)
                return
            }

            AIBridge.shared.describeArtifact(image: image, hints: matches) { json in
                var p: ArtifactProfile
                if let json = json, let remote = ArtifactProfile.remote(fromJSON: json) {
                    p = remote
                    p.photo = image
                    p.patternImages = Self.remoteImages(remote, crops: crops)
                } else {
                    p = ArtifactProfile.localInfer(image: image, matches: matches, crops: crops,
                                                   note: "在线识别未返回可用结果")
                    p.photo = image
                }
                self.finish(p, completion)
            }
        }
    }

    /// 在线生成时没有库图可用：只给照片局部 + 程序化纹样示意
    private static func remoteImages(_ profile: ArtifactProfile, crops: [UIImage]) -> [ArtifactProfile.PatternImage] {
        var out: [ArtifactProfile.PatternImage] = []
        for (i, crop) in crops.enumerated() {
            out.append(ArtifactProfile.PatternImage(image: crop, painted: nil, caption: "你照片中的局部 \(i + 1)"))
        }
        if let painter = ArtifactProfile.painterName(for: profile.patternName) {
            out.append(ArtifactProfile.PatternImage(image: nil, painted: painter,
                                                    caption: "\(profile.patternName) · 程序化示意（非实物纹样图）"))
        }
        return out
    }

    private func finish(_ p: ArtifactProfile, _ completion: @escaping (ArtifactProfile) -> Void) {
        latest = p
        DispatchQueue.main.async { completion(p) }
    }
}

// PoetryCardRenderer.swift
//
// 诗境卡「真卡面」渲染 —— 之前保存一张卡只往快照里塞一个 id（"jiangxue-card"），
// 「我的作品」里能看到的只是诗句配图的缩略图，**并不是用户生成的那张卡**。
// 也就是说"生成诗境卡"这个卖点，实际产出的是三条记录，没有画面。
//
// 这里补上真正的卡面绘制：诗句 + 题注 + 印章 + 画风底色，全部按用户当前选择渲染。
// 关键约束：
// - 纯 SwiftUI 绘制，canvas 比例固定 3:5（竖版）/ 5:3（横版），导出时按 1200px 宽出图；
// - **不做动画**（项目设计禁忌），只用静态排版；
// - 画风用 Core Image 滤镜在诗句配图上做（见 JiangxueStyleFilter），不是换一张图 ——
//   工程里只有一张原图，滤镜是唯一能"真切换"的办法。

import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// 画风滤镜：把同一张原图渲染成水墨 / 工笔 / 青绿 / 宋画
///
/// 为什么用滤镜而不是换图：工程内每个题材只有一张原图，四种画风原图并不存在。
/// 滤镜是"真能切换、真看得出不同"的最小实现；文档里必须如实说明这是滤镜风格化，
/// 不能宣称"AI 生成四种画风"。
enum JiangxueStyleFilter {
    /// 当前选择（StorageKeys.jiangxueStyle / poetryCardStyle 共用同一批值）
    static func apply(to image: UIImage, style: String) -> UIImage {
        guard let ci = CIImage(image: image) else { return image }
        let ctx = CIContext(options: [.useSoftwareRenderer: false])
        let out: CIImage
        switch style {
        case "ink":
            // 水墨：去饱和 + 提对比 + 轻微提亮，模拟宣纸墨色
            out = ci
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputSaturationKey: 0.05,
                    kCIInputContrastKey: 1.35,
                    kCIInputBrightnessKey: 0.06,
                ])
                .applyingFilter("CIPhotoEffectNoir")
        case "gongbi":
            // 工笔：高饱和 + 锐利 + 轻提亮，接近重彩细描
            out = ci
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputSaturationKey: 1.45,
                    kCIInputContrastKey: 1.18,
                    kCIInputBrightnessKey: 0.04,
                ])
                .applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: 0.6])
        case "bluegreen":
            // 青绿：偏青绿调 + 提饱和（宋画里的石青石绿）
            out = ci
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputSaturationKey: 1.25,
                    kCIInputContrastKey: 1.1,
                    kCIInputBrightnessKey: 0.02,
                ])
                .applyingFilter("CIHueAdjust", parameters: [kCIInputAngleKey: -0.35])
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: 0.86, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: 1.06, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: 1.10, w: 0),
                ])
        case "song":
            // 宋画：低饱和 + 暖色调 + 轻微降对比，接近绢本
            out = ci
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputSaturationKey: 0.55,
                    kCIInputContrastKey: 0.92,
                    kCIInputBrightnessKey: 0.08,
                ])
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: 1.08, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0.02, y: 0.99, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: 0.88, w: 0),
                ])
        default:
            out = ci
        }
        guard let cg = ctx.createCGImage(out, from: ci.extent) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
}

/// 一张诗境卡的数据快照 —— 保存时序列化成 JSON 存进快照，作品页按它重绘
struct PoetryCard: Codable, Identifiable, Equatable {
    var id: String
    /// 诗句（正文）
    var poemLine: String
    /// 诗题
    var poemTitle: String
    /// 题注（用户写的那句）
    var note: String
    /// 画风：ink / gongbi / bluegreen / song
    var style: String
    /// 版式：horizontal / vertical / whitespace
    var layout: String
    /// 印章：red / none
    var seal: String
    /// 底图 bundle 路径（诗句配图）
    var image: String
    /// 生成时间 yyyy-MM-dd
    var date: String
}

/// 卡面视图：3:5 或 5:3，按 layout 排诗句与题注
struct PoetryCardView: View {
    let card: PoetryCard

    /// 画风对应的纸底色（让"选了不同画风"在缩略图上也能一眼看出区别）
    private var paperTint: Color {
        switch card.style {
        case "ink": return Color(hex: 0xF2EFE8)
        case "gongbi": return Color(hex: 0xFAF0E2)
        case "bluegreen": return Color(hex: 0xEDF2EE)
        default: return Color(hex: 0xF7F0E1)   // song
        }
    }

    private var isVertical: Bool { card.layout == "vertical" }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                paperTint

                if let img = AssetLoader.image(card.image) {
                    Image(uiImage: JiangxueStyleFilter.apply(to: img, style: card.style))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: w, height: h * (isVertical ? 0.52 : 0.60))
                        .clipped()
                        .frame(maxHeight: .infinity, alignment: .top)
                        .opacity(0.92)
                }

                VStack(spacing: 0) {
                    Spacer(minLength: h * (isVertical ? 0.50 : 0.58))

                    // 诗句主体
                    Text(verbatim: card.poemLine)
                        .font(.custom("KaitiSC-Bold", size: w * (isVertical ? 0.072 : 0.062)))
                        .foregroundColor(Theme.ink)
                        .multilineTextAlignment(isVertical ? .center : .leading)
                        .lineSpacing(w * 0.018)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, w * 0.09)

                    Spacer().frame(height: h * 0.030)

                    // 题注：用户写的那句话
                    if !card.note.isEmpty {
                        Text(verbatim: card.note)
                            .font(.custom("SongtiSC-Regular", size: w * 0.036))
                            .foregroundColor(Theme.inkLight)
                            .multilineTextAlignment(isVertical ? .center : .leading)
                            .lineSpacing(w * 0.010)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, w * 0.09)
                    }

                    Spacer(minLength: h * 0.02)

                    HStack(alignment: .bottom) {
                        Text(verbatim: "《\(card.poemTitle)》")
                            .font(.custom("SongtiSC-Regular", size: w * 0.032))
                            .foregroundColor(Theme.inkMuted)
                        Spacer()
                        if card.seal == "red" {
                            sealMark(size: w * 0.085)
                        }
                    }
                    .padding(.horizontal, w * 0.09)
                    .padding(.bottom, h * 0.045)
                }
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .background(paperTint)
    }

    /// 朱印：方框 + 竖排「一梦千年」
    private func sealMark(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                .strokeBorder(Theme.vermilion, lineWidth: max(1, size * 0.055))
            Text(verbatim: "一梦千年")
                .font(.custom("KaitiSC-Bold", size: size * 0.26))
                .foregroundColor(Theme.vermilion)
                .multilineTextAlignment(.center)
                .frame(width: size * 0.52)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: size, height: size)
    }
}

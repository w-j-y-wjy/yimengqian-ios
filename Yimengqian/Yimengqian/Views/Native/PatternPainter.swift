// PatternPainter.swift
//
// 程序化纹样绘制 —— 补上「相似纹样」三条（缠枝牡丹 / 缠枝菊花 / 缠枝灵芝）缺失的配图。
//
// 为什么画而不是找图：
// 工程里没有这三张配图，而纹样本身是**几何化的对称图形**（缠枝是螺旋藤蔓 + 花头），
// 用 SwiftUI Path 精确画出来比找一张风格不搭的位图更可控，也不增加包体。
//
// 三条纹样各画各的，不是同一张图换色：
// - 缠枝牡丹：多层花瓣（5 层同心瓣）+ 粗藤
// - 缠枝菊花：细长放射瓣（16 瓣）+ 细藤
// - 缠枝灵芝：云头如意形（两个对称卷云）+ 短藤
//
// 颜色取 Theme 色板（朱砂 / 描金 / 墨），保证与整页设计稿同源。

import SwiftUI

struct PatternPainter: View {
    /// 纹样名（与 ContentData.similarPatterns 的 name 一一对应）
    let name: String
    /// 是否用描金（详情页 hero 用金色，卡片缩略图用墨色）
    var tint: Color = Theme.goldBorder
    var lineWidth: CGFloat = 1.6

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // 纸底
                Rectangle().fill(Theme.paperWarm)
                // 缠枝藤蔓：所有三种纹样共用底纹骨架，但密度不同
                vine(size: s)
                    .stroke(tint.opacity(0.55), lineWidth: lineWidth * 0.8)
                // 花头：按纹样种类分支
                switch name {
                case "缠枝菊花":
                    chrysanthemum(size: s)
                case "缠枝灵芝":
                    lingzhi(size: s)
                default:
                    peony(size: s)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - 藤蔓骨架（S 形 + 两处卷须）

    private func vine(size s: CGFloat) -> Path {
        var p = Path()
        let cx = s * 0.5, cy = s * 0.5
        // 主藤：从左下到右上的一段 S
        p.move(to: CGPoint(x: s * 0.18, y: s * 0.86))
        p.addCurve(to: CGPoint(x: s * 0.5, y: s * 0.5),
                   control1: CGPoint(x: s * 0.34, y: s * 0.90),
                   control2: CGPoint(x: s * 0.30, y: s * 0.58))
        p.addCurve(to: CGPoint(x: s * 0.82, y: s * 0.16),
                   control1: CGPoint(x: s * 0.70, y: s * 0.42),
                   control2: CGPoint(x: s * 0.66, y: s * 0.10))
        // 两条对称卷须
        for sign in [CGFloat(-1), CGFloat(1)] {
            p.move(to: CGPoint(x: cx, y: cy))
            p.addQuadCurve(to: CGPoint(x: cx + sign * s * 0.26, y: cy - s * 0.20),
                           control: CGPoint(x: cx + sign * s * 0.22, y: cy + s * 0.04))
        }
        return p
    }

    // MARK: - 缠枝牡丹：五层同心瓣

    private func peony(size s: CGFloat) -> some View {
        let c = CGPoint(x: s * 0.5, y: s * 0.5)
        return ZStack {
            ForEach(0..<5, id: \.self) { ring in
                let r = s * (0.26 - CGFloat(ring) * 0.042)
                let petals = 8
                ForEach(0..<petals, id: \.self) { i in
                    let angle = Double(i) / Double(petals) * 2 * .pi + Double(ring) * 0.3
                    Ellipse()
                        .strokeBorder(tint.opacity(0.9 - Double(ring) * 0.12), lineWidth: lineWidth)
                        .frame(width: r * 0.55, height: r)
                        .offset(x: CGFloat(cos(angle)) * r * 0.5,
                                y: CGFloat(sin(angle)) * r * 0.5 - s * 0.0)
                        .position(c)
                }
            }
            Circle()
                .fill(tint.opacity(0.28))
                .frame(width: s * 0.055, height: s * 0.055)
                .position(c)
        }
    }

    // MARK: - 缠枝菊花：16 条细长放射瓣

    private func chrysanthemum(size s: CGFloat) -> some View {
        let c = CGPoint(x: s * 0.5, y: s * 0.5)
        return ZStack {
            ForEach(0..<16, id: \.self) { i in
                let angle = Double(i) / 16.0 * 2 * .pi
                Capsule()
                    .strokeBorder(tint.opacity(0.85), lineWidth: lineWidth)
                    .frame(width: s * 0.030, height: s * (i % 2 == 0 ? 0.40 : 0.30))
                    .rotationEffect(.radians(angle))
                    .position(c)
            }
            Circle()
                .fill(tint.opacity(0.30))
                .frame(width: s * 0.075, height: s * 0.075)
                .position(c)
        }
    }

    // MARK: - 缠枝灵芝：对称云头如意

    private func lingzhi(size s: CGFloat) -> some View {
        let c = CGPoint(x: s * 0.5, y: s * 0.52)
        return ZStack {
            // 两片对称卷云
            ForEach([CGFloat(-1), CGFloat(1)], id: \.self) { sign in
                CloudHead()
                    .stroke(tint, lineWidth: lineWidth)
                    .frame(width: s * 0.30, height: s * 0.22)
                    .scaleEffect(x: sign, y: 1)
                    .position(x: c.x + sign * s * 0.15, y: c.y)
            }
            // 中间菌柄
            Capsule()
                .fill(tint.opacity(0.75))
                .frame(width: s * 0.045, height: s * 0.26)
                .position(x: c.x, y: c.y + s * 0.16)
        }
    }
}

/// 云头如意：两段外卷 + 一段内收
private struct CloudHead: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.18),
                   control1: CGPoint(x: rect.minX + w * 0.10, y: rect.minY + h * 0.10),
                   control2: CGPoint(x: rect.midX - w * 0.16, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                   control1: CGPoint(x: rect.midX + w * 0.16, y: rect.minY + h * 0.30),
                   control2: CGPoint(x: rect.maxX - w * 0.10, y: rect.midY - h * 0.16))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY - h * 0.10),
                   control1: CGPoint(x: rect.maxX - w * 0.14, y: rect.maxY),
                   control2: CGPoint(x: rect.midX + w * 0.18, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.midY),
                   control1: CGPoint(x: rect.midX - w * 0.18, y: rect.maxY - h * 0.34),
                   control2: CGPoint(x: rect.minX + w * 0.06, y: rect.midY + h * 0.20))
        return p
    }
}

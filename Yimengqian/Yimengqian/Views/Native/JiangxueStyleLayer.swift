// JiangxueStyleLayer.swift
//
// 江雪诗境页的四颗画风胶囊（水墨/工笔/青绿/宋画）—— 第 22 轮像素叠层。
//
// 之前的问题：点画风只写存储 + 弹提示，选中态没有任何层画出来，主视觉也不换风格。
// 「换主视觉」需要四种画风的原图（工程里只有一张），但**选中态可以画**，
// 这样至少能看出「我选的是哪一个」，不再是假选择。
//
// 实测（jiangxue-scene.png 852×1846，靠 3× 放大截图核对）：
// - 选中胶囊（水墨）纵向 1028..1087（59px → 3.20%），即 55.69%..58.88%
// - 四颗胶囊横向 x 5.85/28.69/50.75/72.25%，宽 20.3/21.4/20.9/24.3%
// - 选中底色 #DEBC85；这一带的纸底 #EBDBC3
// - 文字高约 27px（→ 1.46% 的容器高）
//
// 坑：第一版把 y 写成 0.5790（对应 1068），比真实位置低了 ~40px，
// 于是新画的字与位图里的字上下叠成两排（截图一眼可见）。量锚点必须用放大截图核对，
// 不能只按热区矩形的 y 猜 —— 热区高 5%（92px）比胶囊本身（59px）大得多。

import SwiftUI

struct JiangxueStyleLayer: View {
    let screen: ScreenConfig
    let container: CGSize

    @EnvironmentObject private var selection: SelectionStore

    private struct Chip {
        let value: String
        let title: String
        let x: CGFloat
        let w: CGFloat
    }

    private let chips: [Chip] = [
        Chip(value: "ink", title: "水墨", x: 0.05845, w: 0.20329),
        Chip(value: "gongbi", title: "工笔", x: 0.28690, w: 0.21362),
        Chip(value: "bluegreen", title: "青绿", x: 0.50751, w: 0.20892),
        Chip(value: "song", title: "宋画", x: 0.72249, w: 0.24272),
    ]

    /// 胶囊真实的上下边界（占容器高）
    private let pillTop: CGFloat = 0.5569
    private let pillHeight: CGFloat = 0.0320

    private var current: String { selection.value(StorageKeys.jiangxueStyle) ?? "ink" }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                chipView(chip)
            }
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
    }

    private func chipView(_ chip: Chip) -> some View {
        let isOn = chip.value == current
        // 遮罩比胶囊四周各外扩 3px：位图里的胶囊边缘有抗锯齿，盖不干净会留一圈虚线
        let bandW = container.width * (chip.w + 0.007)
        let bandH = container.height * (pillHeight + 0.0034)

        return ZStack {
            Rectangle().fill(Theme.styleBand)
            if isOn {
                Capsule(style: .continuous)
                    .fill(Theme.styleChipSel)
                    .frame(width: container.width * chip.w, height: container.height * pillHeight)
            }
            Text(chip.title)
                .font(.custom(isOn ? "KaitiSC-Bold" : "SongtiSC-Regular", size: container.height * 0.0146))
                .foregroundColor(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: bandW, height: bandH)
        .offset(x: container.width * (chip.x - 0.0035), y: container.height * (pillTop - 0.0017))
    }
}

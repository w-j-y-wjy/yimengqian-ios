// JiangxueStyleLayer.swift
//
// 江雪诗境页的四颗画风胶囊（水墨/工笔/青绿/宋画）—— 第 22 轮像素叠层。
//
// 之前的问题：点画风只写存储 + 弹提示，选中态没有任何层画出来，主视觉也不换风格。
// 「换主视觉」需要四种画风的原图（工程里只有一张），但**选中态可以画**，
// 这样至少能看出「我选的是哪一个」，不再是假选择。
//
// 实测（jiangxue-scene.png 852×1846，靠 4× 放大截图逐边核对）：
// - 选中胶囊（水墨）纵向 1040..1106（67px → 3.63%），即 56.34%..59.97%
// - 胶囊横向比热区窄一圈：水墨 pill 约 6.92%..25.50%，而热区是 5.85%..26.17%
// - 四颗热区 x 5.85/28.69/50.75/72.25%，宽 20.3/21.4/20.9/24.3%（文字居中于热区）
// - 选中底色 #DEBC85；这一带的纸底 #EBDBC3
// - 文字高约 27px（→ 1.46% 的容器高）
//
// 两次量错的教训：
// 1) 先按热区矩形 y（55.72%）当胶囊位置 → 画低 40px，新旧字叠成两排；
// 2) 再用「金色像素上限」判边界 → 纸张暖色被误判，量到 1040..1129 偏大。
// 最终靠 4× 放大图逐边目视核对才准 —— 像素统计只能做交叉验证，不能替代看图。

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
    private let pillTop: CGFloat = 0.5634
    private let pillHeight: CGFloat = 0.0363

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

// JiangxueStyleLayer.swift
//
// 江雪诗境页的四颗画风胶囊（水墨/工笔/青绿/宋画）—— 第 22 轮像素叠层。
//
// 之前的问题：点画风只写存储 + 弹提示，选中态没有任何层画出来，主视觉也不换风格。
// 「换主视觉」需要四种画风的原图（工程里只有一张），但**选中态可以画**，
// 这样至少能看出「我选的是哪一个」，不再是假选择。
//
// 实测（jiangxue-scene.png 852×1846）：
// - 四颗胶囊热区 y 55.72..60.94%、x 5.85/28.69/50.75/72.25%，宽 20.3/21.4/20.9/24.3%
// - 选中胶囊底色 #DEBC85（采样 100,1070 与 80,1085 一致）
// - 文字墨色 #353121 附近；未选中为普通墨色
// - 胶囊纵向 1073..1105（含文字），即 58.1%..59.9%

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

    private var current: String { selection.value(StorageKeys.jiangxueStyle) ?? "ink" }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                let isOn = chip.value == current
                // 遮罩比胶囊略外扩一点：位图里的胶囊与文字都要盖掉，否则会重影。
                // 外扩量控制在 4px 以内 —— 胶囊之间的分隔竖线在热区矩形之外，不会被盖到。
                let w = container.width * (chip.w + 0.008)
                let h = container.height * 0.0240
                ZStack {
                    Rectangle().fill(Theme.styleBand)
                    if isOn {
                        Capsule(style: .continuous)
                            .fill(Theme.styleChipSel)
                            .frame(width: container.width * chip.w, height: container.height * 0.0200)
                    }
                    Text(chip.title)
                        .font(.custom(isOn ? "KaitiSC-Bold" : "SongtiSC-Regular", size: container.height * 0.0144))
                        .foregroundColor(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(width: w, height: h)
                .offset(x: container.width * (chip.x - 0.004), y: container.height * 0.5790)
            }
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
    }
}

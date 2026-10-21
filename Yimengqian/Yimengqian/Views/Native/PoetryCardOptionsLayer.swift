// PoetryCardOptionsLayer.swift
//
// 诗境卡工坊的三排选项（画风 / 版式 / 印章）—— 第 4 轮第一块「像素对齐叠层」。
//
// 为什么整排重画而不是只贴一个高亮：
// 位图里默认选中「水墨 / 横版 / 朱印」，只画新高亮会与旧高亮并存（就像上一轮个人中心那样）。
// 所以做法是：先按实测矩形把整排控件擦成面板底色，再按当前选择重画分段控件。
//
// 实测依据（poetry-card.png 852×1846）：
// - 纵向扫描 x=350：三排胶囊分别落在 y 934..1001 / 1064..1129 / 1193..1261
// - 横向扫描确定选中胶囊：水墨 283..401（四段均分则控件 283..791）；
//   横版 275..430（三段 → 控件约 275..740）；朱印 275..508（两段 → 控件约 275..741）
// - 面板底色采样 #EBDAC4..#F0DECA（取均值 Theme.panelCream），胶囊色 #DDBA87
// 这些数字都是从图上量出来的，不是估的；改之前请重新量。

import SwiftUI

struct PoetryCardOptionsLayer: View {
    let screen: ScreenConfig
    let container: CGSize

    @EnvironmentObject private var selection: SelectionStore

    private struct Row {
        let key: String
        let chips: [(value: String, title: String)]
        /// 控件区域（百分比）
        let x0: CGFloat
        let w: CGFloat
        let y0: CGFloat
        let h: CGFloat
    }

    private let rows: [Row] = [
        Row(key: StorageKeys.poetryCardStyle,
            chips: [("ink", "水墨"), ("gongbi", "工笔"), ("bluegreen", "青绿"), ("song", "宋画")],
            x0: 0.3320, w: 0.5880, y0: 0.5060, h: 0.0363),
        Row(key: StorageKeys.poetryCardLayout,
            chips: [("horizontal", "横版"), ("vertical", "竖版"), ("whitespace", "留白")],
            x0: 0.3228, w: 0.5456, y0: 0.5765, h: 0.0352),
        Row(key: StorageKeys.poetryCardSeal,
            chips: [("red", "朱印"), ("none", "无印")],
            x0: 0.3228, w: 0.5460, y0: 0.6463, h: 0.0368),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                picker(row)
            }
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
    }

    private func picker(_ row: Row) -> some View {
        let padX = container.width * 0.012
        let padY = container.height * 0.006
        // 遮罩右边界固定到 0.945（面板右内缘）：第 2、3 排的可选项在图上还带一圈浅描边，
        // 按控件宽度算遮罩只到 0.88，会在右侧留下两个「(」形弧线残影（截图复现过）。
        let bandLeft = row.x0 - 0.012
        let bandW = container.width * (0.945 - bandLeft)
        let bandH = container.height * (row.h + 0.012)
        let segW = container.width * row.w / CGFloat(row.chips.count)
        let segH = container.height * row.h
        let current = selection.value(row.key) ?? row.chips.first?.value

        // 注意坐标系：外层先把整块平移到 (bandX, bandY)，所以子视图的 offset 是**相对整块**的，
        // 只需加回 padX/padY，别再加一次绝对坐标（否则会整体右移一倍）。
        return ZStack(alignment: .topLeading) {
            // 擦掉位图里的旧控件（含默认选中的胶囊与文字）
            Rectangle()
                .fill(Theme.panelCream)
                .frame(width: bandW, height: bandH)

            ForEach(Array(row.chips.enumerated()), id: \.offset) { index, chip in
                let isOn = chip.value == current
                ZStack {
                    RoundedRectangle(cornerRadius: segH * 0.5, style: .continuous)
                        .fill(isOn ? Theme.chipTan : Color.clear)
                    Text(chip.title)
                        .font(.custom(isOn ? "KaitiSC-Bold" : "SongtiSC-Regular", size: segH * 0.42))
                        .foregroundColor(isOn ? Theme.ink : Theme.inkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(width: segW, height: segH)
                .offset(x: padX + segW * CGFloat(index), y: padY)
            }
        }
        .frame(width: bandW, height: bandH, alignment: .topLeading)
        .offset(x: container.width * (row.x0 - 0.012), y: container.height * (row.y0 - 0.006))
    }
}

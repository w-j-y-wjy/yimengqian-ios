// PatternTabsLayer.swift
//
// 纹样详解页的三个 tab（纹样结构 / 寓意象征 / 时代风格）—— 第 5 轮像素叠层。
//
// 原来点 tab 只弹一句「当前查看：…」，选中态与正文都不变。这里做原位切换：
// 1) 擦掉整排 tab（含默认选中的第一颗）并按当前选择重画；
// 2) 擦掉正文区（保留左侧那枚纹样小图标）并重绘对应段落。
// 正文数据来自 ContentData.artifacts[qinghua-ping].patternDetail 的
// structure / symbolism / eraStyle 三段，本来就有，只是没人渲染。
//
// 实测依据（artifact-pattern.png 852×1846）：
// - 三颗 tab 的热区矩形 y 都是 37.6..42.6%，x 10.3/37.2/63.8%，宽 24.3/24.5/25.9%
// - 正文面板底色采样 #EFDEC8；选中 tab 底色采样 #E9D1AC
// - 正文区从 y 43.7% 到 57.7%（下方 58.7% 起是三张要素卡）
//
// 实现注意（踩过坑）：不要用「frame + offset + clipped」三段式 —— offset 是渲染期位移，
// 再 clipped 会按原始布局框裁剪，文字会被切掉大半（第一次截图就是一列残字）。
// 正确做法：遮罩与内容放进同一个 ZStack，用 padding 排内容，最后整体 offset 到位。

import SwiftUI

struct PatternTabsLayer: View {
    let screen: ScreenConfig
    let container: CGSize

    @EnvironmentObject private var selection: SelectionStore

    private struct Tab {
        let value: String
        let title: String
        let x: CGFloat
        let w: CGFloat
    }

    private let tabs: [Tab] = [
        Tab(value: "structure", title: "纹样结构", x: 0.10258, w: 0.24272),
        Tab(value: "symbolism", title: "寓意象征", x: 0.37221, w: 0.24460),
        Tab(value: "era", title: "时代风格", x: 0.63808, w: 0.25869),
    ]

    private var current: String { selection.value(StorageKeys.patternTab) ?? "structure" }

    private var detail: PatternDetail? {
        ContentData.artifacts.first(where: { $0.id == "qinghua-ping" })?.patternDetail
    }

    private var bodyText: String {
        guard let d = detail else { return "" }
        switch current {
        case "symbolism": return d.symbolism
        case "era": return d.eraStyle
        default: return d.structure
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            tabRow
            bodyPanel
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
    }

    // MARK: - tab 行

    private var tabRow: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Theme.patternPanel)

            ForEach(Array(tabs.enumerated()), id: \.offset) { _, tab in
                let isOn = tab.value == current
                ZStack {
                    Capsule(style: .continuous)
                        .fill(isOn ? Theme.patternTabSel : Color.clear)
                    Text(tab.title)
                        .font(.custom(isOn ? "KaitiSC-Bold" : "SongtiSC-Regular", size: container.height * 0.0155))
                        .foregroundColor(isOn ? Theme.ink : Theme.inkLight)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(width: container.width * tab.w, height: container.height * 0.050)
                .offset(x: (container.width * tab.x) - (container.width * 0.082),
                        y: container.height * 0.0073)
            }
        }
        .frame(width: container.width * 0.836, height: container.height * 0.064, alignment: .topLeading)
        .offset(x: container.width * 0.082, y: container.height * 0.3688)
    }

    // MARK: - 正文

    private var bodyPanel: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Theme.patternPanel)
            Text(bodyText)
                .font(.custom("SongtiSC-Regular", size: container.height * 0.0148))
                .foregroundColor(Theme.inkLight)
                .lineSpacing(container.height * 0.0042)
                .padding(.leading, 10)
                .padding(.top, 4)
        }
        .frame(width: container.width * 0.815, height: container.height * 0.140, alignment: .topLeading)
        .offset(x: container.width * 0.135, y: container.height * 0.4370)
    }
}

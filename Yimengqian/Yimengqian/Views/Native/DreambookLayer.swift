// DreambookLayer.swift
//
// 「千年梦册」顶部三个数字 —— 位图里烤死的是「18 日 / 27 个 / 16 张」，
// 而这三格里有两格本来就能算出真值：
//   · 生成诗境卡 = snapshot.generatedCards.count
//   · 解锁故事   = 诗境卡数 + 已完成对谈数（口径写在这里，界面文案照它说）
//   · 已入梦 N 日 = 首次打开日算起（AppSnapshot.firstOpenDate，升级后第一次启动补记）
//
// 做法与 FavoritesLayer 同源：先擦掉位图里的旧数字，再按同一位置画真值。
// 只擦「数字」那一小块（单位「日/个/张」留在位图上），所以不会碰到卡片圆角与山纹。
//
// 坐标来自 852×1846 设计稿实测：
//   卡片内三格数字的基线区 y 390..450；数字右缘分别落在 x≈250 / 455 / 665；
//   单位「日/个/张」左缘 x≈355 / 472 / 688；卡片底色 #EBD8BB、数字色 #644D30。
//
// 单位左右不对称（第一格是「18 日」中间空隙大，后两格贴得紧），
// 因此不按格子居中，而是**统一右对齐到「单位左缘 - 14px」**，三格的视觉间距才会一致。

import SwiftUI

struct DreambookLayer: View {
    let screen: ScreenConfig
    let container: CGSize

    @EnvironmentObject private var store: AppStore

    private let cardFill = Color(red: 235 / 255, green: 216 / 255, blue: 187 / 255)
    private let digitInk = Color(red: 100 / 255, green: 77 / 255, blue: 48 / 255)

    /// 三格：擦除区（左右） + 数字右对齐基准（单位左缘 - 14）
    private struct Cell {
        let eraseFrom: CGFloat
        let eraseTo: CGFloat
        let rightEdge: CGFloat
    }

    private let cells: [Cell] = [
        Cell(eraseFrom: 0.200, eraseTo: 0.318, rightEdge: (355 - 14) / 852),
        Cell(eraseFrom: 0.447, eraseTo: 0.565, rightEdge: (472 - 14) / 852),
        Cell(eraseFrom: 0.700, eraseTo: 0.818, rightEdge: (688 - 14) / 852),
    ]

    private var values: [String] {
        [
            "\(store.snapshot.dreamDays)",
            "\(store.snapshot.unlockedStories)",
            "\(store.snapshot.generatedCards.count)",
        ]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 先擦，后画（同一 ZStack 内按顺序叠）
            ForEach(Array(cells.enumerated()), id: \.offset) { pair in
                Rectangle()
                    .fill(cardFill)
                    .frame(width: container.width * (pair.element.eraseTo - pair.element.eraseFrom),
                           height: container.height * (450.0 / 1846 - 390.0 / 1846))
                    .offset(x: container.width * pair.element.eraseFrom,
                            y: container.height * (390.0 / 1846))
            }

            // 数字：右对齐到单位左缘
            ForEach(Array(cells.enumerated()), id: \.offset) { pair in
                Text(values[pair.offset])
                    .font(.custom("SongtiSC-Regular", size: container.height * 0.0317))
                    .foregroundColor(digitInk)
                    .lineLimit(1)
                    .frame(width: container.width * 0.16,
                           height: container.height * (450.0 / 1846 - 386.0 / 1846),
                           alignment: .trailing)
                    .offset(x: container.width * pair.element.rightEdge - container.width * 0.16,
                            y: container.height * (386.0 / 1846))
            }
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

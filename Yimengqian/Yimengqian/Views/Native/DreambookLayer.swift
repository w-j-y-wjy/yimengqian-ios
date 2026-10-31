// DreambookLayer.swift
//
// 「千年梦册」顶部三个数字 —— 位图里烤死的是「18 日 / 27 个 / 16 张」，
// 而这三格里有两格本来就能算出真值：
//   · 生成诗境卡 = snapshot.generatedCards.count
//   · 解锁故事   = 诗境卡数 + 已完成对谈数（口径写在这里，界面文案照它说）
//   · 已入梦 N 日 = 首次打开日算起（AppSnapshot.firstOpenDate，升级后第一次启动补记）
//
// 做法与 FavoritesLayer 同源：先擦掉位图里的旧数字，再按同一位置画真值。
// 只擦「数字」那一块（单位「日/个/张」与上方标签都留在位图上）。
//
// 坐标按 852×1846 设计稿实测（dreambook.png，逐块量过两轮）：
//   标签行 y 410..435，数字行 y 445..495（数字高约 50px），卡片下沿 y≈500；
//   三块数字的 x 区间：188..245 / 395..450 / 610..665；
//   单位左缘：日 255 / 个 462 / 张 678；卡片底色 #EBD8BB、数字色 #644D30。
//
// 第一版把数字区当成 390..450，结果擦掉的是**标签那一行**，数字又画到标签位置上，
// CI 截图里就出现「1 日」叠在「已入梦」旁边的错位 —— 这里是修正后的坐标。

import SwiftUI

struct DreambookLayer: View {
    let screen: ScreenConfig
    let container: CGSize

    @EnvironmentObject private var store: AppStore

    private let cardFill = Color(red: 235 / 255, green: 216 / 255, blue: 187 / 255)
    private let digitInk = Color(red: 100 / 255, green: 77 / 255, blue: 48 / 255)

    /// 三格：擦除区（x 起止，像素） + 数字右对齐基准（单位左缘 - 8）
    private struct Cell {
        let eraseFrom: CGFloat
        let eraseTo: CGFloat
        let rightEdge: CGFloat
    }

    private let cells: [Cell] = [
        Cell(eraseFrom: 186, eraseTo: 252, rightEdge: 247),
        Cell(eraseFrom: 391, eraseTo: 457, rightEdge: 454),
        Cell(eraseFrom: 606, eraseTo: 672, rightEdge: 670),
    ]

    static let designHeight: CGFloat = 1846
    static let designWidth: CGFloat = 852
    /// 数字擦除/绘制区：y 438…500
    private let rowTop: CGFloat = 438
    private let rowBottom: CGFloat = 500

    private var values: [String] {
        [
            "\(store.snapshot.dreamDays)",
            "\(store.snapshot.unlockedStories)",
            "\(store.snapshot.generatedCards.count)",
        ]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 先擦
            ForEach(Array(cells.enumerated()), id: \.offset) { pair in
                Rectangle()
                    .fill(cardFill)
                    .frame(width: container.width * (pair.element.eraseTo - pair.element.eraseFrom) / Self.designWidth,
                           height: container.height * (rowBottom - rowTop) / Self.designHeight)
                    .offset(x: container.width * pair.element.eraseFrom / Self.designWidth,
                            y: container.height * rowTop / Self.designHeight)
            }

            // 再画：右对齐到「单位左缘 - 8px」
            ForEach(Array(cells.enumerated()), id: \.offset) { pair in
                Text(values[pair.offset])
                    .font(.custom("SongtiSC-Regular", size: container.height * 0.0400))
                    .foregroundColor(digitInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: container.width * 0.18,
                           height: container.height * (rowBottom - rowTop) / Self.designHeight,
                           alignment: .trailing)
                    .offset(x: container.width * pair.element.rightEdge / Self.designWidth - container.width * 0.18,
                            y: container.height * rowTop / Self.designHeight)
            }
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

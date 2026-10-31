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

    // MARK: - 下半两块：城市足迹「入梦 N 日」/ 相逢古人「相逢 N 次」

    /// 三张卡的文字左缘（x 像素，852 宽设计稿实测：142 / 371 / 586）
    private let columnLeft: [CGFloat] = [140, 368, 588]
    /// 城市足迹副行 y 925…968；相逢古人副行 y 1230…1290
    private let cityRow: (CGFloat, CGFloat) = (925, 968)
    private let meetRow: (CGFloat, CGFloat) = (1230, 1290)

    private let cityIDs = ["bianjing", "linan", "jinling"]
    private let characterIDs = ["sushi", "liqingzhao", "wangwei"]

    private var cityTexts: [String] {
        cityIDs.map { id in
            let days = store.snapshot.cityDays(id)
            return days > 0 ? "入梦 \(days) 日" : "尚未入梦"
        }
    }

    private var meetTexts: [String] {
        characterIDs.map { id in
            let n = store.snapshot.meetCount(id)
            return n > 0 ? "相逢 \(n) 次" : "尚未相逢"
        }
    }

    /// 一行三块：先擦掉位图里的假数字，再按各列左缘重画
    @ViewBuilder
    private func row(_ texts: [String], band: (CGFloat, CGFloat)) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(columnLeft.enumerated()), id: \.offset) { pair in
                Rectangle()
                    .fill(cardFill)
                    .frame(width: container.width * 150 / Self.designWidth,
                           height: container.height * (band.1 - band.0) / Self.designHeight)
                    .offset(x: container.width * (pair.element - 4) / Self.designWidth,
                            y: container.height * band.0 / Self.designHeight)
            }
            ForEach(Array(columnLeft.enumerated()), id: \.offset) { pair in
                Text(texts[pair.offset])
                    .font(.custom("SongtiSC-Regular", size: container.height * 0.0172))
                    .foregroundColor(digitInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: container.width * 150 / Self.designWidth,
                           height: container.height * (band.1 - band.0) / Self.designHeight,
                           alignment: .leading)
                    .offset(x: container.width * pair.element / Self.designWidth,
                            y: container.height * band.0 / Self.designHeight)
            }
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
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

            // 下半两块（城市足迹「入梦 N 日」、相逢古人「相逢 N 次」）暂时不画：
            // 数据侧已经就绪（cityVisits / characterMeets），但它们的文字压在
            // 照片与章节标题之间，量错 40–50px 就会盖住「城市足迹」标题与诗句，
            // 属于"宁可先不画，也不留可见错位"。下一轮按 1:1 裁图重新量准后再启用。
            // 旧值仍留在位图上（入梦 6 日 / 相逢 2 次），已在 README 诚实表登记。
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}
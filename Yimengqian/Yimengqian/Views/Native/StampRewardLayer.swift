// StampRewardLayer.swift
//
// 领奖页底部的「印章图鉴进度」——位图里烤死的是「已收集 12 / 36」和一条固定进度条。
// 两个问题都很实在：
//   1) 分母 36 是编的：`ContentData.stamps` 里只有 4 枚；
//   2) 分子永远是 12：真正被授予的印章在 `snapshot.stamps`（`obtained: true`）里，
//      界面从来没读过它 —— 于是「收下印章」之后这行数字纹丝不动。
//
// 只擦两块，不碰其余排版：
//   · 「12 / 36」这一小段（x 415..570，y 1478..1536），"已收集"三个字留在位图上；
//   · 进度条整条（x 290..570，y 1544..1560），槽底色 #E2C8A3、填充色 #9C4729。
//
// 坐标与取色均按 852×1846 设计稿实测（stamp-reward.png）。

import SwiftUI

struct StampRewardLayer: View {
    let screen: ScreenConfig
    let container: CGSize

    @EnvironmentObject private var store: AppStore

    private let cardFill = Color(red: 233 / 255, green: 211 / 255, blue: 179 / 255)
    private let trackFill = Color(red: 226 / 255, green: 200 / 255, blue: 163 / 255)
    private let barFill = Color(red: 156 / 255, green: 71 / 255, blue: 41 / 255)
    private let digitInk = Color(red: 100 / 255, green: 77 / 255, blue: 48 / 255)

    private var obtained: Int { store.snapshot.stamps.filter { $0.obtained }.count }
    private var total: Int { max(ContentData.stamps.count, 1) }
    private var ratio: CGFloat { CGFloat(min(1, Double(obtained) / Double(total))) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 1) 擦掉「12 / 36」
            Rectangle()
                .fill(cardFill)
                .frame(width: container.width * (570.0 / 852 - 415.0 / 852),
                       height: container.height * (1536.0 / 1846 - 1478.0 / 1846))
                .offset(x: container.width * (415.0 / 852), y: container.height * (1478.0 / 1846))

            // 2) 画真值：右对齐到原来那段数字的右缘
            Text("\(obtained) / \(total)")
                .font(.custom("SongtiSC-Regular", size: container.height * 0.0190))
                .foregroundColor(digitInk)
                .lineLimit(1)
                .frame(width: container.width * 0.30,
                       height: container.height * (1536.0 / 1846 - 1478.0 / 1846),
                       alignment: .trailing)
                .offset(x: container.width * (570.0 / 852) - container.width * 0.30,
                        y: container.height * (1478.0 / 1846))

            // 3) 进度条槽
            Rectangle()
                .fill(trackFill)
                .frame(width: container.width * (570.0 / 852 - 290.0 / 852),
                       height: container.height * (1560.0 / 1846 - 1544.0 / 1846))
                .offset(x: container.width * (290.0 / 852), y: container.height * (1544.0 / 1846))

            // 4) 进度条填充（至少留 2px，让"0 枚"也看得出是条进度而不是坏了）
            Rectangle()
                .fill(barFill)
                .frame(width: max(2, container.width * (570.0 / 852 - 290.0 / 852) * ratio),
                       height: container.height * (1560.0 / 1846 - 1544.0 / 1846))
                .offset(x: container.width * (290.0 / 852), y: container.height * (1544.0 / 1846))
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

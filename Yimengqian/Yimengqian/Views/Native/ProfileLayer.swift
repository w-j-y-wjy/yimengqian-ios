// ProfileLayer.swift
//
// 个人中心叠层（Phase 3 · A-6）
//
// 解决的问题：四张统计卡上的数字（诗词 128 / 器物 86 / 人物 43 / 印章 27）是**烤进位图**的，
// 无论数据层存了什么都不会变。做完 A 线之后收藏已经真实落库，这一层把它们画回卡片上。
//
// 做法：
// - 数字槽位不另起坐标：取 `stat-*` 热区卡片矩形，再按实测比例切出「数字那一行」
//   （左侧插画、上方标签、下方单位都留原位，只盖数字本身）；
// - 覆盖色用 Theme.cardTan（#e8d3b4，从设计稿卡片内部采样的实测值），否则纸色补丁会露出来；
// - 数字来源统一走 AppStore.collection(filter:)，与收藏页筛选看到的一致 ——
//   点「器物 1 件」进收藏页就真的是 1 件，不会出现"上面写 128、进去只有 1 张"。
//
// 数字包围盒实测（profile.png 852×1846，y 648-700 行内深色像素的列簇）：
//   诗词 128 → 130-186 ｜ 器物 86 → 340-379 ｜ 人物 43 → 542-580 ｜ 印章 27 → 743-780
// 每张卡左端还有插画的深色像素（59-111 / 253-309 / 465-507 / 665-710），所以遮罩左边界
// 必须落在"插画右缘"与"数字左缘"之间的空隙里；单位字（篇/件/位/枚）从 y=701 起，
// 遮罩下边界必须停在 700 以内，否则量词会被一起盖掉。
// ⚠️ 第一次实现把遮罩起点定在 135，正好切掉「128」的「1」的左半截，结果 0 画在残字右边，
//    屏幕上看起来像"10"。所有比例都是从上面这些实测列簇反推的，不要凭感觉改。

import SwiftUI

struct ProfileLayer: View {
    let screen: ScreenConfig
    let container: CGSize

    @EnvironmentObject private var store: AppStore

    /// 一个统计卡里的数字槽位：热区 id + 类型 + 相对卡片矩形的比例
    private struct StatSlot {
        let hotspotID: String
        let type: FavoriteType
        /// 数字行左边界（相对卡片宽度）
        let fx: CGFloat
        /// 数字行宽度（相对卡片宽度）
        let fw: CGFloat
    }

    /// fx/fw 逐卡实测：四张卡的插画宽度不同（器物卡的鼎最宽），统一比例必然裁字。
    /// 换算方式：fx = (数字左缘 - 4px) / 卡宽，fw = (卡内右缘 - 数字左缘 + 4px) / 卡宽。
    private let slots: [StatSlot] = [
        StatSlot(hotspotID: "stat-poetry", type: .poem, fx: 0.490, fw: 0.452),
        StatSlot(hotspotID: "stat-artifact", type: .artifact, fx: 0.572, fw: 0.370),
        StatSlot(hotspotID: "stat-character", type: .character, fx: 0.558, fw: 0.381),
        StatSlot(hotspotID: "stat-stamp", type: .stamp, fx: 0.537, fw: 0.405),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            cultureProgress
            ForEach(slots, id: \.hotspotID) { slot in
                if let card = screen.hotspots.first(where: { $0.id == slot.hotspotID }) {
                    numberPatch(slot: slot, card: card.rect(in: container))
                }
            }
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
    }

    // MARK: - 文化进度（第 3 轮：这次先把锚点量准再画）
    //
    // 上一轮失败原因：用"搜索框内深色像素 bbox"量进度条，而搜索框压在纸纹上，
    // bbox 等于搜索框本身 → 坐标全错。这次分三步锚定，每一步都有像素证据：
    //   1) 横向扫描 y=514 这一行：朱砂填充 200..431，其后灰色空槽 449..541 → 整条 200..541（341px）
    //   2) 数值「1280 / 2000」墨色 bbox：577..697，y 506..523
    //   3) 卡片底色采样：#eddbc1（用纸色会露白，所以新增 Theme.cardCream）
    // 换算成百分比：条 x=23.47% w=40.14%，y=27.63% h=0.49%；数值 x=67.72% w=14.20% y=27.41% h=0.98%
    private var cultureProgress: some View {
        let culture = store.snapshot.cultureValue
        let ratio = min(1.0, max(0.0, Double(culture) / 2000.0))
        let barX = container.width * 0.2347
        let barY = container.height * 0.2763
        let barW = container.width * 0.4014
        let barH = max(3.0, container.height * 0.0049)
        return ZStack(alignment: .topLeading) {
            // 先盖掉烤死的旧条（含填充与空槽），再画新条
            Rectangle()
                .fill(Theme.cardCream)
                .frame(width: container.width * 0.4210, height: container.height * 0.0110)
                .offset(x: container.width * 0.2300, y: container.height * 0.2720)

            Capsule()
                .fill(Theme.barTrack)
                .frame(width: barW, height: barH)
                .offset(x: barX, y: barY)
            Capsule()
                .fill(Theme.vermilion)
                .frame(width: barW * CGFloat(ratio), height: barH)
                .offset(x: barX, y: barY)

            // 数值：盖掉「1280 / 2000」重画真实值（右对齐，与设计稿一致）
            // 注意两处细节：
            // 1) 用 Text(verbatim:) —— SwiftUI 的字符串插值会把 Int 按本地化加千分位（1200 → 1,200），
            //    设计稿没有逗号，必须用 verbatim 关掉格式化；
            // 2) 遮罩左缘比文字 bbox 再往左让 0.5% —— 实测旧文字首字符起始于 816px，
            //    只差 1px 没盖住就会在数字前留下一道细竖线残影。
            ZStack(alignment: .trailing) {
                Rectangle().fill(Theme.cardCream)
                Text(verbatim: "\(culture) / 2000")
                    .font(.custom("SongtiSC-Regular", size: container.height * 0.0135))
                    .foregroundColor(Theme.inkLight)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: container.width * 0.1520, height: container.height * 0.0116, alignment: .trailing)
            .offset(x: container.width * 0.6710, y: container.height * 0.2728)
        }
    }

    /// 数字行：遮罩 + 重绘。纵向 0.47h..0.795h 对应设计稿 y 640..700（数字 652..699，量词 701 起）。
    private func numberPatch(slot: StatSlot, card: CGRect) -> some View {
        let band = CGRect(
            x: card.minX + card.width * slot.fx,
            y: card.minY + card.height * 0.470,
            width: card.width * slot.fw,
            height: card.height * 0.325
        )
        let count = store.collection(filter: slot.type.rawValue).count

        return ZStack(alignment: .leading) {
            // 先盖掉烤进图里的旧数字（否则会和新数字叠成「1283」这种鬼影）
            Rectangle()
                .fill(Theme.cardTan)
            // 字号按槽位高度推：实测数字字高约 48px（设计稿 1846 高），≈ 槽高的 0.8 倍
            Text("\(count)")
                .font(.custom("KaitiSC-Bold", size: band.height * 0.95))
                .foregroundColor(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.leading, 2)
        }
        .frame(width: band.width, height: band.height, alignment: .leading)
        .offset(x: band.minX, y: band.minY)
    }

    // MARK: - 关于「文化进度条 / Lv.N」为什么没有重绘
    //
    // 2026-10-22 尝试过：把烤死的 1280/2000 与 Lv.4 覆盖重画。真机截图显示对位失败
    // （白块 + 双份 Lv.4）——原因是我用像素 bbox 去量进度条，而搜索框正好落在纸纹上，
    // 量出来的 bbox 等于搜索框本身，坐标全是错的。
    //
    // 处理：先撤回，不留可见的退步。要做这件事需要像四张统计卡那样，先确定一条真实的
    // 定位依据（热区矩形或精确到 1px 的实测），再落地。在那之前，进度条与等级保持位图，
    // 文化值/等级的"真实值"仍写进快照（RewardRules + applyReward），只是不做像素级展示。
}

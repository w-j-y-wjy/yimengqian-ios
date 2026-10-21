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
            progressPatches
            ForEach(slots, id: \.hotspotID) { slot in
                if let card = screen.hotspots.first(where: { $0.id == slot.hotspotID }) {
                    numberPatch(slot: slot, card: card.rect(in: container))
                }
            }
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
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

    // MARK: - 文化进度 / 等级（数据闭环：这些数字以前是烤死的）

    /// 设计稿实测（852×1846）：
    /// - 进度条：x 19.95%→80.0%，y 26.81%..28.4%（深色像素 bbox 170..759 / 495..525，右侧留给数值文字）
    /// - 进度数值：`culture-progress` 热区矩形（82.9%,25.4%,10%,5%）正好盖住「1280 / 2000」
    /// - 等级文字：`千年知音` 占 56.6%..62.3%，其后的 `Lv.4` 约 62.5%..68.5%，再往右是印章图案，不能碰
    private var progressPatches: some View {
        let culture = store.snapshot.cultureValue
        let ratio = min(1.0, max(0.0, Double(culture) / 2000.0))
        return ZStack(alignment: .topLeading) {
            // 进度条：先铺纸色盖掉烤死的朱砂填充，再画轨道 + 新填充
            Rectangle()
                .fill(Theme.paperWarm)
                .frame(width: container.width * 0.605, height: container.height * 0.018)
                .offset(x: container.width * 0.1995, y: container.height * 0.2665)

            Capsule()
                .fill(Theme.paperDark.opacity(0.55))
                .frame(width: container.width * 0.60, height: container.height * 0.0075)
                .offset(x: container.width * 0.20, y: container.height * 0.2725)
            Capsule()
                .fill(Theme.vermilion)
                .frame(width: container.width * 0.60 * CGFloat(ratio), height: container.height * 0.0075)
                .offset(x: container.width * 0.20, y: container.height * 0.2725)

            // 进度数值：热区矩形就是它的位置，换掉烤死的「1280 / 2000」
            if let hotspot = screen.hotspots.first(where: { $0.id == "culture-progress" }) {
                let rect = hotspot.rect(in: container)
                ZStack(alignment: .trailing) {
                    Rectangle().fill(Theme.paperWarm)
                    Text("\(culture) / 2000")
                        .font(.custom("SongtiSC-Regular", size: rect.height * 0.46))
                        .foregroundColor(Theme.inkLight)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(width: rect.width, height: rect.height, alignment: .trailing)
                .offset(x: rect.minX, y: rect.minY)
            }

            // 等级：只覆盖「Lv.N」那一小段，左边的「千年知音」与右边的印章图案保持位图
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.paperWarm)
                Text("Lv.\(store.snapshot.level)")
                    .font(.custom("KaitiSC-Bold", size: container.height * 0.0125))
                    .foregroundColor(Theme.vermilion)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: container.width * 0.060, height: container.height * 0.0235, alignment: .leading)
            .offset(x: container.width * 0.625, y: container.height * 0.2320)
        }
    }
}

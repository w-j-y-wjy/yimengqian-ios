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
            identityTexts
            avatarImage
            footprintStrip
            ForEach(slots, id: \.hotspotID) { slot in
                if let card = screen.hotspots.first(where: { $0.id == slot.hotspotID }) {
                    numberPatch(slot: slot, card: card.rect(in: container))
                }
            }
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
    }

    // MARK: - 头像（换过才覆盖）
    //
    // ⚠️ 2026-10-27 修正：上一版的圆心/半径 (197.3, 302.2) / r=122.8 是错的。
    // 真机上「换头像后头像不在原位」就是它造成的：新图整体偏右 26px、偏上 67px，
    // 半径比原圆大 15px，于是左边/下边各留一道旧头像的月牙，右边还压到了身份文字。
    //
    // 这次改成**双向线扫描 + 三测点解圆**，三个方向互相校验：
    //   · 水平 y=370：左边界 x=64（纸底 214 → 165），右边界 x=279（190 → 220），
    //     弦长 215 ⇒ 圆心 x=171.5、r=107.5；
    //   · 垂直 x=175：上边界 y=261（描边 162），下边界 y=478（174 → 纸底 215），
    //     弦长 217 ⇒ 圆心 y=369.5、r=108.5；
    //   · 用 y=280（左边界实测 110）交叉验证：r=111 时理论左边界 110 —— 与 108 的差值
    //     落在描边抗锯齿宽度内，符合。
    // 结论：圆心 (171.5, 369.5)、半径 108.0（852×1846）。设计稿的细描边正好在 r≈108 处，
    // 所以覆盖圆取 108.0 会把它一起盖掉，再补一条同色描边，边界干净、无月牙。
    private enum AvatarGeom {
        static let cx: CGFloat = 0.201291      // 171.5 / 852
        static let cy: CGFloat = 0.200163      // 369.5 / 1846
        static let r: CGFloat = 0.126761       // 108.0 / 852
        // 右下角朱砂铅笔徽标：实测圆心 (257, 442.5)、半径 22.75（852×1846）。
        // 它有一半压在头像圆上，所以换过头像后必须重画，否则会被裁成半个月牙。
        static let badgeCx: CGFloat = 0.301643 // 257.0 / 852
        static let badgeCy: CGFloat = 0.239708 // 442.5 / 1846
        static let badgeR: CGFloat = 0.026702  // 22.75 / 852
    }

    // 只在用户真的选过头像时才画：没选就完全让位图原样显示，零风险。
    @ViewBuilder
    private var avatarImage: some View {
        if AvatarStore.hasCustomAvatar, let img = AvatarStore.load() {
            let r = container.width * AvatarGeom.r
            ZStack(alignment: .topLeading) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: r * 2, height: r * 2)
                    .clipShape(Circle())
                    // 细描边盖住位图圆环内侧的抗锯齿边，避免出现"双圈"
                    .overlay(Circle().strokeBorder(Theme.goldBorder.opacity(0.55), lineWidth: 1.2))
                    .position(x: container.width * AvatarGeom.cx, y: container.height * AvatarGeom.cy)

                avatarEditBadge
            }
        }
    }

    /// 重画的铅笔徽标：位图里的那枚被新头像压住了一半，这里按实测位置盖回去。
    /// 用 SF Symbol 而不是把位图抠出来：任意分辨率都清晰，也不再往包里塞一张碎图。
    @ViewBuilder
    private var avatarEditBadge: some View {
        let br = container.width * AvatarGeom.badgeR
        ZStack {
            Circle()
                .fill(Theme.vermilion)
                .overlay(Circle().strokeBorder(Theme.paperLight.opacity(0.9), lineWidth: max(1, br * 0.16)))
            Image(systemName: "pencil")
                .font(.system(size: br * 1.02, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: br * 2, height: br * 2)
        .position(x: container.width * AvatarGeom.badgeCx, y: container.height * AvatarGeom.badgeCy)
    }

    // MARK: - 最近足迹（用真实数据盖掉烤死在位图里的三张假卡）
    //
    // 为什么必须重画：设计稿底部「最近足迹」里的「汴京 / 杭州 / 南京」+「今日 / 昨日 / 2天前」
    // 是**画进位图里的装饰**，跟用户去过哪儿毫无关系 —— 这就是"足迹永远是杭州和南京"的来源。
    // 真实记录在 AppStore.recentFootprints（由 recentViews 的 place: 前缀派生），
    // 这里把整条卡片带擦掉再按真数据重画，最多 3 张；一条都没有时给空态，不再展示假卡片。
    //
    // 几何全部来自 profile.png 的实测（852×1846）：
    //   · 卡片带 x 51..797、y 1372..1603；三张卡等宽 241.3、间距 11（末卡右缘 797）
    //   · 缩略图占卡片上部 155px（1372..1527），下面 76px 是名称与日期
    //   · 名称墨迹 y 1550..1571（字高 22px）、日期墨迹 y 1585..1601（字高 17px）
    //   · 名称/日期文字左缘 x=88，定位钉中心 x=75、y≈1558
    // 区块底色实测 #EDDBC1，与 Theme.cardCream 完全一致，所以擦除后看不出补丁。
    private enum FootprintGeom {
        // 擦除带（比卡片带略大一圈，确保旧卡的描边与阴影一并盖掉）
        static let stripeX: CGFloat = 0.052817   // 45 / 852
        static let stripeY: CGFloat = 0.739978   // 1366 / 1846
        static let stripeW: CGFloat = 0.886150   // 755 / 852
        static let stripeH: CGFloat = 0.132178   // 244 / 1846
        // 卡片
        static let cardTop: CGFloat = 0.743229   // 1372 / 1846
        static let cardH: CGFloat = 0.125136     // 231 / 1846
        static let firstLeft: CGFloat = 0.059859 // 51 / 852
        static let cardW: CGFloat = 0.283251     // 241.3 / 852
        static let stride: CGFloat = 0.296129    // 252.3 / 852
        static let imageH: CGFloat = 0.083966    // 155 / 1846
        static let corner: CGFloat = 0.016431    // 14 / 852
        // 卡内文字（相对卡片左上角，单位仍是全图比例，便于和上面几个数直接相加）
        static let textInset: CGFloat = 0.043427 // 37 / 852
        static let nameTop: CGFloat = 0.091820   // (1541.5-1372) / 1846
        static let dateTop: CGFloat = 0.113760   // (1582-1372) / 1846
        static let pinCx: CGFloat = 0.028169     // (75-51) / 852
        static let pinCy: CGFloat = 0.101029     // (1558.5-1372) / 1846
    }

    @ViewBuilder
    private var footprintStrip: some View {
        let records = Array(store.recentFootprints.prefix(3))
        ZStack(alignment: .topLeading) {
            // 先整条擦干净：旧实现只覆盖单卡时会留下"3 天前"之类的残字
            Rectangle()
                .fill(Theme.cardCream)
                .frame(width: container.width * FootprintGeom.stripeW,
                       height: container.height * FootprintGeom.stripeH)
                .offset(x: container.width * FootprintGeom.stripeX,
                        y: container.height * FootprintGeom.stripeY)

            if records.isEmpty {
                Text("还没有足迹 · 去古城走一走")
                    .font(.custom("SongtiSC-Regular", size: container.height * 0.0122))
                    .foregroundColor(Theme.inkMuted)
                    .frame(width: container.width * FootprintGeom.stripeW,
                           height: container.height * FootprintGeom.stripeH)
                    .offset(x: container.width * FootprintGeom.stripeX,
                            y: container.height * FootprintGeom.stripeY)
            } else {
                ForEach(Array(records.enumerated()), id: \.element.id) { pair in
                    footprintCard(record: pair.element, index: pair.offset)
                }
            }
        }
    }

    private func footprintCard(record: FootprintRecord, index: Int) -> some View {
        let left = container.width * (FootprintGeom.firstLeft + CGFloat(index) * FootprintGeom.stride)
        let w = container.width * FootprintGeom.cardW
        let h = container.height * FootprintGeom.cardH
        let imgH = container.height * FootprintGeom.imageH
        let radius = container.width * FootprintGeom.corner

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Theme.cardCream)
                .frame(width: w, height: h)
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Theme.goldBorder.opacity(0.55), lineWidth: 1)
                .frame(width: w, height: h)

            placeThumbnail(record.place)
                .frame(width: w, height: imgH)
                .clipShape(TopRoundedRectangle(radius: radius))

            Image(systemName: "mappin")
                .font(.system(size: container.height * 0.0087, weight: .medium))
                .foregroundColor(Theme.inkLight)
                .position(x: container.width * FootprintGeom.pinCx,
                          y: container.height * FootprintGeom.pinCy)

            Text(record.place.name)
                .font(.custom("KaitiSC-Bold", size: container.height * 0.0152))
                .foregroundColor(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .offset(x: container.width * FootprintGeom.textInset,
                        y: container.height * FootprintGeom.nameTop)

            Text(record.whenText)
                .font(.custom("SongtiSC-Regular", size: container.height * 0.0098))
                .foregroundColor(Theme.inkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .offset(x: container.width * FootprintGeom.textInset,
                        y: container.height * FootprintGeom.dateTop)
        }
        .frame(width: w, height: h, alignment: .topLeading)
        .offset(x: left, y: container.height * FootprintGeom.cardTop)
    }

    /// 地点缩略图：有专属配图就铺满裁切；没有（黄州 / 白鹿洞）就画同色系纸底 + 淡墨山形，
    /// 绝不借别的城池图凑数 —— 那会让人以为他真去过那座城。
    @ViewBuilder
    private func placeThumbnail(_ place: Place) -> some View {
        if let path = place.image, let img = AssetLoader.image(path) {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                Theme.styleBand
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: container.height * 0.024))
                    .foregroundColor(Theme.goldBorder.opacity(0.45))
            }
        }
    }

    // MARK: - 昵称 / 身份（个人资料编辑后要能看到变化）
    //
    // 实测（profile.png 852×1846，先 4× 放大截图逐边目视，再用行簇/列簇交叉验证）：
    // - 昵称「梦客·苏蘅」墨迹 x 318..536、y 282..321 —— 注意「梦」的长撇最低到 321，
    //   比正文低 8px；上一版按 y 277..313 画遮罩，结果撇尾留在新名字下方变成一道残笔。
    //   字距实测 44/42px ⇒ 字号≈43px（上一版 38px 偏小 12%）。
    //   纸底实测 #EEDCC3，与 Theme.cardCream(#EDDBC1) 只差 1–2 级，可直接用。
    // - 身份胶囊里的「江南游学者」墨迹 x 382..500、y 360..381，字距 25px ⇒ 字号≈25px。
    //   胶囊内填充实测 #E4CCA8 —— 与 #EDDBC1 差 (9,15,25)，用 cardCream 会在胶囊里浮一块浅方块，
    //   所以单独加了 Theme.pillTan。
    // 遮罩 = 墨迹 bbox 四周各外扩 4px（抗锯齿实测外扩 3px 足够，留 4px 富余）；
    // 文字在遮罩里垂直居中 ⇒ 中线与位图文字一致（301.5 / 370.5px），不会整体上移。
    @ViewBuilder
    private var identityTexts: some View {
        let customName = store.string(StorageKeys.profileName)?.trimmingCharacters(in: .whitespaces)
        let customTitle = store.string(StorageKeys.profileTitle)?.trimmingCharacters(in: .whitespaces)

        if let customName = customName, !customName.isEmpty {
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.cardCream)
                Text(customName)
                    .font(.custom("KaitiSC-Bold", size: container.height * 0.0233))
                    .foregroundColor(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(width: container.width * 0.2641, height: container.height * 0.0255, alignment: .leading)
            .offset(x: container.width * 0.3697, y: container.height * 0.1506)
        }

        if let customTitle = customTitle, !customTitle.isEmpty {
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.pillTan)
                Text(customTitle)
                    .font(.custom("SongtiSC-Regular", size: container.height * 0.0135))
                    .foregroundColor(Theme.inkLight)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(width: container.width * 0.1479, height: container.height * 0.0157, alignment: .leading)
            .offset(x: container.width * 0.4437, y: container.height * 0.1929)
        }
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

            // 等级：这次终于取到干净锚点。做法是按列统计行带 y 425..465 的深色像素簇，
            // 「千年知音」占 316..427，「Lv.4」占 442..494（墨色 bbox y 432..452），
            // 右侧 515..531 才是那枚印章——先前的 bbox 之所以连成一片，就是把印章算进去了。
            // 现在只盖 442..494 这一小段，左右两边的位图文字与印章都不动。
            ZStack(alignment: .trailing) {
                Rectangle().fill(Theme.cardCream)
                Text(verbatim: "Lv.\(store.snapshot.level)")
                    .font(.custom("KaitiSC-Bold", size: container.height * 0.0128))
                    .foregroundColor(Theme.vermilion)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            // 遮罩比文字 bbox 再放大一圈：位图文字的抗锯齿下缘实测到 y≈456，
            // 只盖到 452 会在新字下方留一排虚线状的残影（截图复现过）。
            .frame(width: container.width * 0.0800, height: container.height * 0.0165, alignment: .trailing)
            .offset(x: container.width * 0.5100, y: container.height * 0.2306)
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

/// 只有上面两个角是圆的矩形 —— 足迹卡的缩略图与设计稿一致：顶部随卡片圆角，
/// 底部是一条直边接文字区。（用 RoundedRectangle 会把下面两个角也削掉，露出缺口。）
private struct TopRoundedRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(radius, min(rect.width, rect.height) / 2)
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY),
                       control: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

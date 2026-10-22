// FavoritesLayer.swift
//
// 样板叠层 3：收藏页（A 线闭环的最后一环）
//
// 解决的问题：
// 收藏页原本只是设计稿：9 张卡片、6 颗筛选胶囊、日期与星标全部烤在位图里，
// 数据层无论存了什么，界面都不会变一下。做完 A-1/A-2 之后收藏已经真的写进快照，
// 但用户仍然看不见 —— 这一层就是把「已收藏的数据」画回设计稿的槽位。
//
// 做法（Phase 3 文档 §3 的方案 A：槽位填充）：
// - 槽位坐标全部来自热区矩形（`item-*` / `filter-*`），与点击区域同源，不可能错位；
// - 卡片**整卡覆盖重绘**，不是只在位图上叠一行字：位图里的缩略图、类型角标、标题、
//   副标题、日期、星标与真实收藏对不上（收藏了青花瓷纹样，卡上却写着「忆江南」），
//   只叠文字会同时显示真假两套数据；
// - 空槽用宣纸色蒙版 + 虚线框写「暂无收藏」，不保留位图里的示例卡片；
// - 筛选胶囊也要重绘：位图里「全部」是朱砂填充态，选了「器物」仍显示「全部」，自相矛盾。
//
// 克制原则：静态样式、无动画、只用 Theme 色板；本层 `.allowsHitTesting(false)`（由
// ScreenNativeLayer 统一施加），不抢热区点击。

import SwiftUI

struct FavoritesLayer: View {
    let screen: ScreenConfig
    let container: CGSize

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var selection: SelectionStore

    var body: some View {
        ZStack(alignment: .topLeading) {
            filterBand
            ForEach(Array(slots.indices), id: \.self) { index in
                let rect = slots[index].rect(in: container)
                if index < items.count {
                    card(items[index], in: rect)
                } else {
                    emptySlot(in: rect)
                }
            }
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
    }

    // MARK: - 数据

    /// 当前筛选值（SelectionStore 已跟踪 favoriteFilter，改筛选会驱动本层刷新）
    private var activeFilter: String? { selection.value(StorageKeys.favoriteFilter) }

    /// 当前筛选下要显示的条目。走 collection 而不是 favorites：
    /// 印章栏要合并「已获得 + 已收藏」，否则领奖拿到的章在页面里找不到。
    private var items: [FavoriteItem] { store.collection(filter: activeFilter) }

    /// 卡片槽位：`item-*` 热区按「先上后下、先左后右」排序，保证与视觉网格一致
    private var slots: [Hotspot] {
        screen.hotspots
            .filter { $0.id.hasPrefix("item-") }
            .sorted { a, b in a.y == b.y ? a.x < b.x : a.y < b.y }
    }

    /// 筛选胶囊（`filter-all` / `filter-poetry` …），按 x 排序
    private var filterHotspots: [Hotspot] {
        screen.hotspots
            .filter { $0.id.hasPrefix("filter-") }
            .sorted { $0.x < $1.x }
    }

    // MARK: - 筛选条

    /// 先逐颗擦掉位图里的旧胶囊（略外扩，抹掉描边残影），再统一画新的。
    /// 为什么不再整条铺底色：整条铺会在宣纸底上留下一块比周围更亮的横条（CI 截图可见，
    /// 像一条贴上去的色带）；逐颗擦除只影响胶囊本身，缝里的宣纸纹理原样保留。
    /// 必须先擦完所有胶囊再画 —— 交错绘制会让后一颗的擦除盖掉前一颗的新胶囊。
    @ViewBuilder
    private var filterBand: some View {
        ForEach(filterHotspots) { hotspot in
            let rect = hotspot.rect(in: container)
            Capsule(style: .continuous)
                .fill(Theme.paperWarm)
                .frame(width: rect.width + 8, height: rect.height + 8)
                .offset(x: rect.minX - 4, y: rect.minY - 4)
        }
        ForEach(filterHotspots) { hotspot in
            chip(hotspot)
        }
    }

    private func chip(_ hotspot: Hotspot) -> some View {
        let rect = hotspot.rect(in: container)
        let mine = hotspot.action.storageValue ?? "all"
        let current = activeFilter ?? "all"
        let isActive = mine == current
        // filter-poetry 写的是历史值 poetry，显示名要靠归一化拿到「诗词」
        let title = FavoriteType.fromFilter(hotspot.action.storageValue)?.displayName ?? "全部"

        return Text(title)
            .font(.system(size: 12))
            .foregroundColor(isActive ? Theme.paperLight : Theme.inkLight)
            .frame(width: rect.width, height: rect.height)
            .background(
                Capsule(style: .continuous)
                    // 未选中用宣纸底而不是 paperLight：设计稿的胶囊几乎与背景同色，
                    // 只靠金色描边区分；用更亮的 paperLight 会浮出一排白胶囊。
                    .fill(isActive ? Theme.vermilion : Theme.paperWarm)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(isActive ? Color.clear : Theme.goldBorder.opacity(0.55), lineWidth: 1)
            )
            .offset(x: rect.minX, y: rect.minY)
    }

    // MARK: - 卡片

    private func card(_ item: FavoriteItem, in rect: CGRect) -> some View {
        let info = FavoriteCardInfo.resolve(item)
        let pad: CGFloat = 6
        let innerW = rect.width - pad * 2
        let imageH = rect.height * 0.56

        return ZStack(alignment: .topLeading) {
            // 卡片底：盖住位图里的示例卡（缩略图 + 文字 + 星标全在上面）
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.paperLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 1)
                )

            thumbnail(path: info.image, width: innerW, height: imageH)
                .offset(x: pad, y: pad)

            // 类型角标
            Text(item.type.displayName)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Theme.inkLight)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Capsule(style: .continuous).fill(Theme.paperWarm.opacity(0.9)))
                .offset(x: pad + 4, y: pad + 4)

            // 文字区（标题 / 副标题 / 收藏时间）
            VStack(alignment: .leading, spacing: 2) {
                Text(info.title)
                    .font(.custom("KaitiSC-Bold", size: 12))
                    .foregroundColor(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(info.subtitle)
                    .font(.custom("SongtiSC-Regular", size: 9))
                    .foregroundColor(Theme.inkMuted)
                    .lineLimit(1)
                Text(relativeDate(item.date))
                    .font(.custom("SongtiSC-Regular", size: 9))
                    .foregroundColor(Theme.gold)
                    .lineLimit(1)
            }
            .frame(width: max(innerW - 16, 10), alignment: .leading)
            .offset(x: pad, y: pad + imageH + 3)

            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundColor(Theme.vermilion)
                .offset(x: rect.width - 18, y: rect.height - 18)

            // 编辑模式：右上角出现移除标记，提示「这一格现在点下去是取消收藏」
            if isEditing {
                ZStack {
                    Circle().fill(Theme.vermilion)
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.paperWarm)
                }
                .frame(width: 18, height: 18)
                .offset(x: rect.width - 24, y: 6)
            }
        }
        .frame(width: rect.width, height: rect.height)
        .offset(x: rect.minX, y: rect.minY)
    }

    /// 编辑模式（edit-btn 切换）。收藏页的卡片是叠层绘制的（`.allowsHitTesting(false)`），
    /// 所以「点卡片取消收藏」由热区动作完成（见 ActionExecutor.favoriteSlotTap），
    /// 本层只负责把「处于编辑模式」这件事画出来 —— 否则用户不知道点下去会发生什么。
    private var isEditing: Bool {
        selection.value(StorageKeys.favoritesEditing) == "true"
    }

    @ViewBuilder
    private func thumbnail(path: String?, width: CGFloat, height: CGFloat) -> some View {
        if let path = path, let img = AssetLoader.image(path) {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            // 没有配图的类型（书信等）：纸色块 + 淡金文书图标，不用假图充数
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.paperWarm)
                .frame(width: width, height: height)
                .overlay(
                    Image(systemName: "doc.text")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.goldBorder.opacity(0.9))
                )
        }
    }

    private func emptySlot(in rect: CGRect) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Theme.paperWarm)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        Theme.goldBorder.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
            )
            .overlay(
                Text("暂无收藏")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.inkMuted.opacity(0.65))
            )
            .frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
    }

    /// 把 `yyyy-MM-dd` 换算成设计稿里的相对说法（今日 / 昨日 / N 天前）
    private func relativeDate(_ raw: String) -> String {
        guard let date = DayFormat.formatter.date(from: raw) else { return "" }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: Date())).day ?? 0
        switch days {
        case ..<1: return "今日收藏"
        case 1: return "昨日收藏"
        default: return "\(days)天前收藏"
        }
    }
}

/// 卡片文案与缩略图的解析：
/// 收藏项只存 (type, itemId)，展示用的标题/副标题/配图从这里查 ContentData 得到。
/// 查不到时退回 itemId，绝不崩、也不留空卡。
struct FavoriteCardInfo {
    let title: String
    let subtitle: String
    let image: String?

    static func resolve(_ item: FavoriteItem) -> FavoriteCardInfo {
        switch item.type {
        case .poem:
            if let poem = ContentData.poems.first(where: { $0.id == item.itemId }) {
                return FavoriteCardInfo(
                    title: poem.title,
                    subtitle: "\(poem.dynasty) · \(poem.author)",
                    // 优先用诗自己的插画；《江雪》没有专属图，退回它的意象图
                    image: poem.image ?? poem.imagery?.first?.image
                )
            }
            // 意象（如「孤舟」）在枚举里只能归到 poem，靠 imagery 表补正文与配图
            if let imagery = ContentData.jiangxueImagery.first(where: { $0.id == item.itemId }) {
                return FavoriteCardInfo(title: imagery.name, subtitle: "《江雪》意象", image: imagery.image)
            }
        case .artifact:
            if let a = ContentData.artifacts.first(where: { $0.id == item.itemId }) {
                return FavoriteCardInfo(title: a.name, subtitle: "\(a.dynasty) · \(a.type)", image: a.image)
            }
        case .character:
            if let c = ContentData.characters.first(where: { $0.id == item.itemId }) {
                return FavoriteCardInfo(title: c.name, subtitle: "\(c.dynasty) · \(c.title)", image: c.image)
            }
        case .letter:
            let letters = ContentData.characters.flatMap { $0.letters }
            if let l = letters.first(where: { $0.id == item.itemId }) {
                return FavoriteCardInfo(title: "\(l.from)来信", subtitle: l.date, image: nil)
            }
        case .stamp:
            if let s = ContentData.stamps.first(where: { $0.id == item.itemId }) {
                return FavoriteCardInfo(title: s.name, subtitle: "印章 · 已入梦册", image: s.image)
            }
        }
        return FavoriteCardInfo(title: item.itemId, subtitle: item.type.displayName, image: nil)
    }
}

/// 日期解析器（年月日格式固定，复用同一个实例避免每张卡片重建）
private enum DayFormat {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

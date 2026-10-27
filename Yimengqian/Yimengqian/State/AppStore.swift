// 本文件为 app-project/src/context/AppContext.tsx 的 SwiftUI 忠实移植。
// 来源：src/context/AppContext.tsx（AppState / defaultState / LOAD_STATE / RESET）
//       + src/config/appStorageKeys.ts（yimeng-qiannian-state 快照键）
// 存储层：UserDefaults 对应 Web localStorage；AppSnapshot 对应去掉 currentPage 后的持久化 JSON。
// 依赖：DomainModels.swift（Stamp / FavoriteItem）、ContentData.swift（ContentData.stamps）。
import Foundation
import Combine

/// 整体状态快照 —— 与 AppContext 的 AppState 字段一一对应（currentPage 不入库，与 Web 一致）
struct AppSnapshot: Codable, Equatable {
    var onboardingComplete: Bool
    var nickname: String
    var title: String
    var dynasty: String
    var personality: [String]
    var recommendedCity: String
    var userPoem: String
    var initialStamp: Stamp?
    var currentCity: String
    var cultureValue: Int
    var yaValue: Int
    var petals: Int
    var level: Int
    var poetryCount: Int
    var artifactCount: Int
    var characterCount: Int
    var stampCount: Int
    var stamps: [Stamp]
    var favorites: [FavoriteItem]
    var completedTasks: [String]
    var recentViews: [String]
    var dialogueCompleted: [String]
    var feihualingProgress: Int
    var feihualingScore: Int
    var generatedCards: [String]

    /// 默认值 —— 与 AppContext.defaultState 完全一致
    static let `default` = AppSnapshot(
        onboardingComplete: false,
        nickname: "梦客·苏蘅",
        title: "江南游学者",
        dynasty: "北宋",
        personality: ["清雅", "善赏", "好游"],
        recommendedCity: "汴京",
        userPoem: "一帆渡到江南岸，细雨微茫入小楼。\n行尽绿桥人不见，半壶春水向东流。",
        initialStamp: nil,
        currentCity: "bei-song",
        cultureValue: 1200,
        yaValue: 680,
        petals: 12,
        level: 4,
        poetryCount: 32,
        artifactCount: 18,
        characterCount: 12,
        stampCount: 0,
        stamps: ContentData.stamps,
        favorites: AppSnapshot.sampleFavorites(),
        completedTasks: [],
        recentViews: [],
        dialogueCompleted: [],
        feihualingProgress: 0,
        feihualingScore: 0,
        generatedCards: []
    )

    // MARK: - 示例收藏（A 线，2026-10-20 用户决定）

    /// 预置 3 条示例收藏。
    /// 为什么要有：收藏页在空数据下只剩「暂无收藏」，演示与验收都看不出它是活的数据层。
    /// 为什么要挑**不可收藏的对象**（人物 / 书信 / 印章）：三处收藏热区（江雪 / 孤舟 / 青花瓷纹样）
    /// 必须保持「首次点击 = 新增」，否则验收脚本「收藏一个器物」会变成「取消收藏」。
    /// 为什么只放在 `default` 里：它只在**全新安装 / 五连击重置**时出现；用户取消后不会自己长回来。
    static func sampleFavorites() -> [FavoriteItem] {
        [
            FavoriteItem(id: "character-sushi", type: .character, itemId: "sushi", date: dateString(daysAgo: 0)),
            FavoriteItem(id: "letter-letter-sushi-1", type: .letter, itemId: "letter-sushi-1", date: dateString(daysAgo: 1)),
            FavoriteItem(id: "stamp-qing-hui-shan-shui", type: .stamp, itemId: "qing-hui-shan-shui", date: dateString(daysAgo: 2)),
        ]
    }

    /// 统一日期格式 `yyyy-MM-dd`：既能按字符串排序（同格式下字典序 = 时间序），
    /// 也方便叠层换算成「今日收藏 / 2 天前收藏」。
    static func dateString(daysAgo: Int = 0) -> String {
        let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: day)
    }
}

/// 全局状态 —— 语义对齐 AppContext + localStorage
final class AppStore: ObservableObject {
    @Published var snapshot: AppSnapshot {
        didSet { saveSnapshot() }
    }

    init() {
        // 区分「读到了已存快照」与「全新安装」：前者要跑一次历史数据迁移，后者直接用 default。
        if let saved = Self.loadSnapshot() {
            snapshot = saved
            migrateLegacyFavorites()
        } else {
            snapshot = .default
        }
    }

    // —— 离散键语义（与 Web localStorage 完全一致）——
    func string(_ key: String) -> String? { UserDefaults.standard.string(forKey: key) }
    func setString(_ key: String, _ value: String) { UserDefaults.standard.set(value, forKey: key) }
    func remove(_ key: String) { UserDefaults.standard.removeObject(forKey: key) }
    func setIfAbsent(_ key: String, _ value: String) { if string(key) == nil { setString(key, value) } }
    /// 存在则移除并返回 false；不存在则写入 "true" 并返回 true
    @discardableResult
    func toggle(_ key: String) -> Bool {
        if string(key) != nil { remove(key); return false }
        setString(key, "true"); return true
    }
    func bool(_ key: String) -> Bool { string(key) != nil && string(key) == "true" }
    @discardableResult
    func incrementInt(_ key: String, by: Int = 1) -> Int {
        let next = (Int(string(key) ?? "0") ?? 0) + by
        setString(key, String(next)); return next
    }

    // —— 快照持久化（对应 yimeng-qiannian-state）——
    private static func loadSnapshot() -> AppSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.snapshotKey),
              let snap = try? JSONDecoder().decode(AppSnapshot.self, from: data) else {
            return nil
        }
        return snap
    }
    private func saveSnapshot() {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: StorageKeys.snapshotKey)
    }

    // MARK: - 收藏（A 线单一事实源 = snapshot.favorites）

    /// 三个历史热区写的离散键 → 有语义的收藏项。
    /// 这是「离散键 ⇄ 快照」之间唯一被允许的桥：键仍照写（兼容旧逻辑与 resetAll），
    /// 但收藏的真相在 snapshot.favorites，离散键只是它的镜像。
    static let favoriteKeyMap: [String: (type: FavoriteType, itemId: String)] = [
        StorageKeys.favoriteJiangxue: (.poem, "jiangxue"),
        StorageKeys.favoriteImageryLoneBoat: (.poem, "gu-zhou"),
        StorageKeys.favoriteArtifactPattern: (.artifact, "qinghua-ping"),
    ]

    /// 是否已收藏（按 (type, itemId) 判定，与 id 字符串无关）
    func isFavorite(type: FavoriteType, itemId: String) -> Bool {
        snapshot.favorites.contains { $0.type == type && $0.itemId == itemId }
    }

    /// 收藏列表。`filter` 接受配置里的原始取值（含历史值 poetry / all / nil）。
    /// 排序：日期倒序；同日「后加入的在前」——sorted 不保证稳定，显式用下标兜住，避免顺序跳动。
    func favorites(filter: String?) -> [FavoriteItem] {
        let ordered = snapshot.favorites.enumerated()
            .sorted { a, b in
                if a.element.date != b.element.date { return a.element.date > b.element.date }
                return a.offset > b.offset
            }
            .map { $0.element }
        guard let type = FavoriteType.fromFilter(filter) else { return ordered }
        return ordered.filter { $0.type == type }
    }

    /// 切换收藏，返回**切换后**的状态（true = 已收藏），语义与 toggle(_:) 一致。
    /// 幂等：同一 (type, itemId) 只可能有一条（按下标删除，不依赖 id 字符串）。
    @discardableResult
    func toggleFavorite(type: FavoriteType, itemId: String, date: String = AppSnapshot.dateString()) -> Bool {
        if let idx = snapshot.favorites.firstIndex(where: { $0.type == type && $0.itemId == itemId }) {
            snapshot.favorites.remove(at: idx)
            syncLegacyKey(type: type, itemId: itemId, on: false)
            return false
        }
        snapshot.favorites.append(
            FavoriteItem(id: "\(type.rawValue)-\(itemId)", type: type, itemId: itemId, date: date)
        )
        syncLegacyKey(type: type, itemId: itemId, on: true)
        return true
    }

    /// 把收藏状态镜像回历史离散键（没有对应键的收藏项什么也不做）
    private func syncLegacyKey(type: FavoriteType, itemId: String, on: Bool) {
        for (key, target) in Self.favoriteKeyMap where target.type == type && target.itemId == itemId {
            if on { setString(key, "true") } else { remove(key) }
        }
    }

    // MARK: - 印章（P0-2：领奖页要真的发印章）

    /// 「领取」类热区的 flagKey → 印章 id。
    /// 配置里 claim-btn 用 incrementOnce 只写了一个没人读的计数（petalCount），
    /// 领奖页文案却说「已收入收藏」，实际什么都没发生 —— 这张表把「写 flag」接成「真的发章」。
    static let stampClaimMap: [String: String] = [
        StorageKeys.springStampClaimed: "chun-ri-ya-shi",
    ]

    /// 授予印章。幂等：已获得则不改日期。返回本次是否新获得。
    @discardableResult
    func grantStamp(id: String, date: String = AppSnapshot.dateString()) -> Bool {
        guard let idx = snapshot.stamps.firstIndex(where: { $0.id == id }) else { return false }
        guard !snapshot.stamps[idx].obtained else { return false }
        snapshot.stamps[idx].obtained = true
        snapshot.stamps[idx].date = date
        snapshot.stampCount = snapshot.stamps.filter { $0.obtained }.count
        return true
    }

    /// 已获得的印章（按获得日期倒序）
    func obtainedStamps() -> [Stamp] {
        snapshot.stamps.filter { $0.obtained }.sorted { ($0.date ?? "") > ($1.date ?? "") }
    }

    /// 收藏页「印章」口径：已获得的印章 + 被收藏的印章（同一枚只出现一次）。
    /// 为什么合并：设计稿入口叫「查看我的印章」，印章是获得物而不是收藏物，
    /// 只显示收藏会让领奖拿到的章在页面上找不到。
    private func stampItems(extraFavorites: [FavoriteItem]) -> [FavoriteItem] {
        var seen = Set<String>()
        var out: [FavoriteItem] = []
        for s in snapshot.stamps where s.obtained {
            seen.insert(s.id)
            out.append(FavoriteItem(id: "stamp-\(s.id)", type: .stamp, itemId: s.id, date: s.date ?? AppSnapshot.dateString()))
        }
        for f in extraFavorites where f.type == .stamp && !seen.contains(f.itemId) {
            seen.insert(f.itemId)
            out.append(f)
        }
        return out.sorted { $0.date > $1.date }
    }

    /// 收藏页统一入口：印章栏走「已获得 + 已收藏」，其余按类型筛收藏；
    /// filter 为空时把两部分合并 —— 否则「全部」会比「印章」还少，看着像丢数据。
    func collection(filter: String?) -> [FavoriteItem] {
        let favorites = self.favorites(filter: filter)
        let type = FavoriteType.fromFilter(filter)
        if type == .stamp { return stampItems(extraFavorites: favorites) }
        if type == nil {
            let nonStamp = favorites.filter { $0.type != .stamp }
            return (nonStamp + stampItems(extraFavorites: favorites)).sorted { $0.date > $1.date }
        }
        return favorites
    }

    // MARK: - 数值闭环（文化值 / 雅集值 / 花瓣 / 等级 / 足迹）
    //
    // 统一入口：所有"操作带来的数值变化"都走 applyReward，避免又出现
    // "SpecialScreens 写离散键、快照里另有常量"的两套账。

    /// 记一笔奖励，返回变更摘要（供 Toast 用）
    @discardableResult
    func applyReward(_ rule: RewardRule, note: String? = nil, date: String = AppSnapshot.dateString()) -> String {
        var parts: [String] = []
        if rule.culture != 0 {
            snapshot.cultureValue = max(0, snapshot.cultureValue + rule.culture)
            parts.append("文化值\(rule.culture > 0 ? "+" : "")\(rule.culture)")
        }
        if rule.ya != 0 {
            snapshot.yaValue = max(0, snapshot.yaValue + rule.ya)
            parts.append("雅集值\(rule.ya > 0 ? "+" : "")\(rule.ya)")
        }
        if rule.petals != 0 {
            snapshot.petals = max(0, snapshot.petals + rule.petals)
            parts.append("花瓣\(rule.petals > 0 ? "+" : "")\(rule.petals)")
        }
        if rule.culture != 0 {
            snapshot.level = RewardRules.level(for: snapshot.cultureValue)
        }
        if let tag = rule.tag {
            recordVisit(tag, date: date)
        }
        return parts.joined(separator: "、")
    }

    /// 最近足迹：去重后插到最前，最多保留 8 条
    ///
    /// 2026-10-27 修：旧实现用 `$0 == tag` 去重，但存进去的是 `"日期|tag"`，
    /// 二者永远不相等 —— 于是同一个地方去 3 次就占 3 格，8 格很快被挤满。
    /// 现在按 tag 后缀去重（保留最近一次访问的日期）。
    func recordVisit(_ tag: String, date: String = AppSnapshot.dateString()) {
        let entry = "\(date)|\(tag)"
        // 同一天重复到访直接返回：既避免反复写盘，也避免"记账 → @Published → 重渲染 →
        // 再记账"的回环（onInit 每次渲染都会重新构造闭包）。
        if snapshot.recentViews.first == entry { return }
        snapshot.recentViews.removeAll { $0 == tag || $0.hasSuffix("|\(tag)") }
        snapshot.recentViews.insert(entry, at: 0)
        if snapshot.recentViews.count > 8 { snapshot.recentViews = Array(snapshot.recentViews.prefix(8)) }
    }

    /// 记一次「到访某地」。tag 用 `place:<id>` 前缀，与其它行为标签（feihualing / teahouse…）
    /// 共存于同一个 recentViews 数组里 —— 不新增快照字段，旧存档照样能解码。
    func recordPlace(_ placeID: String, date: String = AppSnapshot.dateString()) {
        guard PlaceCatalog.place(id: placeID) != nil else { return }
        recordVisit("place:\(placeID)", date: date)
    }

    /// 个人中心「最近足迹」的真实数据：只取 `place:` 前缀的记录，按**到访日期倒序**。
    ///
    /// 为什么还要按日期排：recordVisit 是"插到最前"，正常使用时插序就等于时间序；
    /// 但一旦出现补记（比如 CI 预置、或者从旧存档迁移），插序就和真实到访顺序不一致了，
    /// 界面却写着"按最近到访排序"。这里显式按 yyyy-MM-dd 倒序，同一天保持插入顺序。
    var recentFootprints: [FootprintRecord] {
        let list = snapshot.recentViews.compactMap { raw -> FootprintRecord? in
            let parts = raw.split(separator: "|", maxSplits: 1).map(String.init)
            guard parts.count == 2, parts[1].hasPrefix("place:") else { return nil }
            let pid = String(parts[1].dropFirst("place:".count))
            guard let place = PlaceCatalog.place(id: pid) else { return nil }
            return FootprintRecord(place: place, date: parts[0])
        }
        return list.enumerated()
            .sorted { a, b in
                if a.element.date != b.element.date { return a.element.date > b.element.date }
                return a.offset < b.offset
            }
            .map { $0.element }
    }


    /// 记录已完成的对谈话题（幂等）
    func completeDialogue(topic: String) {
        guard !snapshot.dialogueCompleted.contains(topic) else { return }
        snapshot.dialogueCompleted.append(topic)
    }

    /// 累计生成的诗境卡（保存一张 +1，幂等由调用方的 flag 保证）
    func addGeneratedCard(_ id: String, date: String = AppSnapshot.dateString()) {
        guard !snapshot.generatedCards.contains(id) else { return }
        snapshot.generatedCards.append(id)
    }

    // MARK: - 诗境卡（真卡面）

    /// 诗境卡作品列表 —— 用**独立存储键**而不是塞进 AppSnapshot。
    ///
    /// 为什么不进快照：AppSnapshot 是 Codable 且整体解码，加字段会让**旧版本存档解码失败**，
    /// 一失败就会静默回落到 .default —— 用户已有的收藏/文化值全丢。
    /// 独立键 + 单独解码可以把风险限制在"这一项读不出来"，其它状态不受影响。
    private static let poetryCardsKey = "yimeng-poetry-cards"

    var poetryCards: [PoetryCard] {
        guard let data = UserDefaults.standard.data(forKey: Self.poetryCardsKey),
              let list = try? JSONDecoder().decode([PoetryCard].self, from: data) else {
            return []
        }
        return list
    }

    private func persistPoetryCards(_ list: [PoetryCard]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: Self.poetryCardsKey)
        }
        // 通知界面刷新（@Published 的 snapshot 没变，需要显式发信号）
        objectWillChange.send()
    }

    /// 保存一张诗境卡：把当时的诗句/题注/画风/版式/印章一起冻结下来。
    /// 为什么必须冻结而不是保存时再去读当前选择：用户保存后继续调整选项，
    /// 旧卡不该跟着变 —— 作品集里的每一张应该是"那一次生成的结果"。
    @discardableResult
    func savePoetryCard(_ card: PoetryCard) -> Bool {
        var list = poetryCards
        guard !list.contains(where: { $0.id == card.id }) else { return false }
        list.append(card)
        persistPoetryCards(list)
        // generatedCards 保留给旧逻辑（设置页张数统计）读，两者同步维护
        addGeneratedCard(card.id)
        return true
    }

    /// 作品列表按时间倒序（最近生成的排最前，符合"我的作品"直觉）
    var poetryCardsNewestFirst: [PoetryCard] {
        poetryCards.sorted { $0.date > $1.date || ($0.date == $1.date && $0.id > $1.id) }
    }

    func deletePoetryCard(id: String) {
        var list = poetryCards
        list.removeAll { $0.id == id }
        persistPoetryCards(list)
        snapshot.generatedCards.removeAll { $0 == id }
    }

    /// 老版本升级迁移：过去只有离散键、快照 favorites 恒为空。
    /// 快照里还没有任何收藏时，把已置位的离散键补成收藏项，避免升级后收藏全丢。
    /// 注意：init 内的赋值不触发 didSet（属性观察器在初始化阶段不回调），所以这里显式落盘。
    private func migrateLegacyFavorites() {
        guard snapshot.favorites.isEmpty else { return }
        var seeded: [FavoriteItem] = []
        for (key, target) in Self.favoriteKeyMap where bool(key) {
            seeded.append(
                FavoriteItem(id: "\(target.type.rawValue)-\(target.itemId)",
                             type: target.type,
                             itemId: target.itemId,
                             date: AppSnapshot.dateString())
            )
        }
        guard !seeded.isEmpty else { return }
        // 字典遍历顺序不稳定 → 按 id 排一下，保证迁移结果可复现
        seeded.sort { $0.id < $1.id }
        snapshot.favorites = seeded
        saveSnapshot()
    }

    /// 重置：清空全部离散键并恢复默认快照（对应 Web 的 ?reset=1 与 RESET action）
    func resetAll() {
        StorageKeys.all.forEach { remove($0) }
        UserDefaults.standard.removeObject(forKey: StorageKeys.snapshotKey)
        // 诗境卡存在独立键里（见 poetryCardsKey 的注释），resetAll 必须一起清，
        // 否则"重置全部数据"后作品集里还留着上一轮的卡。
        UserDefaults.standard.removeObject(forKey: Self.poetryCardsKey)
        // 用户自选头像也要清（它是 Documents 下的文件 + 一个键，键清了就回默认头像）
        snapshot = .default
    }
}

// MARK: - 收藏类型：筛选取值归一化 + 中文名

extension FavoriteType {
    /// 筛选取值 → 收藏类型。
    /// 配置侧历史取值是 `poetry`（favorites/filter-poetry、profile/stat-poetry），
    /// 而枚举原始值是 `poem`；不归一就是「按 poem 存、按 poetry 筛」，永远筛不出东西。
    /// 返回 nil 表示「全部」（含 all / 空串 / 无法识别的旧值）。
    static func fromFilter(_ raw: String?) -> FavoriteType? {
        guard let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        if text == "all" { return nil }
        if text == "poetry" { return .poem }
        return FavoriteType(rawValue: text)
    }

    /// 筛选条 / 卡片角标用的中文名
    var displayName: String {
        switch self {
        case .poem: return "诗词"
        case .artifact: return "器物"
        case .character: return "人物"
        case .letter: return "书信"
        case .stamp: return "印章"
        }
    }
}

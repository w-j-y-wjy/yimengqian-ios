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

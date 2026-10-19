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
        favorites: [],
        completedTasks: [],
        recentViews: [],
        dialogueCompleted: [],
        feihualingProgress: 0,
        feihualingScore: 0,
        generatedCards: []
    )
}

/// 全局状态 —— 语义对齐 AppContext + localStorage
final class AppStore: ObservableObject {
    @Published var snapshot: AppSnapshot {
        didSet { saveSnapshot() }
    }

    init() {
        snapshot = Self.loadSnapshot()
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
    private static func loadSnapshot() -> AppSnapshot {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.snapshotKey),
              let snap = try? JSONDecoder().decode(AppSnapshot.self, from: data) else {
            return .default
        }
        return snap
    }
    private func saveSnapshot() {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: StorageKeys.snapshotKey)
    }

    /// 重置：清空全部离散键并恢复默认快照（对应 Web 的 ?reset=1 与 RESET action）
    func resetAll() {
        StorageKeys.all.forEach { remove($0) }
        UserDefaults.standard.removeObject(forKey: StorageKeys.snapshotKey)
        snapshot = .default
    }
}

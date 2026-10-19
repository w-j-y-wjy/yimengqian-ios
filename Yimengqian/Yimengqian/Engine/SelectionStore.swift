// SelectionStore.swift
//
// 选择态中心：把「离散存储键」升级成可观察的选中态。
//
// 设计判断（2026-10-19）：
// 原工程有 30+ 处选择类交互（偏好测试 10 项、飞花令 4 项、画风 4 项、意象 4 项、
// 筛选 6 项、话题 3 项…），全部走 `setStorageAndToast`：写 UserDefaults + 弹个提示，
// 界面毫无变化 —— 用户根本看不到自己选了什么。
//
// 两条路：
//  A. 在 ScreensConfig 里把每条动作改成新语义 `.selectOne`；
//  B. 保留配置不动，让 ActionExecutor 写完 UserDefaults 后**镜像**一份到本对象。
//
// 选 B。理由：ScreensConfig 是自动生成的（25 屏 / 329 热区），逐条改语义会让
// 「重跑生成器就丢」的风险面从 1 个文件扩大到 329 条配置；而镜像方案对配置零侵入，
// 将来接入 Phase 4 的新屏也只是多写一个叠层视图。

import Foundation
import Combine

final class SelectionStore: ObservableObject {
    /// 参与「选中态回显」的存储键（全部来自 StorageKeys，不另造键名）
    static let trackedKeys: [String] = [
        StorageKeys.preferenceScene,
        StorageKeys.preferenceContent,
        StorageKeys.preferenceDynasty,
        StorageKeys.preferenceMood,
        StorageKeys.feihualingAnswer,
        StorageKeys.jiangxueStyle,
        StorageKeys.selectedImagery,
        StorageKeys.poetryCardStyle,
        StorageKeys.poetryCardLayout,
        StorageKeys.poetryCardSeal,
        StorageKeys.dialogueTopic,
        StorageKeys.favoriteFilter,
    ]

    /// 已经有叠层把选中态**画出来**的键 → 可以省掉那条 Toast（否则提示会盖住设计稿）。
    /// 每实现一个屏的叠层，就把它的键加进来；没加进来的仍保留原文案提示，不会丢反馈。
    static let visuallyRepresentedKeys: Set<String> = [
        StorageKeys.preferenceScene,
        StorageKeys.preferenceContent,
        StorageKeys.preferenceDynasty,
        StorageKeys.preferenceMood,
        StorageKeys.feihualingAnswer,
    ]

    /// key → 当前选中值
    @Published private(set) var values: [String: String] = [:]

    /// 最近一次「答错」发生在哪一屏。用于飞花令给已选项打叉；用户重选即刻清除。
    @Published private(set) var wrongAnswerScreenID: String?

    private let store: AppStore

    init(store: AppStore) {
        self.store = store
        var seed: [String: String] = [:]
        for key in Self.trackedKeys {
            if let v = store.string(key) { seed[key] = v }
        }
        values = seed
    }

    // MARK: - 查询

    func value(_ key: String) -> String? { values[key] }

    func isSelected(_ key: String, _ candidate: String) -> Bool { values[key] == candidate }

    /// 判断某屏是否处于「刚答错」状态
    func isWrongAnswer(on screenID: String) -> Bool { wrongAnswerScreenID == screenID }

    // MARK: - 写入（由 ActionExecutor 调用，配置侧零改动）

    /// ActionExecutor 写完 UserDefaults 后镜像到这里。
    func note(key: String, value: String, screenID: String) {
        guard Self.trackedKeys.contains(key) else { return }
        if values[key] != value { values[key] = value }
        // 重选即认为"用户在纠正"，清掉答错态
        if wrongAnswerScreenID == screenID { wrongAnswerScreenID = nil }
    }

    func noteWrongAnswer(screenID: String) {
        if wrongAnswerScreenID != screenID { wrongAnswerScreenID = screenID }
    }

    func clearWrongAnswer() {
        if wrongAnswerScreenID != nil { wrongAnswerScreenID = nil }
    }
}

// RewardRules.swift
//
// 行为 → 数值 的唯一账本。
//
// 为什么单独一个文件：原来数值散落在三处 —— SpecialScreens 写离散键 cultureValue、
// ActionExecutor 写 petalCount、AppSnapshot 里又有一份 cultureValue 常量，
// 三者互不问。要"操作符合逻辑"，必须先有一条所有人都认的账。
//
// 记账口径（2026-10-22 定）：
// - 收藏 +5 文化（取消收藏对称扣回，避免反复开关刷分）
// - 飞花令答对 +30 文化 +1 花瓣（每题只记一次，靠 feihualingCompleted 之类的 flag 幂等）
// - 茶坊对谈完成 +50 文化 +10 雅集值
// - 领取任务奖励 +50 文化（替代原先只写离散键的写法）
// - 生成诗境卡 +10 文化 +5 雅集值
// 等级：每 400 文化值升一级（默认 1200 → Lv.4，与设计稿一致）

import Foundation

struct RewardRule {
    var culture: Int = 0
    var ya: Int = 0
    var petals: Int = 0
    /// 记录进 recentViews / dialogueCompleted 之类的行为标识（可选）
    var tag: String? = nil
}

enum RewardRules {
    /// 收藏一项内容的奖励（取消收藏时按负数回扣）
    static let favorite = RewardRule(culture: 5)
    /// 飞花令答对一题
    static let feihualingCorrect = RewardRule(culture: 30, petals: 1, tag: "feihualing")
    /// 茶坊对谈完成
    static let teaDialogue = RewardRule(culture: 50, ya: 10, tag: "teahouse")
    /// 任务结算（茶坊奖励页）
    static let taskReward = RewardRule(culture: 50, tag: "task-reward")
    /// 保存一枚诗境卡
    static let savePoetryCard = RewardRule(culture: 10, ya: 5, tag: "poetry-card")
    /// 领奖页「收下印章」的奖励：必须与设计稿上写的「雅集值 +80 / 花瓣 +6」一致。
    /// 之前这一条只发了印章、写了个没人读的 petalCount 键 —— 页面上的 +80/+6 是画上去的，
    /// 用户回到个人中心看不到任何变化（和「江雪播放键」同一类"假收据"）。
    static let stampClaim = RewardRule(ya: 80, petals: 6, tag: "stamp-reward")

    /// 文化值 → 等级：每 400 一点，1 级起，9 级封顶
    static func level(for culture: Int) -> Int {
        max(1, min(9, culture / 400 + 1))
    }
}

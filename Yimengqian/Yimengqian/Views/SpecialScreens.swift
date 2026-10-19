// SpecialScreens.swift
//
// 来源：移植自 React 原型 src/pages/TaskReward.tsx（onInit 结算）与 src/pages/Splash.tsx（重置）。
// 用途：特殊页面的进入时逻辑 ——
//       - TaskReward：进入即结算一次任务奖励（文化值+50、东坡知音印章、苏轼来信、汴京进度 75%）；
//       - Splash：五连击重置全部数据（对应 Web 的 ?reset=1，实现在 RootView）。
// 说明：onInitHandler 供 RootView 在渲染屏幕时获取对应 onInit 回调。

import Foundation

/// TaskReward：进入即结算奖励（对齐 TaskReward.tsx handleInit，仅一次）
func taskRewardOnInit(store: AppStore) {
    guard store.string(StorageKeys.teaRewardClaimed) != "true" else { return }
    let current = Int(store.string(StorageKeys.cultureValue) ?? "0") ?? 0
    store.setString(StorageKeys.cultureValue, String(current + 50))
    store.setString(StorageKeys.teaRewardClaimed, "true")
    store.setString(StorageKeys.stampDongpo, "true")
    store.setString(StorageKeys.sushiLetter, "true")
    store.setString(StorageKeys.bianjingProgress, "75")
}

/// 返回某屏幕 ID 的 onInit 回调（无则 nil）
func onInitHandler(for screenID: String, store: AppStore) -> (() -> Void)? {
    switch screenID {
    case "task-reward":
        return { taskRewardOnInit(store: store) }
    default:
        return nil
    }
}

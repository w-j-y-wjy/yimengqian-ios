// SpecialScreens.swift
//
// 来源：移植自 React 原型 src/pages/TaskReward.tsx（onInit 结算）与 src/pages/Splash.tsx（重置）。
// 用途：特殊页面的进入时逻辑 ——
//       - TaskReward：进入即结算一次任务奖励（文化值+50、东坡知音印章、苏轼来信、汴京进度 75%）；
//       - 足迹：进入「某座城」的屏时记一笔真实足迹（个人中心底部那三张卡的数据源）；
//       - Splash：五连击重置全部数据（对应 Web 的 ?reset=1，实现在 RootView）。
// 说明：onInitHandler 供 RootView 在渲染屏幕时获取对应 onInit 回调。

import Foundation

/// TaskReward：进入即结算奖励（对齐 TaskReward.tsx handleInit，仅一次）
///
/// 2026-10-22 整改：原实现只往离散键写 cultureValue/stampDongpo/bianjingProgress，
/// 而个人中心读的是快照字段、印章读的是 snapshot.stamps —— 于是"领了奖但哪里都没变"。
/// 现在统一走 AppStore.applyReward / grantStamp；离散键仍照写（兼容旧逻辑与 resetAll）。
func taskRewardOnInit(store: AppStore) {
    guard store.string(StorageKeys.teaRewardClaimed) != "true" else { return }
    store.setString(StorageKeys.teaRewardClaimed, "true")
    store.setString(StorageKeys.stampDongpo, "true")
    store.setString(StorageKeys.sushiLetter, "true")
    store.setString(StorageKeys.bianjingProgress, "75")
    store.applyReward(RewardRules.taskReward)
    store.grantStamp(id: "dong-po-zhi-yin")
}

/// 返回某屏幕 ID 的 onInit 回调（无则 nil）
func onInitHandler(for screenID: String, store: AppStore) -> (() -> Void)? {
    switch screenID {
    case "task-reward":
        return { taskRewardOnInit(store: store) }
    default:
        // 任何"到了某座城"的屏都顺手记一笔足迹。
        // 为什么挂在 onInit 而不是 Router：Router 只认路由字符串、拿不到 store；
        // 而 onInit 是"这一屏已经渲染出来"的时机，语义上就等于"用户真的到过这里"。
        // recordVisit 自身按 tag 去重、只保留最近一次日期，反复进出不会把记录撑爆。
        if let place = PlaceCatalog.place(forScreen: screenID) {
            return { store.recordPlace(place.id) }
        }
        return nil
    }
}

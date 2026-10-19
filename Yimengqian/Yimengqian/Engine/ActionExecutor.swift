// ActionExecutor.swift
//
// 来源：移植自 React 原型 app-project/src/components/ImageScreen.tsx 的 executeAction()，
//       是 15 种热区动作在 iOS 端的唯一权威实现（语义逐行对齐）。
// 用途：将 HotspotAction（见 Config/ScreensConfig.swift）翻译为对
//       AppStore（存储）/ Router（导航）/ ToastCenter（提示）的具体调用。
//
// 与 ImageScreen.tsx 的语义对齐说明：
// - toggleStorage：React 中"当前有值 → 移除并提示 offMessage；无值 → 写入 'true' 并提示 onMessage"。
//   本实现依赖 AppStore.toggle(_:) 返回"新状态"（开启后为 true），因此
//   isOn == true 对应 onMessage（默认"已收藏"），isOn == false 对应 offMessage（默认"已取消"），与原型一致。
// - checkAnswer：三分支——无答案 → 提示 message（默认"请先选择答案"）；
//   答案错误 → 提示"回答错误，请重新选择"；正确 → 写入 storageFlags 并跳转 target。
// - incrementOnce：仅当 flagKey 尚未写入时才写入 flag 并给 storageKey 计数 +1；
//   无 flagKey 时只展示 message，不写任何存储（与原型一致）。
// - conditionalJump：onboardingComplete 为 true 时直达 /home（清栈 jump），
//   否则按 action.target 普通压栈 navigate（与原型 navigate 语义一致）。
// - screenID 参数当前未使用，保留参数名以便未来接入埋点/统计。

import Foundation

final class ActionExecutor {
    private let store: AppStore
    private let router: Router
    private let toast: ToastCenter
    /// 选择态镜像（Phase 2 新增）。可选，缺省不影响既有 15 种动作的行为。
    private let selection: SelectionStore?

    init(store: AppStore, router: Router, toast: ToastCenter, selection: SelectionStore? = nil) {
        self.store = store
        self.router = router
        self.toast = toast
        self.selection = selection
    }

    func execute(_ action: HotspotAction, screenID: String) {
        switch action.type {
        case .navigate:
            if let target = action.target { router.navigate(route: target) }

        case .back:
            router.back()

        case .toast:
            if let m = action.message { toast.show(m) }

        case .storage:
            action.storage?.forEach { store.setString($0.key, $0.value) }

        case .storageAndToast:
            action.storage?.forEach {
                store.setString($0.key, $0.value)
                selection?.note(key: $0.key, value: $0.value, screenID: screenID)
            }
            if let m = action.message { toast.show(m) }

        case .conditionalNavigate:
            // ImageScreen：无 dialogueTopic → toast；有 → 写 teaDialogueCompleted 并跳转
            if store.string("dialogueTopic") == nil {
                toast.show(action.message ?? "请先选择一个话题")
            } else {
                store.setString("teaDialogueCompleted", "true")
                if let target = action.target { router.navigate(route: target) }
            }

        case .setStorageAndToast:
            if let key = action.storageKey {
                let value = action.storageValue ?? "true"
                store.setString(key, value)
                selection?.note(key: key, value: value, screenID: screenID)
                // 该键已经有叠层把选中态画出来了 → 省掉 Toast，否则提示条会盖住设计稿
                if SelectionStore.visuallyRepresentedKeys.contains(key) { break }
            }
            if let m = action.message { toast.show(m) }

        case .toggleStorage:
            guard let key = action.storageKey else { return }
            let isOn = store.toggle(key)
            toast.show(isOn ? (action.onMessage ?? "已收藏") : (action.offMessage ?? "已取消"))

        case .storageAndNavigate:
            if let key = action.storageKey, let target = action.target {
                let value = action.storageValue ?? target
                store.setString(key, value)
                selection?.note(key: key, value: value, screenID: screenID)
                router.navigate(route: target)
            }

        case .conditionalStorageNavigate:
            if let key = action.storageKey, store.string(key) == nil {
                let value = action.defaultValue ?? "true"
                store.setString(key, value)
                selection?.note(key: key, value: value, screenID: screenID)
            }
            if let target = action.target { router.navigate(route: target) }

        case .incrementOnce:
            if let flag = action.flagKey, store.string(flag) == nil {
                store.setString(flag, "true")
                if let countKey = action.storageKey {
                    store.incrementInt(countKey, by: 1)
                }
            }
            if let m = action.message { toast.show(m) }

        case .delayedNavigate:
            if let m = action.message { toast.show(m) }
            if let target = action.target {
                // ImageScreen.tsx 以毫秒计时（setTimeout(…, action.delay || 600)），配置值 600/800 均为毫秒
                let delayMs = action.delay ?? 600
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(delayMs))) { [weak self] in
                    self?.router.navigate(route: target)
                }
            }

        case .conditionalJump:
            if store.bool("onboardingComplete") {
                if let home = ScreenCatalog.screen(route: "/home") {
                    router.jump(to: home)
                }
            } else if let target = action.target {
                router.navigate(route: target)
            }

        case .setDefaultsAndNavigate:
            action.defaults?.forEach { kv in store.setIfAbsent(kv.key, kv.value) }
            if let target = action.target { router.navigate(route: target) }

        case .checkAnswer:
            let answer = action.storageKey.flatMap { store.string($0) }
            if answer == nil {
                toast.show(action.message ?? "请先选择答案")
            } else if answer != action.correctAnswer {
                // 让叠层把"选中的这一项"标成错，而不是只弹一句提示就没了下文
                selection?.noteWrongAnswer(screenID: screenID)
                toast.show("回答错误，请重新选择")
            } else {
                selection?.clearWrongAnswer()
                action.storageFlags?.forEach { store.setString($0.key, $0.value) }
                if let target = action.target { router.navigate(route: target) }
            }
        }
    }
}

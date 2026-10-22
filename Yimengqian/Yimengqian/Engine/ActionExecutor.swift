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
            guard let target = action.target else { return }
            // 收藏页编辑模式：同一批 item-* 热区在编辑态下语义变成「取消收藏」。
            // 为什么放在这里拦截而不是给热区换动作：热区动作是生成物（静态配置），
            // 而「是否处于编辑模式」是运行期状态；在唯一入口分流一次，配置不用改动。
            if selection?.value(StorageKeys.favoritesEditing) == "true",
               favoriteSlotIndex(from: target) != nil {
                removeFavorite(at: target)
                return
            }
            router.navigate(route: target)

        case .speakText:
            // 朗读：文本放在 message 里（生成器把 speakText 的 text 写进 message）。
            // 工程内没有音频素材，用系统语音合成 —— 但这是**真的会出声**，不再是假反馈。
            if let text = action.message {
                SpeechCenter.shared.speak(text)
            }

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
                // 对谈完成：除了置位，还要记账（文化值+50/雅集值+10）并记下话题，
                // 否则「完成一次对谈→个人中心数字变化」这条链路是断的。
                let firstTime = store.string("teaDialogueCompleted") == nil
                store.setString("teaDialogueCompleted", "true")
                if let topic = store.string("dialogueTopic") { store.completeDialogue(topic: topic) }
                if firstTime {
                    let gain = store.applyReward(RewardRules.teaDialogue)
                    if !gain.isEmpty { toast.show("对谈完成 · \(gain)") }
                }
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
            // 收藏类热区（§1 的「假收藏」）：过去只往离散键写一个 "true"，收藏页读的是
            // snapshot.favorites，界面因此毫无变化。命中映射表时改走 toggleFavorite，
            // 离散键由 AppStore 作为镜像同步 —— 配置侧零改动，重跑生成器也不会回退。
            if let target = AppStore.favoriteKeyMap[key] {
                let added = store.toggleFavorite(type: target.type, itemId: target.itemId)
                // 收藏 +5 文化值；取消时对称扣回，避免反复开关刷分
                store.applyReward(RewardRule(culture: added ? 5 : -5))
                toast.show(added ? (action.onMessage ?? "已收藏") : (action.offMessage ?? "已取消"))
                return
            }
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
                // 领奖类热区：配置里只写了 flag 与一个没人读的计数，
                // 命中「flag → 印章」映射时才真的发章进快照（否则「已收入收藏」是句空话）。
                if let stampId = AppStore.stampClaimMap[flag] {
                    store.grantStamp(id: stampId)
                }
                // 保存诗境卡：记账 + 记进作品列表（不然「我的作品/最近生成」永远是死的）
                if flag == StorageKeys.jiangxueCardCreated {
                    store.applyReward(RewardRules.savePoetryCard)
                    store.addGeneratedCard("jiangxue-card")
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
            // setIfAbsent：只在缺失时补默认值。镜像时必须读**实际存下来的值**，
            // 否则"没选任何项直接点生成"会出现：存储里已有默认值、叠层却显示全未选。
            action.defaults?.forEach { kv in
                store.setIfAbsent(kv.key, kv.value)
                if let actual = store.string(kv.key) {
                    selection?.note(key: kv.key, value: actual, screenID: screenID)
                }
            }
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
                // 判题前先看 flag 是否已置位：答对奖励只能记一次，重玩不再刷分
                let alreadyRewarded = action.storageFlags?.isEmpty == false
                    && (action.storageFlags ?? []).allSatisfy { store.string($0.key) != nil }
                action.storageFlags?.forEach { store.setString($0.key, $0.value) }
                if !alreadyRewarded {
                    let gain = store.applyReward(RewardRules.feihualingCorrect)
                    if !gain.isEmpty { toast.show("答对了 · \(gain)") }
                }
                if let target = action.target { router.navigate(route: target) }
            }
        }
    }

    // MARK: - 收藏页编辑模式

    /// `/native/favorite/<序号>` → 序号；其它路由返回 nil
    private func favoriteSlotIndex(from target: String) -> Int? {
        guard target.hasPrefix("/native/favorite/") else { return nil }
        return Int(target.replacingOccurrences(of: "/native/favorite/", with: ""))
    }

    /// 取消收藏第 N 格（编辑模式下点卡片）。
    /// 与打开详情同样的取数口径：先按当前筛选取列表，再取第 N 条 —— 保证「点哪取消哪」。
    ///
    /// 陷阱：`collection` 里印章栏是「已获得 + 已收藏」的合并结果，
    /// 已获得的印章**并不在 snapshot.favorites 里**。若直接 toggleFavorite，
    /// 会把它当成「新增收藏」——于是编辑模式下点印章，收藏只增不减。
    /// 所以印章单独处理：不在收藏列表里就明确告知「印章不可移除」。
    private func removeFavorite(at target: String) {
        guard let index = favoriteSlotIndex(from: target) else { return }
        let filter = selection?.value(StorageKeys.favoriteFilter)
        let items = store.collection(filter: filter)
        guard index < items.count else {
            toast.show("这一格现在是空的")
            return
        }
        let item = items[index]
        let isFavorited = store.isFavorite(type: item.type, itemId: item.itemId)
        if !isFavorited {
            // 已获得的印章走这条路：它是成就，不是收藏
            toast.show(item.type == .stamp ? "印章是成就，不可移除" : "这一格现在是空的")
            return
        }
        _ = store.toggleFavorite(type: item.type, itemId: item.itemId)
        store.applyReward(RewardRule(culture: -5))
        toast.show("已取消收藏")
    }
}

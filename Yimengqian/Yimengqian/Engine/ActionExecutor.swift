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

        case .toggleTorch:
            // 真·闪光灯：有摄像头就开/关 torch，没有就如实说明原因（旧实现只弹「闪光灯模拟」）
            if let failure = TorchCenter.shared.toggle() {
                toast.show(failure)
            } else {
                toast.show(TorchCenter.shared.isOn ? "闪光灯已开" : "闪光灯已关")
            }

        case .aiGenerate:
            // AI 通道：有 key 走在线，没 key 走本地规则 —— 两种情况都一定有结果，
            // 且结果会标注来源（本地规则 / 在线生成），不把规则引擎说成语言模型。
            let intent = AIIntent(rawValue: action.storageValue ?? "") ?? .cardNote
            let prompt = action.message ?? ""
            AIBridge.shared.generate(intent: intent, prompt: prompt) { result in
                self.store.setString(StorageKeys.aiResult, result.text)
                self.store.setString(StorageKeys.aiResultSource, result.sourceLabel)
                self.toast.show("\(result.sourceLabel)：\(result.text)")
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
                // 保存诗境卡：记账 + 真正生成一张卡面存进作品集
                // （旧实现只 addGeneratedCard 一个 id，作品页画不出卡，等于"存了个编号"）
                if flag == StorageKeys.jiangxueCardCreated {
                    store.applyReward(RewardRules.savePoetryCard)
                    savePoetryCardSnapshot()
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
            // 判对口径：correctAnswers 非空则以集合为准，否则回落到单值 correctAnswer。
            // 为什么必须有集合：飞花令第 1 题令字是「春」，A「春眠不觉晓」与 C「春风得意马蹄疾」
            // 都真的含「春」，单值判题会把选 C 的人判错 —— 现场只要有人说「C 也含春」，
            // 「真实判题」当场失去可信度。
            let accepted: [String]
            if let set = action.correctAnswers, !set.isEmpty {
                accepted = set
            } else if let single = action.correctAnswer {
                accepted = [single]
            } else {
                accepted = []
            }
            if answer == nil {
                toast.show(action.message ?? "请先选择答案")
            } else if !accepted.contains(answer!) {
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

    // MARK: - 诗境卡：保存真实卡面
    //
    // 保存那一刻把「诗句 + 题注 + 画风 + 版式 + 印章」冻结成一张 PoetryCard。
    // 为什么冻结：用户存完继续调选项，旧卡不该跟着变 —— 作品集里每张都应是那一次的结果。
    private func savePoetryCardSnapshot() {
        let poems = NativeDetail.allPoems()
        // 默认取《江雪》：诗境卡的入口就是江雪诗境页；找不到就取第一首
        let poem = poems.first(where: { $0.id == "jiangxue" }) ?? poems.first(where: { $0.title == "江雪" })
        let title = poem?.title ?? "江雪"
        let line = poem.map { Self.firstTwoLines($0.content) } ?? "千山鸟飞绝，万径人踪灭"

        let card = PoetryCard(
            id: "card-\(Int(Date().timeIntervalSince1970))",
            poemLine: line,
            poemTitle: title,
            note: store.string(StorageKeys.cardNote) ?? "",
            style: store.string(StorageKeys.poetryCardStyle) ?? "ink",
            layout: store.string(StorageKeys.poetryCardLayout) ?? "horizontal",
            seal: store.string(StorageKeys.poetryCardSeal) ?? "red",
            image: poem?.image ?? "ArtApp/poem-niao-ming-jian.jpg",
            date: AppSnapshot.dateString()
        )
        if store.savePoetryCard(card) {
            toast.show("已保存到「我的作品」")
        } else {
            toast.show("这张卡已经保存过了")
        }
    }

    /// 卡面正文取前两句：整首诗排进 3:5 的卡里会挤成一行小字，前两句最像"题画诗"
    private static func firstTwoLines(_ content: String) -> String {
        let parts = content
            .replacingOccurrences(of: "。", with: "。\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.prefix(2).joined(separator: "\n")
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

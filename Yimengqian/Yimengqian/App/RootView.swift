// RootView.swift
//
// 来源：对齐 React 原型 App.tsx（路由栈）与 global.css（app-frame / toast 布局）。
// 用途：根视图 —— 渲染路由栈栈顶屏幕（直接换图、无转场动画），在顶层叠加 Toast 浮层；
//       启动页（splash）支持五连击重置全部数据（对应 Web 的 ?reset=1）。

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var toast: ToastCenter
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var selection: SelectionStore

    @State private var resetTapCount = 0
    @State private var resetTapAt: Date?
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            // 真骨架：TabView + 每个 tab 一条独立栈。
            // 系统 tabBar 暂时隐藏 —— 位图里已经画了一条底栏，两条叠着会出现双层；
            // 等底栏原生化（下一步）时再把系统 tabBar 放出来。
            TabView(selection: Binding(
                get: { router.activeTab },
                set: { router.selectTab($0) }
            )) {
                ForEach(AppTab.allCases) { tab in
                    sceneLayer(for: tab)
                        .tag(tab)
                        .toolbar(.hidden, for: .tabBar)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let msg = toast.message {
                ToastView(message: msg)
                    .padding(.bottom, 90)
            }
        }
        // 原生页（/native/...）：从"自绘浮层 + 手写边缘手势"换成真正的 NavigationStack。
        // 换的理由：
        // 1) 系统自带交互式返回（左缘右滑带跟手动画），不必再手写 DragGesture；
        // 2) 每层页面是真正的 push，标题栏/安全区由系统统一处理；
        // 3) 以后加 tab 时，一个 tab 一条 path，结构才对得上「真骨架」。
        // 代价：NavigationStack 需要 iOS 16（本项目最低版本已从 15 提到 16）。
        .overlay {
            NavigationStack(path: Binding(
                get: { router.nativePath },
                set: { router.nativePath = $0 }
            )) {
                Color.clear
                    .navigationDestination(for: NativeDetail.self) { detail in
                        nativeDestination(detail)
                            .navigationBarHidden(true)
                    }
            }
        }
        .alert("重置全部旅程数据？", isPresented: $showResetConfirm) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) { performReset() }
        } message: {
            Text("将清空偏好、收藏、印章与全部进度。此操作不可撤销。")
        }
        .statusBarHidden(true)
        .preferredColorScheme(.light)
        .environmentObject(store)
        .environmentObject(router)
        .environmentObject(toast)
    }

    /// 原生页分发：与改造前的 switch 同源，只是从 overlay 内联搬到 navigationDestination。
    @ViewBuilder
    private func nativeDestination(_ detail: NativeDetail) -> some View {
        if case .settings = detail {
            NativeSettingsView()
        } else if case .search = detail {
            NativeSearchView()
        } else if case .share = detail {
            NativeShareView()
        } else if case .note = detail {
            NativeNoteView()
        } else if case .profileEdit = detail {
            NativeProfileEditView()
        } else if case .photo = detail {
            // 结果页那颗「相册」按钮：不自动弹选择器，由用户自己点
            ArtifactRecognizeView(source: "manual")
        } else if case .recognize(let source) = detail {
            ArtifactRecognizeView(source: source)
        } else if case .dialogue(let topicID) = detail {
            NativeDialogueView(topicID: topicID)
        } else if case .favoriteSlot(let index) = detail {
            NativeFavoriteSlotView(index: index)
        } else if case .list(let listID) = detail {
            NativeListView(listID: listID)
        } else if case .card(let cardID) = detail {
            NativePoetryCardView(cardID: cardID)
        } else if case .identity = detail {
            NativeIdentityView()
        } else if let content = NativeDetailContent.resolve(detail, obtainedStamps: obtainedStamps) {
            NativeDetailView(detail: detail, content: content)
        } else {
            EmptyView()
        }
    }

    /// 一个 tab 的内容：当前 tab 渲染它自己的栈顶，其余 tab 渲染各自根屏。
    /// 这样切 tab 不会丢失历史（Router 里每个 tab 一条 `stacks[tab]`）。
    @ViewBuilder
    private func sceneLayer(for tab: AppTab) -> some View {
        let screen: ScreenConfig? = tab == router.activeTab
            ? router.top
            : ScreenCatalog.screen(id: tab.rootScreenID)
        if let screen = screen {
            HotspotScreenView(
                screen: screen,
                onInit: onInitHandler(for: screen.id, store: store),
                onExtraTap: screen.id == "splash" ? handleSplashTap : nil
            )
            // 不做转场动画：设计稿屏直接换图（用户 2026-10-21 真机验收要求）。
            // 只有原生页（/native/...）走 NavigationStack 的系统推入动画。
            .id(screen.id + "|" + String(router.stack.count) + "|" + tab.rawValue)
        }
    }

    /// 已获得的印章 id（印章详情按真实状态显示，而不是编译期常量）
    private var obtainedStamps: Set<String> {
        Set(store.snapshot.stamps.filter { $0.obtained }.map { $0.id })
    }

    /// 启动页五连击重置（对应 Web ?reset=1）。
    /// 破坏性操作必须二次确认：旧实现静默清空数据，界面毫无变化，属隐藏的数据丢失路径。
    /// 五连击同样加 3 秒时间窗，避免跨屏、跨时长累计误触发。
    private func handleSplashTap() {
        let now = Date()
        if let last = resetTapAt, now.timeIntervalSince(last) <= 3.0 {
            resetTapCount += 1
        } else {
            resetTapCount = 1
        }
        resetTapAt = now

        guard resetTapCount >= 5 else { return }
        resetTapCount = 0
        resetTapAt = nil
        showResetConfirm = true
    }

    private func performReset() {
        store.resetAll()
        // 头像文件在沙盒 Documents 里，不在 UserDefaults，resetAll 清不到 —— 必须显式删
        AvatarStore.clear()
        // 选择态必须一起清：SelectionStore 启动时从 UserDefaults seed 一次就不再重读，
        // 漏掉这一步，重置后偏好测试的描边、飞花令的选中框、收藏的筛选高亮都还停在上一轮。
        // （这正是 08 文档说的"答错态跨屏残留"同一类问题，2026-10-21 体检发现无人调用。）
        selection.reset()
        // 清空路由栈回到启动页，避免"数据已清空但仍停留在内页"的错乱状态
        if let splash = ScreenCatalog.screen(id: "splash") {
            router.jump(to: splash)
        }
        toast.show("已重置全部旅程数据")
    }
}

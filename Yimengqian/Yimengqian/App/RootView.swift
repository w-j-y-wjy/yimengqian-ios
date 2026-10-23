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

            if let top = router.top {
                HotspotScreenView(
                    screen: top,
                    onInit: onInitHandler(for: top.id, store: store),
                    onExtraTap: top.id == "splash" ? handleSplashTap : nil
                )
                .id(top.id + "|" + String(router.stack.count))
                // 不做转场动画：这是「一屏一张设计稿」的点击原型，从右滑入会把整页图
                // 像卡片一样推过来，反而暴露它是拼出来的。直接换图更像原生 App。
                // （用户 2026-10-21 真机验收要求：不要左右推入，直接切换。）
            }
        }
        .overlay(alignment: .bottom) {
            if let msg = toast.message {
                ToastView(message: msg)
                    .padding(.bottom, 90)
            }
        }
        // 原生浮层（/native/...）：详情页或列表页，盖在整屏设计稿之上、可交互；
        // 关闭只清浮层，不动路由栈（避免"在设计稿上点返回误退一屏"）
        .overlay {
            if let detail = router.nativeDetail {
                Group {
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
                        NativePhotoPickView()
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
                    } else if let content = NativeDetailContent.resolve(detail) {
                        NativeDetailView(detail: detail, content: content)
                    }
                }
                .zIndex(2)
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

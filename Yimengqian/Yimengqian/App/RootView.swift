// RootView.swift
//
// 来源：对齐 React 原型 App.tsx（路由栈）与 global.css（app-frame / toast 布局）。
// 用途：根视图 —— 渲染路由栈栈顶屏幕（带转场动画），在顶层叠加 Toast 浮层；
//       启动页（splash）支持五连击重置全部数据（对应 Web 的 ?reset=1）。

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var toast: ToastCenter
    @EnvironmentObject private var store: AppStore

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
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: router.navigationID)
        .overlay(alignment: .bottom) {
            if let msg = toast.message {
                ToastView(message: msg)
                    .padding(.bottom, 90)
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
        // 清空路由栈回到启动页，避免"数据已清空但仍停留在内页"的错乱状态
        if let splash = ScreenCatalog.screen(id: "splash") {
            router.jump(to: splash)
        }
        toast.show("已重置全部旅程数据")
    }
}

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
        .statusBarHidden(true)
        .preferredColorScheme(.light)
        .environmentObject(store)
        .environmentObject(router)
        .environmentObject(toast)
    }

    /// 启动页五连击重置（对应 Web ?reset=1）
    private func handleSplashTap() {
        resetTapCount += 1
        if resetTapCount >= 5 {
            resetTapCount = 0
            store.resetAll()
        }
    }
}

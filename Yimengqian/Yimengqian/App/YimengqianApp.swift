// YimengqianApp.swift
//
// 一梦千年 iOS 版应用入口。
// 架构：SwiftUI + ObservableObject（AppStore / Router / ToastCenter 注入环境）。
// 初始屏幕为 splash；若 ScreenCatalog 异常则兜底到第一屏。

import SwiftUI

@main
struct YimengqianApp: App {
    @StateObject private var store: AppStore
    @StateObject private var router: Router
    @StateObject private var toast = ToastCenter()

    init() {
        let store = AppStore()
        let initial = ScreenCatalog.screen(id: "splash") ?? ScreenCatalog.all[0]
        let router = Router(initial: initial)
        _store = StateObject(wrappedValue: store)
        _router = StateObject(wrappedValue: router)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
                .environmentObject(toast)
                .tint(Theme.vermilion)
        }
    }
}

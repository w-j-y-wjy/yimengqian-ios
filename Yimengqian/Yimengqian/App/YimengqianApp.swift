// YimengqianApp.swift
//
// 一梦千年 iOS 版应用入口。
// 架构：SwiftUI + ObservableObject（AppStore / Router / ToastCenter 注入环境）。
// 初始屏幕为 splash；若 ScreenCatalog 异常则兜底到第一屏。

import SwiftUI
import Foundation

@main
struct YimengqianApp: App {
    @StateObject private var store: AppStore
    @StateObject private var router: Router
    @StateObject private var toast = ToastCenter()
    @StateObject private var selection: SelectionStore

    init() {
        let store = AppStore()
        // 支持调试 / CI 用的启动参数：`-initialScreen <屏幕 id>`。
        // iOS 会把 "-key value" 形式的启动参数自动注入 UserDefaults 的 ArgumentDomain，
        // 所以 `-preferenceScene landscape` 这类"预置选择"也无需额外代码即可生效——
        // CI 就是靠它直接截到"已选中"的画面，而不必真的去点。
        let startID = UserDefaults.standard.string(forKey: "initialScreen") ?? "splash"
        let initial = ScreenCatalog.screen(id: startID)
            ?? ScreenCatalog.screen(id: "splash")
            ?? ScreenCatalog.all[0]
        let router = Router(initial: initial)
        _store = StateObject(wrappedValue: store)
        _router = StateObject(wrappedValue: router)
        // 选择态由 AppStore 派生：读出已存的选择，后续写入经 ActionExecutor 镜像回来
        _selection = StateObject(wrappedValue: SelectionStore(store: store))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
                .environmentObject(toast)
                .environmentObject(selection)
                .tint(Theme.vermilion)
        }
    }
}

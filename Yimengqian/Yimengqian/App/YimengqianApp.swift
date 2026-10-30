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
        // 调试 / CI 用：`-nativeDetail /native/poem/niao-ming-jian` 直接打开原生详情页，
        // 不需要真实点击就能截图验证（整屏设计稿仍用 -initialScreen）
        if let raw = UserDefaults.standard.string(forKey: "nativeDetail"),
           let detail = NativeDetail.parse(raw) {
            router.openNative(detail)
        }
        // 调试 / CI 用：`-resetProgress 1` 先把进度清干净再截图。
        // 为什么需要：simctl 每次 launch 不会重置 UserDefaults，前面截图预置过的足迹/头像
        // 会一直留着 —— 想验证"空态"就必须先清一次。
        if UserDefaults.standard.bool(forKey: "resetProgress") {
            store.resetAll()
            AvatarStore.clear()
        }
        // 调试 / CI 用：`-seedFootprints "bianjing@0,linan@1,jinling@3"`
        // 预置「最近足迹」（@ 后面是天数），这样截图能验证叠层在 1 条 / 3 条 / 空态下的样子，
        // 而不必在模拟器里真的点进三座城。不传就完全不影响正常流程。
        if let raw = UserDefaults.standard.string(forKey: "seedFootprints") {
            for token in raw.split(separator: ",") {
                let parts = token.split(separator: "@").map(String.init)
                guard let pid = parts.first, PlaceCatalog.place(id: pid) != nil else { continue }
                let daysAgo = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
                store.recordPlace(pid, date: AppSnapshot.dateString(daysAgo: daysAgo))
            }
        }
        // 调试 / CI 用：`-dumpScoreMatrix 1` 把本机比对的分数矩阵写到 Documents/score-matrix.txt。
        // 阈值该定多少只能看这张矩阵 —— 拍脑袋定的 0.45 曾让苏轼画像以 93% 命中青花瓶。
        // 不带这个参数就完全不运行，正式使用不受影响。
        ArtifactScoreProbe.runIfRequested()
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

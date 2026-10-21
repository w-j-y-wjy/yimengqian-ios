// Router.swift
//
// 来源：对齐 React 原型 react-router 的 navigate(route) / navigate(-1) / 直达跳转语义。
// 用途：Yimengqian 的屏幕路由栈（基于 Config/ScreensConfig.swift 的 ScreenConfig）。
//       - push(_:)          对应 navigate(route)，压栈并触发转场令牌更新；
//       - back()            对应 navigate(-1)，栈底不动作；
//       - navigate(route:)  按路由查 ScreenCatalog 后压栈；
//       - jump(to:)         替换整个栈（对齐 conditionalJump 直达 /home：清空栈再推入目标）。
// 说明：@Published navigationID 是「换屏令牌」，值一变 RootView 就重建当前屏。
//       2026-10-21 起不再驱动转场动画（真机验收要求直接换图，不要左右推入）。

import Foundation
import SwiftUI

final class Router: ObservableObject {
    @Published private(set) var stack: [ScreenConfig] = []
    @Published var navigationID = UUID()  // 换屏令牌（只用来强制重建视图，不驱动动画）
    /// 原生详情浮层（/native/... 路由）。为 nil 时不显示，也不改动路由栈。
    @Published var nativeDetail: NativeDetail?

    init(initial: ScreenConfig) {
        stack = [initial]
    }

    var top: ScreenConfig? { stack.last }

    /// 推入新屏幕（对齐 navigate(route)）
    func push(_ screen: ScreenConfig) {
        stack.append(screen)
        navigationID = UUID()
    }

    /// 出栈（对齐 navigate(-1)；栈底不动作）
    /// 注意：原生详情浮层优先关闭 —— 否则在设计稿上点"返回"会误退到上一屏。
    func back() {
        if nativeDetail != nil {
            nativeDetail = nil
            return
        }
        guard stack.count > 1 else { return }
        stack.removeLast()
        navigationID = UUID()
    }

    /// 按路由跳转：先看是不是原生详情路由，再查设计稿屏幕。
    /// 这样热区配置里可以直接写 /native/poem/xxx，不需要新增动作类型。
    func navigate(route: String) {
        if let detail = NativeDetail.parse(route) {
            openNative(detail)
            return
        }
        guard let screen = ScreenCatalog.screen(route: route) else { return }
        push(screen)
    }

    /// 打开原生详情/列表（内容解析失败就忽略，绝不出现空白页）
    func openNative(_ detail: NativeDetail) {
        if detail.isList {
            nativeDetail = detail
            return
        }
        guard NativeDetailContent.resolve(detail) != nil else { return }
        nativeDetail = detail
    }

    func closeNative() {
        nativeDetail = nil
    }

    /// 替换栈顶（对齐 conditionalJump 直达 /home：清空栈再推入目标）
    func jump(to screen: ScreenConfig) {
        stack = [screen]
        navigationID = UUID()
    }
}

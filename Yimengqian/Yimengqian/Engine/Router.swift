// Router.swift
//
// 来源：对齐 React 原型 react-router 的 navigate(route) / navigate(-1) / 直达跳转语义。
// 用途：Yimengqian 的屏幕路由栈（基于 Config/ScreensConfig.swift 的 ScreenConfig）。
//       - push(_:)          对应 navigate(route)，压栈并触发换屏令牌更新；
//       - back()            对应 navigate(-1)，栈底不动作；
//       - navigate(route:)  按路由查 ScreenCatalog 后压栈；
//       - jump(to:)         替换整个栈（对齐 conditionalJump 直达 /home：清空栈再推入目标）。
// 说明：@Published navigationID 是「换屏令牌」，值一变 RootView 就重建当前屏。
//       2026-10-21 起不再驱动转场动画（真机验收要求直接换图，不要左右推入）。
//
// 2026-10-27 三个「像不像软件」的修正：
// 1) 原生浮层从"只能一层"改成**小栈**：诗库 → 点一首诗 → 返回要回到诗库，
//    而不是一路退回设计稿重新滚一遍；
// 2) 连点防护：同一屏连续压栈只会让返回要按 N 次（真机上很常见的手指抖动）；
// 3) 底栏五个 tab 改成**替换栈**而不是压栈：反复点"首页⇄古城⇄收藏"时栈会无限长。

import Foundation
import SwiftUI

final class Router: ObservableObject {
    @Published private(set) var stack: [ScreenConfig] = []
    @Published var navigationID = UUID()  // 换屏令牌（只用来强制重建视图，不驱动动画）

    /// 原生浮层栈（/native/... 路由）。栈空时不显示任何浮层，也不改动设计稿栈。
    /// 为什么改成数组：原生列表点进详情时，返回应当回到列表而不是退回设计稿。
    @Published private(set) var nativeStack: [NativeDetail] = []

    /// 当前展示的原生浮层
    var nativeDetail: NativeDetail? { nativeStack.last }

    init(initial: ScreenConfig) {
        stack = [initial]
    }

    var top: ScreenConfig? { stack.last }

    /// 底栏 tab 的根路由：点它们等于切 tab，不该在栈上越叠越高
    private static let tabRoutes: Set<String> = [
        "/home", "/city/bianjing", "/activities", "/favorites", "/profile",
    ]

    /// 推入新屏幕（对齐 navigate(route)）
    func push(_ screen: ScreenConfig) {
        // 底栏切换：替换整栈（与系统 App 的 tab 行为一致，也避免栈无限增长）
        if Self.tabRoutes.contains(screen.route) {
            if stack.last?.route != screen.route {
                stack = [screen]
                navigationID = UUID()
            }
            return
        }
        // 连点防护：目标就是当前栈顶时不再压一层
        if stack.last?.id == screen.id { return }
        stack.append(screen)
        navigationID = UUID()
    }

    /// 出栈（对齐 navigate(-1)；栈底不动作）
    /// 注意：原生浮层优先关闭 —— 否则在设计稿上点"返回"会误退到上一屏。
    func back() {
        if !nativeStack.isEmpty {
            nativeStack.removeLast()
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
        // 从原生页里跳设计稿页时必须先把浮层收起，否则新屏被浮层盖住，
        // 用户看到的只是"点了没反应"（身份详情页的「重新测一次」就踩过这条）。
        if !nativeStack.isEmpty { nativeStack.removeAll() }
        push(screen)
    }

    /// 打开原生详情/列表/设置（内容解析失败就忽略，绝不出现空白页）
    func openNative(_ detail: NativeDetail) {
        if !detail.isNativePage, NativeDetailContent.resolve(detail) == nil { return }
        // 同一页连点不重复入栈
        if nativeStack.last == detail { return }
        nativeStack.append(detail)
    }

    /// 关闭当前原生浮层（返回一层；没有浮层时什么也不做）
    func closeNative() {
        if !nativeStack.isEmpty { nativeStack.removeLast() }
    }

    /// 替换栈顶（对齐 conditionalJump 直达 /home：清空栈再推入目标）
    func jump(to screen: ScreenConfig) {
        stack = [screen]
        nativeStack.removeAll()
        navigationID = UUID()
    }
}

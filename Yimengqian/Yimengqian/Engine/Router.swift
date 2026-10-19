// Router.swift
//
// 来源：对齐 React 原型 react-router 的 navigate(route) / navigate(-1) / 直达跳转语义。
// 用途：Yimengqian 的屏幕路由栈（基于 Config/ScreensConfig.swift 的 ScreenConfig）。
//       - push(_:)          对应 navigate(route)，压栈并触发转场令牌更新；
//       - back()            对应 navigate(-1)，栈底不动作；
//       - navigate(route:)  按路由查 ScreenCatalog 后压栈；
//       - jump(to:)         替换整个栈（对齐 conditionalJump 直达 /home：清空栈再推入目标）。
// 说明：@Published navigationID 作为转场令牌，视图监听其变化驱动页面切换动画。

import Foundation
import SwiftUI

final class Router: ObservableObject {
    @Published private(set) var stack: [ScreenConfig] = []
    @Published var navigationID = UUID()  // 触发转场的令牌

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
    func back() {
        guard stack.count > 1 else { return }
        stack.removeLast()
        navigationID = UUID()
    }

    /// 按路由跳转
    func navigate(route: String) {
        guard let screen = ScreenCatalog.screen(route: route) else { return }
        push(screen)
    }

    /// 替换栈顶（对齐 conditionalJump 直达 /home：清空栈再推入目标）
    func jump(to screen: ScreenConfig) {
        stack = [screen]
        navigationID = UUID()
    }
}

// ToastCenter.swift
//
// 来源：对齐 React 原型 ImageScreen 的 toast 状态（setToast(msg) + 2000ms 后自动清除）。
// 用途：全局居中提示（Toast）的发布中心；重复 show 会取消上一个未触发的自动清除，
//       保证最新消息展示完整的 2.0 秒后淡出。

import Foundation
import SwiftUI

final class ToastCenter: ObservableObject {
    @Published var message: String?

    private var workItem: DispatchWorkItem?

    func show(_ msg: String) {
        message = msg
        workItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.25)) { self?.message = nil }
        }
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: item)
    }
}

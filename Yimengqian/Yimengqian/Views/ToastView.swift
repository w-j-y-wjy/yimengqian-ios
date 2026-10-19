// ToastView.swift
//
// 来源：移植自 React 原型 global.css 的 .toast 样式（居中浮层、进入/退出动画）。
// 用途：Toast 浮层 —— 由 ToastCenter 驱动，RootView 在 ZStack 顶层展示。

import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(Theme.bodyFont)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Theme.ink.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: Theme.shadowRadius, x: 0, y: 2)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
    }
}

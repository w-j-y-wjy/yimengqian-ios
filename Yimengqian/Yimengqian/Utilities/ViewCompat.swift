// ViewCompat.swift
//
// 系统版本兼容小工具。
//
// 为什么单独放一个文件：这些修饰器在多个原生页都要用，
// 之前 `scrollContentBackgroundHiddenIfAvailable` 是写在 NativeNoteView 里的 **private**
// extension —— 别的页面想用就只能复制一遍，于是「一处修好、七处还是坏的」。
// 统一收到这里，`internal` 可见，谁都能用。

import SwiftUI

extension View {
    /// iOS 16+ 才有 scrollContentBackground；iOS 15 上保持默认即可
    @ViewBuilder
    func scrollContentBackgroundHiddenIfAvailable() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }

    /// iOS 16+ 才有 scrollDismissesKeyboard；iOS 15 上退回默认（点空白或回车收起）
    @ViewBuilder
    func scrollDismissesKeyboardIfAvailable() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollDismissesKeyboard(.interactively)
        } else {
            self
        }
    }

    /// 键盘弹出时不要被顶飞：给输入区留出键盘高度的滚动余量。
    /// iOS 15 上 `safeAreaInset` 已可用，所以不做版本分支。
    func keyboardSafeBottom(_ spacing: CGFloat = 24) -> some View {
        self.safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: spacing)
        }
    }
}

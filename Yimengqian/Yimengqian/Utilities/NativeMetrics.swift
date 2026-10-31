// NativeMetrics.swift
//
// 原生页的顶部留白 —— 从"硬编码 96 / 54"换成按机型算。
//
// 原来的问题是：12 个原生页一律 `.padding(.top, 96)`（标题）与 `.padding(.top, 54)`（返回栏）。
// 在 iPhone 15 上 96pt ≈ 屏高的 11%，看着正常；但 iPhone SE（667pt 高）上同样的 96pt
// 占掉 14%，加上 54pt 的返回栏，一屏先空掉五分之一，列表页尤其明显。
//
// 现在按屏高 6.3% 算基础值，再与"安全区 + 8"取较大者：
//   · 刘海/灵动岛机型：安全区本来就大，取安全区 + 8，不被岛压住；
//   · 非全面屏（SE）：安全区是 20pt，结果是 42pt，不再白留一大块。
//
// 为什么不用 GeometryReader：这 12 处是页面根部的固定留白，
// 用 GeometryReader 会把每个页面都包一层，改动面反而更大、更容易出错。

import UIKit

enum NativeMetrics {
    /// 返回栏顶部留白（原来硬编码 54）：安全区 + 8。
    static var barTop: CGFloat { safeTop + 8 }

    /// 内容区顶部留白（原来硬编码 96）：**必须由 barTop + 42 推出**，不能各自取 max。
    /// 第一版写成 max(屏高*6.3%, safe+8) 与 max(content-42, safe+2) 两路各自取最大，
    /// 在 iPhone 15 上得到 contentTop=67、barTop=61，只差 6pt ——
    /// 返回按钮和标题直接叠在一起（2026-10-31 真机反馈）。固定 42pt 间距就不会再错。
    static var contentTop: CGFloat { barTop + 42 }

    private static var safeTop: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let top = scene.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.top {
                return top
            }
        }
        return 20
    }
}

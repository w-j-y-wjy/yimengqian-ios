// HotspotScreenView.swift
//
// 来源：移植自 React 原型 app-project/src/components/ImageScreen.tsx。
// 用途：单一屏幕渲染引擎 —— 整屏显示设计稿截图，其上叠加透明热区层（百分比坐标），
//       点击热区触发 ActionExecutor 执行对应动作；三连击进入/退出调试模式（对应 Web ?debug=1）。
//
// 布局语义与 Web 一致：图片按宽度铺满（宽度 = 容器宽，高度按图片纵横比），
// 热区坐标为图片坐标系百分比；内容高于屏幕时可纵向滚动（对应 .page-container 的 overflow-y: auto）。

import SwiftUI
import UIKit

/// 单一屏幕：截图 + 热区层引擎视图
struct HotspotScreenView: View {
    let screen: ScreenConfig

    /// 页面进入时的一次性初始化（TaskReward 结算用）
    var onInit: (() -> Void)?

    /// 页面空白区（未命中热区）点击回调（Splash 五连击重置用）
    var onExtraTap: (() -> Void)?

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var toast: ToastCenter
    @EnvironmentObject private var selection: SelectionStore

    /// 调试模式：显示热区红色边框与标签（对应 Web 的 ?debug=1）
    @State private var debug = false
    @State private var hasRunInit = false
    @State private var tapCount = 0
    /// 三连击的时间窗锚点（见 onTapGesture 注释）
    @State private var lastTapAt: Date?

    var body: some View {
        GeometryReader { geo in
            // 一屏只有一张设计稿，**不做滚动**：真机实测能上下拖动，像网页而不是 App。
            // 等比放进屏幕：宽或高任一先到边界即停，余下的边由宣纸色铺底，
            // 这样任何机型都不会把设计稿边缘裁掉（裁切会把底栏按钮切掉半个）。
            let fitted = fittedSize(in: geo.size)
            ZStack(alignment: .topLeading) {
                imageLayer(width: fitted.width, height: fitted.height)
                hotspotLayer(width: fitted.width, height: fitted.height)
                // 原生叠层：只补位图做不到的实时状态（选中态、判题反馈）。
                // 它 .allowsHitTesting(false)，不会抢热区的点击。
                ScreenNativeLayer(screen: screen, containerSize: fitted)
            }
            .frame(width: fitted.width, height: fitted.height)
            // 形状与手势必须写在 .position 之前：.position 会让视图铺满父级，
            // 之后再加 contentShape 等于把可点区域放大到整屏（详见 HotspotButton 注释）。
            .contentShape(Rectangle())
            .onTapGesture { handleBackgroundTap() }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .background(Theme.paper)
        .ignoresSafeArea()
        .onAppear {
            if !hasRunInit {
                hasRunInit = true
                onInit?()
            }
        }
    }

    /// 等比放入屏幕后的设计稿尺寸（保持 852:1846 的比例，只缩不放）
    private func fittedSize(in bounds: CGSize) -> CGSize {
        guard bounds.width > 1, bounds.height > 1 else { return bounds }
        let w = min(bounds.width, bounds.height / imageAspect)
        return CGSize(width: w, height: w * imageAspect)
    }

    /// 空白区点击：三连击切换热区调试框，并回调给启动页（五连击重置）。
    private func handleBackgroundTap() {
        // 必须带时间窗：旧实现只在命中 3 次时才把计数归零，
        // 于是"很久以前点过 2 次 + 今天再点 1 次"也会进调试模式。
        let now = Date()
        if let last = lastTapAt, now.timeIntervalSince(last) <= 3.0 {
            tapCount += 1
        } else {
            tapCount = 1
        }
        lastTapAt = now
        if tapCount >= 3 {
            tapCount = 0
            lastTapAt = nil
            debug.toggle()
        }
        onExtraTap?()
    }

    /// 图片纵横比（高 / 宽）。
    /// 加载失败时回退到设计稿比例 1846:852 ≈ 2.1667，与正常路径**同量纲**。
    /// 旧实现误写成 852/1846 ≈ 0.4617（宽/高），差 4.69 倍，一旦缺图
    /// 热区会全部塌缩到屏幕顶部 21% 的高度里。
    private var imageAspect: CGFloat {
        guard let img = AssetLoader.image(screen.image) else { return 1846.0 / 852.0 }
        return img.size.height / img.size.width
    }

    private func imageLayer(width w: CGFloat, height h: CGFloat) -> some View {
        Group {
            if let img = AssetLoader.image(screen.image) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: w, height: h)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Theme.paperDark)
                    .frame(width: w, height: h)
                    .overlay(
                        Text("图片缺失: \(screen.image)")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.inkMuted)
                    )
            }
        }
    }

    private func hotspotLayer(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(screen.hotspots) { hotspot in
                HotspotButton(hotspot: hotspot, containerW: w, containerH: h, debug: debug) {
                    Haptics.tap()
                    execute(hotspot)
                }
            }
        }
    }

    private func execute(_ hotspot: Hotspot) {
        let executor = ActionExecutor(store: store, router: router, toast: toast, selection: selection)
        executor.execute(hotspot.action, screenID: screen.id)
    }
}

/// 单个热区按钮：按百分比定位在图片坐标系上
private struct HotspotButton: View {
    let hotspot: Hotspot
    let containerW: CGFloat
    let containerH: CGFloat
    let debug: Bool
    let onTap: () -> Void

    var body: some View {
        // 与叠层共用同一套换算（Hotspot.rect），保证两套渲染永远对得上
        let frame = hotspot.rect(in: CGSize(width: containerW, height: containerH))
        return ZStack(alignment: .topLeading) {
            if debug {
                Rectangle()
                    .fill(Color.red.opacity(0.25))
                    .overlay(Rectangle().stroke(Color.red, lineWidth: 1))
                Text(hotspot.label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.red)
                    .padding(1)
                    .background(Color.white.opacity(0.7))
            } else {
                Color.clear
            }
        }
        .frame(width: frame.width, height: frame.height)
        // ⚠️ 顺序不能动：contentShape / onTapGesture 必须在 .position 之前。
        // .position 会把视图撑成父级的整块尺寸（它是「在父坐标系里摆一个点」的布局修饰），
        // 之后再加 contentShape(Rectangle())，可点区域就变成**整个屏幕**，
        // 于是 ZStack 里最后绘制的那个热区吃掉全部点击。
        // 2026-10-21 真机实测症状：不管点哪里都跳到收藏页 —— 正是这条造成的。
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .position(x: frame.midX, y: frame.midY)
    }
}

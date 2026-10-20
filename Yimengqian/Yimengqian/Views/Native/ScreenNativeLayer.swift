// ScreenNativeLayer.swift
//
// 原生叠层容器 —— Phase 2 的核心。
//
// 为什么要这一层：
// 25 屏全是「整屏设计稿 PNG + 百分比透明热区」，页面上所有按钮、文字、列表都烘焙在位图里，
// 无法承载"实时状态"（选中了哪一项、答对没答对、数据是多少）。而重画 25 屏风险极高
// （已有 Yimengqian_Snai 草案证明会"看起来不像原版"）。
//
// 所以：位图仍作底层，在其上叠一层原生 SwiftUI，**只补位图做不到的实时状态**。
//
// 三条原则：
// 1) 坐标不另起一套：全部取自 ScreensConfig 的热区矩形（同源换算），因此不可能错位；
// 2) 默认 `allowsHitTesting(false)`：叠层只负责显示，绝不抢既有 329 个热区的点击；
// 3) 克制的静态样式：只用 Theme 色板，不加动画（大面积动效是明确的设计禁忌）。

import SwiftUI

/// 热区几何：把百分比热区换算成图片坐标系里的矩形。
/// HotspotScreenView 的 HotspotButton 与所有叠层都用它，保证两套渲染永远同源。
extension Hotspot {
    func rect(in size: CGSize) -> CGRect {
        CGRect(
            x: size.width * CGFloat(x) / 100,
            y: size.height * CGFloat(y) / 100,
            width: size.width * CGFloat(width) / 100,
            height: size.height * CGFloat(height) / 100
        )
    }
}

/// 叠层标记样式
enum SelectionMark: Equatable {
    case check   // 已选
    case cross   // 答错
    case none
}

/// 统一的选中框：细描边 + 角标。静态样式，无动画。
struct SelectionRing: View {
    var color: Color = Theme.vermilion
    var mark: SelectionMark = .check

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(color, lineWidth: 1.5)

            if mark != .none {
                Image(systemName: mark == .check ? "checkmark" : "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 15, height: 15)
                    .background(Circle().fill(color))
                    .offset(x: 7, y: -7)
            }
        }
    }
}

/// 按屏幕 id 渲染对应叠层。未实现的屏返回 EmptyView，行为与改造前完全一致。
struct ScreenNativeLayer: View {
    let screen: ScreenConfig
    let containerSize: CGSize

    var body: some View {
        Group {
            switch screen.id {
            case "preference-test":
                PreferenceTestLayer(screen: screen, container: containerSize)
            case "feihualing-challenge":
                FeihualingLayer(screen: screen, container: containerSize)
            case "favorites":
                FavoritesLayer(screen: screen, container: containerSize)
            default:
                EmptyView()
            }
        }
        // 关键：叠层只做展示，不参与命中测试。否则会挡住底下的透明热区。
        .allowsHitTesting(false)
    }
}

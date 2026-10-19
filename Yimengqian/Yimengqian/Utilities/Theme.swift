// Theme.swift
//
// 来源：移植自 React 原型 app-project/src/styles/global.css 的 :root 设计 token
//       （色板 / 圆角 / 阴影 / 间距 / 字号），并与 design-system.md 的字体回退栈对齐。
// 用途：Yimengqian 应用全局设计系统，SwiftUI 视图统一从这里取颜色、圆角、间距、阴影与字体。
//
// 字体说明：使用 iOS 系统自带的中文衬线字体，无需捆绑字体文件即可运行——
//   · 标题：KaitiSC-Bold（楷体-简 粗体，新中式标题气质，对应 design-system.md 的楷/宋标题回退）
//   · 正文/辅助：SongtiSC-Regular（宋体-简，对应 STSong / 宋体正文回退）
//   · 若某字体名在个别系统版本不可用，Font.custom 会自动回退到系统字体，不会崩溃。
// 如需更精确匹配设计稿，可后续将 Noto Serif SC 字体文件放入 Resources/fonts 并在
// Info.plist 的 UIAppFonts 中登记（详见 README「可选：捆绑字体」一节）。

import SwiftUI
import UIKit

enum Theme {
    // MARK: - 色板（与 global.css :root 完全一致）
    static let paper = Color(hex: 0xF5F0E8)
    static let paperLight = Color(hex: 0xFAF6EF)
    static let paperDark = Color(hex: 0xE8E0D0)
    static let ink = Color(hex: 0x2C2416)
    static let inkLight = Color(hex: 0x5A4E3C)
    static let inkMuted = Color(hex: 0x8A7E6C)
    static let vermilion = Color(hex: 0xC23C2A)
    static let vermilionDark = Color(hex: 0xA03020)
    static let vermilionLight = Color(hex: 0xD4564A)
    static let gold = Color(hex: 0xC9A96E)
    static let goldLight = Color(hex: 0xE0CC9A)
    static let goldBorder = Color(hex: 0xD4B882)
    static let greenInk = Color(hex: 0x4A6741)
    static let blueInk = Color(hex: 0x3A5A7C)

    // MARK: - 圆角 / 间距 / 阴影（对应 --radius-* / --spacing-* / box-shadow）
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 16
    static let radiusLarge: CGFloat = 24
    static let radiusXLarge: CGFloat = 28
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: - 字体（标题楷体 / 正文宋体，iOS 系统自带，见文件头字体说明）
    static let titleFont = Font.custom("KaitiSC-Bold", size: 18, relativeTo: .title2)
    static let sectionTitleFont = Font.custom("KaitiSC-Bold", size: 16, relativeTo: .headline)
    static let bodyFont = Font.custom("SongtiSC-Regular", size: 14, relativeTo: .body)
    static let captionFont = Font.custom("SongtiSC-Regular", size: 12, relativeTo: .footnote)
    static let tagFont = Font.custom("SongtiSC-Regular", size: 11, relativeTo: .caption)

    // MARK: - 阴影（对应 --color-shadow / --color-shadow-dark 与卡片层级）
    static let cardShadow = Color.black.opacity(0.08)
    static let cardShadowRaised = Color.black.opacity(0.12)
    static let shadowRadius: CGFloat = 8
    static let shadowRadiusRaised: CGFloat = 16
}

extension Color {
    /// 以 0xRRGGBB 形式构造 sRGB 颜色。
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

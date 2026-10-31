// AppTab.swift
//
// 五个主 tab —— 真骨架的第一层。
//
// 为什么需要它：现在的底部导航是**画在位图里的**五个按钮 + 五条热区，
// 结构上并没有"tab"这个概念：所有屏幕平铺在一条栈上，靠 `tabRoutes` 判断
// "这一屏是不是底栏根屏"来替换栈。这样写导致三件事做不到：
//   1) 每个 tab 的历史无法独立保留（从"我的"进详情再切到"诗词"，回不到原来那层）；
//   2) 系统级的 tab 行为（长按、无障碍"标签页"语义）一概没有；
//   3) 以后想给某个 tab 单独加导航栏/搜索框，没有挂载点。
//
// 这一层先只做"模型"：哪个屏属于哪个 tab、tab 的标题与图标。
// 渲染层（RootView）用它把 5 个根屏装进 TabView，并为每个 tab 保留自己的栈。

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case poetry
    case artifact
    case activities
    case profile

    var id: String { rawValue }

    /// tab 根屏（ScreensConfig 里的屏幕 id）
    var rootScreenID: String {
        switch self {
        case .home: return "home"
        case .poetry: return "poetry-home"
        case .artifact: return "artifact-home"
        case .activities: return "activities-home"
        case .profile: return "profile"
        }
    }

    var title: String {
        switch self {
        case .home: return "入梦"
        case .poetry: return "诗词"
        case .artifact: return "古物"
        case .activities: return "雅集"
        case .profile: return "我的"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .poetry: return "text.book.closed"
        case .artifact: return "circle.hexagongrid"
        case .activities: return "sparkles"
        case .profile: return "person"
        }
    }

    /// 屏幕 → 所属 tab。表里没写到的屏（如启动页、onboarding）沿用当前 tab。
    /// 这张表是"哪些屏归哪个 tab"的唯一事实源，渲染层与路由层都读它。
    static func owner(of screenID: String) -> AppTab? {
        switch screenID {
        case "home", "dynasties", "bianjing", "teahouse", "sushi", "teahouse-dialogue", "jiangxue-imagery":
            return .home
        case "poetry-home", "poetry-card", "jiangxue-scene", "jiangxue-analysis", "feihualing-challenge":
            return .poetry
        case "artifact-home", "artifact-result", "artifact-pattern":
            return .artifact
        case "activities-home", "stamp-reward", "task-reward", "preference-test", "identity-result":
            return .activities
        case "favorites", "dreambook", "profile":
            return .profile
        default:
            return nil
        }
    }
}

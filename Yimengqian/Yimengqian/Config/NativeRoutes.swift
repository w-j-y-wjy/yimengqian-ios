// NativeRoutes.swift
//
// 原生详情路由 —— 这次大整改的关键通道。
//
// 为什么需要它：
// 25 屏都是「整屏设计稿 PNG」，没有设计稿就做不出新屏；于是原工程里大量"点开看详情"的入口
// 只能写一句 toast（"《鸟鸣涧》诗境将在后续开放"）。这类提示既不算功能，也不符合图意 ——
// 用户在图上看到的是诗卡、纹样要素卡、器物卡，点了却什么都不发生。
//
// 做法：把这些"详情"做成原生视图（纯文本 + ContentData 里已有的配图），用 /native/... 路由寻址，
// 由 Router 在整屏设计稿之上叠一层。好处：
// 1) 不需要新设计稿，也不会破坏既有 25 屏；
// 2) 可以把 ContentData 里 16 张闲置配图按语义用起来（纹样要素图、器物图、意象图）；
// 3) 详情页的收藏按钮可以接真实的 AppStore.toggleFavorite，收藏闭环覆盖到所有内容类型。
//
// 路由格式：/native/<kind>/<id>
//   kind: poem | artifact | pattern | activity | character | letter
//   例：/native/poem/niao-ming-jian、/native/pattern/莲瓣

import Foundation

enum NativeDetail: Equatable {
    case poem(String)
    case artifact(String)
    case patternElement(String)
    case activity(String)
    case character(String)
    case letter(String)

    static let prefix = "/native/"

    static func parse(_ route: String) -> NativeDetail? {
        guard route.hasPrefix(prefix) else { return nil }
        let parts = route.dropFirst(prefix.count).split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2, !parts[1].isEmpty else { return nil }
        switch parts[0] {
        case "poem": return .poem(parts[1])
        case "artifact": return .artifact(parts[1])
        case "pattern": return .patternElement(parts[1])
        case "activity": return .activity(parts[1])
        case "character": return .character(parts[1])
        case "letter": return .letter(parts[1])
        default: return nil
        }
    }

    var route: String {
        switch self {
        case .poem(let id): return "\(Self.prefix)poem/\(id)"
        case .artifact(let id): return "\(Self.prefix)artifact/\(id)"
        case .patternElement(let name): return "\(Self.prefix)pattern/\(name)"
        case .activity(let id): return "\(Self.prefix)activity/\(id)"
        case .character(let id): return "\(Self.prefix)character/\(id)"
        case .letter(let id): return "\(Self.prefix)letter/\(id)"
        }
    }

    var kind: String {
        switch self {
        case .poem: return "poem"
        case .artifact: return "artifact"
        case .patternElement: return "pattern"
        case .activity: return "activity"
        case .character: return "character"
        case .letter: return "letter"
        }
    }

    var id: String {
        switch self {
        case .poem(let v), .artifact(let v), .patternElement(let v),
             .activity(let v), .character(let v), .letter(let v):
            return v
        }
    }
}

/// 详情页要显示的内容 —— 全部来自 ContentData，查不到就返回 nil（Router 会忽略这次跳转，
/// 绝不出现空白页）
struct NativeDetailContent {
    let title: String
    let subtitle: String
    let hero: String?
    let lines: [String]
    let sections: [(title: String, body: String)]
    let tags: [String]
    /// 可收藏的类型；纹样要素/活动这类"库内容"不可收藏
    let favorite: (type: FavoriteType, itemId: String)?

    static func resolve(_ detail: NativeDetail) -> NativeDetailContent? {
        switch detail {
        case .poem(let id):
            guard let p = ContentData.poems.first(where: { $0.id == id }) else { return nil }
            var sections: [(String, String)] = []
            if let a = p.analysis {
                sections.append(("译解", a.translation))
                sections.append(("创作背景", a.background))
                sections.append(("艺术特色", a.features))
            }
            let imagery = p.imagery ?? ContentData.jiangxueImagery
            return NativeDetailContent(
                title: p.title,
                subtitle: "\(p.dynasty) · \(p.author)",
                hero: imagery.first?.image,
                lines: p.content.split(separator: "\n").map(String.init),
                sections: sections,
                tags: imagery.flatMap { $0.keywords }.prefix(4).map { $0 },
                favorite: (.poem, id)
            )

        case .artifact(let id):
            guard let a = ContentData.artifacts.first(where: { $0.id == id }) else { return nil }
            var sections: [(String, String)] = [("简介", a.description)]
            if let pd = a.patternDetail {
                sections.append(("纹样 · \(pd.name)", pd.structure))
                sections.append(("寓意", pd.symbolism))
                sections.append(("时代风格", pd.eraStyle))
            }
            return NativeDetailContent(
                title: a.name,
                subtitle: "\(a.dynasty) · \(a.type)",
                hero: a.image,
                lines: [],
                sections: sections,
                tags: [a.pattern, a.shape, a.usage].filter { !$0.isEmpty },
                favorite: (.artifact, id)
            )

        case .patternElement(let name):
            let elements = ContentData.artifacts.compactMap { $0.patternDetail }.flatMap { $0.elements }
            guard let e = elements.first(where: { $0.name == name }) else { return nil }
            return NativeDetailContent(
                title: e.name,
                subtitle: "缠枝莲纹 · 纹样要素",
                hero: e.image,
                lines: [],
                sections: [("说明", e.description)],
                tags: [],
                favorite: nil
            )

        case .activity(let id):
            guard let act = ContentData.activities.first(where: { $0.id == id }) else { return nil }
            return NativeDetailContent(
                title: act.name,
                subtitle: act.unlocked ? "已解锁" : "未解锁",
                hero: nil,
                lines: [],
                sections: [("玩法", act.description)],
                tags: [act.type],
                favorite: nil
            )

        case .character(let id):
            guard let c = ContentData.characters.first(where: { $0.id == id }) else { return nil }
            var sections: [(String, String)] = [("生平", c.bio)]
            if let w = c.works.first {
                sections.append(("代表作《\(w.title)》", w.content))
            }
            return NativeDetailContent(
                title: c.name,
                subtitle: "\(c.dynasty) · \(c.title)",
                hero: c.image,
                lines: [],
                sections: sections,
                tags: c.tags,
                favorite: (.character, id)
            )

        case .letter(let id):
            let all = ContentData.characters.flatMap { $0.letters }
            guard let l = all.first(where: { $0.id == id }) else { return nil }
            return NativeDetailContent(
                title: "\(l.from)来信",
                subtitle: l.date,
                hero: nil,
                lines: l.content.split(separator: "\n").map(String.init),
                sections: [],
                tags: [],
                favorite: (.letter, id)
            )
        }
    }
}

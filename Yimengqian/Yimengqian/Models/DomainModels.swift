//
//  DomainModels.swift
//  领域类型定义 —— 与安卓原型 app-project/src/types/index.ts 一一对应
//

import Foundation

struct Dynasty: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var city: String
    var period: String
    var description: String
    var unlocked: Bool
    var recommended: Bool
    /// 朝代配图。改为可选：像黄州这种没有独立配图的城市条目，不应该为了凑字段而借用别的图。
    var image: String? = nil
    var characters: [String]
}

struct Character: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var dynasty: String
    var title: String
    var tags: [String]
    var bio: String
    var works: [Poem]
    var footprints: [Footprint]
    var letters: [Letter]
    /// 人像配图。改为可选：没有专属画像的历史人物不该借用他人肖像。
    var image: String? = nil
}

struct Poem: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var author: String
    var dynasty: String
    var content: String
    var category: String
    var analysis: PoemAnalysis? = nil
    var imagery: [Imagery]? = nil
    /// 诗作配图（poem-*.jpg）。此前 Poem 没有图片字段，3 张诗作插画从未显示；
    /// 加可选默认值不破坏 Codable（同 analysis / imagery 的写法）。
    var image: String? = nil
}

struct PoemAnalysis: Codable, Equatable {
    var translation: String
    var background: String
    var features: String
}

struct Imagery: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var image: String
    var meaning: String
    var visual: String
    var emotion: String
    var relatedPoems: [String]
    var keywords: [String]
}

struct Footprint: Codable, Equatable {
    var city: String
    var period: String
    var description: String
}

struct Letter: Codable, Identifiable, Equatable {
    var id: String
    var from: String
    var content: String
    var date: String
}

struct CityLocation: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var x: Double
    var y: Double
    var unlocked: Bool
    var description: String
    /// 此地「在宋代是什么样」—— 给原生地点详情页用（默认空，老数据不用改）
    var era: String = ""
    /// 此地「能做点什么」—— 纯说明文案，不假造交互
    var activity: String = ""
}

struct Artifact: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var dynasty: String
    var type: String
    var shape: String
    var pattern: String
    var usage: String
    var description: String
    var image: String
    var patternDetail: PatternDetail? = nil
}

struct PatternDetail: Codable, Equatable {
    var name: String
    var image: String
    var structure: String
    var symbolism: String
    var eraStyle: String
    var elements: [PatternElement]
}

struct PatternElement: Codable, Identifiable, Equatable {
    // 元素无独立 id，用 name 作为 id（计算属性，不参与 Codable 编码与成员初始化器）
    var id: String { name }
    var name: String
    var description: String
    var image: String
}

struct Activity: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var description: String
    var type: String
    var unlocked: Bool
    var participants: Int? = nil
    /// 活动配图（activity-*.jpg）。此前没有该字段，5 张活动图从未显示。
    var image: String? = nil
}

struct FeihualingQuestion: Codable, Identifiable, Equatable {
    var id: Int
    var round: Int
    var character: String
    var options: [String]
    var correctIndex: Int
}

struct Stamp: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var description: String
    var image: String
    var obtained: Bool
    var date: String? = nil
}

struct UserProfile: Codable, Equatable {
    var nickname: String
    var title: String
    var dynasty: String
    var personality: [String]
    var recommendedCity: String
    var poem: String
    var initialStamp: Stamp? = nil
    var level: Int
    var cultureValue: Int
    var yaValue: Int
    var petals: Int
    var poetryCount: Int
    var artifactCount: Int
    var characterCount: Int
    var stampCount: Int
}

enum FavoriteType: String, Codable, Equatable {
    case poem, artifact, character, letter, stamp
}

struct FavoriteItem: Codable, Identifiable, Equatable {
    var id: String
    var type: FavoriteType
    var itemId: String
    var date: String
}

struct Task: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var location: String
    var description: String
    var reward: TaskReward
    var completed: Bool
}

struct TaskReward: Codable, Equatable {
    var cultureValue: Int
    var stamp: Stamp? = nil
    var letter: Letter? = nil
}

struct DialogueLine: Codable, Equatable {
    var id: String
    var speaker: DialogueSpeaker
    var text: String
}

enum DialogueSpeaker: String, Codable, Equatable {
    case user, character
}

struct DialogueTopic: Codable, Identifiable, Equatable {
    var id: String
    var question: String
    var responses: [DialogueLine]
}

struct DailyPoem: Codable, Equatable {
    var text: String
    var author: String
    var title: String
}

struct PoetryCategory: Codable, Equatable {
    var id: String
    var name: String
    var icon: String
}

// MARK: - 地点（「最近足迹」的真实数据源）

/// 一处可到访的地点。
///
/// 为什么单独建一张表：个人中心底部的「最近足迹」原本是**烤在设计稿位图里的**
/// 汴京 / 杭州 / 南京 + 今日 / 昨日 / 2天前，属于纯装饰；用户的真实浏览记录
/// （AppSnapshot.recentViews）写了却从来没人读。有了这张表，界面上每一张卡
/// 都能对上"用户真的去过哪、什么时候去的"。
struct Place: Identifiable, Equatable {
    let id: String
    let name: String
    /// 卡片上的一行说明（朝代 + 气质），点位详情页也用
    let subtitle: String
    /// 缩略图；nil 表示还没有专属配图 —— 调用方画程序化纸底，不借别的地点的图
    let image: String?
    /// 点开去哪（原生城池详情）
    let route: String
}

/// 一条真实的足迹记录（地点 + 最近一次到访日期）
struct FootprintRecord: Identifiable, Equatable {
    var id: String { place.id }
    let place: Place
    /// yyyy-MM-dd
    let date: String

    /// 「今日 / 昨日 / N 天前」—— 与设计稿的措辞一致
    var whenText: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        guard let day = fmt.date(from: date) else { return date }
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: day)
        let today = cal.startOfDay(for: Date())
        let days = cal.dateComponents([.day], from: startOfDay, to: today).day ?? 0
        if days <= 0 { return "今日" }
        if days == 1 { return "昨日" }
        return "\(days) 天前"
    }
}

/// 地点表：把「设计稿里的屏 / 原生城池 id / 中原名字」统一到同一个 id 上。
///
/// 命名口径说明：`cheng` 是城市（长安/汴京/临安/金陵…），不是朝代。
/// 足迹记录里存的是 `place:<id>`，因此改名只需改这里，历史记录自动跟上。
enum PlaceCatalog {
    static let all: [Place] = [
        Place(id: "bianjing", name: "汴京", subtitle: "北宋都城 · 市井繁华",
              image: "ArtApp/footprint-bianjing.jpg", route: "/native/city/bei-song"),
        Place(id: "changan", name: "长安", subtitle: "盛唐都城 · 万国来朝",
              image: "ArtApp/dynasty-tang.jpg", route: "/native/city/tang"),
        // 临安即今杭州：设计稿里写的是「杭州」，这里统一用宋时名，避免一个城两个名字。
        Place(id: "linan", name: "临安", subtitle: "南宋都城 · 西湖烟雨",
              image: "ArtApp/dynasty-nan-song.jpg", route: "/native/city/nan-song"),
        // 金陵即今南京，同上。
        Place(id: "jinling", name: "金陵", subtitle: "明代都城 · 秦淮灯影",
              image: "ArtApp/dynasty-ming.jpg", route: "/native/city/ming"),
        Place(id: "huangzhou", name: "黄州", subtitle: "苏轼谪居 · 赤壁怀古",
              image: nil, route: "/native/city/huang-zhou"),
        Place(id: "shuyuan", name: "白鹿洞", subtitle: "宋代书院 · 讲学之所",
              image: nil, route: "/native/city/shu-yuan"),
    ]

    static func place(id: String) -> Place? {
        all.first { $0.id == id }
    }

    /// 设计稿屏幕 id → 地点（用户真正"走进了这座城"时记一笔）
    ///
    /// home 也算：首页那张大图就是北宋汴京城（「进入城内」按钮跳的就是 /city/bianjing），
    /// 人到首页就已经站在汴京了。这样新装用户也有第一条真实足迹，而不是空白。
    private static let byScreen: [String: String] = [
        "home": "bianjing",         // 首页 = 汴京外城全景
        "bianjing": "bianjing",     // 北宋汴京古城地图页
        "teahouse": "bianjing",     // 东坡茶坊就在汴京城内
        "dynasties": "",            // 朝代选择页只是目录，不算到访
    ]

    /// 原生城池详情 id（ContentData.dynasties 的 id）→ 地点
    private static let byCityID: [String: String] = [
        "bei-song": "bianjing",
        "tang": "changan",
        "nan-song": "linan",
        "ming": "jinling",
        "huang-zhou": "huangzhou",
        "shu-yuan": "shuyuan",
    ]

    static func place(forScreen screenID: String) -> Place? {
        guard let pid = byScreen[screenID], !pid.isEmpty else { return nil }
        return place(id: pid)
    }

    static func place(forCityID cityID: String) -> Place? {
        guard let pid = byCityID[cityID] else { return place(id: cityID) }
        return place(id: pid)
    }

    /// 所有地点的原生城池 id 反查（足迹列表点"去过的地方"时按 route 匹配）
    static func place(route: String) -> Place? {
        all.first { $0.route == route }
    }
}

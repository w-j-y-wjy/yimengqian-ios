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

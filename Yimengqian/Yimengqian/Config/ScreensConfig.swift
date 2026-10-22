// 本文件由 tools/generate_screens_swift.mjs 自动生成 —— 请勿手动编辑。
// Generated from app-project/src/config/screens.ts + hotspot-overrides.json
//        + tools/hotspot-overrides.ios.json（iOS 侧坐标修正）+ tools/hotspot-deletions.json（删除清单）
// 共 25 个屏幕；合并了 25 个屏幕的坐标覆盖。
import Foundation

// MARK: - 键值对（storage / defaults / storageFlags 通用）
struct KV: Codable, Equatable {
    var key: String
    var value: String
}

// MARK: - 热区动作
struct HotspotAction: Codable, Equatable {
    enum Kind: String, Codable, Equatable, CaseIterable {
        case navigate
        case back
        case toast
        case storage
        case storageAndToast
        case conditionalNavigate
        case setStorageAndToast
        case toggleStorage
        case storageAndNavigate
        case conditionalStorageNavigate
        case incrementOnce
        case delayedNavigate
        case conditionalJump
        case setDefaultsAndNavigate
        case checkAnswer
        case speakText
    }
    var type: Kind
    var target: String?
    var message: String?
    var storage: [KV]?
    var storageKey: String?
    var storageValue: String?
    var onMessage: String?
    var offMessage: String?
    var flagKey: String?
    var defaultValue: String?
    var delay: Double?
    var defaults: [KV]?
    var correctAnswer: String?
    var storageFlags: [KV]?

    init(type: Kind, target: String? = nil, message: String? = nil, storage: [KV]? = nil,
         storageKey: String? = nil, storageValue: String? = nil, onMessage: String? = nil,
         offMessage: String? = nil, flagKey: String? = nil, defaultValue: String? = nil,
         delay: Double? = nil, defaults: [KV]? = nil, correctAnswer: String? = nil,
         storageFlags: [KV]? = nil) {
        self.type = type
        self.target = target
        self.message = message
        self.storage = storage
        self.storageKey = storageKey
        self.storageValue = storageValue
        self.onMessage = onMessage
        self.offMessage = offMessage
        self.flagKey = flagKey
        self.defaultValue = defaultValue
        self.delay = delay
        self.defaults = defaults
        self.correctAnswer = correctAnswer
        self.storageFlags = storageFlags
    }
}

// MARK: - 热区
struct Hotspot: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var action: HotspotAction
}

// MARK: - 屏幕配置
struct ScreenConfig: Codable, Identifiable, Equatable {
    var id: String
    var route: String
    var image: String
    var hotspots: [Hotspot]
}

// MARK: - 屏幕目录
enum ScreenCatalog {
    static let all: [ScreenConfig] = [
        ScreenConfig(id: "splash", route: "/splash", image: "Screens/splash.png", hotspots: [
                Hotspot(id: "enter-dream", label: "入梦", x: 20, y: 83.263, width: 59.953, height: 7.34, action: HotspotAction(type: .conditionalJump, target: "/onboarding/intro"))
            ]),
        ScreenConfig(id: "home", route: "/home", image: "Screens/home.png", hotspots: [
                Hotspot(id: "enter-city", label: "进入城内", x: 60.817, y: 34.72, width: 30.939, height: 5, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "nav-dynasty", label: "朝代漫游", x: 2.376, y: 42.476, width: 16.854, height: 11.414, action: HotspotAction(type: .navigate, target: "/city/dynasties")),
                Hotspot(id: "nav-character", label: "古人互动", x: 21, y: 42, width: 18, height: 8, action: HotspotAction(type: .navigate, target: "/character/sushi")),
                Hotspot(id: "nav-poetry", label: "诗境生成", x: 40, y: 42, width: 18, height: 8, action: HotspotAction(type: .navigate, target: "/poetry")),
                Hotspot(id: "nav-artifact", label: "古物识趣", x: 59, y: 42, width: 18, height: 8, action: HotspotAction(type: .navigate, target: "/artifact")),
                Hotspot(id: "nav-activity", label: "雅集活动", x: 78, y: 42, width: 18, height: 8, action: HotspotAction(type: .navigate, target: "/activities")),
                Hotspot(id: "bottom-home", label: "首页", x: 0, y: 93, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/home")),
                Hotspot(id: "bottom-city", label: "古城", x: 20, y: 93, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/city/dynasties")),
                Hotspot(id: "bottom-activity", label: "雅集", x: 40, y: 93, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/activities")),
                Hotspot(id: "bottom-favorites", label: "收藏", x: 60, y: 93, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "bottom-profile", label: "我的", x: 80, y: 93, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/profile")),
                Hotspot(id: "home-avatar", label: "头像", x: 4, y: 4.2, width: 10, height: 6, action: HotspotAction(type: .navigate, target: "/profile")),
                Hotspot(id: "home-feihualing-card", label: "今日雅集·飞花令", x: 3.8, y: 55.5, width: 92.4, height: 17.6, action: HotspotAction(type: .navigate, target: "/activities/feihualing")),
                Hotspot(id: "home-daily-poem", label: "今日诗签", x: 3.8, y: 76.4, width: 66, height: 11.5, action: HotspotAction(type: .navigate, target: "/native/poem/niao-ming-jian"))
            ]),
        ScreenConfig(id: "dynasties", route: "/city/dynasties", image: "Screens/dynasties.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 3.005, y: 5.377, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "tang", label: "盛唐·长安", x: 4.221, y: 14.247, width: 91.972, height: 13.537, action: HotspotAction(type: .navigate, target: "/native/city/tang")),
                Hotspot(id: "song-bianjing", label: "北宋·汴京", x: 3.845, y: 28.73, width: 93.944, height: 13.451, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "song-linan", label: "南宋·临安", x: 3.563, y: 43.424, width: 93.756, height: 12.497, action: HotspotAction(type: .navigate, target: "/native/city/nan-song")),
                Hotspot(id: "ming", label: "明代·金陵", x: 4.502, y: 57.384, width: 92.535, height: 11.934, action: HotspotAction(type: .navigate, target: "/native/city/ming")),
                Hotspot(id: "enter-bianjing", label: "进入汴京", x: 6.455, y: 84.08, width: 87.089, height: 5, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "bottom-home", label: "首页", x: 0, y: 91.206, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/home")),
                Hotspot(id: "bottom-city", label: "古城", x: 20.26, y: 91.087, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/city/dynasties")),
                Hotspot(id: "bottom-activity", label: "雅集", x: 40.78, y: 90.967, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/activities")),
                Hotspot(id: "bottom-favorites", label: "收藏", x: 61.299, y: 90.847, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "bottom-profile", label: "我的", x: 80, y: 90.728, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/profile")),
                Hotspot(id: "dynasties-char-libai", label: "推荐人物·李白", x: 4, y: 74, width: 29.5, height: 9.5, action: HotspotAction(type: .navigate, target: "/native/character/libai")),
                Hotspot(id: "dynasties-char-sushi", label: "推荐人物·苏轼", x: 35.8, y: 74, width: 28.5, height: 9.5, action: HotspotAction(type: .navigate, target: "/native/character/sushi")),
                Hotspot(id: "dynasties-char-liqingzhao", label: "推荐人物·李清照", x: 66, y: 74, width: 29.5, height: 9.5, action: HotspotAction(type: .navigate, target: "/native/character/liqingzhao"))
            ]),
        ScreenConfig(id: "bianjing", route: "/city/bianjing", image: "Screens/bianjing.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 4.225, y: 5.204, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "title", label: "北宋·汴京", x: 34.601, y: 5.117, width: 32.347, height: 5, action: HotspotAction(type: .navigate, target: "/city/dynasties")),
                Hotspot(id: "academy", label: "书院", x: 21.925, y: 14.036, width: 10, height: 8.51, action: HotspotAction(type: .navigate, target: "/native/spot/shuyuan")),
                Hotspot(id: "wanshe", label: "瓦舍", x: 73.802, y: 17.53, width: 10, height: 8.77, action: HotspotAction(type: .navigate, target: "/native/spot/washe")),
                Hotspot(id: "tavern", label: "酒肆", x: 8.31, y: 29.55, width: 10, height: 7.687, action: HotspotAction(type: .navigate, target: "/native/spot/jiusi")),
                Hotspot(id: "pharmacy", label: "药坊", x: 35.657, y: 41.69, width: 10, height: 8.467, action: HotspotAction(type: .navigate, target: "/native/spot/yaofang")),
                Hotspot(id: "dock", label: "码头", x: 83.498, y: 52.107, width: 10, height: 8.727, action: HotspotAction(type: .navigate, target: "/native/spot/matou")),
                Hotspot(id: "teahouse-card", label: "在茶坊偶遇苏轼", x: 5.681, y: 68.83, width: 58.451, height: 9.984, action: HotspotAction(type: .navigate, target: "/city/teahouse")),
                Hotspot(id: "teahouse-enter", label: "进入", x: 32.535, y: 79.717, width: 28.779, height: 5, action: HotspotAction(type: .navigate, target: "/city/teahouse")),
                Hotspot(id: "bottom-home", label: "首页", x: 0, y: 90.01, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/home")),
                Hotspot(id: "bottom-city", label: "古城", x: 20, y: 90.13, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "bottom-experience", label: "体验", x: 40.26, y: 90.13, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/artifact")),
                Hotspot(id: "bottom-favorites", label: "收藏", x: 60.52, y: 90.13, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "bottom-profile", label: "我的", x: 80, y: 89.891, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/profile"))
            ]),
        ScreenConfig(id: "teahouse", route: "/city/teahouse", image: "Screens/teahouse.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 1.69, y: 3.99, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "search", label: "搜索", x: 87.347, y: 4.337, width: 10, height: 5, action: HotspotAction(type: .toast, message: "搜索茶坊与城内地点")),
                Hotspot(id: "hero-image", label: "东坡旧识茶坊", x: 3.874, y: 36.596, width: 92.347, height: 13.234, action: HotspotAction(type: .toast, message: "东坡旧识茶坊")),
                Hotspot(id: "tea-ceremony", label: "宋代点茶", x: 62.746, y: 19.706, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/native/activity/tea-ceremony")),
                Hotspot(id: "literati", label: "文人雅集", x: 31.775, y: 17.583, width: 19.671, height: 5, action: HotspotAction(type: .navigate, target: "/activities")),
                Hotspot(id: "meet-sushi", label: "可遇苏轼", x: 17.516, y: 28.114, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/character/sushi")),
                Hotspot(id: "tea-experience", label: "点茶体验卡", x: 2.84, y: 54.068, width: 31.596, height: 13.234, action: HotspotAction(type: .navigate, target: "/native/activity/tea-ceremony")),
                Hotspot(id: "tea-ware", label: "茶器识别卡", x: 35.005, y: 53.678, width: 29.155, height: 13.277, action: HotspotAction(type: .navigate, target: "/native/activity/qigu")),
                Hotspot(id: "character-card", label: "人物偶遇卡", x: 66.127, y: 54.067, width: 30.939, height: 13.277, action: HotspotAction(type: .navigate, target: "/character/sushi")),
                Hotspot(id: "daily-task", label: "与苏轼谈一谈人生起伏", x: 3.967, y: 71.181, width: 93.286, height: 11.891, action: HotspotAction(type: .navigate, target: "/dialogue/teahouse")),
                Hotspot(id: "enter-teahouse", label: "进入茶坊", x: 6.643, y: 83.993, width: 88.028, height: 5, action: HotspotAction(type: .navigate, target: "/dialogue/teahouse")),
                Hotspot(id: "bottom-home", label: "首页", x: 0, y: 90.847, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/home")),
                Hotspot(id: "bottom-city", label: "古城", x: 20, y: 90.608, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "bottom-activity", label: "雅集", x: 40.78, y: 90.369, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/activities")),
                Hotspot(id: "bottom-favorites", label: "收藏", x: 60, y: 90.25, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "bottom-profile", label: "我的", x: 80, y: 90.25, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/profile"))
            ]),
        ScreenConfig(id: "sushi", route: "/character/sushi", image: "Screens/sushi.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 3.845, y: 5.425, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "voice", label: "苏轼语音", x: 66.026, y: 14.638, width: 10, height: 5, action: HotspotAction(type: .speakText, message: "人生如逆旅，我亦是行人。不必为一时得失而耿耿于怀，且将新火试新茶，诗酒趁年华。")),
                Hotspot(id: "tag-huoda", label: "豁达", x: 50.674, y: 21.436, width: 10, height: 5, action: HotspotAction(type: .toast, message: "豁达：历经起伏仍保持从容")),
                Hotspot(id: "tag-kuangda", label: "旷达", x: 63.358, y: 21.479, width: 10, height: 5, action: HotspotAction(type: .toast, message: "旷达：不困于一时得失")),
                Hotspot(id: "tag-caiqing", label: "才情", x: 77.729, y: 21.306, width: 10, height: 5, action: HotspotAction(type: .toast, message: "才情：诗词书画皆有成就")),
                Hotspot(id: "work-chibi", label: "念奴娇·赤壁怀古", x: 4.343, y: 46.182, width: 36.823, height: 14.067, action: HotspotAction(type: .navigate, target: "/native/poem/nian-nu-jiao")),
                Hotspot(id: "work-dingfengbo", label: "定风波", x: 44.685, y: 45.792, width: 37.667, height: 14.892, action: HotspotAction(type: .navigate, target: "/native/poem/ding-feng-bo")),
                Hotspot(id: "work-more", label: "更多作品", x: 79.279, y: 42.304, width: 17.597, height: 3.134, action: HotspotAction(type: .navigate, target: "/native/list/poems")),
                Hotspot(id: "footprint-bianjing", label: "汴京足迹", x: 3.968, y: 66.757, width: 28.476, height: 5, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "footprint-huangzhou", label: "黄州足迹", x: 35.719, y: 66.887, width: 26.882, height: 5, action: HotspotAction(type: .navigate, target: "/native/city/huang-zhou")),
                Hotspot(id: "footprint-hangzhou", label: "杭州足迹", x: 66.25, y: 66.8, width: 26.788, height: 5, action: HotspotAction(type: .navigate, target: "/native/city/nan-song")),
                Hotspot(id: "letter", label: "收到来信", x: 4.062, y: 74.98, width: 92.626, height: 5, action: HotspotAction(type: .navigate, target: "/native/letter/letter-sushi-1")),
                Hotspot(id: "dialogue-btn", label: "与他对话", x: 15, y: 82, width: 70, height: 6, action: HotspotAction(type: .navigate, target: "/dialogue/teahouse")),
                Hotspot(id: "bottom-home", label: "首页", x: 0, y: 90.847, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/home")),
                Hotspot(id: "bottom-city", label: "古城", x: 20, y: 90.847, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "bottom-character", label: "古人互动", x: 40.518, y: 90.847, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/character/sushi")),
                Hotspot(id: "bottom-favorites", label: "收藏", x: 60, y: 90.848, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "bottom-profile", label: "我的", x: 80, y: 90.847, width: 20, height: 7, action: HotspotAction(type: .navigate, target: "/profile"))
            ]),
        ScreenConfig(id: "teahouse-dialogue", route: "/dialogue/teahouse", image: "Screens/teahouse-dialogue.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 1.219, y: 5.599, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "dialogue-record", label: "对谈记录", x: 75.844, y: 5.425, width: 20.129, height: 5, action: HotspotAction(type: .navigate, target: "/native/list/dialogues")),
                Hotspot(id: "voice-1", label: "语音1", x: 18.231, y: 44.1, width: 67.397, height: 8.21, action: HotspotAction(type: .speakText, message: "人生如逆旅，我亦是行人。")),
                Hotspot(id: "voice-2", label: "语音2", x: 20.199, y: 53.59, width: 61.395, height: 7.386, action: HotspotAction(type: .speakText, message: "起落本无常，且喜杯中有清欢。")),
                Hotspot(id: "topic-1", label: "你如何面对人生起伏？", x: 5.657, y: 67.364, width: 88.499, height: 5, action: HotspotAction(type: .navigate, target: "/native/dialogue/life")),
                Hotspot(id: "topic-2", label: "黄州给你带来了什么？", x: 6.125, y: 73.373, width: 89.062, height: 5, action: HotspotAction(type: .navigate, target: "/native/dialogue/huangzhou")),
                Hotspot(id: "topic-3", label: "你最想告诉后人的一句话？", x: 5.188, y: 79.382, width: 89.062, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已选择：寄语后人", storageKey: "dialogueTopic", storageValue: "words")),
                Hotspot(id: "continue-btn", label: "继续交谈", x: 16.594, y: 86.208, width: 66.647, height: 5, action: HotspotAction(type: .conditionalNavigate, target: "/task/reward", message: "请先选择一个话题"))
            ]),
        ScreenConfig(id: "task-reward", route: "/task/reward", image: "Screens/task-reward.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 2.911, y: 5.68, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "culture-value", label: "文化值+50", x: 6.972, y: 46.723, width: 25.775, height: 16.614, action: HotspotAction(type: .navigate, target: "/profile")),
                Hotspot(id: "stamp-dongpo", label: "东坡知音印章", x: 35.235, y: 46.755, width: 27.559, height: 16.874, action: HotspotAction(type: .storageAndNavigate, target: "/favorites", storageKey: "favoriteFilter", storageValue: "stamp")),
                Hotspot(id: "sushi-letter", label: "苏轼来信", x: 65.845, y: 46.831, width: 26.338, height: 16.571, action: HotspotAction(type: .navigate, target: "/native/letter/letter-sushi-1")),
                Hotspot(id: "progress", label: "汴京探索进度", x: 6.127, y: 64.372, width: 87.371, height: 10.33, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "next-journey", label: "下一段旅程", x: 78.803, y: 80.439, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/native/city/shu-yuan")),
                Hotspot(id: "view-rewards", label: "查看奖励", x: 7.84, y: 87.205, width: 83.709, height: 6.257, action: HotspotAction(type: .storageAndNavigate, target: "/favorites", storageKey: "favoriteFilter", storageValue: "stamp")),
                Hotspot(id: "continue-journey", label: "继续旅程", x: 7.676, y: 93.749, width: 84.46, height: 5, action: HotspotAction(type: .navigate, target: "/city/bianjing"))
            ]),
        ScreenConfig(id: "poetry-home", route: "/poetry", image: "Screens/poetry-home.png", hotspots: [
                Hotspot(id: "user-avatar", label: "用户头像", x: 4.535, y: 5.724, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/profile")),
                Hotspot(id: "search-icon", label: "搜索", x: 71.197, y: 6.07, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/native/search/main")),
                Hotspot(id: "poetry-lib", label: "诗库", x: 81.197, y: 5.897, width: 17.136, height: 4.74, action: HotspotAction(type: .navigate, target: "/native/list/poems")),
                Hotspot(id: "daily-card", label: "今日诗签", x: 3.873, y: 12.189, width: 92.254, height: 22.644, action: HotspotAction(type: .navigate, target: "/native/poem/niao-ming-jian")),
                Hotspot(id: "enter-poetry", label: "进入诗境", x: 8.779, y: 28.45, width: 30.282, height: 4.827, action: HotspotAction(type: .navigate, target: "/native/poem/niao-ming-jian")),
                Hotspot(id: "cat-landscape", label: "山水", x: 3.404, y: 36.191, width: 17.23, height: 5, action: HotspotAction(type: .storageAndNavigate, target: "/native/list/poems", storageKey: "poetryCategory", storageValue: "landscape")),
                Hotspot(id: "cat-seasons", label: "四季", x: 22.183, y: 36.321, width: 17.324, height: 5, action: HotspotAction(type: .storageAndNavigate, target: "/native/list/poems", storageKey: "poetryCategory", storageValue: "seasons")),
                Hotspot(id: "cat-moon", label: "月夜", x: 41.15, y: 36.234, width: 17.042, height: 5, action: HotspotAction(type: .storageAndNavigate, target: "/native/list/poems", storageKey: "poetryCategory", storageValue: "moon")),
                Hotspot(id: "cat-sorrow", label: "离愁", x: 59.836, y: 36.061, width: 17.324, height: 5, action: HotspotAction(type: .storageAndNavigate, target: "/native/list/poems", storageKey: "poetryCategory", storageValue: "sorrow")),
                Hotspot(id: "cat-border", label: "边塞", x: 78.521, y: 36.297, width: 18.169, height: 5, action: HotspotAction(type: .storageAndNavigate, target: "/native/list/poems", storageKey: "poetryCategory", storageValue: "frontier")),
                Hotspot(id: "rec-jiangxue", label: "推荐《江雪》", x: 2.653, y: 46.5, width: 30.939, height: 27.5, action: HotspotAction(type: .navigate, target: "/poetry/jiangxue")),
                Hotspot(id: "rec-jiangxue-play", label: "江雪朗读", x: 23.221, y: 46.774, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/poetry/jiangxue")),
                Hotspot(id: "rec-niaoming", label: "推荐《鸟鸣涧》", x: 35.681, y: 46.5, width: 28.779, height: 27.5, action: HotspotAction(type: .navigate, target: "/native/poem/niao-ming-jian")),
                Hotspot(id: "rec-niaoming-play", label: "鸟鸣涧朗读", x: 57.6, y: 46.6, width: 6.8, height: 4.5, action: HotspotAction(type: .navigate, target: "/native/poem/niao-ming-jian")),
                Hotspot(id: "rec-jingye", label: "推荐《静夜思》", x: 65.726, y: 46.5, width: 30.282, height: 27.5, action: HotspotAction(type: .navigate, target: "/native/poem/jing-ye-si")),
                Hotspot(id: "rec-jingye-play", label: "静夜思朗读", x: 86.507, y: 47.212, width: 7.559, height: 3.397, action: HotspotAction(type: .navigate, target: "/native/poem/jing-ye-si")),
                Hotspot(id: "refresh", label: "换一批", x: 79.131, y: 41.48, width: 18.075, height: 3.57, action: HotspotAction(type: .navigate, target: "/native/list/poems")),
                Hotspot(id: "card-1", label: "最近卡片一", x: 4.812, y: 78.15, width: 43.221, height: 11.547, action: HotspotAction(type: .navigate, target: "/native/list/works")),
                Hotspot(id: "card-2", label: "最近卡片二", x: 51.531, y: 78.713, width: 44.347, height: 11.287, action: HotspotAction(type: .navigate, target: "/native/list/works")),
                Hotspot(id: "cards-all", label: "全部", x: 81.971, y: 74.793, width: 15.258, height: 3.743, action: HotspotAction(type: .navigate, target: "/native/list/works")),
                Hotspot(id: "bottom-home", label: "首页", x: 3.474, y: 90.876, width: 15.07, height: 6.993, action: HotspotAction(type: .navigate, target: "/home")),
                Hotspot(id: "bottom-city", label: "古城", x: 20.563, y: 90.616, width: 18.357, height: 7.687, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "bottom-poetry", label: "诗境", x: 40.469, y: 90.746, width: 16.948, height: 7.47, action: HotspotAction(type: .navigate, target: "/poetry")),
                Hotspot(id: "bottom-favorites", label: "收藏", x: 60.281, y: 90.963, width: 17.136, height: 7.73, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "bottom-profile", label: "我的", x: 79.249, y: 91.31, width: 18.263, height: 6.95, action: HotspotAction(type: .navigate, target: "/profile"))
            ]),
        ScreenConfig(id: "jiangxue-scene", route: "/poetry/jiangxue", image: "Screens/jiangxue-scene.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 0.78, y: 5.305, width: 12, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "poetry-lib", label: "诗库", x: 83.181, y: 5.664, width: 12, height: 5, action: HotspotAction(type: .navigate, target: "/poetry")),
                Hotspot(id: "play-btn", label: "播放按钮", x: 40.939, y: 36.197, width: 17.606, height: 6.907, action: HotspotAction(type: .toggleStorage, storageKey: "jiangxueVideoPlaying", onMessage: "正在播放《江雪》诗境", offMessage: "已暂停诗境")),
                Hotspot(id: "style-ink", label: "水墨画风", x: 5.845, y: 55.72, width: 20.329, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已选择水墨画风", storageKey: "jiangxueStyle", storageValue: "ink")),
                Hotspot(id: "style-gongbi", label: "工笔画风", x: 28.69, y: 55.937, width: 21.362, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已选择工笔画风", storageKey: "jiangxueStyle", storageValue: "gongbi")),
                Hotspot(id: "style-bluegreen", label: "青绿画风", x: 50.751, y: 55.72, width: 20.892, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已选择青绿画风", storageKey: "jiangxueStyle", storageValue: "bluegreen")),
                Hotspot(id: "style-song", label: "宋画画风", x: 72.249, y: 55.894, width: 24.272, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已选择宋画风格", storageKey: "jiangxueStyle", storageValue: "song")),
                Hotspot(id: "analysis-card", label: "赏析卡片", x: 3.873, y: 63.164, width: 44.366, height: 16.901, action: HotspotAction(type: .navigate, target: "/poetry/jiangxue/analysis")),
                Hotspot(id: "enter-analysis", label: "进入赏析", x: 6.784, y: 75.825, width: 15.916, height: 3.96, action: HotspotAction(type: .navigate, target: "/poetry/jiangxue/analysis")),
                Hotspot(id: "imagery-card", label: "意象卡片", x: 51.408, y: 63.164, width: 44.718, height: 16.901, action: HotspotAction(type: .navigate, target: "/poetry/jiangxue/imagery")),
                Hotspot(id: "enter-imagery", label: "进入意象", x: 53.127, y: 75.694, width: 17.981, height: 3.96, action: HotspotAction(type: .navigate, target: "/poetry/jiangxue/imagery")),
                Hotspot(id: "gen-card-btn", label: "生成诗境卡", x: 6.103, y: 82.594, width: 87.371, height: 5.087, action: HotspotAction(type: .navigate, target: "/poetry/card")),
                Hotspot(id: "bottom-home", label: "首页", x: 4.319, y: 90.703, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/home")),
                Hotspot(id: "bottom-city", label: "古城", x: 25.258, y: 90.833, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "bottom-poetry", label: "诗境", x: 44.883, y: 90.876, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/poetry")),
                Hotspot(id: "bottom-favorites", label: "收藏", x: 64.789, y: 90.963, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "bottom-profile", label: "我的", x: 84.977, y: 90.703, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/profile"))
            ]),
        ScreenConfig(id: "jiangxue-analysis", route: "/poetry/jiangxue/analysis", image: "Screens/jiangxue-analysis.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 3.099, y: 4.944, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "favorite-btn", label: "收藏", x: 79.554, y: 5.68, width: 17.793, height: 4.003, action: HotspotAction(type: .toggleStorage, storageKey: "favoriteJiangxue", onMessage: "已收藏《江雪》", offMessage: "已取消收藏《江雪》")),
                Hotspot(id: "tab-translate", label: "译解", x: 9.601, y: 37.563, width: 25.117, height: 5, action: HotspotAction(type: .navigate, target: "/native/poem/jiangxue")),
                Hotspot(id: "tab-background", label: "背景", x: 37.789, y: 37.692, width: 24.836, height: 5, action: HotspotAction(type: .navigate, target: "/native/poem/jiangxue")),
                Hotspot(id: "tab-art", label: "艺术特色", x: 63.784, y: 37.779, width: 30.376, height: 5, action: HotspotAction(type: .navigate, target: "/native/poem/jiangxue")),
                Hotspot(id: "imagery-loneboat", label: "孤舟", x: 3.497, y: 80.239, width: 21.549, height: 5, action: HotspotAction(type: .storageAndNavigate, target: "/poetry/jiangxue/imagery", storageKey: "selectedImagery", storageValue: "loneboat")),
                Hotspot(id: "imagery-coldriver", label: "寒江", x: 26.591, y: 80.368, width: 21.737, height: 5, action: HotspotAction(type: .storageAndNavigate, target: "/poetry/jiangxue/imagery", storageKey: "selectedImagery", storageValue: "coldRiver")),
                Hotspot(id: "imagery-fisherman", label: "蓑笠翁", x: 50.029, y: 80.412, width: 23.521, height: 5, action: HotspotAction(type: .storageAndNavigate, target: "/poetry/jiangxue/imagery", storageKey: "selectedImagery", storageValue: "fisherman")),
                Hotspot(id: "imagery-snow", label: "飞雪", x: 73.747, y: 80.152, width: 22.676, height: 5, action: HotspotAction(type: .storageAndNavigate, target: "/poetry/jiangxue/imagery", storageKey: "selectedImagery", storageValue: "snow")),
                Hotspot(id: "view-imagery", label: "查看意象详解", x: 6.925, y: 85.554, width: 86.995, height: 5, action: HotspotAction(type: .conditionalStorageNavigate, target: "/poetry/jiangxue/imagery", storageKey: "selectedImagery", defaultValue: "loneboat")),
                Hotspot(id: "bottom-home", label: "首页", x: 5.258, y: 92.35, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/home")),
                Hotspot(id: "bottom-city", label: "古城", x: 24.319, y: 92.48, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "bottom-poetry", label: "诗境", x: 44.601, y: 92.35, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/poetry")),
                Hotspot(id: "bottom-favorites", label: "收藏", x: 63.756, y: 92.35, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "bottom-profile", label: "我的", x: 83.568, y: 92.307, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/profile"))
            ]),
        ScreenConfig(id: "jiangxue-imagery", route: "/poetry/jiangxue/imagery", image: "Screens/jiangxue-imagery.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 2.441, y: 4.9, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "favorite-btn", label: "收藏", x: 80.962, y: 5.247, width: 18.075, height: 5, action: HotspotAction(type: .toggleStorage, storageKey: "favoriteImageryLoneBoat", onMessage: "已收藏\"孤舟\"意象", offMessage: "已取消收藏")),
                Hotspot(id: "main-imagery", label: "孤舟", x: 3.498, y: 16.197, width: 93.099, height: 31.046, action: HotspotAction(type: .navigate, target: "/native/imagery/gu-zhou")),
                Hotspot(id: "mini-coldriver", label: "寒江", x: 3.31, y: 48.738, width: 30.845, height: 21.381, action: HotspotAction(type: .navigate, target: "/native/imagery/han-jiang")),
                Hotspot(id: "mini-fisherman", label: "蓑笠翁", x: 35.249, y: 48.131, width: 29.812, height: 22.161, action: HotspotAction(type: .navigate, target: "/native/imagery/suo-li-weng")),
                Hotspot(id: "mini-snow", label: "飞雪", x: 65.779, y: 48.478, width: 31.127, height: 21.555, action: HotspotAction(type: .navigate, target: "/native/imagery/fei-xue")),
                Hotspot(id: "poem-line-1", label: "关联诗句1", x: 6.455, y: 75.027, width: 42.254, height: 2.546, action: HotspotAction(type: .navigate, target: "/native/poem/jiangxue")),
                Hotspot(id: "poem-line-2", label: "关联诗句2", x: 6.455, y: 77.573, width: 42.254, height: 2.546, action: HotspotAction(type: .navigate, target: "/native/poem/jiangxue")),
                Hotspot(id: "keyword-guji", label: "孤寂", x: 6.033, y: 85.402, width: 19.953, height: 5, action: HotspotAction(type: .navigate, target: "/native/search/孤寂")),
                Hotspot(id: "keyword-gaojie", label: "高洁", x: 28.751, y: 85.315, width: 20.61, height: 5, action: HotspotAction(type: .navigate, target: "/native/search/高洁")),
                Hotspot(id: "keyword-kongling", label: "空灵", x: 50.122, y: 85.272, width: 20.892, height: 5, action: HotspotAction(type: .navigate, target: "/native/search/空灵")),
                Hotspot(id: "keyword-qinghan", label: "清寒", x: 72.338, y: 85.315, width: 20.704, height: 5, action: HotspotAction(type: .navigate, target: "/native/search/清寒")),
                Hotspot(id: "back-analysis", label: "返回诗词赏析", x: 4.765, y: 91.707, width: 89.624, height: 5, action: HotspotAction(type: .navigate, target: "/poetry/jiangxue/analysis"))
            ]),
        ScreenConfig(id: "poetry-card", route: "/poetry/card", image: "Screens/poetry-card.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 2.911, y: 5.637, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "poetry-lib", label: "诗库", x: 81.808, y: 5.68, width: 14.413, height: 5, action: HotspotAction(type: .navigate, target: "/poetry")),
                Hotspot(id: "style-ink", label: "水墨", x: 34.577, y: 49.783, width: 10, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "诗境卡画风：水墨", storageKey: "poetryCardStyle", storageValue: "ink")),
                Hotspot(id: "style-gongbi", label: "工笔", x: 50.817, y: 50.65, width: 10, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "诗境卡画风：工笔", storageKey: "poetryCardStyle", storageValue: "gongbi")),
                Hotspot(id: "style-bluegreen", label: "青绿", x: 65.239, y: 50.173, width: 10, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "诗境卡画风：青绿", storageKey: "poetryCardStyle", storageValue: "bluegreen")),
                Hotspot(id: "style-song", label: "宋画", x: 79.85, y: 49.827, width: 10, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "诗境卡画风：宋画", storageKey: "poetryCardStyle", storageValue: "song")),
                Hotspot(id: "layout-horizontal", label: "横版", x: 36.455, y: 56.96, width: 10, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已选择横版布局", storageKey: "poetryCardLayout", storageValue: "horizontal")),
                Hotspot(id: "layout-vertical", label: "竖版", x: 56.657, y: 57.047, width: 10, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已选择竖版布局", storageKey: "poetryCardLayout", storageValue: "vertical")),
                Hotspot(id: "layout-whitespace", label: "留白", x: 71.507, y: 57.133, width: 21.08, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已选择留白布局", storageKey: "poetryCardLayout", storageValue: "whitespace")),
                Hotspot(id: "seal-red", label: "朱印", x: 31.385, y: 63.876, width: 29.249, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已添加朱印", storageKey: "poetryCardSeal", storageValue: "red")),
                Hotspot(id: "seal-none", label: "无印", x: 62.136, y: 63.703, width: 30.563, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已取消印章", storageKey: "poetryCardSeal", storageValue: "none")),
                Hotspot(id: "add-note", label: "添加题注", x: 3.403, y: 71.142, width: 46.62, height: 11.327, action: HotspotAction(type: .navigate, target: "/native/note/main")),
                Hotspot(id: "select-border", label: "选择边框", x: 50.915, y: 71.516, width: 45.211, height: 11.284, action: HotspotAction(type: .toast, message: "已打开边框选择")),
                Hotspot(id: "save-card", label: "保存诗境卡", x: 4.789, y: 84.761, width: 43.521, height: 5, action: HotspotAction(type: .incrementOnce, message: "已保存至\"我的作品\"", storageKey: "poetryCardCount", flagKey: "jiangxueCardCreated")),
                Hotspot(id: "share", label: "分享给朋友", x: 50.164, y: 84.397, width: 44.46, height: 5, action: HotspotAction(type: .navigate, target: "/native/share/card"))
            ]),
        ScreenConfig(id: "onboarding-intro", route: "/onboarding/intro", image: "Screens/onboarding-intro.png", hotspots: [
                Hotspot(id: "card-city", label: "漫游古城", x: 4.437, y: 33.348, width: 91.315, height: 13.711, action: HotspotAction(type: .toast, message: "漫游古城，探索不同朝代的文化记忆")),
                Hotspot(id: "card-people", label: "邂逅古人", x: 2.652, y: 48.684, width: 93.005, height: 14.231, action: HotspotAction(type: .toast, message: "与历史人物相遇，聆听他们的故事")),
                Hotspot(id: "card-dreambook", label: "收集梦册", x: 4.906, y: 64.369, width: 91.69, height: 14.534, action: HotspotAction(type: .toast, message: "收藏诗词、器物、人物与旅程")),
                Hotspot(id: "start-btn", label: "开启入梦之旅", x: 12.394, y: 81.078, width: 74.601, height: 5, action: HotspotAction(type: .navigate, target: "/onboarding/preferences")),
                Hotspot(id: "skip-btn", label: "稍后再看", x: 39.671, y: 86.824, width: 21.455, height: 5, action: HotspotAction(type: .storageAndNavigate, target: "/home", storageKey: "onboardingSkipped", storageValue: "true"))
            ]),
        ScreenConfig(id: "preference-test", route: "/onboarding/preferences", image: "Screens/preference-test.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 0, y: 1, width: 12, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "scene-landscape", label: "山水", x: 5.563, y: 29.8, width: 42.544, height: 8.037, action: HotspotAction(type: .setStorageAndToast, message: "你选择了山水", storageKey: "preferenceScene", storageValue: "landscape")),
                Hotspot(id: "scene-marketplace", label: "市井", x: 51.437, y: 30.321, width: 40.481, height: 7.299, action: HotspotAction(type: .setStorageAndToast, message: "你选择了市井", storageKey: "preferenceScene", storageValue: "marketplace")),
                Hotspot(id: "content-poetry", label: "诗", x: 7.344, y: 45.792, width: 18.347, height: 8.471, action: HotspotAction(type: .setStorageAndToast, message: "你选择了诗", storageKey: "preferenceContent", storageValue: "poetry")),
                Hotspot(id: "content-painting", label: "画", x: 29.716, y: 45.879, width: 19.566, height: 8.688, action: HotspotAction(type: .setStorageAndToast, message: "你选择了画", storageKey: "preferenceContent", storageValue: "painting")),
                Hotspot(id: "content-artifact", label: "器物", x: 73.284, y: 45.618, width: 20.504, height: 8.905, action: HotspotAction(type: .setStorageAndToast, message: "你选择了器物", storageKey: "preferenceContent", storageValue: "artifact")),
                Hotspot(id: "dynasty-tang", label: "盛唐", x: 6.97, y: 62.304, width: 26.319, height: 8.254, action: HotspotAction(type: .setStorageAndToast, message: "你选择了盛唐", storageKey: "preferenceDynasty", storageValue: "tang")),
                Hotspot(id: "dynasty-northern", label: "北宋", x: 36.094, y: 62.607, width: 26.319, height: 8.384, action: HotspotAction(type: .setStorageAndToast, message: "你选择了北宋", storageKey: "preferenceDynasty", storageValue: "northernSong")),
                Hotspot(id: "dynasty-southern", label: "南宋", x: 66.062, y: 62.26, width: 26.038, height: 8.471, action: HotspotAction(type: .setStorageAndToast, message: "你选择了南宋", storageKey: "preferenceDynasty", storageValue: "southernSong")),
                Hotspot(id: "mood-lively", label: "热闹", x: 6.97, y: 78.642, width: 41.512, height: 6.909, action: HotspotAction(type: .setStorageAndToast, message: "你选择了热闹", storageKey: "preferenceMood", storageValue: "lively")),
                Hotspot(id: "mood-quiet", label: "清幽", x: 51.062, y: 78.252, width: 41.419, height: 7.646, action: HotspotAction(type: .setStorageAndToast, message: "你选择了清幽", storageKey: "preferenceMood", storageValue: "quiet")),
                Hotspot(id: "generate-btn", label: "生成我的古典身份", x: 9.027, y: 88.004, width: 80.903, height: 5.738, action: HotspotAction(type: .setDefaultsAndNavigate, target: "/onboarding/result", defaults: [KV(key: "preferenceScene", value: "landscape"), KV(key: "preferenceContent", value: "poetry"), KV(key: "preferenceDynasty", value: "northernSong"), KV(key: "preferenceMood", value: "quiet")]))
            ]),
        ScreenConfig(id: "identity-result", route: "/onboarding/result", image: "Screens/identity-result.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 2.72, y: 5.208, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "identity", label: "身份画像", x: 8.311, y: 12.744, width: 35.791, height: 18.623, action: HotspotAction(type: .toast, message: "梦客·苏蘅，江南游学者")),
                Hotspot(id: "recommend-city", label: "推荐汴京", x: 3.435, y: 59.197, width: 93.751, height: 12.983, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "initial-stamp", label: "初始印章", x: 2.556, y: 72.456, width: 93.939, height: 11.768, action: HotspotAction(type: .storageAndNavigate, target: "/favorites", storageKey: "favoriteFilter", storageValue: "stamp")),
                Hotspot(id: "enter-dream", label: "进入我的梦境", x: 10.246, y: 85.466, width: 79.965, height: 5, action: HotspotAction(type: .storageAndNavigate, target: "/home", storageKey: "onboardingComplete", storageValue: "true")),
                Hotspot(id: "retry-btn", label: "重新测试", x: 25.029, y: 91.21, width: 51.735, height: 5, action: HotspotAction(type: .navigate, target: "/onboarding/preferences"))
            ]),
        ScreenConfig(id: "artifact-home", route: "/artifact", image: "Screens/artifact-home.png", hotspots: [
                Hotspot(id: "guide", label: "识趣指南", x: 78.701, y: 5.664, width: 18, height: 5, action: HotspotAction(type: .toast, message: "拍摄完整器形，可以获得更准确的识别结果")),
                Hotspot(id: "upload", label: "相册上传", x: 3.78, y: 20.434, width: 33.756, height: 12.237, action: HotspotAction(type: .delayedNavigate, target: "/artifact/result", message: "已选择相册上传模拟", delay: 600)),
                Hotspot(id: "camera", label: "拍摄识别", x: 37.258, y: 20.303, width: 26.62, height: 12.237, action: HotspotAction(type: .delayedNavigate, target: "/artifact/result", message: "正在扫描古物", delay: 800)),
                Hotspot(id: "demo", label: "示例体验", x: 63.827, y: 20.058, width: 29.531, height: 13.191, action: HotspotAction(type: .navigate, target: "/artifact/result")),
                Hotspot(id: "hot-qinghua", label: "青花瓷", x: 5, y: 48, width: 20, height: 10, action: HotspotAction(type: .navigate, target: "/artifact/result")),
                Hotspot(id: "hot-mirror", label: "铜镜", x: 28, y: 48, width: 20, height: 10, action: HotspotAction(type: .navigate, target: "/native/artifact/tong-jing")),
                Hotspot(id: "hot-incense", label: "香炉", x: 52, y: 48, width: 20, height: 10, action: HotspotAction(type: .navigate, target: "/native/artifact/xiang-lu")),
                Hotspot(id: "hot-jade", label: "玉佩", x: 76, y: 48, width: 20, height: 10, action: HotspotAction(type: .navigate, target: "/native/artifact/yu-pei")),
                Hotspot(id: "recent-qinghua", label: "最近青花瓷", x: 4.531, y: 78.728, width: 64.93, height: 10.634, action: HotspotAction(type: .navigate, target: "/artifact/result")),
                Hotspot(id: "recent-detail", label: "查看详情", x: 72.507, y: 83.495, width: 19.39, height: 5, action: HotspotAction(type: .navigate, target: "/artifact/result")),
                Hotspot(id: "bottom-home", label: "首页", x: 5.258, y: 91.7, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/home")),
                Hotspot(id: "bottom-city", label: "古城", x: 24.601, y: 91.743, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "bottom-experience", label: "体验", x: 44.789, y: 91.743, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/artifact")),
                Hotspot(id: "bottom-favorites", label: "收藏", x: 63.662, y: 91.7, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "bottom-profile", label: "我的", x: 83.662, y: 91.613, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/profile"))
            ]),
        ScreenConfig(id: "artifact-result", route: "/artifact/result", image: "Screens/artifact-result.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 3.568, y: 5.637, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "main-image", label: "青花瓷", x: 14.202, y: 13.807, width: 71.784, height: 43.136, action: HotspotAction(type: .toast, message: "识别结果：青花缠枝莲纹瓶")),
                Hotspot(id: "shape", label: "器形", x: 24.719, y: 75.217, width: 15.915, height: 5, action: HotspotAction(type: .toast, message: "器形：长颈、溜肩、鼓腹")),
                Hotspot(id: "pattern", label: "纹样", x: 41.728, y: 75.217, width: 16.573, height: 5, action: HotspotAction(type: .navigate, target: "/artifact/pattern")),
                Hotspot(id: "usage", label: "用途", x: 59.207, y: 75.174, width: 15.634, height: 5, action: HotspotAction(type: .toast, message: "主要用于陈设与储藏")),
                Hotspot(id: "detail-btn", label: "查看详情", x: 30.61, y: 80.199, width: 40.235, height: 5.823, action: HotspotAction(type: .navigate, target: "/native/artifact/qinghua-ping")),
                Hotspot(id: "flash", label: "闪光灯", x: 8.192, y: 89.079, width: 13.944, height: 5.65, action: HotspotAction(type: .toast, message: "闪光灯模拟")),
                Hotspot(id: "gallery", label: "相册", x: 78.38, y: 89.123, width: 12.629, height: 5.52, action: HotspotAction(type: .navigate, target: "/native/photo/main")),
                Hotspot(id: "bottom-shoot", label: "拍摄", x: 40.47, y: 88.462, width: 18.732, height: 8.034, action: HotspotAction(type: .navigate, target: "/artifact"))
            ]),
        ScreenConfig(id: "artifact-pattern", route: "/artifact/pattern", image: "Screens/artifact-pattern.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 1.972, y: 5.594, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "share", label: "分享", x: 87.16, y: 5.854, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/native/share/pattern")),
                Hotspot(id: "tab-structure", label: "纹样结构", x: 10.258, y: 37.606, width: 24.272, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "当前查看", storageKey: "patternTab", storageValue: "structure")),
                Hotspot(id: "tab-symbolism", label: "寓意象征", x: 37.221, y: 37.952, width: 24.46, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "当前查看", storageKey: "patternTab", storageValue: "symbolism")),
                Hotspot(id: "tab-era", label: "时代风格", x: 63.808, y: 37.692, width: 25.869, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "当前查看", storageKey: "patternTab", storageValue: "era")),
                Hotspot(id: "lotus-card", label: "莲瓣卡", x: 2.934, y: 58.7, width: 30.657, height: 18.911, action: HotspotAction(type: .navigate, target: "/native/pattern/莲瓣")),
                Hotspot(id: "scroll-card", label: "卷草卡", x: 34.685, y: 59.176, width: 29.531, height: 18.174, action: HotspotAction(type: .navigate, target: "/native/pattern/卷草")),
                Hotspot(id: "border-card", label: "边饰卡", x: 65.874, y: 58.787, width: 29.624, height: 18.868, action: HotspotAction(type: .navigate, target: "/native/pattern/边饰")),
                Hotspot(id: "similar-1", label: "相似纹样1", x: 6.126, y: 82.507, width: 28.122, height: 6.69, action: HotspotAction(type: .navigate, target: "/native/similar/缠枝牡丹")),
                Hotspot(id: "similar-2", label: "相似纹样2", x: 36.657, y: 82.247, width: 27.84, height: 7.167, action: HotspotAction(type: .navigate, target: "/native/similar/缠枝菊花")),
                Hotspot(id: "similar-3", label: "相似纹样3", x: 67, y: 82.16, width: 29.531, height: 7.99, action: HotspotAction(type: .navigate, target: "/native/similar/缠枝灵芝")),
                Hotspot(id: "view-piece", label: "查看整器", x: 9.178, y: 91.75, width: 34.789, height: 5, action: HotspotAction(type: .navigate, target: "/artifact/result")),
                Hotspot(id: "favorite-pattern", label: "收藏纹样", x: 47.488, y: 91.576, width: 44.93, height: 5, action: HotspotAction(type: .toggleStorage, storageKey: "favoriteArtifactPattern", onMessage: "已收藏纹样", offMessage: "已取消收藏纹样"))
            ]),
        ScreenConfig(id: "activities-home", route: "/activities", image: "Screens/activities-home.png", hotspots: [
                Hotspot(id: "search", label: "搜索", x: 86.667, y: 5.42, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/native/search/main")),
                Hotspot(id: "feihualing-card", label: "飞花令·春", x: 5, y: 10, width: 90, height: 15, action: HotspotAction(type: .navigate, target: "/activities/feihualing")),
                Hotspot(id: "join-btn", label: "立即参与", x: 8.075, y: 25.467, width: 26.432, height: 5, action: HotspotAction(type: .navigate, target: "/activities/feihualing")),
                Hotspot(id: "view-all", label: "查看全部活动", x: 68.92, y: 31.9, width: 28.592, height: 5, action: HotspotAction(type: .navigate, target: "/native/list/activities")),
                Hotspot(id: "calendar", label: "日历", x: 5.939, y: 36.977, width: 89.061, height: 8.554, action: HotspotAction(type: .navigate, target: "/native/list/activities")),
                Hotspot(id: "game-lantern", label: "猜灯谜", x: 3.498, y: 47.374, width: 44.742, height: 13.711, action: HotspotAction(type: .navigate, target: "/native/activity/dengmi")),
                Hotspot(id: "game-painting", label: "古画找物", x: 50.817, y: 46.854, width: 46.995, height: 14.967, action: HotspotAction(type: .navigate, target: "/native/activity/hua-zhao")),
                Hotspot(id: "game-pattern", label: "纹样配对", x: 2.047, y: 62.282, width: 46.714, height: 14.534, action: HotspotAction(type: .navigate, target: "/native/activity/wenyang")),
                Hotspot(id: "game-artifact", label: "器物辨识", x: 51.775, y: 62.455, width: 45.493, height: 14.447, action: HotspotAction(type: .navigate, target: "/native/activity/qigu")),
                Hotspot(id: "week-reward", label: "本周奖励", x: 4.343, y: 77.712, width: 92.441, height: 11.977, action: HotspotAction(type: .storageAndNavigate, target: "/favorites", storageKey: "favoriteFilter", storageValue: "stamp")),
                Hotspot(id: "bottom-home", label: "首页", x: 6.854, y: 91.917, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/home")),
                Hotspot(id: "bottom-city", label: "古城", x: 25.446, y: 91.83, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "bottom-activities", label: "雅集", x: 44.601, y: 92.003, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/activities")),
                Hotspot(id: "bottom-favorites", label: "收藏", x: 63.944, y: 91.743, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "bottom-profile", label: "我的", x: 82.723, y: 91.657, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/profile"))
            ]),
        ScreenConfig(id: "feihualing-challenge", route: "/activities/feihualing", image: "Screens/feihualing-challenge.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 0, y: 4.468, width: 12, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "rules-info", label: "活动说明", x: 28.222, y: 5.425, width: 35, height: 5, action: HotspotAction(type: .toast, message: "选择一句含有\"春\"字的诗句")),
                Hotspot(id: "rules-detail", label: "查看规则", x: 65, y: 5.186, width: 35, height: 5, action: HotspotAction(type: .toast, message: "每答对一题可获得花瓣")),
                Hotspot(id: "answer-a", label: "答案A", x: 7.908, y: 53.623, width: 84.091, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已选择 A", storageKey: "feihualingAnswer", storageValue: "A")),
                Hotspot(id: "answer-b", label: "答案B", x: 8.564, y: 60.286, width: 82.778, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已选择 B", storageKey: "feihualingAnswer", storageValue: "B")),
                Hotspot(id: "answer-c", label: "答案C", x: 7.814, y: 66.69, width: 85.967, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已选择 C", storageKey: "feihualingAnswer", storageValue: "C")),
                Hotspot(id: "answer-d", label: "答案D", x: 8.939, y: 73.007, width: 83.529, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "已选择 D", storageKey: "feihualingAnswer", storageValue: "D")),
                Hotspot(id: "submit-btn", label: "提交答案", x: 21.501, y: 79.852, width: 57.268, height: 5, action: HotspotAction(type: .checkAnswer, target: "/stamp/reward", message: "请先选择答案", storageKey: "feihualingAnswer", correctAnswer: "A", storageFlags: [KV(key: "feihualingCompleted", value: "true")]))
            ]),
        ScreenConfig(id: "stamp-reward", route: "/stamp/reward", image: "Screens/stamp-reward.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 0.26, y: 5.305, width: 12, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "share", label: "分享", x: 86.559, y: 5.066, width: 12, height: 5, action: HotspotAction(type: .navigate, target: "/native/share/stamp")),
                Hotspot(id: "main-stamp", label: "春日雅士", x: 24.343, y: 24.221, width: 55.54, height: 24.285, action: HotspotAction(type: .navigate, target: "/native/stamp/chun-ri-ya-shi")),
                Hotspot(id: "stamp-card", label: "印章奖励", x: 8.38, y: 51.235, width: 26.244, height: 15.964, action: HotspotAction(type: .storageAndNavigate, target: "/favorites", storageKey: "favoriteFilter", storageValue: "stamp")),
                Hotspot(id: "ya-card", label: "雅集值", x: 36.657, y: 51.538, width: 26.995, height: 15.228, action: HotspotAction(type: .navigate, target: "/activities")),
                Hotspot(id: "petal-card", label: "花瓣", x: 65.122, y: 51.712, width: 26.714, height: 15.098, action: HotspotAction(type: .navigate, target: "/activities/feihualing")),
                Hotspot(id: "stamp-book", label: "印章图鉴", x: 8.592, y: 78.1, width: 82.958, height: 8.684, action: HotspotAction(type: .storageAndNavigate, target: "/favorites", storageKey: "favoriteFilter", storageValue: "stamp")),
                Hotspot(id: "claim-btn", label: "收下印章", x: 7.23, y: 87.503, width: 85.962, height: 5, action: HotspotAction(type: .incrementOnce, message: "春日雅士印章已收入收藏", storageKey: "petalCount", flagKey: "springStampClaimed")),
                Hotspot(id: "view-stamps", label: "查看我的印章", x: 8.24, y: 93.213, width: 82.113, height: 5, action: HotspotAction(type: .storageAndNavigate, target: "/favorites", storageKey: "favoriteFilter", storageValue: "stamp"))
            ]),
        ScreenConfig(id: "favorites", route: "/favorites", image: "Screens/favorites.png", hotspots: [
                Hotspot(id: "search", label: "搜索", x: 85.54, y: 4.77, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/native/search/main")),
                Hotspot(id: "filter-all", label: "全部", x: 5.005, y: 21.738, width: 15.54, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "查看：全部收藏", storageKey: "favoriteFilter", storageValue: "all")),
                Hotspot(id: "filter-poetry", label: "诗词", x: 21.033, y: 21.868, width: 14.601, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "查看：诗词收藏", storageKey: "favoriteFilter", storageValue: "poetry")),
                Hotspot(id: "filter-artifact", label: "器物", x: 37.061, y: 22.041, width: 14.977, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "查看：器物收藏", storageKey: "favoriteFilter", storageValue: "artifact")),
                Hotspot(id: "filter-character", label: "人物", x: 53.371, y: 21.781, width: 15.634, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "查看：人物收藏", storageKey: "favoriteFilter", storageValue: "character")),
                Hotspot(id: "filter-letter", label: "书信", x: 69.869, y: 22.388, width: 15.352, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "查看：书信收藏", storageKey: "favoriteFilter", storageValue: "letter")),
                Hotspot(id: "filter-stamp", label: "印章", x: 85.85, y: 22.061, width: 14.15, height: 5, action: HotspotAction(type: .setStorageAndToast, message: "查看：印章收藏", storageKey: "favoriteFilter", storageValue: "stamp")),
                Hotspot(id: "edit-btn", label: "编辑", x: 85.562, y: 27.718, width: 10, height: 2.833, action: HotspotAction(type: .toggleStorage, storageKey: "favoritesEditing", onMessage: "编辑中：点卡片可取消收藏", offMessage: "已退出编辑")),
                Hotspot(id: "item-yijiangnan", label: "忆江南", x: 3.122, y: 30.147, width: 31.221, height: 20.948, action: HotspotAction(type: .navigate, target: "/native/favorite/0")),
                Hotspot(id: "item-qingyou", label: "青釉瓶", x: 34.911, y: 30.147, width: 29.906, height: 21.121, action: HotspotAction(type: .navigate, target: "/native/favorite/1")),
                Hotspot(id: "item-sushi", label: "苏轼", x: 65.376, y: 30.836, width: 31.033, height: 20.471, action: HotspotAction(type: .navigate, target: "/native/favorite/2")),
                Hotspot(id: "item-letter", label: "与友人书", x: 3.549, y: 51.725, width: 30.188, height: 20.298, action: HotspotAction(type: .navigate, target: "/native/favorite/3")),
                Hotspot(id: "item-stamp-qinghui", label: "清晖远游", x: 35.141, y: 51.547, width: 29.343, height: 20.125, action: HotspotAction(type: .navigate, target: "/native/favorite/4")),
                Hotspot(id: "item-chunri", label: "春日", x: 66.366, y: 52.327, width: 29.155, height: 19.691, action: HotspotAction(type: .navigate, target: "/native/favorite/5")),
                Hotspot(id: "item-maogong", label: "毛公鼎", x: 4.905, y: 72.778, width: 29.343, height: 18.434, action: HotspotAction(type: .navigate, target: "/native/favorite/6")),
                Hotspot(id: "item-liqingzhao", label: "李清照", x: 35.099, y: 73.038, width: 29.249, height: 17.828, action: HotspotAction(type: .navigate, target: "/native/favorite/7")),
                Hotspot(id: "item-family-letter", label: "一封家书", x: 64.718, y: 73.034, width: 32.817, height: 17.871, action: HotspotAction(type: .navigate, target: "/native/favorite/8")),
                Hotspot(id: "bottom-home", label: "首页", x: 5.822, y: 92.437, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/home")),
                Hotspot(id: "bottom-city", label: "古城", x: 24.601, y: 92.263, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "bottom-activities", label: "雅集", x: 44.225, y: 92.35, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/activities")),
                Hotspot(id: "bottom-favorites", label: "收藏", x: 64.507, y: 92.437, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "bottom-profile", label: "我的", x: 82.911, y: 92.22, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/profile"))
            ]),
        ScreenConfig(id: "dreambook", route: "/dreambook", image: "Screens/dreambook.png", hotspots: [
                Hotspot(id: "back", label: "返回", x: 3.005, y: 5.074, width: 10, height: 5, action: HotspotAction(type: .back)),
                Hotspot(id: "settings", label: "设置", x: 86.502, y: 5.464, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/native/settings/main")),
                Hotspot(id: "city-bianjing", label: "汴京", x: 11.573, y: 32.108, width: 26.526, height: 16.831, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "city-hangzhou", label: "杭州", x: 38.253, y: 32.325, width: 25.117, height: 16.831, action: HotspotAction(type: .navigate, target: "/native/city/nan-song")),
                Hotspot(id: "city-jinling", label: "金陵", x: 63.244, y: 32.455, width: 25.775, height: 16.354, action: HotspotAction(type: .navigate, target: "/native/city/ming")),
                Hotspot(id: "person-sushi", label: "苏轼", x: 11.385, y: 52.925, width: 22.864, height: 11.197, action: HotspotAction(type: .navigate, target: "/character/sushi")),
                Hotspot(id: "person-liqingzhao", label: "李清照", x: 36.939, y: 53.099, width: 26.056, height: 11.154, action: HotspotAction(type: .navigate, target: "/native/character/liqingzhao")),
                Hotspot(id: "person-wangwei", label: "王维", x: 64.652, y: 53.315, width: 23.146, height: 11.544, action: HotspotAction(type: .navigate, target: "/native/character/wangwei")),
                Hotspot(id: "poetry-card-1", label: "诗境留痕1", x: 10.54, y: 72.226, width: 25.117, height: 15.531, action: HotspotAction(type: .navigate, target: "/native/list/works")),
                Hotspot(id: "poetry-card-2", label: "诗境留痕2", x: 36.563, y: 72.355, width: 27.089, height: 15.704, action: HotspotAction(type: .navigate, target: "/native/list/works")),
                Hotspot(id: "poetry-card-3", label: "诗境留痕3", x: 64.183, y: 72.095, width: 24.46, height: 15.964, action: HotspotAction(type: .navigate, target: "/native/list/works")),
                Hotspot(id: "continue-btn", label: "继续补全梦册", x: 13.239, y: 88.938, width: 73.005, height: 5, action: HotspotAction(type: .navigate, target: "/home"))
            ]),
        ScreenConfig(id: "profile", route: "/profile", image: "Screens/profile.png", hotspots: [
                Hotspot(id: "settings", label: "设置", x: 87.16, y: 6.59, width: 11, height: 6, action: HotspotAction(type: .navigate, target: "/native/settings/main")),
                Hotspot(id: "avatar", label: "头像", x: 6.784, y: 13.287, width: 26.714, height: 13.277, action: HotspotAction(type: .toast, message: "头像修改为原型模拟")),
                Hotspot(id: "identity", label: "用户身份", x: 35.23, y: 17.664, width: 28.592, height: 5.043, action: HotspotAction(type: .toast, message: "梦客·苏蘅，江南游学者")),
                Hotspot(id: "culture-progress", label: "文化进度", x: 82.934, y: 25.417, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/native/settings/main")),
                Hotspot(id: "stat-poetry", label: "诗词", x: 5, y: 30, width: 20, height: 10, action: HotspotAction(type: .storageAndNavigate, target: "/favorites", storageKey: "favoriteFilter", storageValue: "poetry")),
                Hotspot(id: "stat-artifact", label: "器物", x: 28, y: 30, width: 20, height: 10, action: HotspotAction(type: .storageAndNavigate, target: "/favorites", storageKey: "favoriteFilter", storageValue: "artifact")),
                Hotspot(id: "stat-character", label: "人物", x: 52, y: 30, width: 20, height: 10, action: HotspotAction(type: .storageAndNavigate, target: "/favorites", storageKey: "favoriteFilter", storageValue: "character")),
                Hotspot(id: "stat-stamp", label: "印章", x: 76, y: 30, width: 20, height: 10, action: HotspotAction(type: .storageAndNavigate, target: "/favorites", storageKey: "favoriteFilter", storageValue: "stamp")),
                Hotspot(id: "my-favorites", label: "我的收藏", x: 3.498, y: 40.836, width: 90.188, height: 7.427, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "my-dreambook", label: "千年梦册", x: 3.216, y: 48.056, width: 91.408, height: 7.557, action: HotspotAction(type: .navigate, target: "/dreambook")),
                Hotspot(id: "my-works", label: "我的作品", x: 3.498, y: 55.536, width: 92.254, height: 6.127, action: HotspotAction(type: .navigate, target: "/native/list/works")),
                Hotspot(id: "my-settings", label: "设置", x: 3.873, y: 61.759, width: 92.723, height: 6.777, action: HotspotAction(type: .navigate, target: "/native/settings/main")),
                Hotspot(id: "trace-bianjing", label: "汴京", x: 6.502, y: 74.1, width: 27.183, height: 14.187, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "trace-hangzhou", label: "杭州", x: 35.906, y: 74.143, width: 26.62, height: 13.754, action: HotspotAction(type: .navigate, target: "/native/city/nan-song")),
                Hotspot(id: "trace-nanjing", label: "南京", x: 64.935, y: 75.356, width: 28.093, height: 12.594, action: HotspotAction(type: .navigate, target: "/native/city/ming")),
                Hotspot(id: "bottom-home", label: "首页", x: 6.854, y: 91.137, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/home")),
                Hotspot(id: "bottom-city", label: "古城", x: 24.319, y: 91.57, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/city/bianjing")),
                Hotspot(id: "bottom-activities", label: "雅集", x: 45.07, y: 91.7, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/activities")),
                Hotspot(id: "bottom-favorites", label: "收藏", x: 64.413, y: 91.44, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/favorites")),
                Hotspot(id: "bottom-profile", label: "我的", x: 83.38, y: 91.223, width: 10, height: 5, action: HotspotAction(type: .navigate, target: "/profile"))
            ])
    ]

    static func screen(id: String) -> ScreenConfig? {
        all.first { $0.id == id }
    }

    static func screen(route: String) -> ScreenConfig? {
        all.first { $0.route == route }
    }
}

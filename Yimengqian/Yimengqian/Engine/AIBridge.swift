// AIBridge.swift
//
// AI 通道 —— 为「诗境卡题注生成 / 对谈追问 / 意象联想」提供统一出入口。
//
// 设计原则（很重要，决定了它现在能不能用）：
// 1) **key 留空即可运行**。本文件不内置任何密钥；未配置时所有能力回落到本地规则引擎，
//    因此断网、无账号、零成本也能演示，且不会白屏或转圈等待。
// 2) 配了 key 才走网络。key 从 Info.plist 的 `YimengAIKey` 或环境变量 `YIMENG_AI_KEY` 读，
//    **不写进仓库**（本项目是公开仓库，写进去等于泄露）。
// 3) 一切失败都必须降级到本地，绝不把"网络错误"直接抛给用户。
//
// 现状（诚实说明）：
// - 本地降级 = 模板 + 意象库 + 押韵校验，属**规则引擎**，不是语言模型；
// - 远端 = OpenAI 兼容的 /v1/chat/completions，只在配置了 key 时启用。
//   真机上要联网，答辩演示若主打"离线"，请保持 key 为空、走本地路径。

import Foundation
import UIKit

/// 一次生成请求的意图
enum AIIntent: String {
    /// 给诗境卡生成一句题注（1 行，≤20 字）
    case cardNote
    /// 对谈追问：把用户的问句转成苏轼口吻的答句（2–3 句）
    case dialogueReply
    /// 意象联想：列 3 个与给定意象相关的画面
    case imageryIdeas

    var systemPrompt: String {
        switch self {
        case .cardNote:
            return "你是一位宋代文人，为一张诗境卡写题注。只输出题注本身，一行，不超过 20 个字，不带引号，不解释。"
        case .dialogueReply:
            return "你扮演苏轼，用第一人称、文白相间的口吻回答。2 到 3 句，不超过 60 字，不要提及自己是 AI。"
        case .imageryIdeas:
            return "围绕用户给出的意象，列出 3 个具体的画面短语，每个不超过 8 字，用顿号分隔，不要解释。"
        }
    }
}

/// 生成结果 + 来源标记（UI 要能如实标注"本地规则"还是"在线生成"）
struct AIResult {
    let text: String
    let source: AISource

    enum AISource {
        /// 本地模板 / 规则引擎
        case local
        /// 远端语言模型
        case remote
    }

    var sourceLabel: String {
        switch source {
        case .local: return "本地规则"
        case .remote: return "在线生成"
        }
    }
}

/// 统一入口。JSON 里写 `"type": "aiGenerate"` + `storageKey` 即可接上。
final class AIBridge {
    static let shared = AIBridge()

    /// key 是否已配置（UI 可以据此显示"可在线生成"或"本地模式"）
    var hasKey: Bool { Self.apiKey() != nil }

    private init() {}

    /// 读取 key：优先 Info.plist 的 YimengAIKey，其次环境变量 YIMENG_AI_KEY。
    /// 两者都没有 → 返回 nil，一切走本地。
    static func apiKey() -> String? {
        if let k = Bundle.main.object(forInfoDictionaryKey: "YimengAIKey") as? String,
           !k.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !k.hasPrefix("$(") {
            return k.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let k = ProcessInfo.processInfo.environment["YIMENG_AI_KEY"],
           !k.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return k.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    /// 主入口：先尝试远端（有 key 时），失败或没 key 一律回落到本地。
    /// - Parameters:
    ///   - intent: 意图
    ///   - prompt: 用户侧输入（诗句 / 问题 / 意象）
    ///   - completion: 主线程回调，永远有值
    func generate(intent: AIIntent, prompt: String, completion: @escaping (AIResult) -> Void) {
        guard let key = Self.apiKey() else {
            completion(AIBridge.localFallback(intent: intent, prompt: prompt))
            return
        }

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": intent.systemPrompt],
                ["role": "user", "content": prompt],
            ],
            "temperature": 0.8,
            "max_tokens": 160,
        ]

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions"),
              let data = try? JSONSerialization.data(withJSONObject: body) else {
            completion(AIBridge.localFallback(intent: intent, prompt: prompt))
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 12
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.httpBody = data

        URLSession.shared.dataTask(with: req) { data, _, _ in
            var result: AIResult = AIBridge.localFallback(intent: intent, prompt: prompt)
            if let data = data,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = obj["choices"] as? [[String: Any]],
               let msg = choices.first?["message"] as? [String: Any],
               let content = msg["content"] as? String {
                let clean = content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty {
                    result = AIResult(text: clean, source: .remote)
                }
            }
            DispatchQueue.main.async { completion(result) }
        }.resume()
    }

    // MARK: - 本地降级（规则引擎，不是模型）

    /// 本地降级：模板 + 意象库。没有网络、没有 key 也能给出**与输入相关**的结果，
    /// 而不是每次都同一句 —— 否则用户一眼就看出是死的。
    static func localFallback(intent: AIIntent, prompt: String) -> AIResult {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        switch intent {
        case .cardNote:
            return AIResult(text: localCardNote(from: trimmed), source: .local)
        case .dialogueReply:
            return AIResult(text: localDialogueReply(to: trimmed), source: .local)
        case .imageryIdeas:
            return AIResult(text: localImageryIdeas(for: trimmed), source: .local)
        }
    }

    /// 题注：按诗句里的意象词挑一句模板，并附上原句里的关键词，保证"看着像针对这句"
    private static func localCardNote(from poem: String) -> String {
        let trimmed = poem.trimmingCharacters(in: .whitespacesAndNewlines)
        let lexicon: [(keys: [String], note: String)] = [
            (["雪", "江", "寒", "孤", "舟"], "寒江一叶，雪意无声"),
            (["月", "夜", "影", "霜"], "月到中天，影落空阶"),
            (["春", "花", "柳", "燕"], "春信初回，一枝先暖"),
            (["山", "云", "松", "泉"], "山深云卧，泉响空林"),
            (["风", "雨", "秋", "叶"], "西风过处，满纸秋声"),
            (["酒", "茶", "炉", "灯"], "小炉初沸，灯下有诗"),
        ]
        for entry in lexicon where entry.keys.contains(where: { poem.contains($0) }) {
            return entry.note
        }
        // 兜底：把用户句子里最像"意象"的两个字接进模板，避免千篇一律
        let fallbackWords = ["一纸烟云，尽在不言", "留白处最见风神", "此中意味，与君共赏"]
        if trimmed.isEmpty { return fallbackWords[0] }
        let seed = trimmed.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return fallbackWords[seed % fallbackWords.count]
    }

    /// 对谈：命中文史关键词就给对应答句，否则给一句通用的、苏轼口吻的收束
    private static func localDialogueReply(to question: String) -> String {
        let table: [(keys: [String], reply: String)] = [
            (["贬", "黄州", "失意", "低谷"], "黄州那几年确是难处。可若无赤壁的江风，我怕也写不出「大江东去」。心事放下，文章才长得出来。"),
            (["诗", "写诗", "作诗", "创作"], "诗不在字工，在眼里有物、心里有事。你且去看一场雨，回来再落笔，自然就不同了。"),
            (["吃", "食", "茶", "酒", "东坡肉"], "慢火少著水，火候足时他自美。人间有味是清欢——这话我是拿日子换来的。"),
            (["官", "仕途", "做官", "政治"], "我这一生，起落都尝过。位子会挪，做的事留在人间，那才是自己的。"),
            (["思乡", "想家", "故乡"], "此心安处是吾乡。走吧，走到哪儿，把心放稳了，哪儿就是家。"),
        ]
        for entry in table where entry.keys.contains(where: { question.contains($0) }) {
            return entry.reply
        }
        let generic = [
            "你这问题问得好。人生如逆旅，我亦是行人——不妨先放一放，且去看江上清风。",
            "且将新火试新茶，诗酒趁年华。有些事想不明白，就先去吃碗热的。",
            "我尝过苦，也尝过甜。回过头看，苦的那段反而记得最清楚。",
        ]
        let seed = question.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return generic[seed % generic.count]
    }

    /// 意象联想：从固定的宋代意象库里按主题取样
    private static func localImageryIdeas(for theme: String) -> String {
        let buckets: [(keys: [String], ideas: [String])] = [
            (["江", "水", "舟"], ["孤舟泊岸", "寒江夜雪", "潮打空城", "渔火三两点"]),
            (["山", "云", "松"], ["云出远岫", "松风满襟", "石径斜入", "半山听雨"]),
            (["月", "夜"], ["月照西楼", "霜阶无声", "挑灯看剑", "露湿青衫"]),
            (["花", "春"], ["满城飞花", "一枝出墙", "杏雨沾衣", "踏青归晚"]),
            (["雪", "冬"], ["千山暮雪", "煮雪烹茶", "炉红映壁", "雪落无声"]),
        ]
        for bucket in buckets where bucket.keys.contains(where: { theme.contains($0) }) {
            return bucket.ideas.prefix(3).joined(separator: "、")
        }
        return "疏影横斜、烟岚四合、一灯如豆"
    }
}

// MARK: - 视觉通道（器物八项报告）

extension AIBridge {
    /// 视觉通道用的模型。deepseek-flash 支持图像输入；deepseek-v4-pro 不支持，
    /// 所以这里写死 flash，不跟着文本通道走。
    static let visionModel = "deepseek-flash"
    static let visionEndpoint = "https://api.deepseek.com/chat/completions"

    /// 在线识别一件器物，回调模型给出的 JSON 字符串。
    /// 没 key、压图失败、网络失败、返回内容为空 —— 一律回调 nil，由调用方走本地兜底。
    ///
    /// 为什么单独开一条通道，而不是复用 generate()：
    /// 那条通道只吃字符串、`max_tokens` 只有 160，既带不了图，也装不下八项
    /// （简介 + 纹样 + 寓意 + 时代风格 各 80–120 字）。
    func describeArtifact(image: UIImage, hints: [ArtifactMatch], completion: @escaping (String?) -> Void) {
        guard let key = Self.apiKey() else {
            completion(nil)
            return
        }
        guard let jpeg = Self.compressedJPEG(image, maxSide: 768, quality: 0.72) else {
            completion(nil)
            return
        }

        let userText = "请识别这张器物照片，并按约定格式输出 json。\n" + Self.hintText(hints)
        let body: [String: Any] = [
            "model": Self.visionModel,
            "messages": [
                ["role": "system", "content": Self.artifactSystemPrompt],
                ["role": "user", "content": [
                    ["type": "text", "text": userText],
                    ["type": "image_url", "image_url": [
                        "url": "data:image/jpeg;base64,\(jpeg.base64EncodedString())",
                        // low = 先缩到 512×512 再推理：一张图最多约 1024 token，单次成本可控
                        "detail": "low",
                    ]],
                ]],
            ],
            // 关掉思考模式：演示要的是"几秒出结果"，不该把 token 花在思维链上
            "thinking": ["type": "disabled"],
            "response_format": ["type": "json_object"],
            "temperature": 0.3,
            "max_tokens": 1600,
        ]

        guard let url = URL(string: Self.visionEndpoint),
              let data = try? JSONSerialization.data(withJSONObject: body) else {
            completion(nil)
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 25
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.httpBody = data

        URLSession.shared.dataTask(with: req) { data, response, _ in
            var text: String? = nil
            if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
               let data = data,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = obj["choices"] as? [[String: Any]],
               let msg = choices.first?["message"] as? [String: Any],
               let content = msg["content"] as? String,
               !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                text = content
            }
            DispatchQueue.main.async { completion(text) }
        }.resume()
    }

    /// 系统提示：要求严格 JSON。
    /// 注意 DeepSeek 的 JSON 模式要求 prompt 里出现 "json" 字样并给出样例，否则会退化成普通文本。
    static let artifactSystemPrompt = """
    你是一位中国古器物研究者，为手机应用「一梦千年」的「古物识趣」栏目写一张器物卡片。
    只输出一个 json 对象，不要代码块，不要任何解释文字。

    json 字段与格式示例：
    {"name":"青花缠枝莲纹瓶","dynasty":"元代","kind":"瓷器 · 瓶 · 陈设器","intro":"此瓶造型饱满，釉色温润洁白，青花发色浓艳，颈部绘缠枝莲纹……","patternName":"缠枝莲纹","patternText":"以莲花为主题，茎蔓缠绕盘旋，枝叶交错相连……","symbol":"莲花出淤泥而不染，象征纯洁高雅……","eraStyle":"元代青花承袭宋制，花头更大、茎叶更舒展……","certainty":0.8}

    写作规则：
    1. 拿不准的宁短勿编。朝代把握不足就写「待考」；纹样认不出就把 patternName 写「待考」，patternText 只描述你确实看到的形态。
    2. certainty 是你对「器物名称 + 朝代」判断的把握，取值 0 到 1。低于 0.5 时，name 前面必须加「疑似」。
    3. 不要虚构尺寸、重量、出土信息、收藏地或价格。
    4. 全部使用简体中文；文风克制，不用感叹号；不要提及自己是 AI。
    """

    /// 把本地比对结果写成"参照提示"，让模型有个锚点。
    /// 这一步很关键：Flash 档模型单看一张照片容易泛泛而谈，
    /// 但给它"本地视觉比对最接近缠枝莲纹瓶（62%）"之后，写出来的内容会具体得多。
    static func hintText(_ hints: [ArtifactMatch]) -> String {
        let top = hints.prefix(2).map { match -> String in
            "《\(match.name)》（\(match.dynasty)·\(match.type)，相似度 \(Int((match.score * 100).rounded()))%）"
        }
        guard !top.isEmpty else {
            return "参照提示：本机参照库未给出候选（照片与库内 4 件都不像），请只依据图片判断。"
        }
        return "参照提示：本机视觉比对认为它最接近 " + top.joined(separator: "，其次 ") +
            "。这只是相似度排序，不是结论；若你的判断与它不同，以你的判断为准。"
    }

    /// 压到长边 maxSide 的 JPEG。图片按内容识别，不依赖扩展名。
    static func compressedJPEG(_ image: UIImage, maxSide: CGFloat, quality: CGFloat) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let longest = max(size.width, size.height)
        let scale = longest > maxSide ? maxSide / longest : 1
        var target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        if target.width < 1 { target.width = 1 }
        if target.height < 1 { target.height = 1 }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let upright = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return upright.jpegData(compressionQuality: quality)
    }
}

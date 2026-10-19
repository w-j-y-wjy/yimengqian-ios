//
//  ContentData.swift
//  静态内容数据 —— 对应安卓原型 app-project/src/data/*.ts
//  dynasties.ts / characters.ts / poems.ts / artifacts.ts / activities.ts / rewards.ts
//
//  图片引用约定（2026-10-19 修正）：
//  旧版本这里全部指向 "Reference/xxx.png"，而 Content/Reference/ 里 24/25 张文件名
//  与内容错配（例：Reference/splash.png 实际是汴京地图），等于每条数据都挂错了图。
//  现统一改指 "Screens/<id>.png" —— 那 25 张文件名与内容严格对应（MD5 已核）。
//  ⚠️ Screens/ 是整屏设计稿（852×1846），当条目缩略图用会显示整页；
//     Phase 4 需要从这里裁切出单件器物/单枚印章的小图。
//

import Foundation

enum ContentData {
    // MARK: - dynasties.ts（4 项，顺序一致）
    static let dynasties: [Dynasty] = [
        Dynasty(
            id: "tang",
            name: "盛唐",
            city: "长安",
            period: "618-907",
            description: "万国来朝，诗酒风流",
            unlocked: false,
            recommended: false,
            image: "Screens/dynasties.png",
            characters: ["libai"]
        ),
        Dynasty(
            id: "bei-song",
            name: "北宋",
            city: "汴京",
            period: "960-1127",
            description: "市井繁华，词韵风情",
            unlocked: true,
            recommended: true,
            image: "Screens/bianjing.png",
            characters: ["sushi"]
        ),
        Dynasty(
            id: "nan-song",
            name: "南宋",
            city: "临安",
            period: "1127-1279",
            description: "山水清雅，西湖烟雨",
            unlocked: false,
            recommended: false,
            image: "Screens/dynasties.png",
            characters: []
        ),
        Dynasty(
            id: "ming",
            name: "明代",
            city: "金陵",
            period: "1368-1644",
            description: "繁华锦绣，秦淮灯影",
            unlocked: false,
            recommended: false,
            image: "Screens/dynasties.png",
            characters: []
        ),
    ]

    // MARK: - characters.ts（2 项：苏轼、李白）
    static let characters: [Character] = [
        Character(
            id: "sushi",
            name: "苏轼",
            dynasty: "北宋",
            title: "东坡居士",
            tags: ["豁达", "旷达", "才情"],
            bio: "字子瞻，号东坡居士，眉州眉山人。文学家、书法家、画家、美食家。为人豁达旷达，词作风豪放一派，与黄庭坚并称“苏黄”，书法亦具其风格，与黄庭坚、米芾、蔡襄并称“宋四家”。",
            works: [
                Poem(
                    id: "nian-nu-jiao",
                    title: "念奴娇·赤壁怀古",
                    author: "苏轼",
                    dynasty: "北宋",
                    content: "大江东去，浪淘尽，千古风流人物。",
                    category: "豪放"
                ),
                Poem(
                    id: "ding-feng-bo",
                    title: "定风波",
                    author: "苏轼",
                    dynasty: "北宋",
                    content: "莫听穿林打叶声，何妨吟啸且徐行。",
                    category: "豁达"
                ),
                Poem(
                    id: "shui-diao",
                    title: "水调歌头",
                    author: "苏轼",
                    dynasty: "北宋",
                    content: "明月几时有？把酒问青天。",
                    category: "思念"
                ),
            ],
            footprints: [
                Footprint(city: "汴京", period: "仕途起始", description: "初入仕途，才华初露"),
                Footprint(city: "黄州", period: "被贬岁月", description: "人生低谷，文学巅峰"),
                Footprint(city: "杭州", period: "治理西湖", description: "筑堤治水，造福百姓"),
            ],
            letters: [
                Letter(
                    id: "letter-sushi-1",
                    from: "苏轼",
                    content: "人生如逆旅，我亦是行人。不必为一时得失而耿耿于怀，且将新火试新茶，诗酒趁年华。",
                    date: "元丰五年"
                ),
            ],
            image: "Screens/sushi.png"
        ),
        Character(
            id: "libai",
            name: "李白",
            dynasty: "盛唐",
            title: "诗仙",
            tags: ["浪漫", "豪放", "飘逸"],
            bio: "字太白，号青莲居士，唐代伟大的浪漫主义诗人，被后人誉为“诗仙”。",
            works: [],
            footprints: [],
            letters: [],
            // TODO(Phase 4)：李白暂无独立立绘，先留空表示"无素材"，
            // 不要拿苏轼的图占位（那会变成张冠李戴的可见错误）。
            image: ""
        ),
    ]

    // MARK: - poems.ts：jiangxueImagery（4 个意象）
    static let jiangxueImagery: [Imagery] = [
        Imagery(
            id: "gu-zhou",
            name: "孤舟",
            image: "Screens/jiangxue-imagery.png",
            meaning: "孤舟是全诗的核心意象，象征着诗人独立于尘世之外的高洁品格。渔船在风雪中，不畏严寒，展现了超然物外、悠然自得的隐逸情怀。",
            visual: "一叶扁舟，泊于江心，渔翁独坐，风雪漫天。舟身斑驳，似历尽沧桑。",
            emotion: "孤寂却不哀伤，清冷中透着坚毅与从容。",
            relatedPoems: [
                "孤舟蓑笠翁，独钓寒江雪。",
                "万径人踪灭，孤舟蓑笠翁。",
            ],
            keywords: ["孤独", "高洁", "清冷"]
        ),
        Imagery(
            id: "han-jiang",
            name: "寒江",
            image: "Screens/jiangxue-imagery.png",
            meaning: "寒江代表了严酷的自然环境，也象征着诗人所处的困境。江水冰冷，却仍有渔翁垂钓，暗示着面对困境时的从容不迫。",
            visual: "江水如墨，寒气逼人，两岸寂寥，唯余飞雪。",
            emotion: "冷寂、深沉，却蕴含着不屈的力量。",
            relatedPoems: [
                "孤舟蓑笠翁，独钓寒江雪。",
                "千山鸟飞绝，万径人踪灭。",
            ],
            keywords: ["严酷", "困境", "坚毅"]
        ),
        Imagery(
            id: "suo-li-weng",
            name: "蓑笠翁",
            image: "Screens/jiangxue-imagery.png",
            meaning: "蓑笠翁是渔翁的形象，代表着一种超然物外的生活态度。他不畏风雪，独自垂钓，象征着诗人对自由与独立的追求。",
            visual: "老翁披蓑戴笠，手持钓竿，端坐船头，神态安详。",
            emotion: "淡泊、宁静，与世无争的从容。",
            relatedPoems: [
                "孤舟蓑笠翁，独钓寒江雪。",
            ],
            keywords: ["隐逸", "淡泊", "从容"]
        ),
        Imagery(
            id: "fei-xue",
            name: "飞雪",
            image: "Screens/jiangxue-imagery.png",
            meaning: "飞雪既是自然景象的描写，也烘托出一种空灵、寂静的意境。雪花纷飞，覆盖了世间一切喧嚣，营造出纯净的世界。",
            visual: "漫天飞雪，纷纷扬扬，天地一片苍茫，万籁俱寂。",
            emotion: "纯净、空灵，洗涤心灵的宁静。",
            relatedPoems: [
                "千山鸟飞绝，万径人踪灭。",
            ],
            keywords: ["纯净", "空灵", "寂静"]
        ),
    ]

    // MARK: - poems.ts（4 首：江雪/鸟鸣涧/静夜思/春日）
    static let poems: [Poem] = [
        Poem(
            id: "jiangxue",
            title: "江雪",
            author: "柳宗元",
            dynasty: "唐",
            content: "千山鸟飞绝，\n万径人踪灭。\n孤舟蓑笠翁，\n独钓寒江雪。",
            category: "山水",
            analysis: PoemAnalysis(
                translation: "千山万岭看不到飞鸟的身影，条条小路上也不见行人的足迹。江面上一叶孤舟，渔翁身披蓑衣、头戴斗笠，在风雪纷飞的寒江中独自垂钓。",
                background: "此诗作于柳宗元被贬永州期间。他政治上遭受打击，内心孤独苦闷。诗人借寒江独钓的渔翁形象，抒发自己清高孤傲、不与世俗同流合污的品格。",
                features: "全诗仅二十字，却勾勒出一幅寒江独钓图。诗人用“绝”“灭”二字将天地间的喧嚣彻底抹去，以“孤”“独”二字突显渔翁的遗世独立。短短数语，动静结合，营造出一种冷峻空灵的艺术境界。"
            ),
            imagery: [
                Imagery(
                    id: "gu-zhou",
                    name: "孤舟",
                    image: "Screens/jiangxue-imagery.png",
                    meaning: "孤舟是全诗的核心意象，象征着诗人独立于尘世之外的高洁品格。渔船在风雪中，不畏严寒，展现了超然物外、悠然自得的隐逸情怀。",
                    visual: "一叶扁舟，泊于江心，渔翁独坐，风雪漫天。舟身斑驳，似历尽沧桑。",
                    emotion: "孤寂却不哀伤，清冷中透着坚毅与从容。",
                    relatedPoems: [
                        "孤舟蓑笠翁，独钓寒江雪。",
                        "万径人踪灭，孤舟蓑笠翁。",
                    ],
                    keywords: ["孤独", "高洁", "清冷"]
                ),
                Imagery(
                    id: "han-jiang",
                    name: "寒江",
                    image: "Screens/jiangxue-imagery.png",
                    meaning: "寒江代表了严酷的自然环境，也象征着诗人所处的困境。江水冰冷，却仍有渔翁垂钓，暗示着面对困境时的从容不迫。",
                    visual: "江水如墨，寒气逼人，两岸寂寥，唯余飞雪。",
                    emotion: "冷寂、深沉，却蕴含着不屈的力量。",
                    relatedPoems: [
                        "孤舟蓑笠翁，独钓寒江雪。",
                        "千山鸟飞绝，万径人踪灭。",
                    ],
                    keywords: ["严酷", "困境", "坚毅"]
                ),
                Imagery(
                    id: "suo-li-weng",
                    name: "蓑笠翁",
                    image: "Screens/jiangxue-imagery.png",
                    meaning: "蓑笠翁是渔翁的形象，代表着一种超然物外的生活态度。他不畏风雪，独自垂钓，象征着诗人对自由与独立的追求。",
                    visual: "老翁披蓑戴笠，手持钓竿，端坐船头，神态安详。",
                    emotion: "淡泊、宁静，与世无争的从容。",
                    relatedPoems: [
                        "孤舟蓑笠翁，独钓寒江雪。",
                    ],
                    keywords: ["隐逸", "淡泊", "从容"]
                ),
                Imagery(
                    id: "fei-xue",
                    name: "飞雪",
                    image: "Screens/jiangxue-imagery.png",
                    meaning: "飞雪既是自然景象的描写，也烘托出一种空灵、寂静的意境。雪花纷飞，覆盖了世间一切喧嚣，营造出纯净的世界。",
                    visual: "漫天飞雪，纷纷扬扬，天地一片苍茫，万籁俱寂。",
                    emotion: "纯净、空灵，洗涤心灵的宁静。",
                    relatedPoems: [
                        "千山鸟飞绝，万径人踪灭。",
                    ],
                    keywords: ["纯净", "空灵", "寂静"]
                ),
            ]
        ),
        Poem(
            id: "niao-ming-jian",
            title: "鸟鸣涧",
            author: "王维",
            dynasty: "唐",
            content: "人闲桂花落，\n夜静春山空。\n月出惊山鸟，\n时鸣春涧中。",
            category: "山水"
        ),
        Poem(
            id: "jing-ye-si",
            title: "静夜思",
            author: "李白",
            dynasty: "唐",
            content: "床前明月光，\n疑是地上霜。\n举头望明月，\n低头思故乡。",
            category: "月夜"
        ),
        Poem(
            id: "chun-ri",
            title: "春日",
            author: "朱熹",
            dynasty: "宋",
            content: "胜日寻芳泗水滨，\n无边光景一时新。\n等闲识得东风面，\n万紫千红总是春。",
            category: "四季"
        ),
    ]

    // MARK: - poems.ts：poetryCategories（icon 在 TS 源中均为空串 ""）
    static let poetryCategories: [PoetryCategory] = [
        PoetryCategory(id: "all", name: "全部", icon: ""),
        PoetryCategory(id: "landscape", name: "山水", icon: ""),
        PoetryCategory(id: "seasons", name: "四季", icon: ""),
        PoetryCategory(id: "moon", name: "月夜", icon: ""),
        PoetryCategory(id: "sorrow", name: "离愁", icon: ""),
        PoetryCategory(id: "frontier", name: "边塞", icon: ""),
    ]

    // MARK: - artifacts.ts（4 件）
    static let artifacts: [Artifact] = [
        Artifact(
            id: "qinghua-ping",
            name: "青花缠枝莲纹瓶",
            dynasty: "元代",
            type: "瓷器",
            shape: "瓶",
            pattern: "缠枝莲纹",
            usage: "陈设器",
            description: "此瓶造型饱满，釉色温润洁白，青花发色浓艳。颈部绘缠枝莲纹，腹部饰饱满盛开的莲花，枝叶交错缠绕，构图繁密而有序。整体纹饰布局与绘画技法俱佳，体现了元代瓷器艺术的最高水平。",
            image: "Screens/artifact-result.png",
            patternDetail: PatternDetail(
                name: "缠枝莲纹",
                image: "Screens/artifact-pattern.png",
                structure: "缠枝莲纹以莲花为主题，茎蔓缠绕盘旋，枝叶交错相连。纹样呈S形或波状连续延伸，花头饱满，叶片翻转自然，整体构图既繁密又富有变化。在元代青花中，缠枝莲纹是最为常见的装饰题材之一。",
                symbolism: "莲花出淤泥而不染，象征纯洁高雅、品格高尚。缠枝莲纹寓意连绵不断、生生不息，寄托了人们对美好生活的向往。在佛教文化中，莲花更是神圣之花，代表着清净无染。",
                eraStyle: "元代青花瓷器的缠枝莲纹承袭宋代传统，但在构图与绘画技法上有了新的发展。元代缠枝莲纹花头更大、茎叶更加舒展，青花色调浓艳，具有鲜明的时代特征。与明清时期的缠枝莲纹相比，元代风格更为粗犷豪放。",
                elements: [
                    PatternElement(name: "莲瓣", description: "花瓣饱满圆润，层次分明，多为仰莲或覆莲形式", image: "Screens/artifact-pattern.png"),
                    PatternElement(name: "卷草", description: "茎蔓卷曲缠绕，连接各花头，使纹样连绵不断", image: "Screens/artifact-pattern.png"),
                    PatternElement(name: "边饰", description: "以回纹、如意云纹等几何纹样作为辅助装饰", image: "Screens/artifact-pattern.png"),
                ]
            )
        ),
        Artifact(
            id: "tong-jing",
            name: "海兽葡萄纹铜镜",
            dynasty: "唐代",
            type: "铜器",
            shape: "镜",
            pattern: "海兽葡萄纹",
            usage: "照容",
            description: "唐代铜镜中的精品，镜面光亮，背面饰海兽葡萄纹，工艺精湛。",
            image: "Screens/artifact-home.png"
        ),
        Artifact(
            id: "xiang-lu",
            name: "缠枝莲纹铜香炉",
            dynasty: "明代",
            type: "铜器",
            shape: "炉",
            pattern: "缠枝莲纹",
            usage: "焚香",
            description: "明代宣德炉风格，造型端庄，铜质精良。",
            image: "Screens/artifact-home.png"
        ),
        Artifact(
            id: "yu-pei",
            name: "白玉双龙佩",
            dynasty: "宋代",
            type: "玉器",
            shape: "佩",
            pattern: "双龙纹",
            usage: "佩饰",
            description: "和田白玉质地，雕工精细，双龙相对，寓意吉祥。",
            image: "Screens/artifact-home.png"
        ),
    ]

    // MARK: - activities.ts：activities（5 项）
    static let activities: [Activity] = [
        Activity(id: "feihualing", name: "飞花令·春", description: "以诗会友，飞花拾春", type: "quiz", unlocked: true, participants: 12345),
        Activity(id: "dengmi", name: "猜灯谜", description: "打开灯谜，谜底顿生", type: "puzzle", unlocked: true, participants: 12345),
        Activity(id: "hua-zhao", name: "古画找物", description: "画中寻物，妙趣在里", type: "find", unlocked: true, participants: 8967),
        Activity(id: "wenyang", name: "纹样配对", description: "纹艺之美，百文百相", type: "match", unlocked: true, participants: 5456),
        Activity(id: "qigu", name: "器物辨识", description: "识器明理，见器如著", type: "identify", unlocked: true, participants: 5128),
    ]

    // MARK: - activities.ts：feihualingQuestions（3 题）
    static let feihualingQuestions: [FeihualingQuestion] = [
        FeihualingQuestion(
            id: 1,
            round: 1,
            character: "春",
            options: [
                "春眠不觉晓，处处闻啼鸟。",
                "无边落木萧萧下，不尽长江滚滚来。",
                "春风得意马蹄疾，一日看尽长安花。",
                "大漠孤烟直，长河落日圆。",
            ],
            correctIndex: 0
        ),
        FeihualingQuestion(
            id: 2,
            round: 2,
            character: "春",
            options: [
                "好雨知时节，当春乃发生。",
                "千山鸟飞绝，万径人踪灭。",
                "举头望明月，低头思故乡。",
                "空山新雨后，天气晚来秋。",
            ],
            correctIndex: 0
        ),
        FeihualingQuestion(
            id: 3,
            round: 3,
            character: "春",
            options: [
                "人面不知何处去，桃花依旧笑春风。",
                "两岸猿声啼不住，轻舟已过万重山。",
                "飞流直下三千尺，疑是银河落九天。",
                "窗含西岭千秋雪，门泊东吴万里船。",
            ],
            correctIndex: 0
        ),
    ]

    // MARK: - activities.ts：stamps（4 枚，obtained 均 false，date 均 nil）
    static let stamps: [Stamp] = [
        Stamp(id: "chun-ri-ya-shi", name: "春日雅士", description: "参与飞花令·春，以诗会友", image: "Screens/stamp-reward.png", obtained: false),
        Stamp(id: "dong-po-zhi-yin", name: "东坡知音", description: "完成茶坊对谈，与苏轼畅谈人生", image: "Screens/stamp-reward.png", obtained: false),
        Stamp(id: "qing-hui-shan-shui", name: "清辉山水", description: "赏读山水诗词，感受自然之美", image: "Screens/stamp-reward.png", obtained: false),
        Stamp(id: "gu-wu-yan-ji", name: "古物研习", description: "识别三件以上传物", image: "Screens/stamp-reward.png", obtained: false),
    ]

    // MARK: - rewards.ts：bianjingLocations（6 处）
    static let bianjingLocations: [CityLocation] = [
        CityLocation(id: "shuyuan", name: "书院", x: 25.0, y: 18.0, unlocked: false, description: "藏书万卷，文人雅集之地"),
        CityLocation(id: "teahouse", name: "茶坊", x: 72.0, y: 15.0, unlocked: true, description: "品茶论道，东坡旧识茶坊"),
        CityLocation(id: "jiusi", name: "酒肆", x: 15.0, y: 45.0, unlocked: false, description: "美酒飘香，诗兴大发"),
        CityLocation(id: "yaofang", name: "药坊", x: 45.0, y: 52.0, unlocked: false, description: "悬壶济世，药香四溢"),
        CityLocation(id: "washe", name: "瓦舍", x: 75.0, y: 42.0, unlocked: false, description: "百戏杂耍，市井繁华"),
        CityLocation(id: "matou", name: "码头", x: 82.0, y: 68.0, unlocked: false, description: "商船云集，连接南北"),
    ]

    // MARK: - rewards.ts：dailyPoems（5 首）
    static let dailyPoems: [DailyPoem] = [
        DailyPoem(text: "人闲桂花落，夜静春山空。", author: "王维", title: "鸟鸣涧"),
        DailyPoem(text: "千山鸟飞绝，万径人踪灭。", author: "柳宗元", title: "江雪"),
        DailyPoem(text: "明月几时有？把酒问青天。", author: "苏轼", title: "水调歌头"),
        DailyPoem(text: "床前明月光，疑是地上霜。", author: "李白", title: "静夜思"),
        DailyPoem(text: "好雨知时节，当春乃发生。", author: "杜甫", title: "春夜喜雨"),
    ]

    // MARK: - rewards.ts：dialogueTopics（3 组，speaker 均为 .character）
    static let dialogueTopics: [DialogueTopic] = [
        DialogueTopic(
            id: "life",
            question: "你如何面对人生起伏？",
            responses: [
                DialogueLine(id: "d1", speaker: .character, text: "人生如逆旅，我亦是行人。"),
                DialogueLine(id: "d2", speaker: .character, text: "起落本无常，且喜杯中有清欢。"),
                DialogueLine(id: "d3", speaker: .character, text: "不以物喜，不以己悲。风雨来时，便是修心时。"),
            ]
        ),
        DialogueTopic(
            id: "huangzhou",
            question: "黄州给你带来了什么？",
            responses: [
                DialogueLine(id: "d4", speaker: .character, text: "黄州于我，虽是贬谪之地，却是文学重生之所。"),
                DialogueLine(id: "d5", speaker: .character, text: "在黄州，我写下了《赤壁赋》《念奴娇》，那是我一生中最珍贵的文字。"),
                DialogueLine(id: "d6", speaker: .character, text: "黄州的山水，黄州的月夜，都成了我笔下的永恒。"),
            ]
        ),
        DialogueTopic(
            id: "words",
            question: "你最想告诉后人的一句话？",
            responses: [
                DialogueLine(id: "d7", speaker: .character, text: "竹杖芒鞋轻胜马，谁怕？一蓑烟雨任平生。"),
                DialogueLine(id: "d8", speaker: .character, text: "人间有味是清欢。"),
                DialogueLine(id: "d9", speaker: .character, text: "且将新火试新茶，诗酒趁年华。"),
            ]
        ),
    ]
}

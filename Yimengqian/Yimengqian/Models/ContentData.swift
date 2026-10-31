//
//  ContentData.swift
//  静态内容数据 —— 对应安卓原型 app-project/src/data/*.ts
//  dynasties.ts / characters.ts / poems.ts / artifacts.ts / activities.ts / rewards.ts
//
//  图片引用约定（2026-10-20 更新）：
//  - 条目小图统一指向 "ArtApp/<类型>-<实体id>.jpg|png"，即 Content/ArtApp/。
//    这批是 26 张独立配图 + 4 枚印章，按实体一一对应，不再拿整屏设计稿当缩略图。
//  - 整屏设计稿仍保留在 "Screens/<屏id>.png"（北宋朝代卡仍用 bianjing 整屏，因为没单独出图）。
//  - Content/Art/ 存放 AI 生成的原始大图（80 MB，体积大，不进包、不进 git）；
//    Content/ArtApp/ 是压缩后的打包用版本（约 9 MB），只提交这一份。
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
            image: "ArtApp/dynasty-tang.jpg",
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
            image: "ArtApp/dynasty-nan-song.jpg",
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
            image: "ArtApp/dynasty-ming.jpg",
            characters: []
        ),
        // 黄州：苏轼谪居地，设计稿「苏轼足迹」里有它，但内容库原本没有这个城市。
        // 没有专属配图 → image 留空（不借别的朝代图，宁可不显示 hero）。
        Dynasty(
            id: "huang-zhou",
            name: "黄州",
            city: "黄州",
            period: "1080-1084",
            description: "苏轼谪居黄州四年，在此写下《赤壁赋》《念奴娇·赤壁怀古》与《寒食帖》",
            unlocked: true,
            recommended: false,
            characters: ["sushi"]
        ),
        // 书院：领奖页「下一段旅程」指向它，但原内容库没有这座城市。
        // 白鹿洞书院为四大书院之一，作为宋代书院讲学的代表地点是史实；
        // 配图缺失 → image 留空，不借别的城池图。
        Dynasty(
            id: "shu-yuan",
            name: "书院",
            city: "白鹿洞",
            period: "宋代",
            description: "宋代书院讲学之所，藏书、讲经、祭祀并重；白鹿洞书院为四大书院之一",
            unlocked: true,
            recommended: false,
            characters: ["wangwei"]
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
            image: "ArtApp/character-sushi.jpg"
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
            image: "ArtApp/character-libai.jpg"
        ),
        Character(
            id: "liqingzhao",
            name: "李清照",
            dynasty: "南宋",
            title: "易安居士",
            tags: ["婉约", "清冷", "才情"],
            bio: "号易安居士，齐州章丘人，宋代女词人，婉约词派代表。前期词风清丽婉转，多写闺阁闲愁与自然风物；南渡之后词风转为沉郁，家国之痛融入笔端，后人誉为“千古第一才女”。",
            works: [
                Poem(
                    id: "ru-meng-ling",
                    title: "如梦令",
                    author: "李清照",
                    dynasty: "南宋",
                    content: "昨夜雨疏风骤，浓睡不消残酒。",
                    category: "婉约"
                ),
                Poem(
                    id: "sheng-sheng-man",
                    title: "声声慢",
                    author: "李清照",
                    dynasty: "南宋",
                    content: "寻寻觅觅，冷冷清清，凄凄惨惨戚戚。",
                    category: "婉约"
                ),
            ],
            footprints: [
                Footprint(city: "汴京", period: "少女时代", description: "生长于书香门第，少年即有诗名"),
                Footprint(city: "青州", period: "屏居岁月", description: "与夫赵明诚屏居青州，共事金石校勘"),
                Footprint(city: "临安", period: "南渡之后", description: "南渡流离，词风转沉郁悲凉"),
            ],
            letters: [
                Letter(
                    id: "letter-liqingzhao-1",
                    from: "李清照",
                    content: "生当作人杰，死亦为鬼雄。治学当以金石为证，不随流俗而改其志。",
                    date: "绍兴二年"
                ),
            ],
            image: "ArtApp/character-liqingzhao.jpg"
        ),
        // 王维：梦册「相逢古人」第三张卡画的是他，但内容库原本只有苏轼/李白/李清照。
        // 没有专属画像 → image 留空，详情页不显示 hero，绝不借别人的肖像。
        Character(
            id: "wangwei",
            name: "王维",
            dynasty: "唐",
            title: "诗佛",
            tags: ["山水", "禅意", "诗画"],
            bio: "王维，字摩诘，盛唐诗人、画家，官至尚书右丞，世称王右丞。晚年隐居辋川，山水田园诗清幽空灵；苏轼评其「诗中有画，画中有诗」。",
            works: [
                Poem(
                    id: "niao-ming-jian",
                    title: "鸟鸣涧",
                    author: "王维",
                    dynasty: "唐",
                    content: "人闲桂花落，\n夜静春山空。\n月出惊山鸟，\n时鸣春涧中。",
                    category: "山水"
                )
            ],
            footprints: [
                Footprint(city: "长安", period: "盛唐", description: "少年成名，以诗画名动京师"),
                Footprint(city: "辋川", period: "晚年", description: "隐居辋川别业，写下《辋川集》"),
            ],
            letters: []
        ),
        // 2026-10-31 加厚度：人物 4 → 8。新增四位都能在诗词页读到代表作，
        // 没有专属画像的 image 留空（不借他人肖像，同王维的规矩）。
        Character(
            id: "dufu",
            name: "杜甫",
            dynasty: "唐",
            title: "诗圣",
            tags: ["沉郁", "写实", "家国"],
            bio: "杜甫，字子美，自号少陵野老。安史之乱中流寓西南，诗多写民生疾苦与家国之思，格律精严、沉郁顿挫，后世尊为「诗圣」，其诗被称为「诗史」。",
            works: [
                Poem(
                    id: "chun-wang",
                    title: "春望",
                    author: "杜甫",
                    dynasty: "唐",
                    content: "国破山河在，\n城春草木深。\n感时花溅泪，\n恨别鸟惊心。\n烽火连三月，\n家书抵万金。\n白头搔更短，\n浑欲不胜簪。",
                    category: "离愁",
                    analysis: PoemAnalysis(
                        translation: "国都已破，山河依旧；春日的长安草木深茂。感伤时局，见花也落泪；怅恨别离，闻鸟亦惊心。",
                        background: "至德二载春，杜甫被困长安，目睹战乱后的都城，写下此诗。",
                        features: "以「山河在」与「草木深」对写：物是人非。末联以搔头白发收束，把家国之痛落到一具衰老的身体上。"
                    )
                )
            ],
            footprints: [
                Footprint(city: "长安", period: "天宝", description: "困守长安，写下《兵车行》"),
                Footprint(city: "成都", period: "上元", description: "营草堂于浣花溪畔，诗风稍得安顿"),
            ],
            letters: []
        ),
        Character(
            id: "baijuyi",
            name: "白居易",
            dynasty: "唐",
            title: "诗魔",
            tags: ["平易", "讽喻", "长庆体"],
            bio: "白居易，字乐天，号香山居士。主张「文章合为时而著，歌诗合为事而作」，诗风平易晓畅，老妪能解；晚年居洛阳，与刘禹锡唱和，世称「刘白」。",
            works: [
                Poem(
                    id: "yi-jiang-nan",
                    title: "忆江南",
                    author: "白居易",
                    dynasty: "唐",
                    content: "江南好，\n风景旧曾谙。\n日出江花红胜火，\n春来江水绿如蓝。\n能不忆江南？",
                    category: "山水"
                )
            ],
            footprints: [
                Footprint(city: "杭州", period: "长庆", description: "任杭州刺史，筑堤蓄水，后人称白堤"),
                Footprint(city: "洛阳", period: "晚年", description: "退居香山，与龙门山水为伴"),
            ],
            letters: []
        ),
        Character(
            id: "xinqiji",
            name: "辛弃疾",
            dynasty: "宋",
            title: "词中之龙",
            tags: ["豪放", "爱国", "稼轩"],
            bio: "辛弃疾，字幼安，号稼轩。生于金人占领的济南，二十二岁率众南归，一生力主抗金而不得用，词风雄浑激越，与苏轼并称「苏辛」。",
            works: [
                Poem(
                    id: "chou-nu-er",
                    title: "丑奴儿·书博山道中壁",
                    author: "辛弃疾",
                    dynasty: "宋",
                    content: "少年不识愁滋味，\n爱上层楼。\n爱上层楼，\n为赋新词强说愁。\n而今识尽愁滋味，\n欲说还休。\n欲说还休，\n却道天凉好个秋。",
                    category: "离愁",
                    analysis: PoemAnalysis(
                        translation: "年少时不懂愁，偏爱登楼，为写新词硬说愁。如今尝尽愁味，想说又止，只道一句「天凉好个秋」。",
                        background: "辛弃疾罢官闲居带湖时，途经博山道中，题于壁上。",
                        features: "上下片以「爱上层楼」「欲说还休」复沓对照，少年与而今两副心境；结句以闲语收浓愁，愈淡愈重。"
                    )
                )
            ],
            footprints: [
                Footprint(city: "济南", period: "绍兴", description: "起兵抗金，率五十骑擒叛将"),
                Footprint(city: "上饶", period: "闲居", description: "罢官居带湖，写下大量田园与抒怀词"),
            ],
            letters: []
        ),
        Character(
            id: "luyou",
            name: "陆游",
            dynasty: "宋",
            title: "放翁",
            tags: ["爱国", "田园", "剑南"],
            bio: "陆游，字务观，号放翁。一生力主北伐，屡遭排挤；诗作近万首，既有金戈铁马的慷慨，也有村居烟火的亲切，是南宋诗坛的巨擘。",
            works: [
                Poem(
                    id: "you-shan-xi-cun",
                    title: "游山西村",
                    author: "陆游",
                    dynasty: "宋",
                    content: "莫笑农家腊酒浑，\n丰年留客足鸡豚。\n山重水复疑无路，\n柳暗花明又一村。",
                    category: "山水",
                    analysis: PoemAnalysis(
                        translation: "别嫌农家腊酒浑浊，丰年待客有鸡有肉。山重水复以为无路，柳暗花明处又见一村。",
                        background: "乾道三年陆游罢官闲居山阴，游山西村时所作。",
                        features: "「山重水复」「柳暗花明」本是写行路，后世移作处境的写照，是流传最广的一联。"
                    )
                )
            ],
            footprints: [
                Footprint(city: "山阴", period: "乾道", description: "罢官归里，村居期间写下大量田园诗"),
                Footprint(city: "南郑", period: "乾道", description: "入四川宣抚使幕，亲历前线军旅"),
            ],
            letters: []
        ),
    ]

    // MARK: - poems.ts：jiangxueImagery（4 个意象）
    static let jiangxueImagery: [Imagery] = [
        Imagery(
            id: "gu-zhou",
            name: "孤舟",
            image: "ArtApp/imagery-gu-zhou.jpg",
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
            image: "ArtApp/imagery-han-jiang.jpg",
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
            image: "ArtApp/imagery-suo-li-weng.jpg",
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
            image: "ArtApp/imagery-fei-xue.jpg",
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
                    image: "ArtApp/imagery-gu-zhou.jpg",
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
                    image: "ArtApp/imagery-han-jiang.jpg",
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
                    image: "ArtApp/imagery-suo-li-weng.jpg",
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
                    image: "ArtApp/imagery-fei-xue.jpg",
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
            category: "山水",
            image: "ArtApp/poem-niao-ming-jian.jpg"
        ),
        Poem(
            id: "jing-ye-si",
            title: "静夜思",
            author: "李白",
            dynasty: "唐",
            content: "床前明月光，\n疑是地上霜。\n举头望明月，\n低头思故乡。",
            category: "月夜",
            image: "ArtApp/poem-jing-ye-si.jpg"
        ),
        Poem(
            id: "chun-ri",
            title: "春日",
            author: "朱熹",
            dynasty: "宋",
            content: "胜日寻芳泗水滨，\n无边光景一时新。\n等闲识得东风面，\n万紫千红总是春。",
            category: "四季",
            image: "ArtApp/poem-chun-ri.jpg"
        ),
        // 收藏页「忆江南」卡片原本只弹「诗词详情将在后续开放」——内容库里补上这首诗（白居易《忆江南》其一）
        Poem(
            id: "yi-jiang-nan",
            title: "忆江南",
            author: "白居易",
            dynasty: "唐",
            content: "江南好，\n风景旧曾谙。\n日出江花红胜火，\n春来江水绿如蓝。\n能不忆江南？",
            category: "山水"
        ),
        // 2026-10-31 加厚度：诗库 16 → 28。选的都是能背、能考的常见篇目，
        // 每首配「译解 / 创作背景 / 艺术特色」三段短注（各 40–60 字），不写没有来源的奇闻。
        Poem(
            id: "deng-guan-que-lou",
            title: "登鹳雀楼",
            author: "王之涣",
            dynasty: "唐",
            content: "白日依山尽，\n黄河入海流。\n欲穷千里目，\n更上一层楼。",
            category: "山水",
            analysis: PoemAnalysis(
                translation: "太阳沿山脊沉落，黄河向海奔流。想把千里景色看尽，就再登上一层楼。",
                background: "鹳雀楼在蒲州（今山西永济），唐代为登临胜地。诗人登楼远眺，写下这首五绝。",
                features: "前两句写景，一句向西（落日）、一句向东（黄河），空间开阔；后两句由景入理，说理却不枯。"
            )
        ),
        Poem(
            id: "wang-lu-shan-pu-bu",
            title: "望庐山瀑布",
            author: "李白",
            dynasty: "唐",
            content: "日照香炉生紫烟，\n遥看瀑布挂前川。\n飞流直下三千尺，\n疑是银河落九天。",
            category: "山水",
            analysis: PoemAnalysis(
                translation: "日光照着香炉峰，升起紫色云烟；远看瀑布像挂在山前的白练。飞泻三千尺，让人疑心是银河倾落。",
                background: "李白漫游庐山时所作，写香炉峰瀑布的雄奇。",
                features: "「挂」字把动态的瀑布写成静物；末句以银河作比，夸张而不失真切，是典型的浪漫笔法。"
            )
        ),
        Poem(
            id: "zao-fa-bai-di-cheng",
            title: "早发白帝城",
            author: "李白",
            dynasty: "唐",
            content: "朝辞白帝彩云间，\n千里江陵一日还。\n两岸猿声啼不住，\n轻舟已过万重山。",
            category: "山水",
            analysis: PoemAnalysis(
                translation: "清晨在彩云间告别白帝城，千里外的江陵一天就到。两岸猿声还在耳边，轻舟已驶过万重山。",
                background: "乾元二年李白流放夜郎，行至白帝城遇赦，旋即东下，写下此诗。",
                features: "全诗写「快」：空间快、舟行快、情绪也快；猿声未歇而山已过尽，把遇赦的轻快写得不着痕迹。"
            )
        ),
        Poem(
            id: "feng-qiao-ye-bo",
            title: "枫桥夜泊",
            author: "张继",
            dynasty: "唐",
            content: "月落乌啼霜满天，\n江枫渔火对愁眠。\n姑苏城外寒山寺，\n夜半钟声到客船。",
            category: "离愁",
            analysis: PoemAnalysis(
                translation: "月落乌啼，寒霜满天；江边枫树与渔火相对，愁人难眠。姑苏城外寒山寺，半夜钟声传到客船。",
                background: "张继落第后途经苏州，夜泊枫桥，羁旅之愁与秋夜之景相合。",
                features: "月落、乌啼、霜天、渔火、钟声层层叠加，最后以「钟声到客船」收束，愁绪有了声音。"
            )
        ),
        Poem(
            id: "shan-ju-qiu-ming",
            title: "山居秋暝",
            author: "王维",
            dynasty: "唐",
            content: "空山新雨后，\n天气晚来秋。\n明月松间照，\n清泉石上流。\n竹喧归浣女，\n莲动下渔舟。\n随意春芳歇，\n王孙自可留。",
            category: "山水",
            analysis: PoemAnalysis(
                translation: "新雨过后空山清寂，傍晚已有秋意。明月照进松林，清泉在石上流淌。竹林喧响是浣女归来，莲叶摇动是渔舟顺流。",
                background: "王维晚年隐居辋川，这首诗写山居秋日傍晚的所见所闻。",
                features: "「诗中有画」的典型：先静（月照、泉流），后动（竹喧、莲动），把人的活动藏进景物里。"
            )
        ),
        Poem(
            id: "lu-zhai",
            title: "鹿柴",
            author: "王维",
            dynasty: "唐",
            content: "空山不见人，\n但闻人语响。\n返景入深林，\n复照青苔上。",
            category: "山水",
            analysis: PoemAnalysis(
                translation: "空山里看不见人影，只听见人说话；夕阳返照进深林，又落在青苔上。",
                background: "辋川别业二十景之一「鹿柴」，写山中一处幽静林谷。",
                features: "以「不见人」与「闻人语」对写，愈显空寂；再由声转光，用一缕返照收住，静得能听见光落。"
            )
        ),
        Poem(
            id: "yong-liu",
            title: "咏柳",
            author: "贺知章",
            dynasty: "唐",
            content: "碧玉妆成一树高，\n万条垂下绿丝绦。\n不知细叶谁裁出，\n二月春风似剪刀。",
            category: "四季",
            analysis: PoemAnalysis(
                translation: "柳树像碧玉装成，万千枝条垂下如绿丝带。不知细叶是谁裁出——原来二月春风就是剪刀。",
                background: "贺知章晚年归乡时所作，写早春新柳。",
                features: "通篇用比：先以碧玉、丝绦写柳，再把春风比作剪刀，一问一答，把无形的风写成了手艺。"
            )
        ),
        Poem(
            id: "chun-xiao",
            title: "春晓",
            author: "孟浩然",
            dynasty: "唐",
            content: "春眠不觉晓，\n处处闻啼鸟。\n夜来风雨声，\n花落知多少。",
            category: "四季",
            analysis: PoemAnalysis(
                translation: "春夜好眠，不知天已亮，到处听见鸟啼。想起昨夜风雨声，不知道花落了多少。",
                background: "孟浩然隐居鹿门山时所作，写春日清晨将醒未醒的一刻。",
                features: "全诗不写景，只写听觉与猜想：鸟声、风雨声、落花数，二十字里藏着整个春天的流逝。"
            )
        ),
        Poem(
            id: "yu-ge-zi",
            title: "渔歌子",
            author: "张志和",
            dynasty: "唐",
            content: "西塞山前白鹭飞，\n桃花流水鳜鱼肥。\n青箬笠，\n绿蓑衣，\n斜风细雨不须归。",
            category: "山水",
            analysis: PoemAnalysis(
                translation: "西塞山前白鹭飞，桃花映水、鳜鱼正肥。戴青箬笠、披绿蓑衣，斜风细雨里也不必回去。",
                background: "张志和辞官后隐居江湖，自号烟波钓徒，这首词写渔隐之乐。",
                features: "色彩极鲜明：白鹭、桃花、青笠、绿蓑铺在水上；末句「不须归」写尽自在。"
            )
        ),
        Poem(
            id: "ti-xi-lin-bi",
            title: "题西林壁",
            author: "苏轼",
            dynasty: "宋",
            content: "横看成岭侧成峰，\n远近高低各不同。\n不识庐山真面目，\n只缘身在此山中。",
            category: "山水",
            analysis: PoemAnalysis(
                translation: "横看是连绵山岭，侧看是陡峭山峰；远近高低看，样子都不同。认不清庐山真面目，只因身在庐山之中。",
                background: "元丰七年苏轼由黄州量移汝州，途中游庐山，题于西林寺壁。",
                features: "前两句写视角，后两句由景入理，说「当局者迷」而不觉说教，是宋诗理趣的代表。"
            )
        ),
        Poem(
            id: "you-shan-xi-cun",
            title: "游山西村",
            author: "陆游",
            dynasty: "宋",
            content: "莫笑农家腊酒浑，\n丰年留客足鸡豚。\n山重水复疑无路，\n柳暗花明又一村。",
            category: "山水",
            analysis: PoemAnalysis(
                translation: "别嫌农家腊酒浑浊，丰年待客有鸡有肉。山重水复以为无路，柳暗花明处又见一村。",
                background: "乾道三年陆游罢官闲居山阴，游山西村时所作。",
                features: "「山重水复」「柳暗花明」本是写行路，后世移作处境的写照，是流传最广的一联。"
            )
        ),
        Poem(
            id: "bo-chuan-gua-zhou",
            title: "泊船瓜洲",
            author: "王安石",
            dynasty: "宋",
            content: "京口瓜洲一水间，\n钟山只隔数重山。\n春风又绿江南岸，\n明月何时照我还。",
            category: "离愁",
            analysis: PoemAnalysis(
                translation: "京口与瓜洲只隔一条江，钟山也不过隔着几重山。春风又吹绿江南岸，明月何时照我回家。",
                background: "王安石晚年退居金陵，往来瓜洲时作，思归之情寓其中。",
                features: "「绿」字作动词，是著名的炼字例：据说曾用「到」「过」「入」「满」，终定「绿」，一字而春意满纸。"
            )
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
            image: "ArtApp/artifact-qinghua-ping.jpg",
            patternDetail: PatternDetail(
                name: "缠枝莲纹",
                image: "ArtApp/pattern-chanzhilian.jpg",
                structure: "缠枝莲纹以莲花为主题，茎蔓缠绕盘旋，枝叶交错相连。纹样呈S形或波状连续延伸，花头饱满，叶片翻转自然，整体构图既繁密又富有变化。在元代青花中，缠枝莲纹是最为常见的装饰题材之一。",
                symbolism: "莲花出淤泥而不染，象征纯洁高雅、品格高尚。缠枝莲纹寓意连绵不断、生生不息，寄托了人们对美好生活的向往。在佛教文化中，莲花更是神圣之花，代表着清净无染。",
                eraStyle: "元代青花瓷器的缠枝莲纹承袭宋代传统，但在构图与绘画技法上有了新的发展。元代缠枝莲纹花头更大、茎叶更加舒展，青花色调浓艳，具有鲜明的时代特征。与明清时期的缠枝莲纹相比，元代风格更为粗犷豪放。",
                elements: [
                    PatternElement(name: "莲瓣", description: "花瓣饱满圆润，层次分明，多为仰莲或覆莲形式", image: "ArtApp/pattern-lianban.jpg"),
                    PatternElement(name: "卷草", description: "茎蔓卷曲缠绕，连接各花头，使纹样连绵不断", image: "ArtApp/pattern-juancao.jpg"),
                    PatternElement(name: "边饰", description: "以回纹、如意云纹等几何纹样作为辅助装饰", image: "ArtApp/pattern-bianshi.jpg"),
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
            image: "ArtApp/artifact-tong-jing.jpg",
            patternDetail: PatternDetail(
                name: "海兽葡萄纹",
                image: "",
                structure: "镜背分内、外两区：内区伏卧数只瑞兽（狮、狻猊一类），兽身周围满布葡萄枝蔓与果实；外区多绕飞禽、葡萄或花草一周。纹饰用高浮雕，凸起明显，兽形与枝蔓层层叠压，几乎不留空地。",
                symbolism: "葡萄果实累累、枝蔓绵长，寓多子丰产、子孙绵延；瑞兽主辟邪纳吉。葡萄与狮子皆自西域传入，唐人视之为祥瑞，这类纹样本身即是中外交流的印记。",
                eraStyle: "盛唐铜镜体量厚重，纹饰用高浮雕，繁密饱满，明显受波斯、中亚工艺影响；中唐以后浮雕渐低、纹饰趋简，海兽葡萄纹随之式微。",
                elements: []
            )
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
            image: "ArtApp/artifact-xiang-lu.jpg",
            patternDetail: PatternDetail(
                name: "缠枝莲纹",
                image: "",
                structure: "炉身外壁以缠枝莲纹为主纹：莲花作正面或侧面花头，茎蔓细而匀，作波状连续盘绕，间以卷叶与花苞补空；口沿或足部多配回纹、如意云纹作边饰。铸纹讲究对称规整，线条粗细一致。",
                symbolism: "莲花出淤泥而不染，寓清净虔敬，与焚香礼佛的用途相合；缠枝连绵不断，寓子孙绵长、香火不绝。",
                eraStyle: "明代宣德炉式样端庄简练，铜质精炼，皮色以栗壳、藏经为主；纹饰较元代规整、程式化，花头略小而茎蔓更细，讲究对称与留白，不再追求元代那种奔放。",
                elements: []
            )
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
            image: "ArtApp/artifact-yu-pei.jpg",
            patternDetail: PatternDetail(
                name: "双龙纹",
                image: "",
                structure: "以镂空透雕作对首双龙，龙身蜿蜒成 S 形，间以云纹衬底；龙首相对，须发与鳞甲用阴线刻出，边缘留穿系的小孔。整体取对称构图，龙身贴合佩形轮廓。",
                symbolism: "双龙相向，寓成双成对、护佑平安；玉在传统文化中比德君子，温润而坚，佩之自省。宋代玉器题材趋于世俗，吉祥寓意也更为直白。",
                eraStyle: "宋代玉雕重线条与层次，镂空多层，刀法细腻含蓄，题材多取花鸟、人物、瑞兽，气息文雅；与汉代玉器的浑厚、明清玉器的繁缛相比，宋玉更讲究以少胜多的韵致。",
                elements: []
            )
        ),
    ]

    // MARK: - activities.ts：activities（5 项 + 茶坊点茶）
    static let activities: [Activity] = [
        // 茶坊页「宋代点茶体验」原本只弹「后续开放」；内容库补上条目（无专属配图，image 留空）
        Activity(id: "tea-ceremony", name: "宋代点茶", description: "碾茶为末，注汤击拂，看乳花咬盏——宋人茶坊里的日常", type: "ritual", unlocked: true, participants: 3260),
        Activity(id: "feihualing", name: "飞花令·春", description: "以诗会友，飞花拾春", type: "quiz", unlocked: true, participants: 12345, image: "ArtApp/activity-feihualing.jpg"),
        Activity(id: "dengmi", name: "猜灯谜", description: "打开灯谜，谜底顿生", type: "puzzle", unlocked: true, participants: 12345, image: "ArtApp/activity-dengmi.jpg"),
        Activity(id: "hua-zhao", name: "古画找物", description: "画中寻物，妙趣在里", type: "find", unlocked: true, participants: 8967, image: "ArtApp/activity-hua-zhao.jpg"),
        Activity(id: "wenyang", name: "纹样配对", description: "纹艺之美，百文百相", type: "match", unlocked: true, participants: 5456, image: "ArtApp/activity-wenyang.jpg"),
        Activity(id: "qigu", name: "器物辨识", description: "识器明理，见器如著", type: "identify", unlocked: true, participants: 5128, image: "ArtApp/activity-qigu.jpg"),
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
        Stamp(id: "chun-ri-ya-shi", name: "春日雅士", description: "参与飞花令·春，以诗会友", image: "ArtApp/seal-chun-ri-ya-shi.png", obtained: false),
        Stamp(id: "dong-po-zhi-yin", name: "东坡知音", description: "完成茶坊对谈，与苏轼畅谈人生", image: "ArtApp/seal-dong-po-zhi-yin.png", obtained: false),
        Stamp(id: "qing-hui-shan-shui", name: "清辉山水", description: "赏读山水诗词，感受自然之美", image: "ArtApp/seal-qing-hui-shan-shui.png", obtained: false),
        Stamp(id: "gu-wu-yan-ji", name: "古物研习", description: "识别三件以上传物", image: "ArtApp/seal-gu-wu-yan-ji.png", obtained: false),
    ]

    // MARK: - 相似纹样（纹样详解页三张对照卡）
    /// 这三张卡原本只弹「相似纹样：缠枝牡丹」，零信息。
    /// 内容按宋代常见缠枝题材写；配图暂缺（工程里没有这三张图），
    /// 所以条目本身不带 image —— 详情页会显示无 hero 的文字页，而不是借别的纹样图充数。
    static let similarPatterns: [PatternDetail] = [
        PatternDetail(
            name: "缠枝牡丹",
            image: "",
            structure: "以牡丹花头为主体，枝茎作波浪状缠绕，花叶翻转自然。宋代牡丹纹多取「折枝」与「缠枝」两式，缠枝者枝蔓连绵不绝。",
            symbolism: "牡丹为花王，缠枝取其「连绵不断」，合为富贵绵长之意；宋人多用于织物与瓷器开光。",
            eraStyle: "宋人画牡丹重「写生」，花瓣层叠有序而不繁乱，与唐代的饱满浓艳相比更清雅。",
            elements: []
        ),
        PatternDetail(
            name: "缠枝菊花",
            image: "",
            structure: "菊瓣细长，层层内卷，枝茎作 S 形延展。宋瓷上常与莲、牡丹并列，作四季花卉之一。",
            symbolism: "菊傲霜而开，寓「长寿」与「隐逸」；与缠枝合用时，兼取长久不绝之意。",
            eraStyle: "宋代菊花纹偏瘦劲，瓣尖挺括，受文人画「疏影」趣味影响。",
            elements: []
        ),
        PatternDetail(
            name: "缠枝灵芝",
            image: "",
            structure: "灵芝头作如意状，枝蔓缠绕成连续纹样，常与卷草、云纹相间。",
            symbolism: "灵芝为瑞草，寓「如意」「长寿」；缠枝化后成为宋元常见的吉祥底纹。",
            eraStyle: "宋元之际灵芝纹趋于图案化，头部简化成如意云头，便于连续排布。",
            elements: []
        ),
    ]

    // MARK: - 独立书信（不属于某位人物的往来信件）
    /// 收藏页「一封家书」原本只弹提示；这里补一封宋人尺牍风格的虚构家书，
    /// 与人物信札一起被 /native/letter/<id> 解析（见 NativeDetailContent.resolve）。
    static let extraLetters: [Letter] = [
        Letter(
            id: "jia-shu",
            from: "江南游子",
            content: "儿自离家，忽已三秋。汴河船行至暮，两岸灯火如昼，儿常思家中灯下之粥。\n今寄俸钱半缗，望母亲添衣。天寒，勿以儿为念。",
            date: "元丰三年冬"
        ),
        // 收藏页「与友人书」卡片：内容库原本没有这封信，补一封友人往还的短札
        Letter(
            id: "yu-you-ren-shu",
            from: "友人",
            content: "久不见，闻君客汴，得句便寄。\n近得茶一卷，候君归时同试。城中瓦舍新到讲史人，说五代事甚妙，不可错过。",
            date: "元祐元年秋"
        ),
    ]

    // MARK: - rewards.ts：bianjingLocations（6 处）
    // era / activity 是本轮补的：汴京城内这五处地点在图上可点，原本只弹「将在后续章节开放」。
    // 文案据宋代史实写成（书院讲学、瓦舍勾栏、正店脚店、惠民和剂局、汴河漕运），不编造交互。
    static let bianjingLocations: [CityLocation] = [
        CityLocation(id: "shuyuan", name: "书院", x: 25.0, y: 18.0, unlocked: false,
                     description: "藏书万卷，文人雅集之地",
                     era: "宋代书院以讲学、藏书、祭祀并重。汴京除太学与国子监外，私学讲席常有名儒开讲，寒门子弟亦可执经问难。",
                     activity: "在此可听讲经义，或抄一段《论语》收进梦册。"),
        CityLocation(id: "teahouse", name: "茶坊", x: 72.0, y: 15.0, unlocked: true,
                     description: "品茶论道，东坡旧识茶坊",
                     era: "宋人饮茶已成日常，茶坊遍布汴京街巷，点茶、分茶之技在士庶间流传。",
                     activity: "可入内与东坡对谈，或看一场点茶。"),
        CityLocation(id: "jiusi", name: "酒肆", x: 15.0, y: 45.0, unlocked: false,
                     description: "美酒飘香，诗兴大发",
                     era: "汴京酒楼分正店与脚店：正店自酿，樊楼最盛，昼夜营业；酒旗招展处，也常是诗人题壁之所。",
                     activity: "点一盅新酒，与邻座对一句飞花令。"),
        CityLocation(id: "yaofang", name: "药坊", x: 45.0, y: 52.0, unlocked: false,
                     description: "悬壶济世，药香四溢",
                     era: "宋代设太医局与惠民和剂局，官药方刻板印行；民间药坊悬壶济世，药材多经汴河运来。",
                     activity: "在此可辨药材，或抄一张方子。"),
        CityLocation(id: "washe", name: "瓦舍", x: 75.0, y: 42.0, unlocked: false,
                     description: "百戏杂耍，市井繁华",
                     era: "瓦舍勾栏是宋人消遣之处：讲史、杂剧、傀儡、影戏、相扑轮番上演，一场说书可连讲数月。",
                     activity: "挑一段讲史听，或看一场傀儡戏。"),
        CityLocation(id: "matou", name: "码头", x: 82.0, y: 68.0, unlocked: false,
                     description: "商船云集，连接南北",
                     era: "汴河是汴京命脉，江淮米粮、茶盐、木材皆由此入城；《清明上河图》画的正是这里的漕船与纤夫。",
                     activity: "看漕船靠岸，听一段船工号子。"),
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

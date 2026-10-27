// NativeListView.swift
//
// 原生列表页：诗库 / 搜索 / 雅集活动列表。
//
// 为什么需要：设计稿里「诗库」「查看更多活动」这类入口原本只能弹一句提示，
// 但内容数据其实齐全（ContentData.poems 9 首、activities 5 个）。
// 用原生列表补上，比在位图上做像素级覆盖安全得多，也不受设计稿尺寸限制。
//
// 规矩：纸色背景 + Theme 色板 + 静态样式；列表项点开走 /native/<kind>/<id> 详情。

import SwiftUI

struct NativeListView: View {
    /// "poems" / "activities" / "works"
    let listID: String

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var selection: SelectionStore
    @State private var keyword: String = ""

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(title)
                        .font(.custom("KaitiSC-Bold", size: 26))
                        .foregroundColor(Theme.ink)
                        .padding(.top, 96)
                    Text(subtitle)
                        .font(.custom("SongtiSC-Regular", size: 12))
                        .foregroundColor(Theme.inkMuted)

                    if listID == "poems" {
                        searchField
                        categoryResetRow
                    }

                    ForEach(rows, id: \.id) { row in
                        Button(action: { router.navigate(route: row.route) }) {
                            HStack(spacing: 12) {
                                thumbnail(row.image)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(row.title)
                                        .font(.custom("KaitiSC-Bold", size: 16))
                                        .foregroundColor(Theme.ink)
                                    Text(row.subtitle)
                                        .font(.custom("SongtiSC-Regular", size: 11.5))
                                        .foregroundColor(Theme.inkMuted)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.inkMuted)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Theme.paperLight)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Theme.goldBorder.opacity(0.45), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(PressableStyle())
                    }

                    if rows.isEmpty {
                        Text(emptyText)
                            .font(.custom("SongtiSC-Regular", size: 13))
                            .foregroundColor(Theme.inkMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 30)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
            }

            topBar
        }
    }

    private var title: String {
        switch listID {
        case "poems": return "诗库"
        case "activities": return "雅集活动"
        case "works": return "我的作品"
        case "dialogues": return "对谈记录"
        case "footprints": return "我的足迹"
        case "characters": return "相逢古人"
        default: return "列表"
        }
    }

    private var subtitle: String {
        switch listID {
        case "poems":
            if let cat = categoryTitle { return "分类：\(cat) · 共 \(rows.count) 首" }
            return "共 \(NativeDetail.allPoems().count) 首 · 点开可读全文与译解"
        case "activities": return "共 \(ContentData.activities.count) 项活动 · 点开看玩法"
        case "works": return "共 \(rows.count) 张诗境卡 · 生成后自动入册"
        case "dialogues": return "共 \(ContentData.dialogueTopics.count) 个话题 · 点开看苏轼的完整回答"
        case "footprints": return "共 \(rows.count) 处 · 按最近到访排序，点开重游"
        case "characters": return "共 \(ContentData.characters.count) 位 · 点开看生平、作品与足迹"
        default: return ""
        }
    }

    /// 空分类的退路：诗库数据里没有「离愁」「边塞」这两类诗，
    /// 从诗境首页点进去就是一张空列表，而页面上原本没有任何"回到全部"的入口 —— 死路。
    /// 这里给一颗「全部」胶囊：写 poetryCategory = all（categoryMap 查不到 ⇒ 不筛）。
    @ViewBuilder
    private var categoryResetRow: some View {
        if categoryTitle != nil {
            Button(action: {
                store.setString(StorageKeys.poetryCategory, "all")
                selection.note(key: StorageKeys.poetryCategory, value: "all", screenID: "poems")
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
                    Text("看全部 \(NativeDetail.allPoems().count) 首")
                        .font(.custom("SongtiSC-Regular", size: 12))
                }
                .foregroundColor(Theme.inkLight)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(Capsule().fill(Theme.paperLight))
                .overlay(Capsule().strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 0.8))
            }
            .buttonStyle(PressableStyle())
        }
    }

    /// 分类胶囊写进 poetryCategory 的值 → 诗词的 category 文案
    private var categoryTitle: String? {
        guard listID == "poems", let raw = selection.value(StorageKeys.poetryCategory) else { return nil }
        return Self.categoryMap[raw]
    }

    private var emptyText: String {
        switch listID {
        case "works": return "还没有生成过诗境卡，去「诗境 · 生成诗境卡」做一张"
        case "poems": return categoryTitle == nil ? "没有找到匹配的诗句" : "该分类下暂时没有诗词"
        case "activities": return "暂无活动"
        case "footprints": return "还没有足迹。进「古城」逛一逛，这里就会记下你去过的地方"
        default: return "暂无内容"
        }
    }

    /// landscape / seasons / moon / sorrow / frontier → 诗词里的 category 文案
    static let categoryMap: [String: String] = [
        "landscape": "山水",
        "seasons": "四季",
        "moon": "月夜",
        "sorrow": "离愁",
        "frontier": "边塞",
    ]

    private var topBar: some View {
        HStack {
            Button(action: { router.closeNative() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                    Text("返回").font(.custom("SongtiSC-Regular", size: 14))
                }
                .foregroundColor(Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Theme.paperLight))
                .overlay(Capsule().strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 0.8))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 54)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(Theme.inkMuted)
            TextField("搜诗名、作者或诗句", text: $keyword)
                .font(.custom("SongtiSC-Regular", size: 13))
                .foregroundColor(Theme.ink)
            if !keyword.isEmpty {
                Button(action: { keyword = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.inkMuted)
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Capsule().fill(Theme.paperLight))
        .overlay(Capsule().strokeBorder(Theme.goldBorder.opacity(0.45), lineWidth: 0.8))
    }

    // MARK: - 行数据

    private struct Row: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let image: String?
        let route: String
    }

    private var rows: [Row] {
        switch listID {
        case "poems":
            let category = categoryTitle
            return NativeDetail.allPoems()
                .filter { category == nil || $0.category == category }
                .filter { keyword.isEmpty || matches($0) }
                .map { p in
                    Row(
                        id: p.id,
                        title: p.title,
                        subtitle: "\(p.dynasty) · \(p.author)　\(p.content.replacingOccurrences(of: "\n", with: " "))",
                        image: p.image ?? p.imagery?.first?.image,
                        route: "/native/poem/\(p.id)"
                    )
                }
        case "works":
            // 诗境卡作品：直接读真实卡面快照（诗句/题注/画风都在里面）。
            // 旧实现只存一个 id、再从诗句库反推标题 —— 画不出用户生成的那张卡。
            return store.poetryCardsNewestFirst.map { card in
                let styleName = Self.styleNames[card.style] ?? card.style
                let layoutName = Self.layoutNames[card.layout] ?? card.layout
                var subtitle = "\(styleName) · \(layoutName)"
                if !card.note.isEmpty { subtitle += "　题注：\(card.note)" }
                subtitle += "　\(card.date)"
                return Row(
                    id: card.id,
                    title: "《\(card.poemTitle)》诗境卡",
                    subtitle: subtitle,
                    image: card.image,
                    route: "/native/card/\(card.id)"
                )
            }
        case "dialogues":
            // 对谈记录：三个话题总览，点开看该话题的完整问答
            return ContentData.dialogueTopics.map { topic in
                Row(
                    id: topic.id,
                    title: topic.question,
                    subtitle: topic.responses.first?.text ?? "",
                    image: nil,
                    route: "/native/dialogue/\(topic.id)"
                )
            }
        case "activities":
            return ContentData.activities.map { a in
                Row(
                    id: a.id,
                    title: a.name,
                    subtitle: a.description,
                    image: a.image,
                    route: "/native/activity/\(a.id)"
                )
            }
        case "characters":
            // 梦册「相逢古人 · 查看全部」的落点：人物库本来就在 ContentData 里，
            // 之前只有三个人的入口，其余（李白/王维）藏在朝代页里，没有统一列表。
            return ContentData.characters.map { c in
                Row(
                    id: c.id,
                    title: "\(c.name) · \(c.title)",
                    subtitle: "\(c.dynasty) · " + c.works.prefix(2).map { "《\($0.title)》" }.joined(),
                    image: c.image,
                    route: "/native/character/\(c.id)"
                )
            }
        case "footprints":
            // 真实足迹：与个人中心底部三张卡同源（AppStore.recentFootprints），
            // 点开重游那座城。没有专属配图的地点显示占位图，不借用别的城池。
            return store.recentFootprints.map { record in
                Row(
                    id: record.place.id,
                    title: record.place.name,
                    subtitle: "\(record.place.subtitle)　·　\(record.whenText)到访",
                    image: record.place.image,
                    route: record.place.route
                )
            }
        default:
            return []
        }
    }

    private func matches(_ p: Poem) -> Bool {
        let k = keyword.trimmingCharacters(in: .whitespaces)
        return p.title.contains(k) || p.author.contains(k) || p.content.contains(k) || p.dynasty.contains(k)
    }

    /// 画风 / 版式的中文名（列表副标题用；与诗境卡工坊的胶囊文案保持一致）
    static let styleNames = ["ink": "水墨", "gongbi": "工笔", "bluegreen": "青绿", "song": "宋画"]
    static let layoutNames = ["horizontal": "横版", "vertical": "竖版", "whitespace": "留白"]

    @ViewBuilder
    private func thumbnail(_ path: String?) -> some View {
        if let path = path, let img = AssetLoader.image(path) {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.paperWarm)
                .frame(width: 56, height: 56)
                .overlay(Image(systemName: "doc.text").font(.system(size: 18)).foregroundColor(Theme.goldBorder))
        }
    }
}

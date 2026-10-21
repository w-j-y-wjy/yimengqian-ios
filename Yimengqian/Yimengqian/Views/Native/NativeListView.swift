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
                        .buttonStyle(.plain)
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
        default: return ""
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
                .buttonStyle(.plain)
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
            // 诗境卡作品：快照里记的是生成记录 id（保存时写入），这里翻成可读行
            return store.snapshot.generatedCards.enumerated().map { index, raw in
                let poemID = raw.replacingOccurrences(of: "-card", with: "")
                let poem = NativeDetail.allPoems().first(where: { $0.id == poemID })
                return Row(
                    id: raw,
                    title: poem.map { "《\($0.title)》诗境卡" } ?? "诗境卡 \(index + 1)",
                    subtitle: "已在诗境卡工坊生成并保存",
                    image: poem?.image ?? poem?.imagery?.first?.image,
                    route: "/poetry/card"
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
        default:
            return []
        }
    }

    private func matches(_ p: Poem) -> Bool {
        let k = keyword.trimmingCharacters(in: .whitespaces)
        return p.title.contains(k) || p.author.contains(k) || p.content.contains(k) || p.dynasty.contains(k)
    }

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

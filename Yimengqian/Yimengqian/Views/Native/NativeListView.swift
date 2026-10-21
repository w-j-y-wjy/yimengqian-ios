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
    /// "poems" 或 "activities"
    let listID: String

    @EnvironmentObject private var router: Router
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
                        Text("没有找到匹配的内容")
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
        default: return "列表"
        }
    }

    private var subtitle: String {
        switch listID {
        case "poems": return "共 \(NativeDetail.allPoems().count) 首 · 点开可读全文与译解"
        case "activities": return "共 \(ContentData.activities.count) 项活动 · 点开看玩法"
        default: return ""
        }
    }

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
            return NativeDetail.allPoems()
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

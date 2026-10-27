// NativeSearchView.swift
//
// 全站搜索 —— 三个「搜索」入口（诗境首页 / 雅集页 / 收藏页）原本都只弹一句提示。
//
// 做法：一个原生搜索页，跨四类内容（诗词 / 器物 / 人物 / 活动）实时过滤：
// 诗词按标题、作者、正文、朝代匹配；器物按名称、朝代、纹样；人物按姓名、称号、标签；活动按名称、描述。
// 结果行点开进对应原生详情页（复用 /native/<kind>/<id>）。
//
// 没有新增数据，也没有像素对齐问题：纯原生页面。

import SwiftUI

struct NativeSearchView: View {
    @EnvironmentObject private var router: Router
    @State private var keyword: String = ""

    private struct Hit: Identifiable {
        let id: String
        let kind: String
        let title: String
        let subtitle: String
        let image: String?
        let route: String
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                Text("搜索")
                    .font(.custom("KaitiSC-Bold", size: 26))
                    .foregroundColor(Theme.ink)
                    .padding(.top, 96)

                searchField

                if keyword.trimmingCharacters(in: .whitespaces).isEmpty {
                    hintList
                } else {
                    resultList
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)

            topBar
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
            TextField("搜诗词、器物、人物、活动", text: $keyword)
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
        // 启动参数 -searchKeyword 可预填关键词（CI 截图用来验证结果列表）；
        // 路由 /native/search/<关键词> 也能预填（意象页的关键词就靠这个跳到搜索结果）
        .onAppear {
            if keyword.isEmpty {
                if let seed = router.nativeDetail?.id, seed != "main", !seed.isEmpty {
                    keyword = seed
                } else {
                    keyword = UserDefaults.standard.string(forKey: "searchKeyword") ?? ""
                }
            }
        }
    }

    private var hintList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("可以搜这些")
                .font(.custom("SongtiSC-Regular", size: 12))
                .foregroundColor(Theme.inkMuted)
            // 自适应列：词语短，竖着排会显得空，一行放三四个更紧凑
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(hintWords, id: \.self) { w in
                    Button(action: { keyword = w }) {
                        Text(w)
                            .font(.custom("SongtiSC-Regular", size: 13))
                            .foregroundColor(Theme.inkLight)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.paperLight))
                            .overlay(Capsule().strokeBorder(Theme.goldBorder.opacity(0.4), lineWidth: 0.8))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
        .padding(.top, 6)
    }

    private var resultList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                if hits.isEmpty {
                    Text("没有找到「\(keyword)」，换个词试试")
                        .font(.custom("SongtiSC-Regular", size: 13))
                        .foregroundColor(Theme.inkMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 30)
                }
                ForEach(hits) { hit in
                    Button(action: { router.navigate(route: hit.route) }) {
                        HStack(spacing: 12) {
                            thumbnail(hit.image)
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(kindName(hit.kind))
                                        .font(.custom("SongtiSC-Regular", size: 10))
                                        .foregroundColor(Theme.paperWarm)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Theme.vermilion.opacity(0.8)))
                                    Text(hit.title)
                                        .font(.custom("KaitiSC-Bold", size: 15))
                                        .foregroundColor(Theme.ink)
                                }
                                Text(hit.subtitle)
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
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.paperLight))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.goldBorder.opacity(0.45), lineWidth: 0.8))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var hintWords: [String] {
        ["江雪", "苏轼", "青花", "飞花令", "月", "山水"]
    }

    private func kindName(_ kind: String) -> String {
        switch kind {
        case "poem": return "诗"
        case "artifact": return "物"
        case "character": return "人"
        case "activity": return "集"
        default: return "·"
        }
    }

    private func matches(_ text: String) -> Bool {
        let k = keyword.trimmingCharacters(in: .whitespaces)
        return !k.isEmpty && text.contains(k)
    }

    private var hits: [Hit] {
        let k = keyword.trimmingCharacters(in: .whitespaces)
        guard !k.isEmpty else { return [] }
        var out: [Hit] = []

        for p in NativeDetail.allPoems() where p.title.contains(k) || p.author.contains(k) || p.content.contains(k) || p.dynasty.contains(k) {
            out.append(Hit(id: "poem-\(p.id)", kind: "poem", title: p.title,
                           subtitle: "\(p.dynasty) · \(p.author)　\(p.content.replacingOccurrences(of: "\n", with: " "))",
                           image: p.image ?? p.imagery?.first?.image, route: "/native/poem/\(p.id)"))
        }
        for a in ContentData.artifacts where a.name.contains(k) || a.dynasty.contains(k) || a.pattern.contains(k) || a.type.contains(k) {
            out.append(Hit(id: "artifact-\(a.id)", kind: "artifact", title: a.name,
                           subtitle: "\(a.dynasty) · \(a.type) · \(a.pattern)",
                           image: a.image, route: "/native/artifact/\(a.id)"))
        }
        for c in ContentData.characters where c.name.contains(k) || c.title.contains(k) || c.tags.contains(where: { $0.contains(k) }) {
            out.append(Hit(id: "character-\(c.id)", kind: "character", title: c.name,
                           subtitle: "\(c.dynasty) · \(c.title)　\(c.tags.joined(separator: "、"))",
                           image: c.image, route: "/native/character/\(c.id)"))
        }
        for a in ContentData.activities where a.name.contains(k) || a.description.contains(k) {
            out.append(Hit(id: "activity-\(a.id)", kind: "activity", title: a.name,
                           subtitle: a.description,
                           image: a.image, route: "/native/activity/\(a.id)"))
        }
        return out
    }

    @ViewBuilder
    private func thumbnail(_ path: String?) -> some View {
        if let path = path, let img = AssetLoader.image(path) {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 52, height: 52)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.paperWarm)
                .frame(width: 52, height: 52)
                .overlay(Image(systemName: "magnifyingglass").font(.system(size: 16)).foregroundColor(Theme.goldBorder))
        }
    }
}

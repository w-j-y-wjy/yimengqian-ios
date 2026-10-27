// NativeDetailView.swift
//
// 原生详情页 —— 叠在整屏设计稿之上，用来承载"设计稿里没有、但数据里有"的详情：
// 诗/词、器物、纹样要素、活动、人物、书信。
//
// 设计原则（与既有叠层一致，但这一层是**可交互**的）：
// - 纸色 + 墨色 + 朱砂，只用 Theme 色板；无动画、无花哨背景；
// - 顶部一条返回栏，返回走 Router.closeNative() —— 不会污染路由栈；
// - 有配图就显示配图（这些图此前 16 张从不出现），没配图就只排文字；
// - 可收藏的内容给一个真实收藏按钮（写 AppStore.snapshot.favorites，和收藏页同源）。

import SwiftUI

struct NativeDetailView: View {
    let detail: NativeDetail
    let content: NativeDetailContent
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var toast: ToastCenter

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    heroBlock

                    VStack(alignment: .leading, spacing: 6) {
                        Text(content.title)
                            .font(.custom("KaitiSC-Bold", size: 26))
                            .foregroundColor(Theme.ink)
                        Text(content.subtitle)
                            .font(.custom("SongtiSC-Regular", size: 13))
                            .foregroundColor(Theme.inkMuted)
                    }
                    .padding(.horizontal, 20)

                    if !content.tags.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(content.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.custom("SongtiSC-Regular", size: 11))
                                    .foregroundColor(Theme.inkLight)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Theme.paperLight))
                                    .overlay(Capsule().strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 0.8))
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    if !content.lines.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(Array(content.lines.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.custom("KaitiSC-Bold", size: 19))
                                    .foregroundColor(Theme.ink)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.paperLight.opacity(0.7))
                        )
                        .padding(.horizontal, 20)
                    }

                    ForEach(Array(content.sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Rectangle().fill(Theme.vermilion).frame(width: 3, height: 13)
                                Text(section.title)
                                    .font(.custom("KaitiSC-Bold", size: 15))
                                    .foregroundColor(Theme.ink)
                            }
                            Text(section.body)
                                .font(.custom("SongtiSC-Regular", size: 13.5))
                                .foregroundColor(Theme.inkLight)
                                .lineSpacing(5)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    }

                    // 纹样画廊：NativeDetailContent.gallery 早就填好了（器物详情的纹样大图 +
                    // 三个要素图），但此前**没有任何视图渲染它** —— 数据白填。
                    // 这里按设计稿的气质排一条横向画廊，点不放大的交互（单张即可看清）。
                    if !content.gallery.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Rectangle().fill(Theme.vermilion).frame(width: 3, height: 13)
                                Text("纹样图")
                                    .font(.custom("KaitiSC-Bold", size: 15))
                                    .foregroundColor(Theme.ink)
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(content.gallery.enumerated()), id: \.offset) { _, path in
                                        galleryCell(path)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    if let fav = content.favorite {
                        favoriteButton(type: fav.type, itemId: fav.itemId)
                            .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 96)
            }

            topBar
        }
        .onAppear(perform: recordCityVisitIfNeeded)
    }

    /// 到访城池详情就记一笔真实足迹 —— 个人中心「最近足迹」的数据来源。
    /// 放在 onAppear 而不是热点动作里：同一个城池详情可能从朝代页、梦册、足迹卡三处进入，
    /// 在"页面真的显示了"的时机记，才能覆盖全部入口。
    private func recordCityVisitIfNeeded() {
        if case .city(let id) = detail, let place = PlaceCatalog.place(forCityID: id) {
            store.recordPlace(place.id)
        }
    }

    /// 画廊里的一格：装不下就裁切，别把图压扁
    @ViewBuilder
    private func galleryCell(_ path: String) -> some View {
        if let img = AssetLoader.image(path) {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 110)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.goldBorder.opacity(0.45), lineWidth: 0.8)
                )
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

    @ViewBuilder
    private var heroBlock: some View {
        if let path = content.hero, let img = AssetLoader.image(path) {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 220)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Theme.paperWarm.opacity(0.6)],
                        startPoint: .center, endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                )
                .padding(.horizontal, 20)
        } else if let patternName = content.paintedPattern {
            // 没有配图的纹样：程序化绘制（相似纹样三条走这里）。
            // 比留一块空白 hero 好 —— 用户点进「缠枝菊花」应该看到菊花，而不是空白。
            PatternPainter(name: patternName, tint: Theme.goldBorder, lineWidth: 1.8)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Theme.goldBorder.opacity(0.4), lineWidth: 0.8)
                )
                .padding(.horizontal, 20)
        } else {
            Rectangle().fill(Theme.paperWarm).frame(height: 8)
        }
    }

    private func favoriteButton(type: FavoriteType, itemId: String) -> some View {
        let on = store.isFavorite(type: type, itemId: itemId)
        return Button(action: {
            let added = store.toggleFavorite(type: type, itemId: itemId)
            toast.show(added ? "已收藏" : "已取消收藏")
        }) {
            HStack(spacing: 6) {
                Image(systemName: on ? "star.fill" : "star")
                    .font(.system(size: 13, weight: .semibold))
                Text(on ? "已收藏" : "收藏")
                    .font(.custom("SongtiSC-Regular", size: 14))
            }
            .foregroundColor(on ? Theme.paperLight : Theme.vermilion)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                Capsule().fill(on ? Theme.vermilion : Color.clear)
            )
            .overlay(
                Capsule().strokeBorder(Theme.vermilion.opacity(on ? 0 : 0.7), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

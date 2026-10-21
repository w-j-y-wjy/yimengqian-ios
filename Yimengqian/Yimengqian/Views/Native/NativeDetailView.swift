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
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Theme.paperWarm.opacity(0.85)],
                        startPoint: .center, endPoint: .bottom
                    )
                )
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

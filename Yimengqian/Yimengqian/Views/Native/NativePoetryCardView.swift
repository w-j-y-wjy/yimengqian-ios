// NativePoetryCardView.swift
//
// 诗境卡作品详情 —— 「我的作品」里点开一张卡，看到的是**用户自己生成的那张卡面**。
//
// 之前的问题：保存时只往快照塞了一个 id（"jiangxue-card"），
// 「我的作品」列表里显示的是《江雪》的配图缩略图，点进去还会跳回工坊重新选参数 ——
// 也就是说"生成诗境卡"这个核心卖点，产出的其实只是一条记录，没有画面。
//
// 这里补上完整闭环：
//   工坊选项（画风/版式/印章）→ 保存 → 冻结成 PoetryCard → 作品列表 → 详情看卡面 → 可分享/删除

import SwiftUI

struct NativePoetryCardView: View {
    let cardID: String

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var toast: ToastCenter

    @State private var showDeleteConfirm = false

    private var card: PoetryCard? {
        store.poetryCards.first { $0.id == cardID }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            if let card = card {
                ScrollView {
                    VStack(spacing: 16) {
                        // 卡面本体：竖版 3:5 / 横版 5:3，与作品列表里的一致
                        PoetryCardView(card: card)
                            .aspectRatio(card.layout == "vertical" ? 3.0 / 5.0 : 5.0 / 3.0, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Theme.goldBorder.opacity(0.55), lineWidth: 1)
                            )
                            .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 4)
                            .padding(.top, NativeMetrics.contentTop)

                        metaRow(card)
                        actionRow(card)
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                VStack(spacing: 10) {
                    Spacer()
                    Text("这张卡已经不在了")
                        .font(.custom("KaitiSC-Bold", size: 17))
                        .foregroundColor(Theme.ink)
                    Text("可能是刚被删除，回到「我的作品」看看其它卡。")
                        .font(.custom("SongtiSC-Regular", size: 12.5))
                        .foregroundColor(Theme.inkMuted)
                    Spacer()
                }
            }

            topBar
        }
        .confirmationDialog("删除这张诗境卡？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                store.deletePoetryCard(id: cardID)
                toast.show("已删除")
                router.closeNative()
            }
            Button("取消", role: .cancel) {}
        }
    }

    /// 元信息：画风 / 版式 / 印章 / 生成日期 —— 都是真实存储值，不是写死的
    private func metaRow(_ card: PoetryCard) -> some View {
        let rows: [(String, String)] = [
            ("画风", NativeListView.styleNames[card.style] ?? card.style),
            ("版式", NativeListView.layoutNames[card.layout] ?? card.layout),
            ("印章", card.seal == "red" ? "朱印" : "无印"),
            ("生成", card.date),
        ]
        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, item in
                HStack {
                    Text(item.0)
                        .font(.custom("SongtiSC-Regular", size: 12.5))
                        .foregroundColor(Theme.inkMuted)
                    Spacer()
                    Text(item.1)
                        .font(.custom("SongtiSC-Regular", size: 12.5))
                        .foregroundColor(Theme.ink)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                if index < rows.count - 1 {
                    Divider().overlay(Theme.goldBorder.opacity(0.25))
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.paperLight))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.goldBorder.opacity(0.35), lineWidth: 0.8))
    }

    private func actionRow(_ card: PoetryCard) -> some View {
        VStack(spacing: 10) {
            Button(action: {
                router.openNative(.share("card"))
            }) {
                Text("分享这张卡")
                    .font(.custom("SongtiSC-Regular", size: 15))
                    .foregroundColor(Theme.paperWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(Theme.vermilion))
            }
            .buttonStyle(PressableStyle())

            Button(action: { showDeleteConfirm = true }) {
                Text("删除这张卡")
                    .font(.custom("SongtiSC-Regular", size: 13.5))
                    .foregroundColor(Theme.inkMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Capsule().strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 0.9))
            }
            .buttonStyle(PressableStyle())
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
            Text("我的诗境卡")
                .font(.custom("KaitiSC-Bold", size: 15))
                .foregroundColor(Theme.ink)
            Spacer()
            // 占位保持标题居中（与返回按钮同宽）
            Color.clear.frame(width: 62, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, NativeMetrics.barTop)
    }
}

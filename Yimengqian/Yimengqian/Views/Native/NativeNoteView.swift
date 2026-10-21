// NativeNoteView.swift
//
// 诗境卡「添加题注」—— 原本只弹「题注编辑将在后续开放」。
//
// 这里做成真的：写一段题注 → 存进本地（StorageKeys.cardNote）→ 在「我的作品」每张卡下方显示。
// 不涉及位图叠加（题注并不画到诗境卡位图上，那是设计稿的一部分），所以能诚实地闭环：
// 写完有地方看得到、下次进入还在。

import SwiftUI

struct NativeNoteView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var toast: ToastCenter

    @State private var text: String = ""

    private let limit = 60

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text("添加题注")
                    .font(.custom("KaitiSC-Bold", size: 26))
                    .foregroundColor(Theme.ink)
                    .padding(.top, 96)

                Text("给这张诗境卡写一句话。保存后会显示在「我的作品」里。")
                    .font(.custom("SongtiSC-Regular", size: 12.5))
                    .foregroundColor(Theme.inkMuted)

                ZStack(alignment: .topLeading) {
                    // iOS 15 没有 TextEditor 占位符，自己叠一层
                    if text.isEmpty {
                        Text("例如：此卡取水墨意，留白处最见寒江")
                            .font(.custom("SongtiSC-Regular", size: 14))
                            .foregroundColor(Theme.inkMuted.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                    }
                    TextEditor(text: $text)
                        .font(.custom("SongtiSC-Regular", size: 14))
                        .foregroundColor(Theme.ink)
                        .scrollContentBackgroundHiddenIfAvailable()
                        .padding(8)
                }
                .frame(height: 170)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.paperLight))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.goldBorder.opacity(0.45), lineWidth: 0.8))

                HStack {
                    Text("\(text.count) / \(limit)")
                        .font(.custom("SongtiSC-Regular", size: 11.5))
                        .foregroundColor(text.count > limit ? Theme.vermilion : Theme.inkMuted)
                    Spacer()
                    if !text.isEmpty {
                        Button(action: { text = "" }) {
                            Text("清空")
                                .font(.custom("SongtiSC-Regular", size: 12.5))
                                .foregroundColor(Theme.inkMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button(action: save) {
                    Text("保存题注")
                        .font(.custom("SongtiSC-Regular", size: 15))
                        .foregroundColor(Theme.paperWarm)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Capsule().fill(Theme.vermilion))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)

            topBar
        }
        .onAppear { text = store.string(StorageKeys.cardNote) ?? "" }
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

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            toast.show("题注还是空的")
            return
        }
        guard trimmed.count <= limit else {
            toast.show("题注最多 \(limit) 个字")
            return
        }
        store.setString(StorageKeys.cardNote, trimmed)
        toast.show("题注已保存")
        router.closeNative()
    }
}

private extension View {
    /// iOS 16+ 才有 scrollContentBackground；iOS 15 上保持默认即可
    @ViewBuilder
    func scrollContentBackgroundHiddenIfAvailable() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}

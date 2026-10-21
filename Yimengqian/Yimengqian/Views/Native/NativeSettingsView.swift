// NativeSettingsView.swift
//
// 原生设置页 —— 补上「设置」这个原本只弹提示的入口。
//
// 为什么值得做：个人中心右上角齿轮、入口行第四行、梦册右上角齿轮，三处都指向设置，
// 却全都只回一句「原型模拟」。而设置页要展示的东西（数据统计、版本、重置）本来就有真实数据。
//
// 规矩：纸色 + Theme 色板 + 静态样式；重置走与启动页五连击相同的确认流程，
// 清快照 + 清离散键 + 清选择态 + 回启动页。

import SwiftUI

struct NativeSettingsView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var selection: SelectionStore
    @EnvironmentObject private var toast: ToastCenter

    @State private var showResetConfirm = false

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("设置")
                        .font(.custom("KaitiSC-Bold", size: 26))
                        .foregroundColor(Theme.ink)
                        .padding(.top, 96)

                    section("我的数据", rows: [
                        ("已收藏内容", "\(store.snapshot.favorites.count) 项"),
                        ("已获得印章", "\(store.obtainedStamps().count) 枚"),
                        ("文化值", "\(store.snapshot.cultureValue) / 2000"),
                        ("当前等级", "Lv.\(store.snapshot.level)"),
                        ("诗境卡作品", "\(store.snapshot.generatedCards.count) 张"),
                    ])

                    section("收藏口径", rows: [
                        ("诗词", "\(store.collection(filter: "poem").count) 首"),
                        ("器物", "\(store.collection(filter: "artifact").count) 件"),
                        ("人物", "\(store.collection(filter: "character").count) 位"),
                        ("书信", "\(store.collection(filter: "letter").count) 封"),
                        ("印章", "\(store.collection(filter: "stamp").count) 枚"),
                    ])

                    section("关于", rows: [
                        ("版本", appVersion),
                        ("内容来源", "\(ContentData.poems.count + ContentData.characters.flatMap { $0.works }.count) 首诗词 · \(ContentData.artifacts.count) 件器物 · \(ContentData.characters.count) 位人物"),
                    ])

                    Button(action: { showResetConfirm = true }) {
                        Text("重置全部旅程数据")
                            .font(.custom("SongtiSC-Regular", size: 15))
                            .foregroundColor(Theme.vermilion)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Capsule().fill(Theme.paperLight))
                            .overlay(Capsule().strokeBorder(Theme.vermilion.opacity(0.6), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)

                    Text("重置会清空收藏、印章、进度与偏好，且不可撤销。")
                        .font(.custom("SongtiSC-Regular", size: 11.5))
                        .foregroundColor(Theme.inkMuted)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }

            topBar
        }
        .alert("重置全部旅程数据？", isPresented: $showResetConfirm) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) { performReset() }
        } message: {
            Text("将清空偏好、收藏、印章与全部进度。此操作不可撤销。")
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

    private func section(_ title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Rectangle().fill(Theme.vermilion).frame(width: 3, height: 13)
                Text(title)
                    .font(.custom("KaitiSC-Bold", size: 15))
                    .foregroundColor(Theme.ink)
            }
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack {
                        Text(row.0)
                            .font(.custom("SongtiSC-Regular", size: 13.5))
                            .foregroundColor(Theme.inkLight)
                        Spacer()
                        Text(row.1)
                            .font(.custom("SongtiSC-Regular", size: 13.5))
                            .foregroundColor(Theme.inkMuted)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    if index < rows.count - 1 {
                        Divider().background(Theme.goldBorder.opacity(0.3)).padding(.leading, 12)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.paperLight))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.goldBorder.opacity(0.4), lineWidth: 0.8))
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "?"
        let b = info?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    private func performReset() {
        store.resetAll()
        selection.reset()
        router.closeNative()
        if let splash = ScreenCatalog.screen(id: "splash") {
            router.jump(to: splash)
        }
        toast.show("已重置全部旅程数据")
    }
}

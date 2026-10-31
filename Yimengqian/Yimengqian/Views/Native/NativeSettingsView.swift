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
import UniformTypeIdentifiers

struct NativeSettingsView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var selection: SelectionStore
    @EnvironmentObject private var toast: ToastCenter

    @State private var showResetConfirm = false
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var backupDoc: BackupDocument?

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("设置")
                        .font(.custom("KaitiSC-Bold", size: 26))
                        .foregroundColor(Theme.ink)
                        .padding(.top, NativeMetrics.contentTop)

                    section("我的数据", rows: [
                        ("已收藏内容", "\(store.snapshot.favorites.count) 项"),
                        ("已获得印章", "\(store.obtainedStamps().count) 枚"),
                        ("文化值", "\(store.snapshot.cultureValue) / 2000"),
                        ("雅集值", "\(store.snapshot.yaValue)"),
                        // 花瓣此前是个"隐形字段"：领奖时 +6，界面上却没有任何一处显示它。
                        ("花瓣", "\(store.snapshot.petals) 片"),
                        ("已入梦", "\(store.snapshot.dreamDays) 日"),
                        ("到访城池", "\(store.snapshot.cityVisits?.filter { $0.value > 0 }.count ?? 0) 座"),
                        ("相逢古人", "\(store.snapshot.characterMeets?.filter { $0.value > 0 }.count ?? 0) 位"),
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

                    // 备份：能把自己的旅程带走 —— 换机/重装/答辩后留档都靠它
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Rectangle().fill(Theme.vermilion).frame(width: 3, height: 13)
                            Text("数据备份").font(.custom("KaitiSC-Bold", size: 15)).foregroundColor(Theme.ink)
                        }
                        HStack(spacing: 10) {
                            Button(action: prepareExport) {
                                Text("导出备份")
                                    .font(.custom("SongtiSC-Regular", size: 14))
                                    .foregroundColor(Theme.paperLight)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(Capsule().fill(Theme.vermilion))
                            }
                            .buttonStyle(PressableStyle())

                            Button(action: { showImporter = true }) {
                                Text("导入备份")
                                    .font(.custom("SongtiSC-Regular", size: 14))
                                    .foregroundColor(Theme.vermilion)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .overlay(Capsule().strokeBorder(Theme.vermilion.opacity(0.7), lineWidth: 1))
                            }
                            .buttonStyle(PressableStyle())
                        }
                        Text("导出为 JSON 文件（\(BackupService.summary(store.snapshot))）。导入会覆盖当前进度，请先导出一份再导入。")
                            .font(.custom("SongtiSC-Regular", size: 11))
                            .foregroundColor(Theme.inkMuted)
                            .lineSpacing(2)
                    }
                    .padding(.top, 4)

                    Button(action: { showResetConfirm = true }) {
                        Text("重置全部旅程数据")
                            .font(.custom("SongtiSC-Regular", size: 15))
                            .foregroundColor(Theme.vermilion)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Capsule().fill(Theme.paperLight))
                            .overlay(Capsule().strokeBorder(Theme.vermilion.opacity(0.6), lineWidth: 1))
                    }
                    .buttonStyle(PressableStyle())
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
        .fileExporter(isPresented: $showExporter,
                      document: backupDoc,
                      contentType: .json,
                      defaultFilename: BackupService.defaultFilename()) { result in
            if case .success = result {
                toast.show("备份已导出")
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
    }

    // MARK: - 备份

    private func prepareExport() {
        do {
            backupDoc = BackupDocument(data: try BackupService.exportData(store.snapshot))
            showExporter = true
        } catch {
            toast.show("导出失败：文件写入被拒绝")
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        // 走文件选择器拿到的 URL 是安全作用域资源，不 start 就读不到内容
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let snapshot = try BackupService.decodeSnapshot(from: Data(contentsOf: url))
            store.snapshot = snapshot
            toast.show("已恢复：\(BackupService.summary(snapshot))")
        } catch {
            toast.show("这个文件不是有效的备份")
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
        .padding(.top, NativeMetrics.barTop)
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
        // 头像存在 Documents/avatar.png，不在 UserDefaults 里，resetAll() 清不到它 ——
        // 不删的话"重置全部旅程数据"之后头像还是自定义的那张。
        AvatarStore.clear()
        router.closeNative()
        if let splash = ScreenCatalog.screen(id: "splash") {
            router.jump(to: splash)
        }
        toast.show("已重置全部旅程数据")
    }
}

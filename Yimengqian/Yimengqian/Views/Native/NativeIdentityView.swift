// NativeIdentityView.swift
//
// 古典身份详情 —— Phase 3-4 的正确落地方式。
//
// 为什么不做像素叠层：
// 身份结果页那张卡是**带纸纹与梅花点缀的渐变底**，不是纯色。用纯色矩形去盖位图旧字，
// 卡面上会留下一块肉眼可见的方块（第一次就是这么翻车的，CI 截图能看到接缝）。
// 所以这一块改成"原生页承载"：位图原样不动，点身份卡进原生页看重新算出的画像。
//
// 内容来自 4 项偏好（场景 / 内容 / 朝代 / 心境）→ IdentityProfile 规则映射，
// 不是随机文案，也不是模型：同一个选择组合永远得到同一个身份。

import SwiftUI

struct NativeIdentityView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var toast: ToastCenter

    private var profile: IdentityProfile {
        IdentityProfile(
            scene: store.string(StorageKeys.preferenceScene),
            content: store.string(StorageKeys.preferenceContent),
            dynasty: store.string(StorageKeys.preferenceDynasty),
            mood: store.string(StorageKeys.preferenceMood)
        )
    }

    /// 四选项的中文名（用于"你的选择"回显，让用户知道画像从哪来）
    private var choiceRows: [(String, String)] {
        let sceneMap = ["landscape": "山水", "marketplace": "市井"]
        let contentMap = ["poetry": "诗词", "painting": "绘画", "artifact": "器物"]
        let moodMap = ["lively": "灵动", "quiet": "清幽"]
        func label(_ map: [String: String], _ key: String?) -> String {
            guard let key = key else { return "未选" }
            return map[key] ?? key
        }
        return [
            ("偏好场景", label(sceneMap, store.string(StorageKeys.preferenceScene))),
            ("偏好内容", label(contentMap, store.string(StorageKeys.preferenceContent))),
            // 朝代走归一化：偏好页存的是 northernSong/southernSong，统一翻成中文
            ("心仪朝代", IdentityProfile.dynastyLabel(store.string(StorageKeys.preferenceDynasty))),
            ("心境", label(moodMap, store.string(StorageKeys.preferenceMood))),
        ]
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    choiceCard
                    bioCard
                    actionRow
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 100)
            }

            topBar
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("你的古典身份")
                .font(.custom("SongtiSC-Regular", size: 12.5))
                .foregroundColor(Theme.inkMuted)
            Text(verbatim: profile.title)
                .font(.custom("KaitiSC-Bold", size: 30))
                .foregroundColor(Theme.ink)
            HStack(spacing: 8) {
                ForEach(profile.tags, id: \.self) { tag in
                    Text(verbatim: tag)
                        .font(.custom("SongtiSC-Regular", size: 12))
                        .foregroundColor(Theme.inkLight)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Theme.paperLight))
                        .overlay(Capsule().strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 0.8))
                }
            }
        }
    }

    private var choiceCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(choiceRows.enumerated()), id: \.offset) { index, row in
                HStack {
                    Text(row.0)
                        .font(.custom("SongtiSC-Regular", size: 12.5))
                        .foregroundColor(Theme.inkMuted)
                    Spacer()
                    Text(row.1)
                        .font(.custom("SongtiSC-Regular", size: 12.5))
                        .foregroundColor(Theme.ink)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                if index < choiceRows.count - 1 {
                    Divider().overlay(Theme.goldBorder.opacity(0.25))
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.paperLight))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.goldBorder.opacity(0.35), lineWidth: 0.8))
    }

    private var bioCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("身份释义")
                .font(.custom("KaitiSC-Bold", size: 15))
                .foregroundColor(Theme.ink)
            Text(verbatim: profile.bio)
                .font(.custom("SongtiSC-Regular", size: 13.5))
                .foregroundColor(Theme.inkLight)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.paperLight))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.goldBorder.opacity(0.35), lineWidth: 0.8))
    }

    private var actionRow: some View {
        VStack(spacing: 10) {
            Button(action: { router.navigate(route: "/onboarding/preferences") }) {
                Text("重新测一次")
                    .font(.custom("SongtiSC-Regular", size: 15))
                    .foregroundColor(Theme.paperWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(Theme.vermilion))
            }
            .buttonStyle(.plain)

            Button(action: {
                // 把画像念出来：与"苏轼语音"同一套系统语音，真出声
                SpeechCenter.shared.speak("\(profile.title)。\(profile.bio.replacingOccurrences(of: "\n", with: ""))")
                toast.show("正在朗读你的身份")
            }) {
                Text("朗读我的身份")
                    .font(.custom("SongtiSC-Regular", size: 13.5))
                    .foregroundColor(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Theme.paperLight))
                    .overlay(Capsule().strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 0.9))
            }
            .buttonStyle(.plain)
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
}

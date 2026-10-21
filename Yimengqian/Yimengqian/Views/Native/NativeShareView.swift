// NativeShareView.swift
//
// 分享页 —— 三处「分享」按钮（诗境卡 / 纹样详解 / 印章奖励）原本只弹「分享功能为原型模拟」。
//
// 这里做成真的：给出要分享的标题与一句话介绍，点「分享」拉起系统分享面板
// （UIActivityViewController，可直接发到微信/存备忘录/拷贝）。
// 不接第三方 SDK，不需要额外素材与权限。

import SwiftUI
import UIKit

/// SwiftUI 里桥接 UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct NativeShareView: View {
    @EnvironmentObject private var router: Router
    @State private var showSheet = false

    /// 分享内容（由路由第二段决定：card / pattern / stamp）
    private var card: (title: String, subtitle: String, body: String) {
        switch router.nativeDetail?.id ?? "card" {
        case "pattern":
            return ("缠枝莲纹 · 青花缠枝莲纹瓶",
                    "元代 · 瓷器",
                    "缠枝莲纹以莲花为主题，茎蔓缠绕盘旋，寓意连绵不断、生生不息。我在《一梦千年》里看到的纹样。")
        case "stamp":
            return ("春日雅士 · 印章",
                    "一梦千年",
                    "我在《一梦千年》得了「春日雅士」这枚印章——集诗词、器物、人物于一处。")
        default:
            return ("《江雪》诗境卡",
                    "一梦千年 · 诗境卡工坊",
                    "孤舟蓑笠翁，独钓寒江雪。这是我在《一梦千年》里生成的诗境卡。")
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("分享")
                    .font(.custom("KaitiSC-Bold", size: 26))
                    .foregroundColor(Theme.ink)
                    .padding(.top, 96)

                VStack(alignment: .leading, spacing: 10) {
                    Text(card.title)
                        .font(.custom("KaitiSC-Bold", size: 18))
                        .foregroundColor(Theme.ink)
                    Text(card.subtitle)
                        .font(.custom("SongtiSC-Regular", size: 12))
                        .foregroundColor(Theme.inkMuted)
                    Divider().background(Theme.goldBorder.opacity(0.4))
                    Text(card.body)
                        .font(.custom("SongtiSC-Regular", size: 13.5))
                        .foregroundColor(Theme.inkLight)
                        .lineSpacing(5)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.paperLight))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.goldBorder.opacity(0.45), lineWidth: 0.8))

                Button(action: { showSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up").font(.system(size: 15, weight: .semibold))
                        Text("分享给朋友").font(.custom("SongtiSC-Regular", size: 15))
                    }
                    .foregroundColor(Theme.paperWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(Theme.vermilion))
                }
                .buttonStyle(.plain)

                Text("会拉起系统分享面板，可发到任意已安装的应用。")
                    .font(.custom("SongtiSC-Regular", size: 11.5))
                    .foregroundColor(Theme.inkMuted)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)

            topBar
        }
        .sheet(isPresented: $showSheet) {
            ShareSheet(items: ["\(card.title)\n\(card.body)"])
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

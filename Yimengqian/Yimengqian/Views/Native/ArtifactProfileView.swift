// ArtifactProfileView.swift
//
// 「古物识趣」的八项器物报告 —— 按青花瓷详页的模板排版：
//   器物名称 / 朝代 / 属性 / 简介 / 纹样 / 寓意 / 时代风格 / 纹样图
//
// 与 NativeDetailView 的关系：那是"查库"的静态详情页，数据来自 ContentData；
// 这里是"看图生成"的报告，数据来自 ArtifactProfileBuilder（库 / 在线模型 / 本地推断）。
// 两者共用同一套排版语言（纸色底、朱砂竖条小标题、楷体标题 + 宋体正文），
// 但本页多两样东西：**来源角标**与**把握度**——生成出来的内容必须自报家门。
//
// 为什么不复用 NativeDetailContent：那份结构只有 (标题, 段落数组)，表达不了
// "纹样图来自哪、这条是模型写的还是库里的"这类元信息，硬塞会让详情页变脏。

import SwiftUI

struct ArtifactProfileView: View {
    let profile: ArtifactProfile
    /// 命中参照库时，给一个"打开这件器物的详页"的入口
    var onOpenLibrary: ((String) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if let photo = profile.photo {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 168)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 0.8)
                    )
            }

            section("简介", profile.intro)
            section("纹样 · \(profile.patternName)", profile.patternText)
            section("寓意", profile.symbol)
            section("时代风格", profile.eraStyle)
            patternGallery
            sourceNote
        }
    }

    // MARK: - 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                sourceBadge
                if let certainty = profile.certainty {
                    Text(certaintyText(certainty))
                        .font(.custom("SongtiSC-Regular", size: 10.5))
                        .foregroundColor(Theme.inkMuted)
                }
                Spacer(minLength: 0)
            }

            Text(profile.name)
                .font(.custom("KaitiSC-Bold", size: 24))
                .foregroundColor(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text(profile.dynasty.isEmpty ? "朝代待考" : profile.dynasty)
                Text("·")
                Text(profile.kind.isEmpty ? "属性待辨" : profile.kind)
            }
            .font(.custom("SongtiSC-Regular", size: 12.5))
            .foregroundColor(Theme.inkMuted)
            .fixedSize(horizontal: false, vertical: true)

            if let id = matchedArtifactID, let open = onOpenLibrary {
                Button(action: { open(id) }) {
                    HStack(spacing: 4) {
                        Text("打开这件器物的详页")
                            .font(.custom("SongtiSC-Regular", size: 12))
                        Image(systemName: "chevron.right").font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(Theme.vermilion)
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 2)
            }
        }
    }

    /// 只有"命中参照库"的报告才允许跳详页 —— 模型生成的器物在库里没有对应条目
    private var matchedArtifactID: String? {
        guard profile.source == .library else { return nil }
        return ContentData.artifacts.first(where: { $0.name == profile.name })?.id
    }

    private var sourceBadge: some View {
        let tint: Color = {
            switch profile.source {
            case .library: return Theme.vermilion
            case .remote: return Theme.goldBorder
            case .localInfer: return Theme.inkMuted
            }
        }()
        return Text(profile.source.label)
            .font(.custom("SongtiSC-Regular", size: 10.5))
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Theme.paperLight))
            .overlay(Capsule().strokeBorder(tint.opacity(0.65), lineWidth: 0.8))
    }

    private func certaintyText(_ c: Double) -> String {
        let pct = Int((max(0, min(1, c)) * 100).rounded())
        switch profile.source {
        // 「同款比对」= 与参照库那张图有多像，不是分类把握，措辞上必须区分开
        case .library: return "同款比对 \(pct)%"
        case .remote: return "模型把握 \(pct)%"
        case .localInfer: return ""
        }
    }

    // MARK: - 段落

    @ViewBuilder
    private func section(_ title: String, _ body: String) -> some View {
        if !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Rectangle().fill(Theme.vermilion).frame(width: 3, height: 13)
                    Text(title)
                        .font(.custom("KaitiSC-Bold", size: 15))
                        .foregroundColor(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(body)
                    .font(.custom("SongtiSC-Regular", size: 13.5))
                    .foregroundColor(Theme.inkLight)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 纹样图

    @ViewBuilder
    private var patternGallery: some View {
        if !profile.patternImages.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Rectangle().fill(Theme.vermilion).frame(width: 3, height: 13)
                    Text("纹样图")
                        .font(.custom("KaitiSC-Bold", size: 15))
                        .foregroundColor(Theme.ink)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(profile.patternImages) { item in
                            VStack(alignment: .leading, spacing: 5) {
                                patternCell(item)
                                Text(item.caption)
                                    .font(.custom("SongtiSC-Regular", size: 10))
                                    .foregroundColor(Theme.inkMuted)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(width: patternSide, alignment: .leading)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    /// 纹样图边长（列表里统一，横向滚动）
    private let patternSide: CGFloat = 138

    @ViewBuilder
    private func patternCell(_ item: ArtifactProfile.PatternImage) -> some View {
        if let img = item.image {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: patternSide, height: patternSide)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.goldBorder.opacity(0.45), lineWidth: 0.8)
                )
        } else if let painted = item.painted {
            PatternPainter(name: painted)
                .frame(width: patternSide, height: patternSide)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.goldBorder.opacity(0.45), lineWidth: 0.8)
                )
        }
    }

    // MARK: - 来源说明（最要紧的一块）

    private var sourceNote: some View {
        Text(sourceText)
            .font(.custom("SongtiSC-Regular", size: 10.5))
            .foregroundColor(Theme.inkMuted.opacity(0.95))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
    }

    private var sourceText: String {
        switch profile.source {
        case .library:
            return "来源：本机参照库。这八项内容取自 App 内置的器物条目（真数据），未经过任何模型生成；相似度是本机视觉特征比对的相对排序，不是分类概率。"
        case .remote:
            return "来源：DeepSeek 视觉模型依据你拍的照片生成（在线）。器物命名、断代与纹样释义均可能出现错误，仅供参考；如需采信，请以实物与文献考据为准。"
        case .localInfer:
            let reason = profile.failureNote ?? "未配置 AI 通道"
            return "来源：本地推断（\(reason)）。以下只写照片上能核实的观察，不做断代与纹样题材的推测；配置 AI 通道后可获得完整的命名与释义。"
        }
    }
}

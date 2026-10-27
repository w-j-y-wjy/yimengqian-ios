// IdentityLayer.swift
//
// 身份结果页叠层 —— Phase 3-4：按 4 项偏好（场景 / 内容 / 朝代 / 心境）实时计算结果。
//
// 之前的问题：这一页整块是位图，「江南游学者 / 清雅·善赏·好游 / 你如江南春水…」全部烤死。
// 用户在偏好测试页选了南宋 + 清幽，翻到这页看到的还是同一套文案 —— 问卷白填了。
//
// 做法：不重画整页（风险高），只覆盖三块"随偏好变化"的文字：
//   1) 身份称号（江南游学者 / 汴京倦客 / 西湖散人 …）
//   2) 三个性格标签
//   3) bio 三行
// 每一块的遮罩都按**墨迹 bbox** 实测并四周外扩 4px（跟个人中心那套同一规矩），
// 文字在遮罩内居中，保证中线与位图一致。
//
// 实测（identity-result.png 853×1844，行簇/列簇交叉验证）：
//   称号   x 421..736  y 237..319   （两行高度，第二行是"江南游学者"的第二字部分）
//   标签   x 416..679  y 320..353
//   bio    x 415..745  y 390..556
//   名字   x 136..329  y 600..642

import SwiftUI

struct IdentityLayer: View {
    let screen: ScreenConfig
    let container: CGSize

    @EnvironmentObject private var store: AppStore

    /// 从 4 项偏好推导出的身份画像
    private var profile: IdentityProfile {
        IdentityProfile(
            scene: store.string(StorageKeys.preferenceScene),
            content: store.string(StorageKeys.preferenceContent),
            dynasty: store.string(StorageKeys.preferenceDynasty),
            mood: store.string(StorageKeys.preferenceMood)
        )
    }

    var body: some View {
        let p = profile
        ZStack(alignment: .topLeading) {
            // 1) 身份称号
            patch(
                text: p.title,
                font: .custom("KaitiSC-Bold", size: container.height * 0.0235),
                color: Theme.ink,
                x: 0.4830, y: 0.1265, w: 0.3860, h: 0.0480,
                align: .leading
            )

            // 2) 性格标签（三个词用「·」连起来，与设计稿排版一致）
            patch(
                text: p.tags.joined(separator: " · "),
                font: .custom("SongtiSC-Regular", size: container.height * 0.0118),
                color: Theme.inkLight,
                x: 0.4770, y: 0.1720, w: 0.3300, h: 0.0205,
                align: .leading
            )

            // 3) bio 三行
            patch(
                text: p.bio,
                font: .custom("SongtiSC-Regular", size: container.height * 0.0122),
                color: Theme.inkLight,
                x: 0.4770, y: 0.2095, w: 0.4060, h: 0.0940,
                align: .topLeading,
                lineSpacing: container.height * 0.0088
            )
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
    }

    /// 通用文字补丁：先铺卡片底色遮住位图旧字，再按同一矩形重画。
    /// 底色取 Theme.cardCream（#EDDBC1）—— 这张卡内部多点采样就是这个值。
    @ViewBuilder
    private func patch(text: String,
                       font: Font,
                       color: Color,
                       x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                       align: Alignment,
                       lineSpacing: CGFloat = 0) -> some View {
        ZStack(alignment: align) {
            Rectangle().fill(Theme.cardCream)
            Text(verbatim: text)
                .font(font)
                .foregroundColor(color)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(align == .topLeading ? .leading : .leading)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.6)
        }
        .frame(width: container.width * w, height: container.height * h, alignment: align)
        .offset(x: container.width * x, y: container.height * y)
    }
}

/// 由偏好推导的身份画像 —— 纯规则映射，不是随机，也不是模型。
/// 之所以做成独立类型：未来接 AI（AIBridge）时可以整体替换，UI 不用改。
struct IdentityProfile {
    let scene: String?
    let content: String?
    let dynasty: String?
    let mood: String?

    init(scene: String?, content: String?, dynasty: String?, mood: String?) {
        self.scene = scene
        self.content = content
        // ⚠️ 口径统一（2026-10-27 修）：偏好测试页的朝代热区写的是
        // northernSong / southernSong，而下面这张规则表按 northern / southern 分支。
        // 不归一化的话「北宋」和「南宋」都会落进 default —— 选哪个朝代算出的身份完全一样，
        // 身份详情页还会把 "northernSong" 这种英文键当中文直接显示给用户。
        self.dynasty = Self.normalizeDynasty(dynasty)
        self.mood = mood
    }

    /// 把上游各种朝代写法收敛成规则表认的三种值
    static func normalizeDynasty(_ raw: String?) -> String? {
        guard let raw = raw, !raw.isEmpty else { return nil }
        switch raw {
        case "northernSong", "northern-song", "northernsong", "bei-song":
            return "northern"
        case "southernSong", "southern-song", "southernsong", "nan-song":
            return "southern"
        case "tangSong", "tang-song":
            return "tang"
        default:
            return raw
        }
    }

    /// 朝代键 → 中文名（界面回显用，绝不把英文键甩给用户）
    static func dynastyLabel(_ raw: String?) -> String {
        switch normalizeDynasty(raw) {
        case "tang": return "盛唐"
        case "northern": return "北宋"
        case "southern": return "南宋"
        case let other?: return other
        case nil: return "未选"
        }
    }

    /// 身份称号：朝代 × 心境 决定
    var title: String {
        switch (dynasty, mood) {
        case ("southern", "quiet"): return "西湖散人"
        case ("southern", _): return "临安行客"
        case ("tang", "lively"): return "长安少年"
        case ("tang", _): return "盛唐游侠"
        case ("northern", "quiet"): return "汴京倦客"
        case ("northern", _): return "江南游学者"
        case (_, "quiet"): return "山水闲人"
        case (_, "lively"): return "春风词客"
        default: return "江南游学者"
        }
    }

    /// 三个性格标签：场景 + 内容 + 心境 各出一个
    var tags: [String] {
        var out: [String] = []
        out.append(scene == "marketplace" ? "好游" : "善赏")
        switch content {
        case "painting": out.append("工丹青")
        case "artifact": out.append("好古物")
        default: out.append("耽诗书")
        }
        out.append(mood == "quiet" ? "清雅" : "旷达")
        return out
    }

    /// bio 三行：按朝代与心境组合，句式与设计稿保持一致（你如…／…／以一颗…之心）
    var bio: String {
        let core: String
        switch (dynasty, mood) {
        case ("southern", "quiet"):
            core = "你如西湖暮雪，清冷而自持，\n偏爱寂静处的一盏灯。\n于残山剩水中见天地，以一颗孤高之心，守纸上风骨。"
        case ("southern", _):
            core = "你如江南春雨，绵密而缠绵，\n心怀旧事，向暖而生。\n于词句间寻慰藉，于市井中得清欢，以一颗温柔之心，度过流年。"
        case ("tang", "lively"):
            core = "你如长安烈日，明朗而张扬，\n胸有丘壑，志在四方。\n于边塞诗中闻鼓角，于酒肆间结知己，以一颗炽热之心，赴万里山河。"
        case ("tang", _):
            core = "你如盛唐长风，浩荡而不羁，\n心怀远方，步履不停。\n于山水间访古迹，于金石中辨真章，以一颗阔大之心，纳天地之美。"
        case ("northern", "quiet"):
            core = "你如汴京夜雨，沉静而内敛，\n偏爱书斋的一炉香。\n于旧纸堆中寻逸事，于无声处听清音，以一颗澄明之心，守一室清欢。"
        default:
            core = "你如江南春水，温润而灵动，\n心怀丘壑，向往远方。\n于诗书中寻幽，于山水间得趣，以一颗澄明之心，体味天地之美。"
        }
        return core
    }
}

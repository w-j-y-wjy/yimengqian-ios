// PreferenceTestLayer.swift
//
// 样板叠层 1：入梦偏好测试页（12 热区，其中 10 个是选项）
//
// 解决的问题（报告 P1-1 点名的最大可用性短板）：
// 点「山水 / 市井 / 诗 / 画 / 器物 / 盛唐 / 北宋 / 南宋 / 热闹 / 清幽」时，
// 原来只写 UserDefaults 再弹一句 Toast，界面毫无变化 —— 用户看不到自己选了什么。
//
// 做法：按热区几何把「选中框」画在选项上（不新造坐标，因此不会错位）。
// 四组都选齐后，给底部的「生成我的古典身份」按钮描一圈朱砂边，表示"可以点了"。
// 不写摘要文字：设计稿上没有确定留白，凭空加字只会压到画面。

import SwiftUI

struct PreferenceTestLayer: View {
    let screen: ScreenConfig
    let container: CGSize

    @EnvironmentObject private var selection: SelectionStore

    /// 四个单选组（顺序即题目顺序）
    private static let groups: [String] = [
        StorageKeys.preferenceScene,
        StorageKeys.preferenceContent,
        StorageKeys.preferenceDynasty,
        StorageKeys.preferenceMood,
    ]

    /// 属于这四个组的选项热区
    private var optionHotspots: [Hotspot] {
        screen.hotspots.filter { hotspot in
            guard let key = hotspot.action.storageKey else { return false }
            return Self.groups.contains(key)
        }
    }

    /// 四组是否都已选择
    private var allGroupsChosen: Bool {
        Self.groups.allSatisfy { selection.value($0) != nil }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(optionHotspots) { hotspot in
                if isChosen(hotspot) {
                    ring(for: hotspot)
                }
            }
            if allGroupsChosen, let generate = screen.hotspots.first(where: { $0.id == "generate-btn" }) {
                ring(for: generate, mark: .none)
            }
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
    }

    private func isChosen(_ hotspot: Hotspot) -> Bool {
        guard let key = hotspot.action.storageKey else { return false }
        return selection.isSelected(key, hotspot.action.storageValue ?? "true")
    }

    private func ring(for hotspot: Hotspot, mark: SelectionMark = .check) -> some View {
        let frame = hotspot.rect(in: container)
        return SelectionRing(mark: mark)
            .frame(width: frame.width, height: frame.height)
            .offset(x: frame.minX, y: frame.minY)
    }
}

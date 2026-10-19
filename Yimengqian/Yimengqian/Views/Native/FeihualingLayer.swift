// FeihualingLayer.swift
//
// 样板叠层 2：飞花令挑战页（8 热区，其中 4 个选项 + 1 个提交）
//
// 解决的问题：
// 1) 4 个选项点下去没有任何选中反馈；
// 2) 答错时 ActionExecutor 只弹一句提示，既不清旧答案、也不在选项上标错，
//    用户不知道"我选的那句为什么不对"；
// 3) 现场演示时，评委看到的只是"点了没反应"。
//
// 做法：
// - 已选项 → 朱砂描边 + ✓；
// - 答错 → 同一选项改成墨黑描边 + ✕（刻意不用红色：朱砂是本项目的品牌强调色，
//   用它标错会和"已选"混淆；墨黑+叉在米白底上足够清楚且不刺眼）；
// - 用户重新选择即清除答错态（SelectionStore.note 里处理）。
//
// 注意：本层只做**视觉反馈**，判题逻辑仍在 ActionExecutor.checkAnswer；
// 判题规则本身的升级（令字/韵脚/多答案）是 Phase 5-2 的事。

import SwiftUI

struct FeihualingLayer: View {
    let screen: ScreenConfig
    let container: CGSize

    @EnvironmentObject private var selection: SelectionStore

    /// 4 个答案选项（都以 feihualingAnswer 为存储键）
    private var answerHotspots: [Hotspot] {
        screen.hotspots.filter { $0.action.storageKey == StorageKeys.feihualingAnswer }
    }

    private var chosenValue: String? {
        selection.value(StorageKeys.feihualingAnswer)
    }

    private var isWrong: Bool {
        selection.isWrongAnswer(on: screen.id)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(answerHotspots) { hotspot in
                if let value = hotspot.action.storageValue, value == chosenValue {
                    ring(
                        for: hotspot,
                        color: isWrong ? Theme.ink : Theme.vermilion,
                        mark: isWrong ? .cross : .check
                    )
                }
            }
        }
        .frame(width: container.width, height: container.height, alignment: .topLeading)
        // 答错态只对本屏当次有效：离开再回来不该还挂着上一轮的 ✕
        .onAppear { selection.clearWrongAnswer() }
    }

    private func ring(for hotspot: Hotspot, color: Color, mark: SelectionMark) -> some View {
        let frame = hotspot.rect(in: container)
        return SelectionRing(color: color, mark: mark)
            .frame(width: frame.width, height: frame.height)
            .offset(x: frame.minX, y: frame.minY)
    }
}

// NativeFavoriteSlotView.swift
//
// 收藏页的卡片是「动态数据」填进「静态热区」：9 个 item-* 热区的位置固定，
// 里面显示什么由当前筛选结果决定。所以点击时不能写死跳某个 id，
// 必须运行时按「第几格 + 当前筛选」取实际条目，再分发到对应详情。
//
// 这个包装视图做的就是这件事：拿到 slot 序号 → 问 AppStore 取条目 → 换成
// 对应的 NativeDetail 再交给 NativeDetailView 渲染。取不到（例如空槽）就直接关闭，
// 绝不显示空白页。

import SwiftUI

struct NativeFavoriteSlotView: View {
    let index: Int

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var selection: SelectionStore

    private var filter: String? { selection.value(StorageKeys.favoriteFilter) }

    /// 已获得的印章 id —— 印章详情要按真实状态显示「已获得 / 尚未获得」
    private var obtainedStamps: Set<String> {
        Set(store.snapshot.stamps.filter { $0.obtained }.map { $0.id })
    }

    /// 收藏页当前筛选下的第 index 个条目
    private var item: FavoriteItem? {
        let items = store.collection(filter: filter)
        return index < items.count ? items[index] : nil
    }

    private var target: NativeDetail? {
        guard let item = item else { return nil }
        switch item.type {
        case .poem:
            // 江雪意象（孤舟/寒江/蓑笠翁/飞雪）也是按 .poem 存进收藏的，
            // 但它们不在 allPoems() 里 —— 直接当 .poem 解析会渲染成"这一格现在是空的"。
            // 先按意象查一次，命中就进意象详情。
            if ContentData.jiangxueImagery.contains(where: { $0.id == item.itemId }) {
                return .imagery(item.itemId)
            }
            return .poem(item.itemId)
        case .artifact: return .artifact(item.itemId)
        case .character: return .character(item.itemId)
        case .letter: return .letter(item.itemId)
        case .stamp: return .stamp(item.itemId)
        }
    }

    var body: some View {
        Group {
            if let detail = target,
               let content = NativeDetailContent.resolve(detail, obtainedStamps: obtainedStamps) {
                NativeDetailView(detail: detail, content: content)
            } else {
                // 空槽 / 条目已不存在：给一句明确说明并可直接返回，而不是白屏
                VStack(spacing: 14) {
                    Text("这一格现在是空的")
                        .font(.custom("KaitiSC-Bold", size: 18))
                        .foregroundColor(Theme.ink)
                    Text("该收藏可能已被取消，或当前筛选下没有这么多条目。")
                        .font(.custom("SongtiSC-Regular", size: 13))
                        .foregroundColor(Theme.inkMuted)
                    Button(action: { router.closeNative() }) {
                        Text("返回收藏")
                            .font(.custom("SongtiSC-Regular", size: 14))
                            .foregroundColor(Theme.paperWarm)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Theme.vermilion))
                    }
                    .buttonStyle(PressableStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.paperWarm.ignoresSafeArea())
            }
        }
    }
}

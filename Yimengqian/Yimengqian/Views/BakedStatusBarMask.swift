// BakedStatusBarMask.swift
//
// 25 张设计稿顶部都烤死了一条假的「9:41 + 信号 + 电量」，而 App 又把系统状态栏隐藏了。
// 结果：真机下午三点，App 里永远九点四十一；而且 22 个原生页根本没有状态栏，
// 位图屏有假表、原生页没表，来回一跳就露馅。
//
// 处理方式选中间那条：**保留全屏沉浸（继续隐藏系统状态栏），把烤死的假表擦掉**。
// 为什么不让系统状态栏显示：它会画在安全区顶部（0…59pt），而设计稿里返回键/标题
// 就在 y≈110–185px，遮住烤死那条需要盖到 ~128px 才能盖住系统栏覆盖区域，
// 会切掉标题与返回键。擦掉假表、保留整块画面，是最不破坏设计的做法。
//
// 颜色不是写死的 25 个常量，也不是统一用 Theme.paper：每张设计稿顶部都有一条
// 纸色/山纹渐变，统一色会露出明显的横条接缝。这里按屏幕各采一次纸色，
// 表里 25 组数字由 Content/Screens/*.png 的第 36–64 行（剔除深色文字后）取中位数得到。

import SwiftUI

struct BakedStatusBarMask: View {
    let screenID: String
    let container: CGSize

    /// 每屏顶部的纸色（852×1846 设计稿第 36–64 行的纸色中位数）
    private static let paper: [String: (Int, Int, Int)] = [
        "activities-home": (236, 217, 190),
        "artifact-home": (232, 211, 182),
        "artifact-pattern": (234, 212, 181),
        "artifact-result": (220, 197, 163),
        "bianjing": (237, 220, 193),
        "dreambook": (230, 208, 176),
        "dynasties": (232, 208, 174),
        "favorites": (233, 210, 178),
        "feihualing-challenge": (234, 215, 185),
        "home": (233, 211, 179),
        "identity-result": (234, 215, 187),
        "jiangxue-analysis": (232, 212, 183),
        "jiangxue-imagery": (233, 212, 182),
        "jiangxue-scene": (240, 222, 196),
        "onboarding-intro": (230, 207, 175),
        "poetry-card": (232, 211, 180),
        "poetry-home": (233, 208, 173),
        "preference-test": (238, 221, 194),
        "profile": (232, 210, 178),
        "splash": (237, 220, 192),
        "stamp-reward": (231, 207, 172),
        "sushi": (234, 216, 190),
        "task-reward": (232, 209, 175),
        "teahouse-dialogue": (234, 216, 189),
        "teahouse": (235, 214, 184),
    ]

    private var fill: Color {
        let c = Self.paper[screenID] ?? (235, 214, 184)
        return Color(red: Double(c.0) / 255, green: Double(c.1) / 255, blue: Double(c.2) / 255)
    }

    var body: some View {
        // 只盖假表那一条：y 28…72（烤死内容实测在 36…63）。
        // 用 top 对齐 + offset，避免手算中心点（第一版就是算错了中心，条子跑到了屏幕中间）。
        ZStack(alignment: .top) {
            Rectangle()
                .fill(fill)
                .frame(width: container.width,
                       height: container.height * (72.0 / 1846 - 28.0 / 1846))
                .offset(y: container.height * (28.0 / 1846))
        }
        .frame(width: container.width, height: container.height, alignment: .top)
        .allowsHitTesting(false)
    }
}

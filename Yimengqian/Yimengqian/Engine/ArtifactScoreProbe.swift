// ArtifactScoreProbe.swift
//
// 本机比对的自检探针 —— 把「一组固定图片 × 4 件参照器物」的分数矩阵打出来。
//
// 为什么需要它（这是本轮最重要的一课）：
// 原来的 `confidentThreshold = 0.45` 是拍脑袋定的，没人量过。CI 里用一张苏轼画像测，
// 它以 93% 的相似度"命中"青花缠枝莲纹瓶 —— 因为参照库 4 件全是纸本国风插画，
// Vision 特征指纹认的是**画风**，不是**器物**。这种错误光靠看代码发现不了，
// 必须把分数摊开看：同一件器物的自比对是多少、干扰图是多少、两者差多少。
//
// 用法（只给 CI 与本地自检，正式使用不会触发）：
//   xcrun simctl launch <udid> com.yimeng.qiannian -dumpScoreMatrix 1
//   然后读 <app 容器>/Documents/score-matrix.txt
//
// 它不改变任何线上行为：只读、只写一个文本文件、不联网。

import Foundation
import UIKit

enum ArtifactScoreProbe {
    static var isRequested: Bool { UserDefaults.standard.bool(forKey: "dumpScoreMatrix") }

    /// 干扰图：人物像、山水诗意图、朝代图、活动图、足迹图 —— 全都"不是参照库里的器物"，
    /// 正确答案是「不该命中」。它们代表用户可能随手拍到的杂图。
    private static let distractors: [String] = [
        "ArtApp/character-sushi.jpg",
        "ArtApp/character-libai.jpg",
        "ArtApp/character-liqingzhao.jpg",
        "ArtApp/poem-niao-ming-jian.jpg",
        "ArtApp/poem-jing-ye-si.jpg",
        "ArtApp/poem-chun-ri.jpg",
        "ArtApp/dynasty-tang.jpg",
        "ArtApp/activity-feihualing.jpg",
        "ArtApp/imagery-fei-xue.jpg",
        "ArtApp/footprint-bianjing.jpg",
    ]

    static func runIfRequested() {
        guard isRequested else { return }
        DispatchQueue.global(qos: .utility).async {
            var lines: [String] = []
            lines.append("# 本机比对分数矩阵")
            lines.append("# 每行：查询图 → top1 / top2 / 差值(margin) / 现阈值(>=0.45 且 margin>=0.05)是否通过")
            lines.append("")

            var queries: [(name: String, image: UIImage, expectSelf: Bool)] = []
            for artifact in ContentData.artifacts {
                guard let img = AssetLoader.image(artifact.image) else { continue }
                queries.append((name: "REF:" + artifact.name + "(" + artifact.id + ")", image: img, expectSelf: true))
            }
            for path in distractors {
                guard let img = AssetLoader.image(path) else { continue }
                queries.append((name: "DIST:" + path.replacingOccurrences(of: "ArtApp/", with: ""), image: img, expectSelf: false))
            }

            for query in queries {
                let scores = ArtifactRecognizer.shared.probeDetails(query.image)
                guard let top = scores.first else {
                    lines.append("\(query.name)  → 无参照可用")
                    continue
                }
                let second = scores.count > 1 ? scores[1] : nil
                let margin = top.score - (second?.score ?? 0)
                let pass = top.score >= ArtifactRecognizer.confidentThreshold
                    && margin >= ArtifactRecognizer.marginThreshold
                let verdict: String = query.expectSelf
                    ? (pass ? "通过(应通过)" : "未通过(应通过)")
                    : (pass ? "通过(不应通过·误判)" : "未通过(正确)")
                lines.append(String(format: "%@ → %@ %.3f(structure %.2f / color %.2f) / %@ %.3f / margin %.3f → %@",
                                    query.name,
                                    top.name, top.score, top.structure, top.color,
                                    second?.name ?? "-", second?.score ?? 0,
                                    margin, verdict))
                // 附完整排序，方便看"所有参照都 0.9"这种塌缩现象
                let detail = scores.map { String(format: "%.3f %@", $0.score, $0.name) }.joined(separator: " | ")
                lines.append("    全部： " + detail)
            }

            let text = lines.joined(separator: "\n") + "\n"
            print(text)
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let url = dir.appendingPathComponent("score-matrix.txt")
                try? text.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

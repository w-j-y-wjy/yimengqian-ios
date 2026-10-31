// BackupService.swift
//
// 旅程数据备份 —— 导出 / 导入一个 JSON 文件。
//
// 为什么要有：App 目前把全部进度存在 UserDefaults 里（`AppSnapshot`），
// 换机、重装、或者学生答辩后想保留演示数据，都没有任何出口。
// 「能带走自己的数据」是"软件"和"演示稿"的分界线之一，这条补上之后才算闭环。
//
// 只导快照，不导离散键：快照是唯一事实源（收藏/印章/进度/偏好都在里面），
// 离散键只是历史镜像，导过去反而可能与快照冲突。
// 格式就是 `AppSnapshot` 的 Codable 表示，带一个 version 字段方便以后迁移。

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// 备份文件（供 `.fileExporter` 使用）
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

enum BackupService {
    /// 备份文件里额外记录格式版本与导出时间，便于以后做迁移或"从旧版恢复"。
    struct Envelope: Codable {
        var formatVersion: Int
        var exportedAt: String
        var snapshot: AppSnapshot
    }

    static let currentFormatVersion = 1

    static func defaultFilename(date: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyyMMdd-HHmm"
        return "一梦千年备份-\(fmt.string(from: date))"
    }

    static func exportData(_ snapshot: AppSnapshot) throws -> Data {
        let env = Envelope(formatVersion: currentFormatVersion,
                           exportedAt: ISO8601DateFormatter().string(from: Date()),
                           snapshot: snapshot)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(env)
    }

    /// 解析备份。兼容两种历史写法：带 envelope 的，和"直接就是快照"的裸 JSON。
    static func decodeSnapshot(from data: Data) throws -> AppSnapshot {
        let decoder = JSONDecoder()
        if let env = try? decoder.decode(Envelope.self, from: data) {
            return env.snapshot
        }
        return try decoder.decode(AppSnapshot.self, from: data)
    }

    /// 给界面用的摘要：导出了什么、恢复回来有多少东西
    static func summary(_ s: AppSnapshot) -> String {
        "收藏 \(s.favorites.count) 项 · 印章 \(s.stamps.filter { $0.obtained }.count) 枚 · 诗境卡 \(s.generatedCards.count) 张"
    }
}

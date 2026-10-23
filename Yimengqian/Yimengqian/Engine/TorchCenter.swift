// TorchCenter.swift
//
// 闪光灯 —— 器物识别页那颗「闪光灯」热区原本只弹一句「闪光灯模拟」，
// 是典型的占位式假反馈：图标画着闪光灯，点下去什么都不发生。
//
// 这次接真的 AVCaptureDevice.torchMode：
// - 有后置摄像头且支持 torch → 真的开/关，并回读实际状态（不是你点一下就假设它开了）；
// - 模拟器 / 无摄像头 / 不支持 → 明确告知「这台设备没有闪光灯」，而不是继续撒谎说"模拟"。
//
// 为什么不做「自动 / 常亮 / 关闭」三态：设计稿上只有一颗按钮，
// 多态会引入一个位图上根本不存在的 UI，反而违背"像素对齐"的约束。

import AVFoundation
import Combine

final class TorchCenter: ObservableObject {
    static let shared = TorchCenter()

    /// 当前是否真的亮着（以设备回读为准，不是以点击次数为准）
    @Published private(set) var isOn = false

    /// 设备到底有没有可用闪光灯 —— 决定按钮该"切换"还是该"说明原因"
    var isAvailable: Bool {
        guard let device = Self.backCamera() else { return false }
        return device.hasTorch && device.isTorchAvailable
    }

    private init() {}

    /// 切换闪光灯。返回 nil 表示成功（状态已变），返回字符串表示失败原因（直接弹给用户）。
    @discardableResult
    func toggle() -> String? {
        guard let device = Self.backCamera() else {
            return "这台设备没有摄像头，无法使用闪光灯"
        }
        guard device.hasTorch, device.isTorchAvailable else {
            return "这台设备的闪光灯不可用"
        }

        let turningOn = !isOn
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if turningOn {
                // 0.6 是常用亮度：全功率(1.0)拍近物容易过曝，且发热明显
                try device.setTorchModeOn(level: 0.6)
            } else {
                device.torchMode = .off
            }
            // 回读真实状态，而不是拿我们以为的值去更新 UI
            isOn = device.torchMode == .on
            return nil
        } catch {
            // 常见原因：相机被别的 App 占用、或设备过热保护
            isOn = device.torchMode == .on
            return "闪光灯切换失败：\(error.localizedDescription)"
        }
    }

    /// 离开器物页时务必关掉 —— 否则用户切到别的屏，手电筒还在亮。
    func turnOffIfNeeded() {
        guard isOn, let device = Self.backCamera(), device.hasTorch else {
            isOn = false
            return
        }
        if (try? device.lockForConfiguration()) != nil {
            device.torchMode = .off
            device.unlockForConfiguration()
        }
        isOn = false
    }

    private static func backCamera() -> AVCaptureDevice? {
        // 先找广角主摄（builtInWideAngleCamera），退化到 .builtInDualCamera
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video)
    }
}

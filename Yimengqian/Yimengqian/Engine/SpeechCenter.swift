// SpeechCenter.swift
//
// 朗读 —— 之前全仓没有任何音频实现，但四个喇叭键的提示语都说「正在播放」，
// 这是纯假反馈。改用系统自带的 AVSpeechSynthesizer：不需要任何音频素材，
// 也不需要网络，直接把文本念出来，而且能在真机上听到。
//
// 为什么不做「播放中/停止」两态：喇叭键在热区配置里是单次动作（speakText），
// 再点一次就重新朗读一次 —— 这符合「再听一遍」的直觉，也避免引入无法测试的计时状态。

import AVFoundation
import Foundation

final class SpeechCenter: NSObject, ObservableObject {
    static let shared = SpeechCenter()

    private let synthesizer = AVSpeechSynthesizer()

    /// 当前是否在朗读（供 UI 可选地显示状态）
    @Published private(set) var isSpeaking = false

    private override init() {
        super.init()
        // 静音键打开时也要能听见朗读：AVSpeechSynthesizer 默认遵守静音开关，
        // 这里用 playback 类别让朗读在静音下仍然发声（与系统「朗读屏幕」一致）。
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // 会话配置失败不影响朗读本身，最坏情况是静音键下听不到
        }
        // 用 delegate 而不是通知：Swift 侧没有 AVSpeechSynthesizer.didFinishSpeechUtteranceNotification
        // 这个静态成员（CI 第一次就报 no member），delegate 是稳定可用的公开 API。
        synthesizer.delegate = self
    }

    /// 朗读一段中文文本。空文本直接忽略。
    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 正在念旧的（例如连点两个喇叭）先停掉，避免两句重叠
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        // 略慢于默认，古诗词念得清楚一些；音调略低更接近「讲述」
        utterance.rate = 0.46
        utterance.pitchMultiplier = 0.95
        utterance.postUtteranceDelay = 0.1

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
}

extension SpeechCenter: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}

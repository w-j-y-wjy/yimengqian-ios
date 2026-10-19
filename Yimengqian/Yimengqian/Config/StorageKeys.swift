// 本文件与 app-project/src/config/appStorageKeys.ts 一一对应（忠实移植）。
// 来源：src/config/appStorageKeys.ts —— APP_STORAGE_KEYS（共 39 个键，含快照键）。
import Foundation

/// 与 appStorageKeys.ts 一一对应的存储键
enum StorageKeys {
    // Onboarding
    static let onboardingComplete = "onboardingComplete"
    static let onboardingSkipped = "onboardingSkipped"
    static let preferenceScene = "preferenceScene"
    static let preferenceContent = "preferenceContent"
    static let preferenceDynasty = "preferenceDynasty"
    static let preferenceMood = "preferenceMood"
    // Dialogue
    static let dialogueTopic = "dialogueTopic"
    static let teaDialogueCompleted = "teaDialogueCompleted"
    static let teaRewardClaimed = "teaRewardClaimed"
    static let cultureValue = "cultureValue"
    static let stampDongpo = "stampDongpo"
    static let sushiLetter = "sushiLetter"
    /// 苏轼页「语音」热区会写入该键。补登记原因：旧版本只在 ScreensConfig 里写、
    /// 没在 StorageKeys 声明，导致它不在 `all` 数组里 → resetAll 清不掉。
    static let sushiVoicePlaying = "sushiVoicePlaying"
    static let bianjingProgress = "bianjingProgress"
    // Poetry
    static let jiangxuePlaying = "jiangxuePlaying"
    static let jiangxueVideoPlaying = "jiangxueVideoPlaying"
    static let jiangxueStyle = "jiangxueStyle"
    static let favoriteJiangxue = "favoriteJiangxue"
    static let selectedImagery = "selectedImagery"
    static let favoriteImageryLoneBoat = "favoriteImageryLoneBoat"
    static let poetryCardStyle = "poetryCardStyle"
    static let poetryCardLayout = "poetryCardLayout"
    static let poetryCardSeal = "poetryCardSeal"
    static let poetryCardSaved = "poetryCardSaved"
    static let poetryCardCount = "poetryCardCount"
    static let jiangxueCardCreated = "jiangxueCardCreated"
    // Artifact
    static let favoriteArtifact = "favoriteArtifact"
    static let favoriteArtifactPattern = "favoriteArtifactPattern"
    static let artifactCompleted = "artifactCompleted"
    // Activities
    static let feihualingAnswer = "feihualingAnswer"
    static let feihualingCompleted = "feihualingCompleted"
    static let springStampClaimed = "springStampClaimed"
    static let petalCount = "petalCount"
    static let stampSpring = "stampSpring"
    static let yaValue = "yaValue"
    // Favorites / Profile
    static let favoriteFilter = "favoriteFilter"
    static let dreambookOpened = "dreambookOpened"
    static let currentCity = "currentCity"
    static let initialStamp = "initialStamp"
    // Misc
    static let snapshotKey = "yimeng-qiannian-state"

    /// 全部键（用于 resetAll）——snapshotKey 除外，由 AppStore.resetAll 单独移除
    static let all: [String] = [
        // Onboarding
        onboardingComplete,
        onboardingSkipped,
        preferenceScene,
        preferenceContent,
        preferenceDynasty,
        preferenceMood,
        // Dialogue
        dialogueTopic,
        teaDialogueCompleted,
        teaRewardClaimed,
        cultureValue,
        stampDongpo,
        sushiLetter,
        sushiVoicePlaying,
        bianjingProgress,
        // Poetry
        jiangxuePlaying,
        jiangxueVideoPlaying,
        jiangxueStyle,
        favoriteJiangxue,
        selectedImagery,
        favoriteImageryLoneBoat,
        poetryCardStyle,
        poetryCardLayout,
        poetryCardSeal,
        poetryCardSaved,
        poetryCardCount,
        jiangxueCardCreated,
        // Artifact
        favoriteArtifact,
        favoriteArtifactPattern,
        artifactCompleted,
        // Activities
        feihualingAnswer,
        feihualingCompleted,
        springStampClaimed,
        petalCount,
        stampSpring,
        yaValue,
        // Favorites / Profile
        favoriteFilter,
        dreambookOpened,
        currentCity,
        initialStamp,
    ]
}

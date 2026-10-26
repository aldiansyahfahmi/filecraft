import AppKit

public final class SoundManager: @unchecked Sendable {
    public static let shared = SoundManager()

    private init() {}

    public func playPetalHover() {
        // Subtle haptic tick
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .now
        )
    }

    public func playActionComplete() {
        // Strong haptic confirmation & system audio feedback
        NSHapticFeedbackManager.defaultPerformer.perform(
            .levelChange,
            performanceTime: .now
        )
        NSSound(named: "Pop")?.play()
    }

    public func playDropSuccess() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .levelChange,
            performanceTime: .now
        )
        NSSound(named: "Tink")?.play()
    }
}

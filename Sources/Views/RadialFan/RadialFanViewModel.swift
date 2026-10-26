import SwiftUI
import Foundation

@MainActor
public final class RadialFanViewModel: ObservableObject {
    @Published public var hoveredAction: RadialPetalAction? = nil
    @Published public var fanMode: ConversionFanMode = .conversions
    @Published public var sourceURLs: [URL] = []

    public var activeActions: [RadialPetalAction] {
        RadialPetalAction.actions(for: sourceURLs, mode: fanMode)
    }

    public var defaultCenterTitle: String {
        if let first = sourceURLs.first {
            let ext = first.pathExtension.uppercased()
            return ext.isEmpty ? "FILE" : ext
        }
        return "FileCraft"
    }

    public init(sourceURLs: [URL] = [], fanMode: ConversionFanMode = .conversions) {
        self.sourceURLs = sourceURLs
        self.fanMode = fanMode
    }

    public func switchMode(_ newMode: ConversionFanMode) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
            self.fanMode = newMode
            self.hoveredAction = nil
        }
        SoundManager.shared.playPetalHover()
    }
}

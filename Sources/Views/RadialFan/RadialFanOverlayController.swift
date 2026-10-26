import AppKit
import SwiftUI

@MainActor
public final class RadialFanOverlayController {
    public static let shared = RadialFanOverlayController()

    private var panel: NSPanel?
    private var currentViewModel: RadialFanViewModel?

    private init() {}

    public func show(
        at screenPoint: CGPoint? = nil,
        urls: [URL] = [],
        initialMode: ConversionFanMode = .conversions,
        onSelectAction: @escaping @MainActor (RadialPetalAction, [URL]) -> Void
    ) {
        close()

        let mousePos = screenPoint ?? NSEvent.mouseLocation
        let panelSize = CGSize(width: 360, height: 380)
        let wheelCenter = ConversionOverlayView.wheelCenterInAppKit

        // Center overlay around mouse point so the wheel center aligns precisely with the cursor
        let origin = CGPoint(
            x: mousePos.x - wheelCenter.x,
            y: mousePos.y - wheelCenter.y
        )

        let overlayPanel = NSPanel(
            contentRect: NSRect(origin: origin, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        overlayPanel.isOpaque = false
        overlayPanel.backgroundColor = .clear
        overlayPanel.hasShadow = false
        // Match decompiled level 0x65 (popUpMenu / 101) to ensure top drag destination
        overlayPanel.level = NSWindow.Level(rawValue: 101)
        overlayPanel.hidesOnDeactivate = false
        overlayPanel.isReleasedWhenClosed = false
        overlayPanel.becomesKeyOnlyIfNeeded = false
        overlayPanel.ignoresMouseEvents = false
        overlayPanel.animationBehavior = .none
        overlayPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        overlayPanel.registerForDraggedTypes([.fileURL])

        let model = RadialFanViewModel(sourceURLs: urls, fanMode: initialMode)
        self.currentViewModel = model

        let overlayView = ConversionOverlayView(frame: NSRect(origin: .zero, size: panelSize), model: model)

        overlayView.onSelectAction = { [weak self] action, selectedURLs in
            self?.close()
            onSelectAction(action, selectedURLs)
        }

        overlayView.onDismiss = { [weak self] in
            self?.close()
        }

        overlayPanel.contentView = overlayView
        overlayPanel.makeKeyAndOrderFront(nil)
        self.panel = overlayPanel
    }

    public func switchMode(to mode: ConversionFanMode) {
        currentViewModel?.switchMode(mode)
    }

    public func close() {
        panel?.orderOut(nil)
        panel = nil
        currentViewModel = nil
    }

    public var isVisible: Bool {
        panel?.isVisible ?? false
    }
}

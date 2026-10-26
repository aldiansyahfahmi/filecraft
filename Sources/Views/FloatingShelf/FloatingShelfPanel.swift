import AppKit
import SwiftUI

@MainActor
public final class FloatingShelfPanel {
    public static let shared = FloatingShelfPanel()

    public let model = FloatingShelfModel()
    private var panel: NSPanel?

    public var onTriggerTool: (@MainActor (RadialPetalAction, [URL]) -> Void)?

    private init() {}

    public func show(near point: CGPoint? = nil) {
        if let existing = panel {
            existing.orderFront(nil)
            return
        }

        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1440, height: 900)
        let screenOrigin = NSScreen.main?.visibleFrame.origin ?? .zero

        // Default to right edge of main display
        let panelWidth: CGFloat = 290
        let panelHeight: CGFloat = 380

        let posX = point?.x ?? (screenOrigin.x + screenSize.width - panelWidth - 24)
        let posY = point?.y ?? (screenOrigin.y + (screenSize.height / 2.0) - (panelHeight / 2.0))

        let rect = NSRect(x: posX, y: posY, width: panelWidth, height: panelHeight)

        let shelfPanel = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        shelfPanel.isOpaque = false
        shelfPanel.backgroundColor = .clear
        shelfPanel.hasShadow = false
        shelfPanel.level = .floating
        shelfPanel.isMovableByWindowBackground = true
        shelfPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = FloatingShelfView(
            groupModel: model,
            onTriggerAction: { [weak self] action, urls in
                self?.onTriggerTool?(action, urls)
            },
            onClose: { [weak self] in
                self?.close()
            }
        )

        shelfPanel.contentView = NSHostingView(rootView: view)
        shelfPanel.makeKeyAndOrderFront(nil)
        self.panel = shelfPanel
    }

    public func toggle() {
        if panel != nil {
            close()
        } else {
            show()
        }
    }

    public func addFiles(_ urls: [URL]) {
        for url in urls {
            model.addFile(url: url)
        }
        show()
    }

    public func close() {
        panel?.orderOut(nil)
        panel = nil
    }
}

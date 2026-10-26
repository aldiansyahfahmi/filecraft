import AppKit
import SwiftUI

public final class ConversionOverlayView: NSView {
    public let model: RadialFanViewModel
    public var onSelectAction: ((RadialPetalAction, [URL]) -> Void)?
    public var onDismiss: (() -> Void)?

    private var hostingView: NSHostingView<RadialFanWheelView>?
    private var currentHoveredAction: RadialPetalAction? = nil
    private var isHoveringCenter: Bool = false
    private var lastActiveAction: RadialPetalAction? = nil

    public static let wheelCenterInAppKit = CGPoint(x: 180.0, y: 186.0)

    public init(frame frameRect: NSRect, model: RadialFanViewModel) {
        self.model = model
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        setupSwiftUIHosting()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSwiftUIHosting() {
        let rootView = RadialFanWheelView(
            model: model,
            onSelectAction: { [weak self] action, urls in
                self?.onSelectAction?(action, urls)
            },
            onDismiss: { [weak self] in
                self?.onDismiss?()
            }
        )

        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = bounds
        hosting.autoresizingMask = [.width, .height]
        addSubview(hosting)
        self.hostingView = hosting
    }

    // MARK: - NSDraggingDestination Implementation

    public override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        updateDragHover(at: sender.draggingLocation)
        return .copy
    }

    public override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        updateDragHover(at: sender.draggingLocation)
        return .copy
    }

    public override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        self.model.hoveredAction = nil
        self.currentHoveredAction = nil
        self.isHoveringCenter = false
    }

    public override func prepareForDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        return true
    }

    public override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let (dropAction, isCenter) = hitTestWheel(at: sender.draggingLocation)
        let resolvedAction = dropAction ?? self.currentHoveredAction ?? self.lastActiveAction

        let pboard = sender.draggingPasteboard
        var urls = (pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL]) ?? []
        if urls.isEmpty {
            urls = model.sourceURLs
        }

        NSLog("[FileCraft] performDragOperation: dropAction=\(String(describing: dropAction)), resolvedAction=\(String(describing: resolvedAction)), isCenter=\(isCenter), urlsCount=\(urls.count)")

        if let action = resolvedAction {
            SoundManager.shared.playActionComplete()
            onSelectAction?(action, urls)
            return true
        } else if isCenter || self.isHoveringCenter {
            SoundManager.shared.playActionComplete()
            onSelectAction?(.floatShelf, urls)
            return true
        } else {
            // Dropped outside all petals and outside center - cancel cleanly
            onDismiss?()
            return false
        }
    }

    // MARK: - Hit-Testing & Hover Feedback

    private func updateDragHover(at windowPoint: NSPoint) {
        let (action, isCenter) = hitTestWheel(at: windowPoint)
        self.currentHoveredAction = action
        self.isHoveringCenter = isCenter
        if let action = action {
            self.lastActiveAction = action
        }

        // Synchronously update model for responsive SwiftUI animations
        if self.model.hoveredAction != action {
            self.model.hoveredAction = action
            if action != nil {
                SoundManager.shared.playPetalHover()
            }
        }
    }

    private func hitTestWheel(at windowPoint: NSPoint) -> (action: RadialPetalAction?, isCenter: Bool) {
        let localPoint = convert(windowPoint, from: nil)
        let center = Self.wheelCenterInAppKit
        let dx = localPoint.x - center.x
        // In AppKit, localPoint.y is from bottom; SVG/SwiftUI coordinate system has Y increasing downwards
        let dy = -(localPoint.y - center.y)
        let dist = hypot(dx, dy)

        // 1. Center hole / capsule (inner radius 48.64 pt)
        if dist < FileCraftGeometry.inner * 0.95 {
            return (nil, true)
        }

        // 2. Beyond outer edge of the wheel (backdrop radius is 125.92 pt)
        if dist > (FileCraftGeometry.backdrop + 35.0) {
            return (nil, false)
        }

        // 3. Petal ring hit testing using exact FileCraft sector geometry
        let actions = model.activeActions
        let count = actions.count
        guard count > 0 else { return (nil, false) }

        if let index = FileCraftGeometry.hitTest(x: dx, y: dy, total: count), index < count {
            return (actions[index], false)
        }

        // Seamless gap fallback: avoid dead-zones when dragging across the 4pt gap between petals
        let angle = atan2(-dy, dx)
        let step = CGFloat.pi * 2.0 / CGFloat(count)
        let rawDiff = (FileCraftGeometry.angleFor(index: 0, total: count) - angle).truncatingRemainder(dividingBy: .pi * 2.0)
        let normalizedDiff = (rawDiff + .pi * 2.0).truncatingRemainder(dividingBy: .pi * 2.0)
        let fallbackIndex = Int(round(normalizedDiff / step)) % count

        if fallbackIndex < count {
            return (actions[fallbackIndex], false)
        }

        return (nil, false)
    }
}

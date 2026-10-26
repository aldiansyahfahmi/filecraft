import AppKit
import Foundation

public final class DragGestureMonitor: @unchecked Sendable {
    public static let shared = DragGestureMonitor()

    private var timerSource: (any DispatchSourceTimer)? = nil
    private let pasteboard = NSPasteboard(name: .drag)
    private var lastChangeCount: Int = 0
    private var isDraggingFiles: Bool = false
    private var isOverlayShownForCurrentDrag: Bool = false
    private var currentMode: ConversionFanMode = .conversions

    public var onDragDetected: (([URL], CGPoint, ConversionFanMode) -> Void)? = nil
    public var onModeSwitched: ((ConversionFanMode) -> Void)? = nil
    public var onEscapeDismiss: (() -> Void)? = nil
    public var isEnabled: Bool = true

    private init() {
        lastChangeCount = pasteboard.changeCount
    }

    public func startMonitoring() {
        guard timerSource == nil else { return }

        let queue = DispatchQueue.main
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(30))

        timer.setEventHandler { [weak self] in
            self?.checkDragState()
        }

        timer.resume()
        timerSource = timer
        NSLog("[FileCraft] Drag shortcut monitor started")
    }

    public func stopMonitoring() {
        timerSource?.cancel()
        timerSource = nil
    }

    private func checkDragState() {
        guard isEnabled else { return }

        // 1. Check if Escape key (keycode 0x35) is pressed to cancel
        let isEscapeDown = CGEventSource.keyState(.combinedSessionState, key: 0x35)
        if isEscapeDown {
            if isOverlayShownForCurrentDrag {
                isOverlayShownForCurrentDrag = false
                DispatchQueue.main.async { [weak self] in
                    self?.onEscapeDismiss?()
                }
            }
            return
        }

        // 2. Check mouse button state
        let isLeftMouseDown = CGEventSource.buttonState(.combinedSessionState, button: .left) || (NSEvent.pressedMouseButtons & 1 != 0)

        // 3. Check modifier keys:
        //    Shift (⇧)   -> Conversions
        //    Command (⌘) -> Advanced Tools
        //    Control (⌃) -> File Actions
        //    Option (⌥)  -> Advanced Tools (convenience fallback)
        let flags = CGEventSource.flagsState(.combinedSessionState)
        let currentEventFlags = NSEvent.modifierFlags

        let isShiftPressed = flags.contains(.maskShift) || currentEventFlags.contains(.shift)
        let isCommandPressed = flags.contains(.maskCommand) || currentEventFlags.contains(.command)
        let isControlPressed = flags.contains(.maskControl) || currentEventFlags.contains(.control)
        let isOptionPressed = flags.contains(.maskAlternate) || currentEventFlags.contains(.option)

        var requestedMode: ConversionFanMode? = nil
        if isShiftPressed {
            requestedMode = .conversions
        } else if isCommandPressed || isOptionPressed {
            requestedMode = .tools
        } else if isControlPressed {
            requestedMode = .actions
        }

        let currentChangeCount = pasteboard.changeCount

        if isLeftMouseDown {
            if currentChangeCount != lastChangeCount {
                lastChangeCount = currentChangeCount
                isDraggingFiles = true
            }

            if isDraggingFiles, let mode = requestedMode {
                if !isOverlayShownForCurrentDrag {
                    // Initial Summon of Wheel
                    if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
                        isOverlayShownForCurrentDrag = true
                        currentMode = mode
                        let mouseLocation = NSEvent.mouseLocation

                        DispatchQueue.main.async { [weak self] in
                            self?.onDragDetected?(urls, mouseLocation, mode)
                        }
                    }
                } else if mode != currentMode {
                    // Live Switch between Conversions, Tools, Actions wheels while dragging
                    currentMode = mode
                    DispatchQueue.main.async { [weak self] in
                        self?.onModeSwitched?(mode)
                    }
                }
            }
        } else {
            // Mouse button released
            isDraggingFiles = false
            isOverlayShownForCurrentDrag = false
            lastChangeCount = currentChangeCount
        }
    }
}

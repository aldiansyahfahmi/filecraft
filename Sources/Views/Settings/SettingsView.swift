import SwiftUI
import ServiceManagement

public struct SettingsView: View {
    @AppStorage("enableSoundAndHaptics") private var enableSoundAndHaptics: Bool = true
    @AppStorage("enableDragMonitor") private var enableDragMonitor: Bool = true
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

    public init() {}

    public var body: some View {
        Form {
            Section("General Behavior") {
                Toggle("Sound and Haptic Feedback", isOn: $enableSoundAndHaptics)
                    .help("Plays subtle sound and haptic vibration on petal hover and file actions")

                Toggle("Auto-Detect Drag Shortcuts", isOn: $enableDragMonitor)
                    .help("Listens for file dragging gestures and modifier keys to summon FileCraft")
                    .onChange(of: enableDragMonitor) { val in
                        DragGestureMonitor.shared.isEnabled = val
                    }

                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { val in
                        configureLaunchAtLogin(val)
                    }
            }

            Section("FileCraft Drag Gestures") {
                LabeledContent("Convert Formats") {
                    Text("Drag file + Tap ⇧ Shift")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(.orange)
                }

                LabeledContent("Advanced File Tools") {
                    Text("Drag file + Tap ⌘ Command")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(.blue)
                }

                LabeledContent("File Actions") {
                    Text("Drag file + Tap ⌃ Control")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(.green)
                }
            }

            Section("Global Shortcuts") {
                LabeledContent("Toggle Drop Shelf") {
                    Text("⌥ ⌘ F")
                        .font(.system(.body, design: .monospaced))
                }

                LabeledContent("Open Radial Wheel") {
                    Text("⌥ ⌘ W")
                        .font(.system(.body, design: .monospaced))
                }
            }

            Section("Provenance & Architecture") {
                Text("Reconstructed with the assistance of REA (Reverse Engineer Anything) MCP Server on macOS.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 320)
    }

    private func configureLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("[FileCraft] Failed to set login item: \(error)")
            }
        }
    }
}

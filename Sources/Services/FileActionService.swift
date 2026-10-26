import AppKit
import Foundation

@MainActor
public enum FileActionService {

    // 1. Share via AirDrop
    public static func airDrop(urls: [URL]) {
        guard !urls.isEmpty else { return }
        if let service = NSSharingService(named: .sendViaAirDrop) {
            service.perform(withItems: urls)
        }
    }

    // 2. Float in Shelf
    public static func float(urls: [URL]) {
        guard !urls.isEmpty else { return }
        FloatingShelfPanel.shared.addFiles(urls)
    }

    // 3. Copy files to clipboard ready to paste in Finder
    public static func copy(urls: [URL]) {
        guard !urls.isEmpty else { return }
        let pboard = NSPasteboard.general
        pboard.clearContents()
        pboard.writeObjects(urls as [NSURL])
    }

    // 4. Move files to chosen destination folder
    public static func move(urls: [URL]) {
        guard !urls.isEmpty else { return }
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose Destination Folder"
        openPanel.prompt = "Move Here"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK, let targetDir = openPanel.url {
            var movedURLs: [URL] = []
            for url in urls {
                let destURL = targetDir.appendingPathComponent(url.lastPathComponent)
                do {
                    if FileManager.default.fileExists(atPath: destURL.path) {
                        try FileManager.default.removeItem(at: destURL)
                    }
                    try FileManager.default.moveItem(at: url, to: destURL)
                    movedURLs.append(destURL)
                } catch {
                    NSLog("[FileCraft] Failed to move \(url): \(error)")
                }
            }
            if !movedURLs.isEmpty {
                NSWorkspace.shared.activateFileViewerSelecting(movedURLs)
            }
        }
    }

    // 5. Copy Path as text to clipboard
    public static func copyPath(urls: [URL]) {
        guard !urls.isEmpty else { return }
        let paths = urls.map { $0.path }.joined(separator: "\n")
        let pboard = NSPasteboard.general
        pboard.clearContents()
        pboard.setString(paths, forType: .string)
    }

    // 6. Open in Terminal
    public static func openTerminal(urls: [URL]) {
        guard let firstURL = urls.first else { return }
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: firstURL.path, isDirectory: &isDir)
        guard exists else { return }

        let folderURL = isDir.boolValue ? firstURL : firstURL.deletingLastPathComponent()

        // Launch Terminal with folderURL
        let config = NSWorkspace.OpenConfiguration()
        if let termAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") {
            NSWorkspace.shared.open([folderURL], withApplicationAt: termAppURL, configuration: config, completionHandler: nil)
        } else {
            NSWorkspace.shared.open(folderURL)
        }
    }
}

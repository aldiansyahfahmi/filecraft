import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
public class FloatingFileItem: Identifiable, ObservableObject {
    public let id: UUID
    public let url: URL
    public let name: String
    public let fileSize: Int64
    public let fileExtension: String
    public let utType: UTType?
    @Published public var thumbnail: NSImage?
    @Published public var isSelected: Bool = false

    public init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.fileExtension = url.pathExtension.lowercased()
        self.utType = UTType(filenameExtension: url.pathExtension)

        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        self.fileSize = Int64(values?.fileSize ?? 0)

        self.thumbnail = nil
        loadThumbnail()
    }

    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    public func loadThumbnail() {
        Task { @MainActor in
            if let image = NSImage(contentsOf: self.url) {
                // Resize for thumbnail preview
                let size = NSSize(width: 120, height: 120)
                let resized = NSImage(size: size)
                resized.lockFocus()
                image.draw(in: NSRect(origin: .zero, size: size),
                           from: NSRect(origin: .zero, size: image.size),
                           operation: .copy,
                           fraction: 1.0)
                resized.unlockFocus()
                self.thumbnail = resized
            } else {
                let icon = NSWorkspace.shared.icon(forFile: self.url.path)
                self.thumbnail = icon
            }
        }
    }
}

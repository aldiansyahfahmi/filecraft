import SwiftUI
import AppKit

public struct MetadataCleanerEditorView: View {
    @State private var fileURLs: [URL]
    @State private var inspectedMetadata: [String: Any] = [:]
    @State private var cleaningReports: [MetadataReport] = []
    @State private var isProcessing: Bool = false
    @State private var completionMessage: String?

    public init(initialURLs: [URL] = []) {
        _fileURLs = State(initialValue: initialURLs)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 28))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Privacy & Metadata Cleaner")
                        .font(.system(size: 16, weight: .bold))

                    Text("Strip GPS locations, camera serials, and tracking tags from photos")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Add Images...") {
                    selectFiles()
                }
                .buttonStyle(.bordered)
            }
            .padding(18)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Main Content
            if fileURLs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))

                    Text("Drop images here to inspect and clean metadata")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers)
                    return true
                }
            } else {
                HSplitView {
                    // Left: File List
                    List(fileURLs, id: \.self) { url in
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.orange)
                            Text(url.lastPathComponent)
                                .font(.system(size: 12))
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            inspectFile(url)
                        }
                    }
                    .frame(minWidth: 200, maxWidth: 280)

                    // Right: Metadata Inspection & Results
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Metadata Inspection")
                            .font(.system(size: 13, weight: .bold))

                        if inspectedMetadata.isEmpty {
                            Text("Select an image to inspect its metadata tags.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(inspectedMetadata.keys.sorted(), id: \.self) { key in
                                        HStack(alignment: .top) {
                                            Text(key)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.orange)
                                                .frame(width: 130, alignment: .leading)

                                            Text("\(String(describing: inspectedMetadata[key] ?? ""))")
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(.primary)
                                                .lineLimit(2)

                                            Spacer()
                                        }
                                        Divider()
                                    }
                                }
                            }
                            .frame(maxHeight: 240)
                        }

                        if !cleaningReports.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cleaned Results:")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.green)

                                ForEach(Array(cleaningReports.enumerated()), id: \.offset) { _, report in
                                    Text("✓ Removed: \(report.strippedKeys.joined(separator: ", "))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()

                        // Action Buttons
                        HStack {
                            if let msg = completionMessage {
                                Text(msg)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.green)
                            }

                            Spacer()

                            Button {
                                cleanAllFiles()
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Strip All Metadata")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .controlSize(.large)
                            .disabled(fileURLs.isEmpty || isProcessing)
                        }
                    }
                    .padding(16)
                    .frame(minWidth: 340)
                }
            }
        }
        .frame(minWidth: 680, minHeight: 460)
        .onAppear {
            if let first = fileURLs.first {
                inspectFile(first)
            }
        }
    }

    private func inspectFile(_ url: URL) {
        inspectedMetadata = MetadataCleaner.inspect(fileURL: url)
    }

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            fileURLs.append(contentsOf: panel.urls)
            if let first = panel.urls.first {
                inspectFile(first)
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        Task {
            var urls: [URL] = []
            for p in providers {
                if let item = try? await p.loadItem(forTypeIdentifier: "public.file-url"),
                   let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urls.append(url)
                }
            }
            await MainActor.run {
                fileURLs.append(contentsOf: urls)
                if let first = urls.first {
                    inspectFile(first)
                }
            }
        }
    }

    private func cleanAllFiles() {
        isProcessing = true
        var reports: [MetadataReport] = []

        let savePanel = NSOpenPanel()
        savePanel.canChooseDirectories = true
        savePanel.canChooseFiles = false
        savePanel.canCreateDirectories = true
        savePanel.prompt = "Choose Destination Folder"

        guard savePanel.runModal() == .OK, let destFolder = savePanel.url else {
            isProcessing = false
            return
        }

        for url in fileURLs {
            let outName = "Cleaned_" + url.lastPathComponent
            let outURL = destFolder.appendingPathComponent(outName)
            if let report = try? MetadataCleaner.cleanImage(inputURL: url, outputURL: outURL) {
                reports.append(report)
            }
        }

        cleaningReports = reports
        isProcessing = false
        completionMessage = "Successfully cleaned \(reports.count) files to \(destFolder.lastPathComponent)!"
        SoundManager.shared.playActionComplete()
    }
}

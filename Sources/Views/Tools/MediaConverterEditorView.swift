import SwiftUI
import AppKit

public struct MediaConverterEditorView: View {
    @State private var fileURLs: [URL]
    @State private var selectedFormat: ConversionFormat = .png
    @State private var compressionQuality: Double = 0.85
    @State private var isConverting: Bool = false
    @State private var progressText: String?
    @State private var successCount: Int = 0

    public init(initialURLs: [URL] = []) {
        _fileURLs = State(initialValue: initialURLs)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 26))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Batch Media & Format Converter")
                        .font(.system(size: 15, weight: .bold))

                    Text("Fast local conversion between image and document formats")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Add Files...") {
                    addFilesPrompt()
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Main Layout
            HStack(spacing: 0) {
                // Left File List
                VStack {
                    if fileURLs.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary.opacity(0.5))

                            Text("Drop files here to convert")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(fileURLs, id: \.self) { url in
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.orange)
                                    Text(url.lastPathComponent)
                                        .font(.system(size: 12))
                                    Spacer()
                                    Button {
                                        fileURLs.removeAll(where: { $0 == url })
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .frame(minWidth: 260)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers)
                    return true
                }

                Divider()

                // Right Options
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Format")
                            .font(.system(size: 12, weight: .bold))

                        Picker("", selection: $selectedFormat) {
                            ForEach(ConversionFormat.allCases) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if selectedFormat == .jpeg || selectedFormat == .heic {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Quality / Compression")
                                Spacer()
                                Text("\(Int(compressionQuality * 100))%").foregroundColor(.secondary)
                            }
                            .font(.system(size: 11, weight: .medium))

                            Slider(value: $compressionQuality, in: 0.1...1.0, step: 0.05)
                        }
                    }

                    Spacer()

                    if let prog = progressText {
                        Text(prog)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.orange)
                    }

                    Button {
                        startConversion()
                    } label: {
                        HStack {
                            if isConverting {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "bolt.fill")
                            }
                            Text("Convert \(fileURLs.count) Files")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.large)
                    .disabled(fileURLs.isEmpty || isConverting)
                }
                .padding(18)
                .frame(width: 250)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .frame(minWidth: 620, minHeight: 440)
    }

    private func addFilesPrompt() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            fileURLs.append(contentsOf: panel.urls)
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
            }
        }
    }

    private func startConversion() {
        let savePanel = NSOpenPanel()
        savePanel.canChooseDirectories = true
        savePanel.canChooseFiles = false
        savePanel.canCreateDirectories = true
        savePanel.prompt = "Select Output Folder"

        guard savePanel.runModal() == .OK, let destFolder = savePanel.url else { return }

        isConverting = true
        successCount = 0

        Task {
            for (idx, url) in fileURLs.enumerated() {
                await MainActor.run {
                    progressText = "Converting (\(idx + 1)/\(fileURLs.count))..."
                }

                let baseName = url.deletingPathExtension().lastPathComponent
                let outURL = destFolder.appendingPathComponent("\(baseName).\(selectedFormat.fileExtension)")

                do {
                    try ImageProcessor.convert(
                        inputURL: url,
                        targetFormat: selectedFormat,
                        compressionQuality: compressionQuality,
                        outputURL: outURL
                    )
                    await MainActor.run {
                        successCount += 1
                    }
                } catch {
                    print("Conversion error for \(url): \(error)")
                }
            }

            await MainActor.run {
                isConverting = false
                progressText = "Successfully converted \(successCount) file(s)!"
                SoundManager.shared.playActionComplete()
            }
        }
    }
}

import SwiftUI
import AppKit

public struct QRCodeOCRStudioView: View {
    @State private var selectedTab: Int = 0

    // QR Generator State
    @State private var qrInputText: String = "https://apple.com"
    @State private var generatedQR: NSImage?

    // Scanner / OCR State
    @State private var droppedImage: NSImage?
    @State private var detectedBarcodes: [RecognizedBarcode] = []
    @State private var recognizedText: String = ""
    @State private var isAnalyzing: Bool = false
    @State private var copiedFeedback: String?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("", selection: $selectedTab) {
                Text("QR Generator").tag(0)
                Text("Scan QR & Barcode").tag(1)
                Text("Extract Text (OCR)").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            Group {
                if selectedTab == 0 {
                    generatorTab
                } else if selectedTab == 1 {
                    scannerTab
                } else {
                    ocrTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 580, minHeight: 460)
        .onAppear {
            updateQR()
        }
    }

    // MARK: - Tab 1: QR Generator
    private var generatorTab: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Enter URL or text to encode...", text: $qrInputText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: qrInputText) { _ in
                        updateQR()
                    }

                Button("Generate") {
                    updateQR()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            if let qr = generatedQR {
                Image(nsImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220, height: 220)
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(radius: 6)
            }

            HStack(spacing: 12) {
                Button {
                    copyQRToClipboard()
                } label: {
                    Label("Copy QR Image", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)

                Button {
                    saveQRPrompt()
                } label: {
                    Label("Save PNG...", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }

            if let msg = copiedFeedback {
                Text(msg)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
            }

            Spacer()
        }
    }

    // MARK: - Tab 2: Scan QR / Barcode
    private var scannerTab: some View {
        VStack(spacing: 16) {
            if let img = droppedImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                if isAnalyzing {
                    ProgressView("Analyzing image...")
                } else if detectedBarcodes.isEmpty {
                    Text("No barcode or QR code detected in this image.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detected Codes:")
                            .font(.system(size: 12, weight: .bold))

                        ForEach(detectedBarcodes, id: \.payload) { code in
                            HStack {
                                Image(systemName: "qrcode")
                                    .foregroundColor(.purple)

                                Text(code.payload)
                                    .font(.system(size: 12, design: .monospaced))
                                    .lineLimit(1)

                                Spacer()

                                Button("Copy") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(code.payload, forType: .string)
                                    copiedFeedback = "Copied to clipboard!"
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                if let url = URL(string: code.payload), url.scheme != nil {
                                    Button("Open") {
                                        NSWorkspace.shared.open(url)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(.horizontal, 24)
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 44))
                        .foregroundColor(.purple.opacity(0.8))

                    Text("Drop any image or screenshot containing a QR code or Barcode")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    Button("Select Image...") {
                        selectImageForScanner()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDropForScan(providers)
                    return true
                }
            }

            Spacer()
        }
        .padding(.top, 16)
    }

    // MARK: - Tab 3: Text OCR
    private var ocrTab: some View {
        VStack(spacing: 12) {
            if !recognizedText.isEmpty {
                HStack {
                    Text("Extracted Text:")
                        .font(.system(size: 12, weight: .bold))
                    Spacer()
                    Button("Copy All Text") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(recognizedText, forType: .string)
                        copiedFeedback = "Text copied to clipboard!"
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
                .padding(.horizontal, 20)

                TextEditor(text: $recognizedText)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 44))
                        .foregroundColor(.purple.opacity(0.8))

                    Text("Drop an image with text to extract via Apple Vision OCR")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    Button("Select Image...") {
                        selectImageForOCR()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDropForOCR(providers)
                    return true
                }
            }

            if let msg = copiedFeedback {
                Text(msg)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.bottom, 8)
            }
        }
        .padding(.top, 16)
    }

    private func updateQR() {
        guard !qrInputText.isEmpty else { return }
        generatedQR = VisionService.generateQRCode(from: qrInputText)
    }

    private func copyQRToClipboard() {
        guard let qr = generatedQR else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([qr])
        copiedFeedback = "Copied QR image to clipboard!"
    }

    private func saveQRPrompt() {
        guard let qr = generatedQR,
              let tiff = qr.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "QRCode.png"
        if panel.runModal() == .OK, let url = panel.url {
            try? png.write(to: url)
            copiedFeedback = "Saved QR code to \(url.lastPathComponent)!"
        }
    }

    private func selectImageForScanner() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            droppedImage = img
            scanImage(img)
        }
    }

    private func selectImageForOCR() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            runOCR(on: img)
        }
    }

    private func handleDropForScan(_ providers: [NSItemProvider]) {
        Task {
            for p in providers {
                if let item = try? await p.loadItem(forTypeIdentifier: "public.file-url"),
                   let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil),
                   let img = NSImage(contentsOf: url) {
                    await MainActor.run {
                        droppedImage = img
                        scanImage(img)
                    }
                }
            }
        }
    }

    private func handleDropForOCR(_ providers: [NSItemProvider]) {
        Task {
            for p in providers {
                if let item = try? await p.loadItem(forTypeIdentifier: "public.file-url"),
                   let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil),
                   let img = NSImage(contentsOf: url) {
                    await MainActor.run {
                        runOCR(on: img)
                    }
                }
            }
        }
    }

    private func scanImage(_ img: NSImage) {
        isAnalyzing = true
        Task {
            let codes = await VisionService.detectBarcodes(in: img)
            await MainActor.run {
                detectedBarcodes = codes
                isAnalyzing = false
            }
        }
    }

    private func runOCR(on img: NSImage) {
        isAnalyzing = true
        Task {
            let text = await VisionService.recognizeText(in: img)
            await MainActor.run {
                recognizedText = text
                isAnalyzing = false
            }
        }
    }
}

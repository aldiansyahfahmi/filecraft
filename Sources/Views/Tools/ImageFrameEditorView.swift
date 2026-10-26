import SwiftUI
import AppKit

public struct ImageFrameEditorView: View {
    @State private var sourceImage: NSImage?
    @State private var selectedPreset: FrameGradientPreset = FrameGradientPreset.presets[0]
    @State private var padding: CGFloat = 48
    @State private var cornerRadius: CGFloat = 16
    @State private var shadowRadius: CGFloat = 24
    @State private var canvasRatio: FrameCanvasRatio = .auto
    @State private var renderedMockup: NSImage?
    @State private var statusMessage: String?

    public init(initialImage: NSImage? = nil) {
        _sourceImage = State(initialValue: initialImage)
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Left: Live Canvas Preview
            VStack {
                if let mockup = renderedMockup {
                    Image(nsImage: mockup)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(24)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "square.inset.filled")
                            .font(.system(size: 48))
                            .foregroundColor(.orange.opacity(0.8))

                        Text("Drop an image or choose a file")
                            .font(.system(size: 14, weight: .semibold))

                        Button("Select Image...") {
                            selectImagePrompt()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if let msg = statusMessage {
                    Text(msg)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.bottom, 8)
                }
            }
            .frame(minWidth: 460)
            .background(Color(NSColor.windowBackgroundColor))
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                Task {
                    for provider in providers {
                        if let item = try? await provider.loadItem(forTypeIdentifier: "public.file-url"),
                           let data = item as? Data,
                           let url = URL(dataRepresentation: data, relativeTo: nil),
                           let img = NSImage(contentsOf: url) {
                            await MainActor.run {
                                sourceImage = img
                                updateMockup()
                            }
                        }
                    }
                }
                return true
            }

            Divider()

            // Right: Settings Sidebar
            VStack(alignment: .leading, spacing: 18) {
                Text("Mockup Frame Studio")
                    .font(.system(size: 16, weight: .bold))

                // Presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Background Preset")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                        ForEach(FrameGradientPreset.presets) { preset in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: preset.colors,
                                        startPoint: preset.startPoint,
                                        endPoint: preset.endPoint
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedPreset.id == preset.id ? 3 : 0)
                                )
                                .shadow(radius: 2)
                                .onTapGesture {
                                    selectedPreset = preset
                                    updateMockup()
                                }
                        }
                    }
                }

                // Aspect Ratio
                VStack(alignment: .leading, spacing: 6) {
                    Text("Aspect Ratio")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    Picker("", selection: $canvasRatio) {
                        ForEach(FrameCanvasRatio.allCases) { ratio in
                            Text(ratio.rawValue).tag(ratio)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: canvasRatio) { _ in
                        updateMockup()
                    }
                }

                // Controls: Padding, Corner, Shadow
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Padding")
                            Spacer()
                            Text("\(Int(padding)) pt").foregroundColor(.secondary)
                        }
                        .font(.system(size: 11, weight: .medium))

                        Slider(value: $padding, in: 16...120, step: 4) { _ in
                            updateMockup()
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Corner Radius")
                            Spacer()
                            Text("\(Int(cornerRadius)) pt").foregroundColor(.secondary)
                        }
                        .font(.system(size: 11, weight: .medium))

                        Slider(value: $cornerRadius, in: 0...48, step: 2) { _ in
                            updateMockup()
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Shadow")
                            Spacer()
                            Text("\(Int(shadowRadius)) pt").foregroundColor(.secondary)
                        }
                        .font(.system(size: 11, weight: .medium))

                        Slider(value: $shadowRadius, in: 0...64, step: 2) { _ in
                            updateMockup()
                        }
                    }
                }

                Spacer()

                // Export Button
                Button {
                    exportMockup()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Export Framed Image...")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.large)
                .disabled(renderedMockup == nil)
            }
            .padding(20)
            .frame(width: 280)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 760, minHeight: 520)
        .onAppear {
            updateMockup()
        }
    }

    private func updateMockup() {
        guard let source = sourceImage else { return }
        renderedMockup = ImageProcessor.generateMockup(
            sourceImage: source,
            gradientPreset: selectedPreset,
            padding: padding,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            canvasRatio: canvasRatio
        )
    }

    private func selectImagePrompt() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            sourceImage = img
            updateMockup()
        }
    }

    private func exportMockup() {
        guard let mockup = renderedMockup,
              let tiffData = mockup.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Mockup.png"
        if panel.runModal() == .OK, let url = panel.url {
            try? pngData.write(to: url)
            statusMessage = "Exported to \(url.lastPathComponent)!"
            SoundManager.shared.playActionComplete()
        }
    }
}

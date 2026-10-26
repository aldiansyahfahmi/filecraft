import SwiftUI
import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

public struct PhotoEditorStudioView: View {
    public let imageURL: URL?
    @State private var originalImage: NSImage?
    @State private var previewImage: NSImage?

    // Adjustments
    @State private var brightness: Double = 0.0     // -1.0 .. 1.0
    @State private var contrast: Double = 1.0       // 0.5 .. 2.0
    @State private var saturation: Double = 1.0     // 0.0 .. 2.0
    @State private var rotationDegrees: Double = 0.0
    @State private var isFlippedHorizontal: Bool = false
    @State private var isFlippedVertical: Bool = false

    @State private var isSaving: Bool = false
    @State private var saveSuccess: Bool = false

    private let ciContext = CIContext()

    public init(imageURL: URL?) {
        self.imageURL = imageURL
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Preview Canvas (Left)
            ZStack {
                Color(nsColor: .windowBackgroundColor).opacity(0.6)

                if let preview = previewImage {
                    Image(nsImage: preview)
                        .resizable()
                        .scaledToFit()
                        .padding(24)
                        .shadow(color: Color.black.opacity(0.18), radius: 16, y: 6)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Image Loaded")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Inspector Controls (Right)
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Photo Adjustments")
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Button("Reset") {
                        resetAdjustments()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                }

                Divider()

                // Sliders
                VStack(alignment: .leading, spacing: 14) {
                    sliderRow(title: "Brightness", value: $brightness, range: -0.5...0.5, defaultValue: 0.0)
                    sliderRow(title: "Contrast", value: $contrast, range: 0.5...1.8, defaultValue: 1.0)
                    sliderRow(title: "Saturation", value: $saturation, range: 0.0...2.0, defaultValue: 1.0)
                }

                Divider()

                // Orientation Controls
                VStack(alignment: .leading, spacing: 8) {
                    Text("Orientation")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Button {
                            rotationDegrees = (rotationDegrees + 90.0).truncatingRemainder(dividingBy: 360.0)
                            applyFilters()
                        } label: {
                            Label("Rotate 90°", systemImage: "rotate.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            isFlippedHorizontal.toggle()
                            applyFilters()
                        } label: {
                            Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            isFlippedVertical.toggle()
                            applyFilters()
                        } label: {
                            Image(systemName: "arrow.up.and.down.righttriangle.up.righttriangle.down")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Spacer()

                // Save Action
                Button {
                    saveEditedImage()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else if saveSuccess {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(saveSuccess ? "Saved!" : "Save Edited Photo")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(previewImage == nil || isSaving)
            }
            .padding(18)
            .frame(width: 280)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(minWidth: 760, minHeight: 520)
        .onAppear {
            loadImage()
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, defaultValue: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Slider(value: value, in: range) {
                Text(title)
            } onEditingChanged: { _ in
                applyFilters()
            }
        }
    }

    private func resetAdjustments() {
        brightness = 0.0
        contrast = 1.0
        saturation = 1.0
        rotationDegrees = 0.0
        isFlippedHorizontal = false
        isFlippedVertical = false
        previewImage = originalImage
    }

    private func loadImage() {
        guard let url = imageURL, let img = NSImage(contentsOf: url) else { return }
        self.originalImage = img
        self.previewImage = img
    }

    private func applyFilters() {
        guard let original = originalImage,
              let tiff = original.tiffRepresentation,
              let ciInput = CIImage(data: tiff) else { return }

        // 1. Color Controls (Brightness, Contrast, Saturation)
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(ciInput, forKey: kCIInputImageKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        filter.setValue(saturation, forKey: kCIInputSaturationKey)

        guard var output = filter.outputImage else { return }

        // 2. Transform (Rotation & Flip)
        var transform = CGAffineTransform.identity
        if rotationDegrees != 0 {
            transform = transform.rotated(by: CGFloat(rotationDegrees * .pi / 180.0))
        }
        if isFlippedHorizontal {
            transform = transform.scaledBy(x: -1, y: 1)
        }
        if isFlippedVertical {
            transform = transform.scaledBy(x: 1, y: -1)
        }
        if transform != .identity {
            output = output.transformed(by: transform)
        }

        if let cgImg = ciContext.createCGImage(output, from: output.extent) {
            let newImg = NSImage(cgImage: cgImg, size: NSSize(width: cgImg.width, height: cgImg.height))
            self.previewImage = newImg
        }
    }

    private func saveEditedImage() {
        guard let img = previewImage, let sourceURL = imageURL else { return }
        isSaving = true

        let dir = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension.isEmpty ? "jpg" : sourceURL.pathExtension
        let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Edited", ext: ext)

        DispatchQueue.global(qos: .userInitiated).async {
            if let tiff = img.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff) {
                let fileType: NSBitmapImageRep.FileType = (ext.lowercased() == "png") ? .png : .jpeg
                if let data = rep.representation(using: fileType, properties: [:]) {
                    try? data.write(to: outURL)
                }
            }

            DispatchQueue.main.async {
                self.isSaving = false
                self.saveSuccess = true
                SoundManager.shared.playActionComplete()
                NSWorkspace.shared.activateFileViewerSelecting([outURL])
            }
        }
    }

    private func generateUniqueURL(dir: URL, baseName: String, ext: String) -> URL {
        var out = dir.appendingPathComponent("\(baseName).\(ext)")
        var counter = 1
        while FileManager.default.fileExists(atPath: out.path) {
            out = dir.appendingPathComponent("\(baseName)_\(counter).\(ext)")
            counter += 1
        }
        return out
    }
}

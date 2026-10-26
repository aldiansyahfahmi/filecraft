import SwiftUI
import AppKit
import CoreGraphics

public enum CropAspectRatio: String, CaseIterable, Identifiable {
    case freeform = "Freeform"
    case square = "1:1 Square"
    case fourThree = "4:3 Classic"
    case sixteenNine = "16:9 Wide"
    case nineSixteen = "9:16 Story"

    public var id: String { rawValue }

    public var ratio: CGFloat? {
        switch self {
        case .freeform: return nil
        case .square: return 1.0
        case .fourThree: return 4.0 / 3.0
        case .sixteenNine: return 16.0 / 9.0
        case .nineSixteen: return 9.0 / 16.0
        }
    }
}

public struct CropStudioView: View {
    public let imageURL: URL?
    @State private var originalImage: NSImage?

    // Normalized Crop Rect (0.0 .. 1.0)
    @State private var cropRect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
    @State private var selectedRatio: CropAspectRatio = .freeform

    @State private var isSaving: Bool = false
    @State private var saveSuccess: Bool = false

    public init(imageURL: URL?) {
        self.imageURL = imageURL
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Interactive Crop View (Left)
            GeometryReader { geo in
                ZStack {
                    Color(nsColor: .windowBackgroundColor).opacity(0.6)

                    if let img = originalImage {
                        let fittedSize = aspectFitSize(imageSize: img.size, containerSize: geo.size)

                        ZStack {
                            Image(nsImage: img)
                                .resizable()
                                .frame(width: fittedSize.width, height: fittedSize.height)

                            // Semi-transparent overlay with crop cutout
                            CropBoxOverlay(
                                cropRect: $cropRect,
                                containerSize: fittedSize
                            )
                        }
                        .frame(width: fittedSize.width, height: fittedSize.height)
                    } else {
                        Text("No Image Loaded")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            // Controls Sidebar (Right)
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "crop")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Crop Image")
                        .font(.system(size: 15, weight: .bold))
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Aspect Ratio Presets")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    ForEach(CropAspectRatio.allCases) { preset in
                        Button {
                            selectedRatio = preset
                            applyRatio(preset)
                        } label: {
                            HStack {
                                Text(preset.rawValue)
                                    .font(.system(size: 12))
                                Spacer()
                                if selectedRatio == preset {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedRatio == preset ? Color.orange.opacity(0.15) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                Button("Reset to Full") {
                    cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
                    selectedRatio = .freeform
                }
                .buttonStyle(.bordered)
                .font(.system(size: 11))

                Spacer()

                Button {
                    saveCroppedImage()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else if saveSuccess {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(saveSuccess ? "Saved!" : "Crop & Save")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(originalImage == nil || isSaving)
            }
            .padding(18)
            .frame(width: 250)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(minWidth: 740, minHeight: 500)
        .onAppear {
            if let url = imageURL, let img = NSImage(contentsOf: url) {
                self.originalImage = img
            }
        }
    }

    private func applyRatio(_ preset: CropAspectRatio) {
        guard let r = preset.ratio, let img = originalImage else { return }
        let imgAspect = img.size.width / max(1, img.size.height)

        var newW: CGFloat = 0.8
        var newH: CGFloat = 0.8

        if r > imgAspect {
            newW = 0.85
            newH = (newW / r) * imgAspect
        } else {
            newH = 0.85
            newW = (newH * r) / imgAspect
        }

        let newX = max(0, (1.0 - newW) / 2.0)
        let newY = max(0, (1.0 - newH) / 2.0)
        self.cropRect = CGRect(x: newX, y: newY, width: newW, height: newH)
    }

    private func aspectFitSize(imageSize: CGSize, containerSize: CGSize) -> CGSize {
        let maxW = containerSize.width - 48
        let maxH = containerSize.height - 48
        let scale = min(maxW / max(1, imageSize.width), maxH / max(1, imageSize.height))
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    private func saveCroppedImage() {
        guard let sourceURL = imageURL,
              let tiff = originalImage?.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let cgImg = rep.cgImage else { return }

        isSaving = true

        let imgW = CGFloat(cgImg.width)
        let imgH = CGFloat(cgImg.height)

        let pixelCrop = CGRect(
            x: max(0, min(imgW, cropRect.origin.x * imgW)),
            y: max(0, min(imgH, cropRect.origin.y * imgH)),
            width: max(1, min(imgW, cropRect.size.width * imgW)),
            height: max(1, min(imgH, cropRect.size.height * imgH))
        )

        guard let croppedCG = cgImg.cropping(to: pixelCrop) else {
            isSaving = false
            return
        }

        let dir = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension.isEmpty ? "jpg" : sourceURL.pathExtension
        let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Cropped", ext: ext)

        DispatchQueue.global(qos: .userInitiated).async {
            let croppedNS = NSImage(cgImage: croppedCG, size: NSSize(width: croppedCG.width, height: croppedCG.height))
            if let tiff = croppedNS.tiffRepresentation,
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

// MARK: - Crop Box Overlay
private struct CropBoxOverlay: View {
    @Binding var cropRect: CGRect
    let containerSize: CGSize

    var body: some View {
        let x = cropRect.origin.x * containerSize.width
        let y = cropRect.origin.y * containerSize.height
        let w = cropRect.size.width * containerSize.width
        let h = cropRect.size.height * containerSize.height

        ZStack(alignment: .topLeading) {
            // Darkened backdrop outside crop box
            Color.black.opacity(0.4)
                .mask(
                    Rectangle()
                        .overlay(
                            Rectangle()
                                .frame(width: w, height: h)
                                .position(x: x + w / 2, y: y + h / 2)
                                .blendMode(.destinationOut)
                        )
                )

            // Crop Box with Grid & Handles
            ZStack {
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)

                // Grid Lines
                VStack {
                    Divider().background(Color.white.opacity(0.4))
                    Spacer()
                    Divider().background(Color.white.opacity(0.4))
                }
                .padding(.vertical, h / 3)

                HStack {
                    Divider().background(Color.white.opacity(0.4))
                    Spacer()
                    Divider().background(Color.white.opacity(0.4))
                }
                .padding(.horizontal, w / 3)
            }
            .frame(width: w, height: h)
            .offset(x: x, y: y)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let deltaX = value.translation.width / containerSize.width
                        let deltaY = value.translation.height / containerSize.height
                        var newX = cropRect.origin.x + deltaX
                        var newY = cropRect.origin.y + deltaY
                        newX = max(0, min(1.0 - cropRect.width, newX))
                        newY = max(0, min(1.0 - cropRect.height, newY))
                        cropRect.origin = CGPoint(x: newX, y: newY)
                    }
            )
        }
    }
}

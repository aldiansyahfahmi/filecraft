import SwiftUI
import AppKit

public struct RedactStudioView: View {
    public let imageURL: URL?
    @State private var originalImage: NSImage?

    @State private var redactionBoxes: [CGRect] = []
    @State private var currentDragStart: CGPoint? = nil
    @State private var currentDragCurrent: CGPoint? = nil

    @State private var isSaving: Bool = false
    @State private var saveSuccess: Bool = false

    public init(imageURL: URL?) {
        self.imageURL = imageURL
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Interactive Redaction Canvas (Left)
            GeometryReader { geo in
                ZStack {
                    Color(nsColor: .windowBackgroundColor).opacity(0.6)

                    if let img = originalImage {
                        let fitted = aspectFitSize(imageSize: img.size, containerSize: geo.size)

                        ZStack(alignment: .topLeading) {
                            Image(nsImage: img)
                                .resizable()
                                .frame(width: fitted.width, height: fitted.height)

                            // Existing Redaction Boxes
                            ForEach(0..<redactionBoxes.count, id: \.self) { i in
                                let box = redactionBoxes[i]
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: box.width * fitted.width, height: box.height * fitted.height)
                                    .offset(x: box.origin.x * fitted.width, y: box.origin.y * fitted.height)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            .frame(width: box.width * fitted.width, height: box.height * fitted.height)
                                            .offset(x: box.origin.x * fitted.width, y: box.origin.y * fitted.height)
                                    )
                            }

                            // Active Dragging Box
                            if let start = currentDragStart, let cur = currentDragCurrent {
                                let rect = normalizedRect(from: start, to: cur)
                                Rectangle()
                                    .fill(Color.black.opacity(0.85))
                                    .frame(width: rect.width * fitted.width, height: rect.height * fitted.height)
                                    .offset(x: rect.origin.x * fitted.width, y: rect.origin.y * fitted.height)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.red, lineWidth: 1.5)
                                            .frame(width: rect.width * fitted.width, height: rect.height * fitted.height)
                                            .offset(x: rect.origin.x * fitted.width, y: rect.origin.y * fitted.height)
                                    )
                            }
                        }
                        .frame(width: fitted.width, height: fitted.height)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 4)
                                .onChanged { value in
                                    let normStart = CGPoint(x: value.startLocation.x / fitted.width, y: value.startLocation.y / fitted.height)
                                    let normCur = CGPoint(x: value.location.x / fitted.width, y: value.location.y / fitted.height)
                                    currentDragStart = normStart
                                    currentDragCurrent = normCur
                                }
                                .onEnded { value in
                                    if let start = currentDragStart, let cur = currentDragCurrent {
                                        let rect = normalizedRect(from: start, to: cur)
                                        if rect.width > 0.02 && rect.height > 0.02 {
                                            redactionBoxes.append(rect)
                                        }
                                    }
                                    currentDragStart = nil
                                    currentDragCurrent = nil
                                }
                        )
                    } else {
                        Text("No Image Loaded")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            // Sidebar Controls (Right)
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Redact Image")
                        .font(.system(size: 15, weight: .bold))
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Instructions")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Click and drag over sensitive text, faces, or numbers on the photo to black them out.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Divider()

                Text("\(redactionBoxes.count) Redaction\(redactionBoxes.count == 1 ? "" : "s") Added")
                    .font(.system(size: 12, weight: .medium))

                HStack {
                    Button("Undo") {
                        if !redactionBoxes.isEmpty {
                            redactionBoxes.removeLast()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(redactionBoxes.isEmpty)

                    Button("Clear All") {
                        redactionBoxes.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .disabled(redactionBoxes.isEmpty)
                }

                Spacer()

                Button {
                    saveRedactedImage()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView().scaleEffect(0.7)
                        } else if saveSuccess {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(saveSuccess ? "Saved!" : "Save Redacted Photo")
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
        .frame(minWidth: 760, minHeight: 520)
        .onAppear {
            if let url = imageURL, let img = NSImage(contentsOf: url) {
                self.originalImage = img
            }
        }
    }

    private func normalizedRect(from p1: CGPoint, to p2: CGPoint) -> CGRect {
        let x = min(p1.x, p2.x)
        let y = min(p1.y, p2.y)
        let w = abs(p2.x - p1.x)
        let h = abs(p2.y - p1.y)
        return CGRect(x: max(0, min(1, x)), y: max(0, min(1, y)), width: min(1, w), height: min(1, h))
    }

    private func aspectFitSize(imageSize: CGSize, containerSize: CGSize) -> CGSize {
        let maxW = containerSize.width - 48
        let maxH = containerSize.height - 48
        let scale = min(maxW / max(1, imageSize.width), maxH / max(1, imageSize.height))
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    private func saveRedactedImage() {
        guard let sourceURL = imageURL,
              let original = originalImage,
              let tiff = original.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let cgImg = rep.cgImage else { return }

        isSaving = true
        let width = cgImg.width
        let height = cgImg.height

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        // Draw original image
        context.draw(cgImg, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Draw black redaction rectangles (in CoreGraphics, y is flipped from SwiftUI)
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        for box in redactionBoxes {
            let pixelX = box.origin.x * CGFloat(width)
            let pixelY = (1.0 - box.origin.y - box.size.height) * CGFloat(height)
            let pixelW = box.size.width * CGFloat(width)
            let pixelH = box.size.height * CGFloat(height)
            context.fill(CGRect(x: pixelX, y: pixelY, width: pixelW, height: pixelH))
        }

        guard let outputCG = context.makeImage() else {
            isSaving = false
            return
        }

        let dir = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension.isEmpty ? "jpg" : sourceURL.pathExtension
        let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Redacted", ext: ext)

        DispatchQueue.global(qos: .userInitiated).async {
            let redactedNS = NSImage(cgImage: outputCG, size: NSSize(width: width, height: height))
            if let tiffData = redactedNS.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiffData) {
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

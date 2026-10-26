import SwiftUI
import AppKit

public struct CollageStudioView: View {
    public let imageURLs: [URL]
    @State private var images: [NSImage] = []
    @State private var spacing: CGFloat = 16
    @State private var cornerRadius: CGFloat = 12

    @State private var isSaving: Bool = false
    @State private var saveSuccess: Bool = false

    public init(imageURLs: [URL]) {
        self.imageURLs = imageURLs
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Collage Preview (Left)
            ZStack {
                Color(nsColor: .windowBackgroundColor).opacity(0.6)

                if images.isEmpty {
                    Text("No Images to Collage")
                        .foregroundColor(.secondary)
                } else {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: images.count > 2 ? 2 : images.count)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: spacing) {
                            ForEach(0..<images.count, id: \.self) { i in
                                Image(nsImage: images[i])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(minHeight: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                                    .shadow(color: Color.black.opacity(0.12), radius: 8, y: 3)
                            }
                        }
                        .padding(32)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Inspector (Right)
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Photo Collage")
                        .font(.system(size: 15, weight: .bold))
                }

                Divider()

                Text("\(images.count) Photo\(images.count == 1 ? "" : "s") Included")
                    .font(.system(size: 12, weight: .medium))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Grid Spacing")
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(Int(spacing)) pt")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $spacing, in: 0...40)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Corner Radius")
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(Int(cornerRadius)) pt")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $cornerRadius, in: 0...32)
                }

                Spacer()

                Button {
                    saveCollage()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView().scaleEffect(0.7)
                        } else if saveSuccess {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(saveSuccess ? "Saved!" : "Save Collage")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(images.isEmpty || isSaving)
            }
            .padding(18)
            .frame(width: 250)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(minWidth: 760, minHeight: 520)
        .onAppear {
            self.images = imageURLs.compactMap { NSImage(contentsOf: $0) }
        }
    }

    private func saveCollage() {
        guard let firstURL = imageURLs.first, !images.isEmpty else { return }
        isSaving = true

        let totalW: CGFloat = 1600
        let colCount = images.count > 2 ? 2 : images.count
        let rowCount = (images.count + colCount - 1) / colCount

        let cellW = (totalW - (CGFloat(colCount + 1) * spacing)) / CGFloat(colCount)
        let cellH = cellW * 0.75
        let totalH = (CGFloat(rowCount) * cellH) + (CGFloat(rowCount + 1) * spacing)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: Int(totalW),
            height: Int(totalH),
            bitsPerComponent: 8,
            bytesPerRow: Int(totalW) * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        // Background
        context.setFillColor(CGColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: totalW, height: totalH))

        // Draw cells
        for (i, img) in images.enumerated() {
            guard let tiff = img.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let cg = rep.cgImage else { continue }

            let col = i % colCount
            let row = i / colCount

            let x = spacing + CGFloat(col) * (cellW + spacing)
            // Flip Y for CoreGraphics
            let y = totalH - (spacing + CGFloat(row + 1) * cellH + CGFloat(row) * spacing)
            let rect = CGRect(x: x, y: y, width: cellW, height: cellH)

            context.saveGState()
            let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            context.addPath(path)
            context.clip()
            context.draw(cg, in: rect)
            context.restoreGState()
        }

        guard let outputCG = context.makeImage() else {
            isSaving = false
            return
        }

        let dir = firstURL.deletingLastPathComponent()
        let outURL = generateUniqueURL(dir: dir, baseName: "Collage", ext: "jpg")

        DispatchQueue.global(qos: .userInitiated).async {
            let resNS = NSImage(cgImage: outputCG, size: NSSize(width: totalW, height: totalH))
            if let tiffData = resNS.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiffData),
               let jpg = rep.representation(using: .jpeg, properties: [:]) {
                try? jpg.write(to: outURL)
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

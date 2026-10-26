import SwiftUI
import AppKit

public enum AnnotationToolType: String, CaseIterable, Identifiable {
    case arrow = "Arrow"
    case box = "Box"
    case text = "Text"
    case pen = "Pen"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .box: return "rectangle"
        case .text: return "textformat"
        case .pen: return "pencil.tip"
        }
    }
}

public struct AnnotationItem: Identifiable {
    public let id = UUID()
    public var type: AnnotationToolType
    public var startPoint: CGPoint
    public var endPoint: CGPoint
    public var points: [CGPoint] = []
    public var color: Color
    public var text: String = "Note"
}

public struct AnnotationStudioView: View {
    public let imageURL: URL?
    @State private var originalImage: NSImage?

    @State private var selectedTool: AnnotationToolType = .arrow
    @State private var selectedColor: Color = .red
    @State private var annotations: [AnnotationItem] = []

    @State private var currentDrawing: AnnotationItem? = nil

    @State private var isSaving: Bool = false
    @State private var saveSuccess: Bool = false

    private let availableColors: [Color] = [.red, .orange, .yellow, .green, .blue, .white, .black]

    public init(imageURL: URL?) {
        self.imageURL = imageURL
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Canvas (Left)
            GeometryReader { geo in
                ZStack {
                    Color(nsColor: .windowBackgroundColor).opacity(0.6)

                    if let img = originalImage {
                        let fitted = aspectFitSize(imageSize: img.size, containerSize: geo.size)

                        ZStack(alignment: .topLeading) {
                            Image(nsImage: img)
                                .resizable()
                                .frame(width: fitted.width, height: fitted.height)

                            // Render Completed Annotations
                            ForEach(annotations) { item in
                                renderAnnotation(item: item, containerSize: fitted)
                            }

                            // Render Active Drawing
                            if let cur = currentDrawing {
                                renderAnnotation(item: cur, containerSize: fitted)
                            }
                        }
                        .frame(width: fitted.width, height: fitted.height)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 2)
                                .onChanged { value in
                                    let pStart = CGPoint(x: value.startLocation.x / fitted.width, y: value.startLocation.y / fitted.height)
                                    let pCur = CGPoint(x: value.location.x / fitted.width, y: value.location.y / fitted.height)

                                    if selectedTool == .pen {
                                        if currentDrawing == nil {
                                            currentDrawing = AnnotationItem(type: .pen, startPoint: pStart, endPoint: pCur, points: [pStart, pCur], color: selectedColor)
                                        } else {
                                            currentDrawing?.points.append(pCur)
                                        }
                                    } else {
                                        currentDrawing = AnnotationItem(type: selectedTool, startPoint: pStart, endPoint: pCur, color: selectedColor)
                                    }
                                }
                                .onEnded { _ in
                                    if let finished = currentDrawing {
                                        annotations.append(finished)
                                    }
                                    currentDrawing = nil
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

            // Inspector (Right)
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Annotate Image")
                        .font(.system(size: 15, weight: .bold))
                }

                Divider()

                // Tool Pickers
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tool")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(AnnotationToolType.allCases) { tool in
                            Button {
                                selectedTool = tool
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: tool.icon)
                                        .font(.system(size: 16))
                                    Text(tool.rawValue)
                                        .font(.system(size: 10))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedTool == tool ? Color.orange.opacity(0.18) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(selectedTool == tool ? Color.orange : Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Colors
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(availableColors, id: \.self) { c in
                            Circle()
                                .fill(c)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == c ? Color.primary : Color.black.opacity(0.2), lineWidth: selectedColor == c ? 2 : 1)
                                )
                                .onTapGesture {
                                    selectedColor = c
                                }
                        }
                    }
                }

                Divider()

                HStack {
                    Button("Undo") {
                        if !annotations.isEmpty {
                            annotations.removeLast()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(annotations.isEmpty)

                    Button("Clear All") {
                        annotations.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .disabled(annotations.isEmpty)
                }

                Spacer()

                Button {
                    saveAnnotatedImage()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView().scaleEffect(0.7)
                        } else if saveSuccess {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(saveSuccess ? "Saved!" : "Save Annotated Photo")
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
            .frame(width: 260)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(minWidth: 780, minHeight: 520)
        .onAppear {
            if let url = imageURL, let img = NSImage(contentsOf: url) {
                self.originalImage = img
            }
        }
    }

    @ViewBuilder
    private func renderAnnotation(item: AnnotationItem, containerSize: CGSize) -> some View {
        let p1 = CGPoint(x: item.startPoint.x * containerSize.width, y: item.startPoint.y * containerSize.height)
        let p2 = CGPoint(x: item.endPoint.x * containerSize.width, y: item.endPoint.y * containerSize.height)

        switch item.type {
        case .arrow:
            Path { path in
                path.move(to: p1)
                path.addLine(to: p2)
            }
            .stroke(item.color, lineWidth: 3)

        case .box:
            let minX = min(p1.x, p2.x)
            let minY = min(p1.y, p2.y)
            let w = abs(p2.x - p1.x)
            let h = abs(p2.y - p1.y)
            Rectangle()
                .stroke(item.color, lineWidth: 3)
                .frame(width: w, height: h)
                .offset(x: minX, y: minY)

        case .pen:
            Path { path in
                if let first = item.points.first {
                    path.move(to: CGPoint(x: first.x * containerSize.width, y: first.y * containerSize.height))
                    for pt in item.points.dropFirst() {
                        path.addLine(to: CGPoint(x: pt.x * containerSize.width, y: pt.y * containerSize.height))
                    }
                }
            }
            .stroke(item.color, lineWidth: 3)

        case .text:
            Text(item.text)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(item.color)
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.6)))
                .offset(x: p1.x, y: p1.y)
        }
    }

    private func aspectFitSize(imageSize: CGSize, containerSize: CGSize) -> CGSize {
        let maxW = containerSize.width - 48
        let maxH = containerSize.height - 48
        let scale = min(maxW / max(1, imageSize.width), maxH / max(1, imageSize.height))
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    private func saveAnnotatedImage() {
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

        // Draw original
        context.draw(cgImg, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Draw annotations
        context.setLineWidth(4.0)
        for item in annotations {
            let nsColor = NSColor(item.color)
            context.setStrokeColor(nsColor.cgColor)
            context.setFillColor(nsColor.cgColor)

            let p1 = CGPoint(x: item.startPoint.x * CGFloat(width), y: (1.0 - item.startPoint.y) * CGFloat(height))
            let p2 = CGPoint(x: item.endPoint.x * CGFloat(width), y: (1.0 - item.endPoint.y) * CGFloat(height))

            switch item.type {
            case .arrow:
                context.move(to: p1)
                context.addLine(to: p2)
                context.strokePath()

            case .box:
                let minX = min(p1.x, p2.x)
                let minY = min(p1.y, p2.y)
                let w = abs(p2.x - p1.x)
                let h = abs(p2.y - p1.y)
                context.stroke(CGRect(x: minX, y: minY, width: w, height: h))

            case .pen:
                if let first = item.points.first {
                    context.move(to: CGPoint(x: first.x * CGFloat(width), y: (1.0 - first.y) * CGFloat(height)))
                    for pt in item.points.dropFirst() {
                        context.addLine(to: CGPoint(x: pt.x * CGFloat(width), y: (1.0 - pt.y) * CGFloat(height)))
                    }
                    context.strokePath()
                }

            case .text:
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: nsColor
                ]
                let str = NSAttributedString(string: item.text, attributes: attrs)
                let line = CTLineCreateWithAttributedString(str)
                context.textPosition = p1
                CTLineDraw(line, context)
            }
        }

        guard let outputCG = context.makeImage() else {
            isSaving = false
            return
        }

        let dir = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension.isEmpty ? "jpg" : sourceURL.pathExtension
        let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Annotated", ext: ext)

        DispatchQueue.global(qos: .userInitiated).async {
            let annotatedNS = NSImage(cgImage: outputCG, size: NSSize(width: width, height: height))
            if let tiffData = annotatedNS.tiffRepresentation,
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

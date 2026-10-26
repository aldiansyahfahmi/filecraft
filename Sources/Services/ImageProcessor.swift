import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import PDFKit

public enum ImageProcessor {

    // MARK: - Format Conversion & Compression
    public static func convert(
        inputURL: URL,
        targetFormat: ConversionFormat,
        compressionQuality: Double = 0.85,
        outputURL: URL
    ) throws {
        // Special Case 1: Target is PDF
        if targetFormat == .pdf {
            if let image = NSImage(contentsOf: inputURL) {
                let pdfDoc = PDFDocument()
                if let page = PDFPage(image: image) {
                    pdfDoc.insert(page, at: 0)
                    if pdfDoc.write(to: outputURL) {
                        return
                    }
                }
            }
            throw NSError(domain: "ImageProcessor", code: 10, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF from \(inputURL.lastPathComponent)"])
        }

        // Special Case 2: Input is PDF, converting to image format
        if inputURL.pathExtension.lowercased() == "pdf" {
            if let pdfDoc = PDFDocument(url: inputURL), let page = pdfDoc.page(at: 0) {
                let pageSize = page.bounds(for: .mediaBox).size
                let thumb = page.thumbnail(of: pageSize, for: .mediaBox)
                if let tiffData = thumb.tiffRepresentation,
                   let rep = NSBitmapImageRep(data: tiffData),
                   let cgImg = rep.cgImage {
                    try writeCGImage(cgImg, to: outputURL, format: targetFormat, quality: compressionQuality)
                    return
                }
            }
        }

        // Standard image-to-image conversion
        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw NSError(domain: "ImageProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not decode image at \(inputURL.lastPathComponent)"])
        }

        try writeCGImage(cgImage, to: outputURL, format: targetFormat, quality: compressionQuality)
    }

    private static func writeCGImage(
        _ cgImage: CGImage,
        to outputURL: URL,
        format: ConversionFormat,
        quality: Double
    ) throws {
        if format == .webp {
            try encodeWebP(cgImage: cgImage, outputURL: outputURL, quality: quality)
            return
        }

        let typeIdentifier: CFString
        switch format {
        case .png:
            typeIdentifier = UTType.png.identifier as CFString
        case .jpeg:
            typeIdentifier = UTType.jpeg.identifier as CFString
        case .heic:
            typeIdentifier = UTType.heic.identifier as CFString
        case .tiff:
            typeIdentifier = UTType.tiff.identifier as CFString
        case .bmp:
            typeIdentifier = UTType.bmp.identifier as CFString
        case .pdf:
            typeIdentifier = UTType.pdf.identifier as CFString
        default:
            let resolvedType = UTType(filenameExtension: format.fileExtension) ?? .jpeg
            typeIdentifier = resolvedType.identifier as CFString
        }

        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, typeIdentifier, 1, nil) else {
            throw NSError(domain: "ImageProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create image destination"])
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "ImageProcessor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize converted image"])
        }
    }

    // MARK: - WebP Encoder
    public static func findCWebP() -> String? {
        var candidates: [String] = []
        if let bundlePath = Bundle.main.resourceURL?.appendingPathComponent("Tools/cwebp").path {
            candidates.append(bundlePath)
        }
        candidates.append(contentsOf: [
            "/opt/homebrew/bin/cwebp",
            "/usr/local/bin/cwebp",
            "/usr/bin/cwebp"
        ])
        for c in candidates {
            if FileManager.default.isExecutableFile(atPath: c) {
                return c
            }
        }
        return nil
    }

    public static func encodeWebP(cgImage: CGImage, outputURL: URL, quality: Double = 0.85) throws {
        guard let cwebpPath = findCWebP() else {
            throw NSError(domain: "ImageProcessor", code: 404, userInfo: [NSLocalizedDescriptionKey: "cwebp executable not found. Please install webp or ensure Tools/cwebp is present."])
        }

        let width = cgImage.width
        let height = cgImage.height
        let header = "P7\nWIDTH \(width)\nHEIGHT \(height)\nDEPTH 4\nMAXVAL 255\nTUPLTYPE RGB_ALPHA\nENDHDR\n"
        guard var pamData = header.data(using: .ascii) else {
            throw NSError(domain: "ImageProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to construct PAM header"])
        }

        let bytesPerRow = width * 4
        var rawData = Data(count: height * bytesPerRow)
        rawData.withUnsafeMutableBytes { ptr in
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        pamData.append(rawData)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pam")
        defer { try? FileManager.default.removeItem(at: tempURL) }
        try pamData.write(to: tempURL)

        let qInt = max(1, min(100, Int(quality * 100)))
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cwebpPath)
        process.arguments = ["-q", "\(qInt)", tempURL.path, "-o", outputURL.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0, FileManager.default.fileExists(atPath: outputURL.path) else {
            throw NSError(domain: "ImageProcessor", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "cwebp failed with exit code \(process.terminationStatus)"])
        }
    }

    // MARK: - Frame Mockup Generator
    public static func generateMockup(
        sourceImage: NSImage,
        gradientPreset: FrameGradientPreset,
        padding: CGFloat = 64,
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 28,
        canvasRatio: FrameCanvasRatio = .auto
    ) -> NSImage? {
        let imgSize = sourceImage.size
        guard imgSize.width > 0 && imgSize.height > 0 else { return nil }

        var targetWidth = imgSize.width + (padding * 2)
        var targetHeight = imgSize.height + (padding * 2)

        if let ratio = canvasRatio.ratio(originalWidth: imgSize.width, originalHeight: imgSize.height) {
            let currentRatio = targetWidth / targetHeight
            if currentRatio > ratio {
                targetHeight = targetWidth / ratio
            } else {
                targetWidth = targetHeight * ratio
            }
        }

        let canvasSize = NSSize(width: targetWidth, height: targetHeight)
        let outputImage = NSImage(size: canvasSize)

        outputImage.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            outputImage.unlockFocus()
            return nil
        }

        // 1. Draw Background Gradient
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgColors = gradientPreset.colors.map { NSColor($0).cgColor } as CFArray
        let locations: [CGFloat] = [0.0, 1.0]

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: locations) {
            let start = CGPoint(x: 0, y: canvasSize.height)
            let end = CGPoint(x: canvasSize.width, y: 0)
            context.drawLinearGradient(gradient, start: start, end: end, options: [])
        }

        // 2. Compute inner image frame centered
        let innerOriginX = (canvasSize.width - imgSize.width) / 2.0
        let innerOriginY = (canvasSize.height - imgSize.height) / 2.0
        let innerRect = NSRect(x: innerOriginX, y: innerOriginY, width: imgSize.width, height: imgSize.height)

        // 3. Draw Drop Shadow
        context.saveGState()
        let shadowColor = NSColor.black.withAlphaComponent(0.35).cgColor
        context.setShadow(offset: CGSize(width: 0, height: -shadowRadius * 0.4), blur: shadowRadius, color: shadowColor)

        // Clip to rounded rect
        let roundedPath = CGPath(roundedRect: innerRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        context.addPath(roundedPath)
        context.setFillColor(NSColor.black.cgColor)
        context.fillPath()
        context.restoreGState()

        // 4. Draw Image inside rounded clip
        context.saveGState()
        context.addPath(roundedPath)
        context.clip()

        sourceImage.draw(in: innerRect, from: NSRect(origin: .zero, size: imgSize), operation: .sourceOver, fraction: 1.0)

        // Subtle inner border
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.18).cgColor)
        context.setLineWidth(1.0)
        context.addPath(roundedPath)
        context.strokePath()

        context.restoreGState()

        outputImage.unlockFocus()
        return outputImage
    }
}

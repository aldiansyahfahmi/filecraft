import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public struct MetadataReport: Sendable {
    public let strippedKeys: [String]
    public let hadGPS: Bool
    public let cameraModel: String?
    public let originalSize: Int64
    public let cleanedSize: Int64
}

public enum MetadataCleaner {
    public static func inspect(fileURL: URL) -> [String: Any] {
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return [:]
        }
        return props
    }

    @discardableResult
    public static func cleanMetadata(at inputURL: URL, outputURL: URL) throws -> MetadataReport {
        return try cleanImage(inputURL: inputURL, outputURL: outputURL)
    }

    public static func cleanImage(inputURL: URL, outputURL: URL) throws -> MetadataReport {
        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil) else {
            throw NSError(domain: "MetadataCleaner", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read image source"])
        }

        let originalProps = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] ?? [:]
        let hadGPS = originalProps[kCGImagePropertyGPSDictionary as String] != nil

        var cameraModel: String? = nil
        if let tiffDict = originalProps[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            cameraModel = tiffDict[kCGImagePropertyTIFFModel as String] as? String
        }

        guard let imageRef = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw NSError(domain: "MetadataCleaner", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to extract image pixels"])
        }

        let utType = UTType(filenameExtension: inputURL.pathExtension) ?? .png
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, utType.identifier as CFString, 1, nil) else {
            throw NSError(domain: "MetadataCleaner", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create destination"])
        }

        // Clean properties: only retain pixel orientation if needed, no EXIF/GPS/MakerNotes
        let cleanProps: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.95
        ]

        CGImageDestinationAddImage(destination, imageRef, cleanProps as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "MetadataCleaner", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to write clean image"])
        }

        let origSize = (try? inputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let cleanSize = (try? outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0

        var stripped: [String] = []
        if originalProps[kCGImagePropertyExifDictionary as String] != nil { stripped.append("EXIF Metadata") }
        if hadGPS { stripped.append("GPS Coordinates & Location") }
        if originalProps[kCGImagePropertyMakerAppleDictionary as String] != nil { stripped.append("Apple MakerNotes & Sensor Data") }
        if originalProps[kCGImagePropertyTIFFDictionary as String] != nil { stripped.append("Camera & Software Tags") }
        if originalProps[kCGImagePropertyIPTCDictionary as String] != nil { stripped.append("IPTC / Author Tags") }

        return MetadataReport(
            strippedKeys: stripped,
            hadGPS: hadGPS,
            cameraModel: cameraModel,
            originalSize: Int64(origSize),
            cleanedSize: Int64(cleanSize)
        )
    }
}

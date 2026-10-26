import SwiftUI
import UniformTypeIdentifiers

// MARK: - Supported Conversion Formats
public enum ConversionFormat: String, CaseIterable, Identifiable, Sendable {
    case png = "PNG"
    case jpeg = "JPEG"
    case webp = "WebP"
    case heic = "HEIC"
    case tiff = "TIFF"
    case bmp = "BMP"
    case avif = "AVIF"
    case pdf = "PDF"
    case mp4 = "MP4"
    case mov = "MOV"
    case gif = "GIF"
    case mp3 = "MP3"
    case m4a = "M4A"
    case wav = "WAV"
    case aiff = "AIFF"
    case docx = "DOCX"
    case txt = "TXT"
    case md = "MD"
    case html = "HTML"
    case zip = "ZIP"

    public var id: String { rawValue }

    public var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .webp: return "webp"
        case .heic: return "heic"
        case .tiff: return "tiff"
        case .bmp: return "bmp"
        case .avif: return "avif"
        case .pdf: return "pdf"
        case .mp4: return "mp4"
        case .mov: return "mov"
        case .gif: return "gif"
        case .mp3: return "mp3"
        case .m4a: return "m4a"
        case .wav: return "wav"
        case .aiff: return "aiff"
        case .docx: return "docx"
        case .txt: return "txt"
        case .md: return "md"
        case .html: return "html"
        case .zip: return "zip"
        }
    }

    public var iconName: String {
        switch self {
        case .png, .jpeg, .webp, .heic, .bmp, .avif: return "photo"
        case .tiff: return "doc.richtext"
        case .pdf: return "doc.text.fill"
        case .mp4, .mov: return "film"
        case .gif: return "play.square"
        case .mp3, .m4a, .wav, .aiff: return "waveform"
        case .docx, .txt, .md, .html: return "doc.plaintext"
        case .zip: return "archivebox"
        }
    }
}

// MARK: - FileCraft Wheels / Modes
public enum ConversionFanMode: String, CaseIterable, Identifiable, Sendable {
    case conversions = "Conversions" // Shift (⇧)
    case tools = "Tools"             // Command (⌘)
    case actions = "Actions"         // Control (⌃)

    public var id: String { rawValue }

    public var shortcutSymbol: String {
        switch self {
        case .conversions: return "⇧"
        case .tools: return "⌘"
        case .actions: return "⌃"
        }
    }

    public var shortcutName: String {
        switch self {
        case .conversions: return "shift"
        case .tools: return "command"
        case .actions: return "control"
        }
    }
}

// MARK: - All Actions Across the 3 Wheels
public enum RadialPetalAction: String, CaseIterable, Identifiable, Sendable {
    // 6 File Actions (Control ⌃)
    case airDrop = "airDrop"
    case floatShelf = "float"
    case copyFiles = "copy"
    case moveFiles = "move"
    case copyPath = "copyPath"
    case openTerminal = "openTerminal"

    // 26 Advanced File Tools (Command ⌘)
    case compress = "compress"
    case removeMetadata = "removeMetadata"
    case editImage = "editImage"
    case annotateImage = "annotateImage"
    case frameImage = "frameImage"
    case cropImage = "cropImage"
    case redactImage = "redactImage"
    case createCollage = "createCollage"
    case createPDF = "createPDF"
    case normalizeAudio = "normalizeAudio"
    case trimAudio = "trimAudio"
    case audioChannels = "audioChannels"
    case audioToVideo = "audioToVideo"
    case redactAudio = "redactAudio"
    case muteVideo = "muteVideo"
    case trimVideo = "trimVideo"
    case cropVideo = "cropVideo"
    case changeVideoSpeed = "changeVideoSpeed"
    case videoSnapshots = "videoSnapshots"
    case splitVideo = "splitVideo"
    case joinVideos = "joinVideos"
    case redactVideo = "redactVideo"
    case splitPDF = "splitPDF"
    case organizePDF = "organizePDF"
    case mergePDF = "mergePDF"
    case extractArchive = "extractArchive"

    // In-Place Conversions (Shift ⇧)
    case convertToJPG = "convertToJPG"
    case convertToPNG = "convertToPNG"
    case convertToWebP = "convertToWebP"
    case convertToHEIC = "convertToHEIC"
    case convertToTIFF = "convertToTIFF"
    case convertToAVIF = "convertToAVIF"
    case convertToBMP = "convertToBMP"
    case convertToPDF = "convertToPDF"
    case convertToMP4 = "convertToMP4"
    case convertToMOV = "convertToMOV"
    case convertToGIF = "convertToGIF"
    case convertToMP3 = "convertToMP3"
    case convertToM4A = "convertToM4A"
    case convertToWAV = "convertToWAV"
    case convertToAIFF = "convertToAIFF"
    case convertToDOCX = "convertToDOCX"
    case convertToTXT = "convertToTXT"
    case convertToMD = "convertToMD"
    case convertToHTML = "convertToHTML"
    case convertToZIP = "convertToZIP"

    // Legacy aliases
    public static var floatingShelf: RadialPetalAction { .floatShelf }
    public static var cleanMetadata: RadialPetalAction { .removeMetadata }
    public static var frameMockup: RadialPetalAction { .frameImage }
    public static var pdfOrganizer: RadialPetalAction { .organizePDF }
    public static var compressMedia: RadialPetalAction { .compress }
    public static var convertToJPEG: RadialPetalAction { .convertToJPG }

    public var id: String { rawValue }

    // MARK: - The 6 Universal File Actions
    public static var fileActions: [RadialPetalAction] {
        [.airDrop, .floatShelf, .copyFiles, .moveFiles, .copyPath, .openTerminal]
    }

    // MARK: - Dynamic Resolver per File Type & Mode
    public static func actions(for urls: [URL], mode: ConversionFanMode) -> [RadialPetalAction] {
        switch mode {
        case .actions:
            return fileActions

        case .tools:
            return tools(for: urls)

        case .conversions:
            return conversions(for: urls)
        }
    }

    private static func tools(for urls: [URL]) -> [RadialPetalAction] {
        guard let firstURL = urls.first else {
            return [.compress, .removeMetadata, .frameImage, .organizePDF, .floatShelf]
        }
        let ext = firstURL.pathExtension.lowercased()
        let isMultiple = urls.count > 1

        if ["jpg", "jpeg", "png", "webp", "heic", "tiff", "bmp"].contains(ext) {
            return isMultiple
                ? [.compress, .removeMetadata, .cropImage, .createPDF, .createCollage]
                : [.compress, .removeMetadata, .editImage, .annotateImage, .frameImage, .cropImage, .redactImage]
        }
        if ["mp4", "mov", "mkv", "avi", "webm"].contains(ext) {
            return isMultiple
                ? [.compress, .removeMetadata, .muteVideo, .trimVideo, .cropVideo, .changeVideoSpeed, .joinVideos]
                : [.compress, .removeMetadata, .muteVideo, .trimVideo, .cropVideo, .changeVideoSpeed, .videoSnapshots, .splitVideo]
        }
        if ["mp3", "m4a", "wav", "flac", "aiff"].contains(ext) {
            return [.compress, .removeMetadata, .normalizeAudio, .audioToVideo, .trimAudio, .audioChannels, .redactAudio]
        }
        if ext == "pdf" {
            return isMultiple
                ? [.compress, .removeMetadata, .splitPDF, .mergePDF]
                : [.compress, .removeMetadata, .splitPDF, .organizePDF]
        }
        if ["zip", "tar", "gz", "tgz", "rar"].contains(ext) {
            return [.extractArchive]
        }
        return [.compress, .removeMetadata, .floatShelf]
    }

    private static func conversions(for urls: [URL]) -> [RadialPetalAction] {
        guard let firstURL = urls.first else {
            return [.convertToPNG, .convertToJPG, .convertToHEIC, .convertToTIFF, .convertToPDF]
        }
        let ext = firstURL.pathExtension.lowercased()

        if ["jpg", "jpeg", "png", "webp", "heic", "tiff", "bmp", "avif", "svg"].contains(ext) {
            var list: [RadialPetalAction] = [
                .convertToPNG, .convertToWebP, .convertToHEIC, .convertToTIFF, .convertToAVIF, .convertToBMP, .convertToPDF, .convertToJPG
            ]
            if ext == "jpg" || ext == "jpeg" {
                list.removeAll { $0 == .convertToJPG }
            } else if ext == "png" {
                list.removeAll { $0 == .convertToPNG }
            } else if ext == "webp" {
                list.removeAll { $0 == .convertToWebP }
            } else if ext == "heic" {
                list.removeAll { $0 == .convertToHEIC }
            } else if ext == "tiff" {
                list.removeAll { $0 == .convertToTIFF }
            } else if ext == "avif" {
                list.removeAll { $0 == .convertToAVIF }
            } else if ext == "bmp" {
                list.removeAll { $0 == .convertToBMP }
            }
            return list
        }
        if ["mp4", "mov", "mkv", "avi", "webm"].contains(ext) {
            return [.convertToMP4, .convertToMOV, .convertToGIF, .convertToMP3]
        }
        if ["mp3", "m4a", "wav", "flac", "aiff"].contains(ext) {
            return [.convertToMP3, .convertToM4A, .convertToWAV, .convertToAIFF]
        }
        if ext == "pdf" {
            return [.convertToJPG, .convertToPNG, .convertToTXT, .convertToDOCX]
        }
        if ["txt", "md", "rtf", "docx"].contains(ext) {
            return [.convertToPDF, .convertToTXT, .convertToHTML, .convertToMD]
        }
        if ["zip", "tar", "gz", "rar"].contains(ext) {
            return [.convertToZIP]
        }
        return [.convertToPNG, .convertToJPG, .convertToPDF]
    }

    // MARK: - Presentation Metadata
    public var title: String {
        switch self {
        // Actions
        case .airDrop: return "AirDrop"
        case .floatShelf: return "Float"
        case .copyFiles: return "Copy"
        case .moveFiles: return "Move"
        case .copyPath: return "Copy Path"
        case .openTerminal: return "Terminal"

        // Tools
        case .compress: return "Compress"
        case .removeMetadata: return "Metadata"
        case .editImage: return "Edit Photo"
        case .annotateImage: return "Annotate"
        case .frameImage: return "Add BG"
        case .cropImage: return "Crop"
        case .redactImage: return "Redact"
        case .createCollage: return "Collage"
        case .createPDF: return "Create PDF"
        case .normalizeAudio: return "Normalize"
        case .trimAudio: return "Trim Audio"
        case .audioChannels: return "Channels"
        case .audioToVideo: return "Visualize"
        case .redactAudio: return "Bleep"
        case .muteVideo: return "Remove Audio"
        case .trimVideo: return "Trim Video"
        case .cropVideo: return "Crop Video"
        case .changeVideoSpeed: return "Speed 2x"
        case .videoSnapshots: return "Snapshot"
        case .splitVideo: return "Split Video"
        case .joinVideos: return "Join"
        case .redactVideo: return "Redact"
        case .splitPDF: return "Split PDF"
        case .organizePDF: return "Organize PDF"
        case .mergePDF: return "Merge PDFs"
        case .extractArchive: return "Extract"

        // Conversions
        case .convertToJPG: return "JPG"
        case .convertToPNG: return "PNG"
        case .convertToWebP: return "WEBP"
        case .convertToHEIC: return "HEIC"
        case .convertToTIFF: return "TIFF"
        case .convertToAVIF: return "AVIF"
        case .convertToBMP: return "BMP"
        case .convertToPDF: return "PDF"
        case .convertToMP4: return "MP4"
        case .convertToMOV: return "MOV"
        case .convertToGIF: return "GIF"
        case .convertToMP3: return "MP3"
        case .convertToM4A: return "M4A"
        case .convertToWAV: return "WAV"
        case .convertToAIFF: return "AIFF"
        case .convertToDOCX: return "DOCX"
        case .convertToTXT: return "TXT"
        case .convertToMD: return "MD"
        case .convertToHTML: return "HTML"
        case .convertToZIP: return "ZIP"
        }
    }

    public var isConversion: Bool {
        rawValue.hasPrefix("convertTo")
    }

    public var subtitle: String {
        switch self {
        case .airDrop: return "Share through recipient picker"
        case .floatShelf: return "Pin to edge shelf"
        case .copyFiles: return "Copy to clipboard"
        case .moveFiles: return "Choose destination folder"
        case .copyPath: return "Copy file path as text"
        case .openTerminal: return "Open containing folder"

        case .compress: return "Reduce file size"
        case .removeMetadata: return "Strip GPS & private tags"
        case .editImage: return "Filters, curves & adjustments"
        case .annotateImage: return "Draw shapes & text"
        case .frameImage: return "Gradient canvas & shadow"
        case .cropImage: return "Aspect ratio & bounds"
        case .redactImage: return "Obscure private areas"
        case .createCollage: return "Combine photos grid"
        case .createPDF: return "Package images into PDF"
        case .normalizeAudio: return "Consistent audio levels"
        case .trimAudio: return "Cut start and end"
        case .audioChannels: return "Stereo to mono mix"
        case .audioToVideo: return "Generate audio visualizer"
        case .redactAudio: return "Mute / bleep segments"
        case .muteVideo: return "Strip audio tracks"
        case .trimVideo: return "Cut video duration"
        case .cropVideo: return "Reframe video canvas"
        case .changeVideoSpeed: return "Double video playback rate"
        case .videoSnapshots: return "Extract keyframe images"
        case .splitVideo: return "Cut into smaller clips"
        case .joinVideos: return "Concatenate clips"
        case .redactVideo: return "Blur face or info"
        case .splitPDF: return "Export individual pages"
        case .organizePDF: return "Rotate, reorder, delete"
        case .mergePDF: return "Combine into single document"
        case .extractArchive: return "Unpack contents to folder"

        case .convertToJPG: return "Standard web image"
        case .convertToPNG: return "Lossless alpha image"
        case .convertToWebP: return "Next-gen web raster"
        case .convertToHEIC: return "High efficiency photo"
        case .convertToTIFF: return "Uncompressed raster"
        case .convertToAVIF: return "Modern AV1 image"
        case .convertToBMP: return "Bitmap raster"
        case .convertToPDF: return "Document presentation"
        case .convertToMP4: return "Standard H.264 video"
        case .convertToMOV: return "Apple QuickTime video"
        case .convertToGIF: return "Animated graphic clip"
        case .convertToMP3: return "Universal audio file"
        case .convertToM4A: return "AAC audio stream"
        case .convertToWAV: return "Uncompressed PCM audio"
        case .convertToAIFF: return "Apple audio format"
        case .convertToDOCX: return "Word document format"
        case .convertToTXT: return "Plain text encoding"
        case .convertToMD: return "Markdown formatted text"
        case .convertToHTML: return "Web hypertext markup"
        case .convertToZIP: return "Compressed ZIP archive"
        }
    }

    public var iconName: String {
        switch self {
        case .airDrop: return "airplayaudio"
        case .floatShelf: return "pin.fill"
        case .copyFiles: return "doc.on.doc"
        case .moveFiles: return "folder"
        case .copyPath: return "doc.text"
        case .openTerminal: return "terminal"

        case .compress: return "arrow.down.right.and.arrow.up.left"
        case .removeMetadata: return "tag"
        case .editImage: return "slider.horizontal.3"
        case .annotateImage: return "pencil.and.outline"
        case .frameImage: return "photo.artframe"
        case .cropImage: return "crop"
        case .redactImage: return "eye.slash"
        case .createCollage: return "rectangle.3.group"
        case .createPDF: return "doc.badge.plus"
        case .normalizeAudio: return "waveform"
        case .trimAudio: return "scissors"
        case .audioChannels: return "hifispeaker.2"
        case .audioToVideo: return "waveform"
        case .redactAudio: return "waveform.badge.minus"
        case .muteVideo: return "speaker.slash.fill"
        case .trimVideo: return "scissors"
        case .cropVideo: return "crop"
        case .changeVideoSpeed: return "speedometer"
        case .videoSnapshots: return "camera"
        case .splitVideo: return "film"
        case .joinVideos: return "film.stack"
        case .redactVideo: return "eye.slash"
        case .splitPDF: return "rectangle.split.2x1"
        case .organizePDF: return "square.grid.2x2"
        case .mergePDF: return "doc.on.doc"
        case .extractArchive: return "archivebox"

        case .convertToJPG, .convertToPNG, .convertToWebP, .convertToHEIC, .convertToAVIF, .convertToBMP: return "photo"
        case .convertToTIFF: return "doc.richtext"
        case .convertToPDF: return "doc.text.fill"
        case .convertToMP4, .convertToMOV: return "film"
        case .convertToGIF: return "play.square"
        case .convertToMP3, .convertToM4A, .convertToWAV, .convertToAIFF: return "waveform"
        case .convertToDOCX, .convertToTXT, .convertToMD, .convertToHTML: return "doc.plaintext"
        case .convertToZIP: return "archivebox"
        }
    }

    public var accentColor: Color {
        switch self {
        case .airDrop: return Color(red: 0.1, green: 0.6, blue: 1.0)
        case .floatShelf: return Color(red: 1.0, green: 0.7, blue: 0.1)
        case .copyFiles: return Color(red: 0.4, green: 0.8, blue: 0.4)
        case .moveFiles: return Color(red: 0.9, green: 0.6, blue: 0.2)
        case .copyPath: return Color(red: 0.6, green: 0.4, blue: 0.9)
        case .openTerminal: return Color(red: 0.3, green: 0.3, blue: 0.3)

        case .compress: return Color(red: 0.0, green: 0.75, blue: 0.85)
        case .removeMetadata: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .frameImage: return Color(red: 0.35, green: 0.45, blue: 1.0)
        case .organizePDF, .splitPDF, .mergePDF: return Color(red: 0.95, green: 0.3, blue: 0.3)
        case .muteVideo, .trimVideo, .cropVideo, .changeVideoSpeed, .videoSnapshots: return Color(red: 0.65, green: 0.3, blue: 0.95)
        case .extractArchive: return Color(red: 0.9, green: 0.5, blue: 0.1)

        default: return Color(red: 1.0, green: 0.55, blue: 0.0) // FileCraft orange default
        }
    }
}

// MARK: - Canvas Frame Background Presets
public struct FrameGradientPreset: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let colors: [Color]
    public let startPoint: UnitPoint
    public let endPoint: UnitPoint

    public static let presets: [FrameGradientPreset] = [
        FrameGradientPreset(
            id: "craft_sunset",
            name: "Craft Sunset",
            colors: [Color(red: 1.0, green: 0.45, blue: 0.15), Color(red: 1.0, green: 0.75, blue: 0.25)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        FrameGradientPreset(
            id: "deep_ocean",
            name: "Deep Ocean",
            colors: [Color(red: 0.1, green: 0.2, blue: 0.5), Color(red: 0.1, green: 0.6, blue: 0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        FrameGradientPreset(
            id: "purple_haze",
            name: "Purple Haze",
            colors: [Color(red: 0.45, green: 0.15, blue: 0.75), Color(red: 0.85, green: 0.3, blue: 0.65)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        FrameGradientPreset(
            id: "emerald_glow",
            name: "Emerald Glow",
            colors: [Color(red: 0.05, green: 0.4, blue: 0.3), Color(red: 0.2, green: 0.75, blue: 0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        FrameGradientPreset(
            id: "minimal_dark",
            name: "Minimal Dark",
            colors: [Color(white: 0.12), Color(white: 0.22)],
            startPoint: .top,
            endPoint: .bottom
        ),
        FrameGradientPreset(
            id: "minimal_light",
            name: "Pure Light",
            colors: [Color(white: 0.94), Color(white: 0.86)],
            startPoint: .top,
            endPoint: .bottom
        )
    ]
}

// MARK: - Frame Canvas Ratio
public enum FrameCanvasRatio: String, CaseIterable, Identifiable, Sendable {
    case auto = "Auto"
    case square = "1:1"
    case standard = "4:3"
    case widescreen = "16:9"

    public var id: String { rawValue }

    public func ratio(originalWidth: CGFloat, originalHeight: CGFloat) -> CGFloat? {
        switch self {
        case .auto: return nil
        case .square: return 1.0
        case .standard: return 4.0 / 3.0
        case .widescreen: return 16.0 / 9.0
        }
    }
}

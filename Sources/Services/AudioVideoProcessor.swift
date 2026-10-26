import AppKit
import AVFoundation
import CoreGraphics
import UniformTypeIdentifiers

public enum AudioVideoProcessor {

    // MARK: - Mute Video (Remove Audio Track)
    public static func muteVideo(inputURL: URL, outputURL: URL) async throws {
        let asset = AVURLAsset(url: inputURL)
        let composition = AVMutableComposition()

        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let firstVideoTrack = videoTracks.first else {
            throw NSError(domain: "AudioVideoProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "No video track found"])
        }

        let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let duration = try await asset.load(.duration)
        let timeRange = CMTimeRange(start: .zero, duration: duration)
        try compVideoTrack?.insertTimeRange(timeRange, of: firstVideoTrack, at: .zero)

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            throw NSError(domain: "AudioVideoProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        await exportSession.export()

        if exportSession.status != .completed {
            throw exportSession.error ?? NSError(domain: "AudioVideoProcessor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Export failed"])
        }
    }

    // MARK: - Video Snapshot (Extract Frame as Image)
    public static func extractSnapshot(inputURL: URL, outputURL: URL) async throws {
        let asset = AVURLAsset(url: inputURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        let cgImage = try await generator.image(at: time).image

        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw NSError(domain: "AudioVideoProcessor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create snapshot destination"])
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "AudioVideoProcessor", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize snapshot"])
        }
    }

    // MARK: - Extract Audio from Video (To M4A / Audio)
    public static func extractAudio(inputURL: URL, outputURL: URL) async throws {
        let asset = AVURLAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "AudioVideoProcessor", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio export session"])
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        await exportSession.export()

        if exportSession.status != .completed {
            throw exportSession.error ?? NSError(domain: "AudioVideoProcessor", code: 7, userInfo: [NSLocalizedDescriptionKey: "Audio export failed"])
        }
    }

    // MARK: - Compress Video
    public static func compressVideo(inputURL: URL, outputURL: URL) async throws {
        let asset = AVURLAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            throw NSError(domain: "AudioVideoProcessor", code: 8, userInfo: [NSLocalizedDescriptionKey: "Failed to create video compression session"])
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        await exportSession.export()

        if exportSession.status != .completed {
            throw exportSession.error ?? NSError(domain: "AudioVideoProcessor", code: 9, userInfo: [NSLocalizedDescriptionKey: "Video compression failed"])
        }
    }

    // MARK: - Change Video Speed (2x Speed)
    public static func changeVideoSpeed(inputURL: URL, outputURL: URL, rate: Float = 2.0) async throws {
        let asset = AVURLAsset(url: inputURL)
        let composition = AVMutableComposition()

        let duration = try await asset.load(.duration)
        let timeRange = CMTimeRange(start: .zero, duration: duration)
        let scaledDuration = CMTimeMultiplyByFloat64(duration, multiplier: 1.0 / Float64(rate))

        if let videoTrack = try await asset.loadTracks(withMediaType: .video).first {
            let compTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            compTrack?.scaleTimeRange(timeRange, toDuration: scaledDuration)
        }

        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            let compTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compTrack?.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            compTrack?.scaleTimeRange(timeRange, toDuration: scaledDuration)
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "AudioVideoProcessor", code: 10, userInfo: [NSLocalizedDescriptionKey: "Failed to create speed export session"])
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        await exportSession.export()

        if exportSession.status != .completed {
            throw exportSession.error ?? NSError(domain: "AudioVideoProcessor", code: 11, userInfo: [NSLocalizedDescriptionKey: "Speed change export failed"])
        }
    }

    // MARK: - Join Multiple Videos Sequentially
    public static func joinVideos(inputURLs: [URL], outputURL: URL) async throws {
        guard inputURLs.count > 1 else { return }
        let composition = AVMutableComposition()
        let compVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        var currentTime = CMTime.zero

        for url in inputURLs {
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            let timeRange = CMTimeRange(start: .zero, duration: duration)

            if let videoTrack = try? await asset.loadTracks(withMediaType: .video).first {
                try? compVideo?.insertTimeRange(timeRange, of: videoTrack, at: currentTime)
            }
            if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first {
                try? compAudio?.insertTimeRange(timeRange, of: audioTrack, at: currentTime)
            }
            currentTime = CMTimeAdd(currentTime, duration)
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "AudioVideoProcessor", code: 12, userInfo: [NSLocalizedDescriptionKey: "Failed to create join export session"])
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        await exportSession.export()

        if exportSession.status != .completed {
            throw exportSession.error ?? NSError(domain: "AudioVideoProcessor", code: 13, userInfo: [NSLocalizedDescriptionKey: "Join videos export failed"])
        }
    }

    // MARK: - Split Video into Halves
    public static func splitVideo(inputURL: URL, outputURL1: URL, outputURL2: URL) async throws {
        let asset = AVURLAsset(url: inputURL)
        let duration = try await asset.load(.duration)
        let totalSeconds = CMTimeGetSeconds(duration)
        guard totalSeconds > 1.0 else { return }

        let halfTime = CMTime(seconds: totalSeconds / 2.0, preferredTimescale: 600)
        let range1 = CMTimeRange(start: .zero, duration: halfTime)
        let range2 = CMTimeRange(start: halfTime, duration: CMTimeSubtract(duration, halfTime))

        // Export Part 1
        if let export1 = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) {
            export1.outputURL = outputURL1
            export1.outputFileType = .mp4
            export1.timeRange = range1
            await export1.export()
        }

        // Export Part 2
        if let export2 = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) {
            export2.outputURL = outputURL2
            export2.outputFileType = .mp4
            export2.timeRange = range2
            await export2.export()
        }
    }

    // MARK: - Normalize Audio Peak
    public static func normalizeAudio(inputURL: URL, outputURL: URL) async throws {
        let asset = AVURLAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "AudioVideoProcessor", code: 14, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio normalization session"])
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        await exportSession.export()

        if exportSession.status != .completed {
            throw exportSession.error ?? NSError(domain: "AudioVideoProcessor", code: 15, userInfo: [NSLocalizedDescriptionKey: "Audio normalization failed"])
        }
    }

    // MARK: - Convert Audio to Mono
    public static func convertAudioToMono(inputURL: URL, outputURL: URL) async throws {
        let asset = AVURLAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "AudioVideoProcessor", code: 16, userInfo: [NSLocalizedDescriptionKey: "Failed to create mono export session"])
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        await exportSession.export()

        if exportSession.status != .completed {
            throw exportSession.error ?? NSError(domain: "AudioVideoProcessor", code: 17, userInfo: [NSLocalizedDescriptionKey: "Mono export failed"])
        }
    }
}

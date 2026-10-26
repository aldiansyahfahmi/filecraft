import SwiftUI
import AVKit
import AVFoundation

public enum VideoCropRatio: String, CaseIterable, Identifiable {
    case square = "1:1 Square"
    case vertical = "9:16 Vertical (Reel / TikTok)"
    case widescreen = "16:9 Landscape"

    public var id: String { rawValue }

    public var targetAspect: CGFloat {
        switch self {
        case .square: return 1.0
        case .vertical: return 9.0 / 16.0
        case .widescreen: return 16.0 / 9.0
        }
    }
}

public struct VideoCropStudioView: View {
    public let videoURL: URL?
    @State private var player: AVPlayer?
    @State private var selectedRatio: VideoCropRatio = .square

    @State private var isExporting: Bool = false
    @State private var exportSuccess: Bool = false

    public init(videoURL: URL?) {
        self.videoURL = videoURL
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Player Preview (Left)
            VStack {
                if let p = player {
                    VideoPlayer(player: p)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 4)
                        .padding(24)
                } else {
                    Text("Loading video...")
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))

            Divider()

            // Controls (Right)
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "crop")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Crop Video")
                        .font(.system(size: 15, weight: .bold))
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Aspect Ratio")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    ForEach(VideoCropRatio.allCases) { r in
                        Button {
                            selectedRatio = r
                        } label: {
                            HStack {
                                Text(r.rawValue)
                                    .font(.system(size: 12))
                                Spacer()
                                if selectedRatio == r {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedRatio == r ? Color.orange.opacity(0.15) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                Button {
                    exportCroppedVideo()
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView().scaleEffect(0.7)
                        } else if exportSuccess {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(exportSuccess ? "Saved!" : "Crop & Export Video")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(isExporting)
            }
            .padding(18)
            .frame(width: 260)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(minWidth: 780, minHeight: 520)
        .onAppear {
            if let u = videoURL {
                self.player = AVPlayer(url: u)
            }
        }
    }

    private func exportCroppedVideo() {
        guard let sourceURL = videoURL else { return }
        isExporting = true

        let dir = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Cropped", ext: "mp4")

        Task {
            let asset = AVURLAsset(url: sourceURL)
            guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
                await MainActor.run { isExporting = false }
                return
            }

            let naturalSize = try await videoTrack.load(.naturalSize)
            let duration = try await asset.load(.duration)

            var targetW = naturalSize.width
            var targetH = naturalSize.height

            if selectedRatio == .square {
                let side = min(naturalSize.width, naturalSize.height)
                targetW = side
                targetH = side
            } else if selectedRatio == .vertical {
                targetW = min(naturalSize.width, naturalSize.height * (9.0 / 16.0))
                targetH = targetW * (16.0 / 9.0)
            }

            let composition = AVMutableComposition()
            let compTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            let timeRange = CMTimeRange(start: .zero, duration: duration)
            try? compTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)

            if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first {
                let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                try? compAudio?.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            }

            let videoComp = AVMutableVideoComposition()
            videoComp.renderSize = CGSize(width: targetW, height: targetH)
            videoComp.frameDuration = CMTime(value: 1, timescale: 30)

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = timeRange

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compTrack!)
            let offsetX = (targetW - naturalSize.width) / 2.0
            let offsetY = (targetH - naturalSize.height) / 2.0
            let transform = CGAffineTransform(translationX: offsetX, y: offsetY)
            layerInstruction.setTransform(transform, at: .zero)
            instruction.layerInstructions = [layerInstruction]
            videoComp.instructions = [instruction]

            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                await MainActor.run { isExporting = false }
                return
            }

            exportSession.outputURL = outURL
            exportSession.outputFileType = .mp4
            exportSession.videoComposition = videoComp

            await exportSession.export()

            await MainActor.run {
                self.isExporting = false
                if exportSession.status == .completed {
                    self.exportSuccess = true
                    SoundManager.shared.playActionComplete()
                    NSWorkspace.shared.activateFileViewerSelecting([outURL])
                }
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

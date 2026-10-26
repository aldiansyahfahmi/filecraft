import SwiftUI
import AVKit
import AVFoundation

public struct VideoTrimStudioView: View {
    public let videoURL: URL?
    @State private var player: AVPlayer?
    @State private var totalDuration: Double = 0.0

    @State private var startTime: Double = 0.0
    @State private var endTime: Double = 0.0
    @State private var isPlaying: Bool = false

    @State private var isExporting: Bool = false
    @State private var exportSuccess: Bool = false

    public init(videoURL: URL?) {
        self.videoURL = videoURL
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Video Player (Left)
            VStack(spacing: 12) {
                if let p = player {
                    VideoPlayer(player: p)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 4)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    HStack(spacing: 16) {
                        Button {
                            togglePlay()
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 18))
                        }
                        .buttonStyle(.plain)

                        Text(formatTime(startTime) + " — " + formatTime(endTime))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 16)
                } else {
                    Text("Loading video...")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))

            Divider()

            // Trimming Controls (Right)
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "timeline.selection")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Trim Video")
                        .font(.system(size: 15, weight: .bold))
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Start Time")
                            .font(.system(size: 12))
                        Spacer()
                        Text(formatTime(startTime))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $startTime, in: 0...max(0.1, endTime - 0.5)) { _ in
                        seekPlayer(to: startTime)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("End Time")
                            .font(.system(size: 12))
                        Spacer()
                        Text(formatTime(endTime))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $endTime, in: min(totalDuration, startTime + 0.5)...max(0.1, totalDuration)) { _ in
                        seekPlayer(to: endTime)
                    }
                }

                Divider()

                HStack {
                    Text("Trimmed Duration:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatTime(max(0, endTime - startTime)))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                }

                Spacer()

                Button {
                    exportTrimmedVideo()
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView().scaleEffect(0.7)
                        } else if exportSuccess {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(exportSuccess ? "Saved!" : "Export Trimmed Video")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(isExporting || totalDuration == 0)
            }
            .padding(18)
            .frame(width: 260)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(minWidth: 780, minHeight: 520)
        .onAppear {
            setupPlayer()
        }
    }

    private func setupPlayer() {
        guard let url = videoURL else { return }
        let asset = AVURLAsset(url: url)
        Task {
            if let duration = try? await asset.load(.duration) {
                let durSec = CMTimeGetSeconds(duration)
                await MainActor.run {
                    self.totalDuration = durSec
                    self.startTime = 0.0
                    self.endTime = durSec
                    self.player = AVPlayer(url: url)
                }
            }
        }
    }

    private func togglePlay() {
        guard let p = player else { return }
        if isPlaying {
            p.pause()
            isPlaying = false
        } else {
            p.play()
            isPlaying = true
        }
    }

    private func seekPlayer(to seconds: Double) {
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let ms = Int((seconds.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", mins, secs, ms)
    }

    private func exportTrimmedVideo() {
        guard let sourceURL = videoURL else { return }
        isExporting = true

        let dir = sourceURL.deletingLastPathComponent()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Trimmed", ext: "mp4")

        Task {
            let asset = AVURLAsset(url: sourceURL)
            let startCM = CMTime(seconds: startTime, preferredTimescale: 600)
            let durCM = CMTime(seconds: endTime - startTime, preferredTimescale: 600)
            let timeRange = CMTimeRange(start: startCM, duration: durCM)

            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
                await MainActor.run { isExporting = false }
                return
            }

            exportSession.outputURL = outURL
            exportSession.outputFileType = .mp4
            exportSession.timeRange = timeRange

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

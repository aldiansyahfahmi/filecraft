import SwiftUI

public struct AboutView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .orange.opacity(0.4), radius: 10, y: 5)

                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text("FileCraft")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))

                Text("Version 2.0.2 • Pro File Actions & Conversions")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Text("The modern drag-and-drop workspace, floating drop shelf, radial petal conversion wheel, and creative file utility suite for macOS.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Divider()

            HStack(spacing: 12) {
                Label("Mach-O arm64", systemImage: "cpu")
                Label("SwiftUI + AppKit", systemImage: "swift")
                Label("REA Reverse Engine", systemImage: "wrench.and.screwdriver")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 380, height: 260)
    }
}

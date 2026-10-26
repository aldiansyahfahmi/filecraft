import SwiftUI
import UniformTypeIdentifiers
import QuickLook

public struct FloatingShelfView: View {
    @ObservedObject var groupModel: FloatingShelfModel
    public var onTriggerAction: ((RadialPetalAction, [URL]) -> Void)?
    public var onClose: (() -> Void)?

    @State private var hoveredItemId: UUID? = nil
    @State private var isCollapsed: Bool = false

    public var body: some View {
        Group {
            if isCollapsed {
                collapsedTabHandle
            } else {
                expandedShelfView
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.75), value: isCollapsed)
    }

    // MARK: - Collapsed Mini Tab Handle
    private var collapsedTabHandle: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 26, height: 26)

                Image(systemName: "paperclip")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            if !groupModel.items.isEmpty {
                Text("\(groupModel.items.count)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
            }

            Image(systemName: "chevron.left")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                isCollapsed = false
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            withAnimation {
                isCollapsed = false
            }
            handleDrop(providers)
            return true
        }
    }

    // MARK: - Expanded Full Shelf View
    private var expandedShelfView: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 8) {
                // FileCraft Paperclip Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 28, height: 28)

                    Image(systemName: "paperclip")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("FileCraft Shelf")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("\(groupModel.items.count) item\(groupModel.items.count == 1 ? "" : "s")")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Collapse Button
                Button {
                    withAnimation {
                        isCollapsed = true
                    }
                } label: {
                    Image(systemName: "arrow.right.to.line.compact")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Collapse Float to screen edge")

                // Actions Menu Button
                if !groupModel.items.isEmpty {
                    Menu {
                        Button {
                            onTriggerAction?(.convertToPNG, groupModel.items.map(\.url))
                        } label: {
                            Label("Convert to PNG", systemImage: "photo.fill")
                        }

                        Button {
                            onTriggerAction?(.convertToJPEG, groupModel.items.map(\.url))
                        } label: {
                            Label("Convert to JPEG", systemImage: "photo")
                        }

                        Button {
                            onTriggerAction?(.cleanMetadata, groupModel.items.map(\.url))
                        } label: {
                            Label("Clean Privacy / EXIF", systemImage: "shield.lefthalf.filled")
                        }

                        Button {
                            onTriggerAction?(.pdfOrganizer, groupModel.items.map(\.url))
                        } label: {
                            Label("Organize as PDF", systemImage: "doc.on.doc.fill")
                        }

                        Divider()

                        Button(role: .destructive) {
                            groupModel.clearAll()
                        } label: {
                            Label("Clear Shelf", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24, height: 24)
                }

                // Close Button
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .opacity(0.4)

            // Content Area
            if groupModel.items.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange.opacity(0.7))

                    Text("Drop files here")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Hold Option while dragging files to pop the shelf")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    Button {
                        selectFilesPrompt()
                    } label: {
                        Text("Browse Files...")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 8) {
                        ForEach(groupModel.items) { item in
                            ShelfItemRow(
                                item: item,
                                isHovered: hoveredItemId == item.id,
                                onRemove: {
                                    groupModel.removeItem(item)
                                },
                                onQuickLook: {
                                    NSWorkspace.shared.open(item.url)
                                }
                            )
                            .onHover { hovering in
                                hoveredItemId = hovering ? item.id : nil
                            }
                        }
                    }
                    .padding(12)
                }
            }

            // Bottom Quick Actions Bar
            if !groupModel.items.isEmpty {
                Divider().opacity(0.4)

                HStack(spacing: 8) {
                    Button {
                        onTriggerAction?(.convertToPNG, groupModel.items.map(\.url))
                    } label: {
                        Label("Convert", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.small)

                    Button {
                        onTriggerAction?(.frameMockup, groupModel.items.map(\.url))
                    } label: {
                        Label("Frame", systemImage: "square.inset.filled")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        onTriggerAction?(.cleanMetadata, groupModel.items.map(\.url))
                    } label: {
                        Label("Clean", systemImage: "shield.lefthalf.filled")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()

                    // Reveal in Finder
                    Button {
                        revealInFinder()
                    } label: {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Reveal files in Finder")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 290, height: 380)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 10)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
            return true
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        Task {
            for provider in providers {
                if let item = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier),
                   let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    await MainActor.run {
                        groupModel.addFile(url: url)
                        SoundManager.shared.playDropSuccess()
                    }
                }
            }
        }
    }

    private func selectFilesPrompt() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            for url in panel.urls {
                groupModel.addFile(url: url)
            }
            SoundManager.shared.playDropSuccess()
        }
    }

    private func revealInFinder() {
        let urls = groupModel.items.map(\.url)
        if !urls.isEmpty {
            NSWorkspace.shared.activateFileViewerSelecting(urls)
        }
    }
}

// MARK: - Shelf Item Row
private struct ShelfItemRow: View {
    @ObservedObject var item: FloatingFileItem
    let isHovered: Bool
    let onRemove: () -> Void
    let onQuickLook: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail Preview
            Group {
                if let thumb = item.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                }
            }
            .frame(width: 38, height: 38)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )

            // File Details
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(item.fileExtension.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                    Text(item.formattedSize)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Remove Button on Hover
            if isHovered {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(5)
                        .background(Circle().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onQuickLook()
        }
        .onDrag {
            NSItemProvider(object: item.url as NSURL)
        }
        .contextMenu {
            Button {
                NSWorkspace.shared.open(item.url)
            } label: {
                Label("Open", systemImage: "arrow.up.forward.app")
            }

            Button {
                onQuickLook()
            } label: {
                Label("Quick Look", systemImage: "eye")
            }

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            } label: {
                Label("Show in Finder", systemImage: "folder")
            }

            Divider()

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([item.url as NSURL])
            } label: {
                Label("Copy File", systemImage: "doc.on.doc")
            }

            Button {
                duplicateFile(item.url)
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }

            Divider()

            Button(role: .destructive) {
                try? FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
                onRemove()
            } label: {
                Label("Move to Trash", systemImage: "trash")
            }

            Button {
                onRemove()
            } label: {
                Label("Remove from Float", systemImage: "xmark.circle")
            }
        }
    }

    private func duplicateFile(_ url: URL) {
        let dir = url.deletingLastPathComponent()
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        let newURL = dir.appendingPathComponent("\(name) copy.\(ext)")
        try? FileManager.default.copyItem(at: url, to: newURL)
    }
}

// MARK: - Floating Shelf Model
@MainActor
public final class FloatingShelfModel: ObservableObject {
    @Published public var items: [FloatingFileItem] = []

    public init() {}

    public func addFile(url: URL) {
        if !items.contains(where: { $0.url == url }) {
            items.append(FloatingFileItem(url: url))
        }
    }

    public func removeItem(_ item: FloatingFileItem) {
        items.removeAll(where: { $0.id == item.id })
    }

    public func clearAll() {
        items.removeAll()
    }
}

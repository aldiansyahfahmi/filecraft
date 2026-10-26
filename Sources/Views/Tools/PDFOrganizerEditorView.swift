import SwiftUI
import AppKit
import PDFKit

public struct PDFOrganizerEditorView: View {
    @State private var pdfPages: [PDFPageItem] = []
    @State private var selectedPageId: UUID? = nil
    @State private var statusMessage: String?
    private let initialURL: URL?

    public init(initialURL: URL? = nil) {
        self.initialURL = initialURL
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            HStack(spacing: 12) {
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text("PDF Organizer Studio")
                        .font(.system(size: 15, weight: .bold))

                    Text("\(pdfPages.count) pages loaded")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Page Actions
                if let selectedId = selectedPageId,
                   let index = pdfPages.firstIndex(where: { $0.id == selectedId }) {
                    Button {
                        rotatePage(at: index, by: 90)
                    } label: {
                        Label("Rotate", systemImage: "rotate.right")
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        deletePage(at: index)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }

                Button("Add PDF...") {
                    addPDFPrompt()
                }
                .buttonStyle(.bordered)

                Button("Export PDF...") {
                    exportPDFPrompt()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(pdfPages.isEmpty)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Main Content Area: Thumbnails Grid
            if pdfPages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("Drop a PDF here to reorder, rotate, or merge pages")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    Button("Open PDF...") {
                        addPDFPrompt()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers)
                    return true
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 180))], spacing: 16) {
                        ForEach(Array(pdfPages.enumerated()), id: \.element.id) { index, item in
                            VStack(spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    Image(nsImage: item.thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 180)
                                        .rotationEffect(.degrees(Double(item.rotation)))
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)

                                    Text("\(index + 1)")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                        .padding(6)
                                }
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedPageId == item.id ? Color.red : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedPageId = item.id
                                }

                                Text("Page \(index + 1)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(20)
                }
                .background(Color(NSColor.windowBackgroundColor))
            }

            if let msg = statusMessage {
                HStack {
                    Text(msg)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            if let url = initialURL {
                loadPDF(url: url)
            }
        }
    }

    private func loadPDF(url: URL) {
        let pages = PDFProcessor.loadPages(from: url)
        pdfPages.append(contentsOf: pages)
    }

    private func addPDFPrompt() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            for url in panel.urls {
                loadPDF(url: url)
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        Task {
            for p in providers {
                if let item = try? await p.loadItem(forTypeIdentifier: "public.file-url"),
                   let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil),
                   url.pathExtension.lowercased() == "pdf" {
                    await MainActor.run {
                        loadPDF(url: url)
                    }
                }
            }
        }
    }

    private func rotatePage(at index: Int, by degrees: Int) {
        var page = pdfPages[index]
        page.rotation = (page.rotation + degrees) % 360
        pdfPages[index] = page
    }

    private func deletePage(at index: Int) {
        pdfPages.remove(at: index)
        selectedPageId = nil
    }

    private func exportPDFPrompt() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "Organized.pdf"
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try PDFProcessor.exportDocument(from: pdfPages, to: url)
                statusMessage = "Successfully exported PDF to \(url.lastPathComponent)!"
                SoundManager.shared.playActionComplete()
            } catch {
                statusMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }
}

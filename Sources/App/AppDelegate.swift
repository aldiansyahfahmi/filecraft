import AppKit
import SwiftUI
import PDFKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var isWorking: Bool = false
    private var activeWindows: [String: NSWindowController] = [:]

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory / menu bar app (LSUIElement = true)
        NSApp.setActivationPolicy(.accessory)
        ProcessInfo.processInfo.disableAutomaticTermination("FileCraft active background monitor")

        setupStatusBar()
        setupDragMonitoring()
        setupGlobalEventMonitors()

        NSLog("[FileCraft] Application initialized and ready.")
    }

    // MARK: - Status Bar Setup
    private func setupStatusBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "circle.hexagongrid.fill", accessibilityDescription: "FileCraft")
            button.imagePosition = .imageLeft
        }

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        self.statusItem = item
    }

    private func updateStatusWorking(_ working: Bool) {
        self.isWorking = working
        if let button = statusItem?.button {
            let symbol = working ? "arrow.triangle.2.circlepath" : "circle.hexagongrid.fill"
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "FileCraft")
        }
    }

    // MARK: - Drag Monitoring Setup (Shift: Conversions, Command: Tools, Control: Actions)
    private func setupDragMonitoring() {
        DragGestureMonitor.shared.onDragDetected = { [weak self] urls, mousePoint, mode in
            self?.handleDragDetected(urls: urls, mousePoint: mousePoint, mode: mode)
        }
        DragGestureMonitor.shared.onModeSwitched = { mode in
            RadialFanOverlayController.shared.switchMode(to: mode)
        }
        DragGestureMonitor.shared.onEscapeDismiss = {
            RadialFanOverlayController.shared.close()
        }
        DragGestureMonitor.shared.startMonitoring()

        FloatingShelfPanel.shared.onTriggerTool = { [weak self] action, urls in
            self?.executeAction(action, urls: urls)
        }
    }

    private func handleDragDetected(urls: [URL], mousePoint: CGPoint, mode: ConversionFanMode) {
        RadialFanOverlayController.shared.show(at: mousePoint, urls: urls, initialMode: mode) { [weak self] action, selectedURLs in
            self?.executeAction(action, urls: selectedURLs)
        }
    }

    // MARK: - Global Keyboard Shortcuts
    private func setupGlobalEventMonitors() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == [.option, .command] {
                switch event.charactersIgnoringModifiers?.lowercased() {
                case "f":
                    FloatingShelfPanel.shared.toggle()
                    return nil
                case "w":
                    self?.openRadialWheelAtMouse()
                    return nil
                case "i":
                    self?.openImageFrameStudio()
                    return nil
                case "m":
                    self?.openMetadataCleanerStudio()
                    return nil
                case "p":
                    self?.openPDFOrganizerStudio()
                    return nil
                case "q":
                    self?.openQRCodeOCRStudio()
                    return nil
                case "c":
                    self?.openMediaConverterStudio()
                    return nil
                default:
                    break
                }
            }
            return event
        }
    }

    // MARK: - Comprehensive Action Execution
    public func executeAction(_ action: RadialPetalAction, urls: [URL]) {
        NSLog("[FileCraft] Executing action: \(action.rawValue) on \(urls.count) files")

        switch action {
        // 6 File Actions (Control ⌃)
        case .airDrop:
            FileActionService.airDrop(urls: urls)
        case .floatShelf:
            FileActionService.float(urls: urls)
        case .copyFiles:
            FileActionService.copy(urls: urls)
        case .moveFiles:
            FileActionService.move(urls: urls)
        case .copyPath:
            FileActionService.copyPath(urls: urls)
        case .openTerminal:
            FileActionService.openTerminal(urls: urls)

        // 26 Advanced File Tools (Command ⌘)
        case .compress:
            compressMediaFiles(urls: urls)
        case .removeMetadata:
            cleanMetadataInPlace(urls: urls)
        case .editImage:
            openPhotoEditorStudio(with: urls.first)
        case .cropImage:
            openCropStudio(with: urls.first)
        case .annotateImage:
            openAnnotationStudio(with: urls.first)
        case .frameImage:
            openImageFrameStudio(with: urls.first)
        case .redactImage:
            openRedactStudio(with: urls.first)
        case .createCollage:
            openCollageStudio(with: urls)
        case .createPDF:
            convertDirectly(urls: urls, format: .pdf)
        case .normalizeAudio:
            normalizeAudioInPlace(urls: urls)
        case .trimAudio:
            openMediaConverterStudio(with: urls)
        case .audioChannels:
            convertAudioChannelsInPlace(urls: urls)
        case .audioToVideo:
            snapshotVideoInPlace(urls: urls)
        case .redactAudio:
            muteVideoInPlace(urls: urls)
        case .muteVideo:
            muteVideoInPlace(urls: urls)
        case .trimVideo:
            openVideoTrimStudio(with: urls.first)
        case .cropVideo:
            openVideoCropStudio(with: urls.first)
        case .splitVideo:
            splitVideoInPlace(urls: urls)
        case .joinVideos:
            joinVideosInPlace(urls: urls)
        case .redactVideo:
            muteVideoInPlace(urls: urls)
        case .changeVideoSpeed:
            changeSpeedVideoInPlace(urls: urls)
        case .videoSnapshots:
            snapshotVideoInPlace(urls: urls)
        case .splitPDF:
            splitPDFInPlace(urls: urls)
        case .organizePDF:
            openPDFOrganizerStudio(with: urls.first)
        case .mergePDF:
            mergePDFsInPlace(urls: urls)
        case .extractArchive:
            extractArchiveInPlace(urls: urls)

        // In-Place Conversions (Shift ⇧)
        case .convertToJPG:
            convertDirectly(urls: urls, format: .jpeg)
        case .convertToPNG:
            convertDirectly(urls: urls, format: .png)
        case .convertToWebP:
            convertDirectly(urls: urls, format: .webp)
        case .convertToHEIC:
            convertDirectly(urls: urls, format: .heic)
        case .convertToTIFF:
            convertDirectly(urls: urls, format: .tiff)
        case .convertToAVIF:
            convertDirectly(urls: urls, format: .avif)
        case .convertToBMP:
            convertDirectly(urls: urls, format: .bmp)
        case .convertToPDF:
            convertDirectly(urls: urls, format: .pdf)
        case .convertToMP4:
            convertDirectly(urls: urls, format: .mp4)
        case .convertToMOV:
            convertDirectly(urls: urls, format: .mov)
        case .convertToGIF:
            snapshotVideoInPlace(urls: urls)
        case .convertToMP3:
            extractAudioInPlace(urls: urls, format: .mp3)
        case .convertToM4A:
            extractAudioInPlace(urls: urls, format: .m4a)
        case .convertToWAV:
            convertDirectly(urls: urls, format: .wav)
        case .convertToAIFF:
            convertDirectly(urls: urls, format: .aiff)
        case .convertToDOCX:
            convertDirectly(urls: urls, format: .docx)
        case .convertToTXT:
            convertDirectly(urls: urls, format: .txt)
        case .convertToMD:
            convertDirectly(urls: urls, format: .md)
        case .convertToHTML:
            convertDirectly(urls: urls, format: .html)
        case .convertToZIP:
            zipFiles(urls: urls)
        }
    }

    // MARK: - Direct In-Place Background Conversion
    private func convertDirectly(urls: [URL], format: ConversionFormat) {
        guard !urls.isEmpty else {
            openMediaConverterStudio()
            return
        }

        updateStatusWorking(true)

        Task {
            var convertedURLs: [URL] = []
            for url in urls {
                let dir = url.deletingLastPathComponent()
                let baseName = url.deletingPathExtension().lastPathComponent
                let outURL = generateUniqueURL(dir: dir, baseName: baseName, ext: format.fileExtension)

                do {
                    try ImageProcessor.convert(
                        inputURL: url,
                        targetFormat: format,
                        compressionQuality: 0.9,
                        outputURL: outURL
                    )
                    convertedURLs.append(outURL)
                    NSLog("[FileCraft] Converted: \(url.lastPathComponent) -> \(outURL.lastPathComponent)")
                } catch {
                    NSLog("[FileCraft] Direct conversion failed for \(url): \(error)")
                }
            }

            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()

                if !convertedURLs.isEmpty {
                    // Reveal the newly created file in Finder without opening the shelf
                    NSWorkspace.shared.activateFileViewerSelecting(convertedURLs)
                }
            }
        }
    }

    // MARK: - In-Place Processing Implementations
    private func cleanMetadataInPlace(urls: [URL]) {
        updateStatusWorking(true)
        Task {
            var cleanedURLs: [URL] = []
            for url in urls {
                let dir = url.deletingLastPathComponent()
                let baseName = url.deletingPathExtension().lastPathComponent
                let ext = url.pathExtension
                let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Clean", ext: ext)
                do {
                    try MetadataCleaner.cleanMetadata(at: url, outputURL: outURL)
                    cleanedURLs.append(outURL)
                } catch {
                    NSLog("[FileCraft] Metadata clean failed: \(error)")
                }
            }
            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()
                if !cleanedURLs.isEmpty {
                    NSWorkspace.shared.activateFileViewerSelecting(cleanedURLs)
                }
            }
        }
    }

    private func compressMediaFiles(urls: [URL]) {
        updateStatusWorking(true)
        Task {
            var compressedURLs: [URL] = []
            for url in urls {
                let ext = url.pathExtension.lowercased()
                let dir = url.deletingLastPathComponent()
                let baseName = url.deletingPathExtension().lastPathComponent
                let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Compressed", ext: ext)

                if ["mp4", "mov", "mkv"].contains(ext) {
                    do {
                        try await AudioVideoProcessor.compressVideo(inputURL: url, outputURL: outURL)
                        compressedURLs.append(outURL)
                    } catch {
                        NSLog("[FileCraft] Video compression failed: \(error)")
                    }
                } else {
                    do {
                        try ImageProcessor.convert(inputURL: url, targetFormat: .jpeg, compressionQuality: 0.65, outputURL: outURL)
                        compressedURLs.append(outURL)
                    } catch {
                        NSLog("[FileCraft] Image compression failed: \(error)")
                    }
                }
            }
            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()
                if !compressedURLs.isEmpty {
                    NSWorkspace.shared.activateFileViewerSelecting(compressedURLs)
                }
            }
        }
    }

    private func muteVideoInPlace(urls: [URL]) {
        updateStatusWorking(true)
        Task {
            var mutedURLs: [URL] = []
            for url in urls {
                let dir = url.deletingLastPathComponent()
                let baseName = url.deletingPathExtension().lastPathComponent
                let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Muted", ext: "mov")
                do {
                    try await AudioVideoProcessor.muteVideo(inputURL: url, outputURL: outURL)
                    mutedURLs.append(outURL)
                } catch {
                    NSLog("[FileCraft] Mute video failed: \(error)")
                }
            }
            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()
                if !mutedURLs.isEmpty {
                    NSWorkspace.shared.activateFileViewerSelecting(mutedURLs)
                }
            }
        }
    }

    private func snapshotVideoInPlace(urls: [URL]) {
        updateStatusWorking(true)
        Task {
            var snapshotURLs: [URL] = []
            for url in urls {
                let dir = url.deletingLastPathComponent()
                let baseName = url.deletingPathExtension().lastPathComponent
                let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Snapshot", ext: "png")
                do {
                    try await AudioVideoProcessor.extractSnapshot(inputURL: url, outputURL: outURL)
                    snapshotURLs.append(outURL)
                } catch {
                    NSLog("[FileCraft] Snapshot failed: \(error)")
                }
            }
            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()
                if !snapshotURLs.isEmpty {
                    NSWorkspace.shared.activateFileViewerSelecting(snapshotURLs)
                }
            }
        }
    }

    private func changeSpeedVideoInPlace(urls: [URL]) {
        updateStatusWorking(true)
        Task {
            var speedURLs: [URL] = []
            for url in urls {
                let dir = url.deletingLastPathComponent()
                let baseName = url.deletingPathExtension().lastPathComponent
                let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Speed2x", ext: "mp4")
                do {
                    try await AudioVideoProcessor.changeVideoSpeed(inputURL: url, outputURL: outURL, rate: 2.0)
                    speedURLs.append(outURL)
                } catch {
                    NSLog("[FileCraft] Speed change failed: \(error)")
                }
            }
            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()
                if !speedURLs.isEmpty {
                    NSWorkspace.shared.activateFileViewerSelecting(speedURLs)
                }
            }
        }
    }

    private func extractAudioInPlace(urls: [URL], format: ConversionFormat) {
        updateStatusWorking(true)
        Task {
            var audioURLs: [URL] = []
            for url in urls {
                let dir = url.deletingLastPathComponent()
                let baseName = url.deletingPathExtension().lastPathComponent
                let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Audio", ext: "m4a")
                do {
                    try await AudioVideoProcessor.extractAudio(inputURL: url, outputURL: outURL)
                    audioURLs.append(outURL)
                } catch {
                    NSLog("[FileCraft] Audio extraction failed: \(error)")
                }
            }
            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()
                if !audioURLs.isEmpty {
                    NSWorkspace.shared.activateFileViewerSelecting(audioURLs)
                }
            }
        }
    }

    private func extractArchiveInPlace(urls: [URL]) {
        updateStatusWorking(true)
        Task {
            var extractedDirs: [URL] = []
            for url in urls {
                do {
                    let outDir = try ArchiveProcessor.extractArchive(archiveURL: url)
                    extractedDirs.append(outDir)
                } catch {
                    NSLog("[FileCraft] Archive extraction failed: \(error)")
                }
            }
            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()
                if !extractedDirs.isEmpty {
                    NSWorkspace.shared.activateFileViewerSelecting(extractedDirs)
                }
            }
        }
    }

    private func splitPDFInPlace(urls: [URL]) {
        guard let firstURL = urls.first, let pdfDoc = PDFDocument(url: firstURL) else { return }
        updateStatusWorking(true)
        Task {
            let dir = firstURL.deletingLastPathComponent()
            let baseName = firstURL.deletingPathExtension().lastPathComponent
            var pageURLs: [URL] = []

            for i in 0..<pdfDoc.pageCount {
                if let page = pdfDoc.page(at: i) {
                    let singleDoc = PDFDocument()
                    singleDoc.insert(page, at: 0)
                    let pageURL = dir.appendingPathComponent("\(baseName)_Page_\(i + 1).pdf")
                    if singleDoc.write(to: pageURL) {
                        pageURLs.append(pageURL)
                    }
                }
            }

            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()
                if !pageURLs.isEmpty {
                    NSWorkspace.shared.activateFileViewerSelecting(pageURLs)
                }
            }
        }
    }

    private func mergePDFsInPlace(urls: [URL]) {
        guard urls.count > 1 else { return }
        updateStatusWorking(true)
        Task {
            let dir = urls[0].deletingLastPathComponent()
            let mergedDoc = PDFDocument()
            var pageIndex = 0

            for url in urls {
                if let doc = PDFDocument(url: url) {
                    for i in 0..<doc.pageCount {
                        if let page = doc.page(at: i) {
                            mergedDoc.insert(page, at: pageIndex)
                            pageIndex += 1
                        }
                    }
                }
            }

            let outURL = generateUniqueURL(dir: dir, baseName: "Merged", ext: "pdf")
            mergedDoc.write(to: outURL)

            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()
                NSWorkspace.shared.activateFileViewerSelecting([outURL])
            }
        }
    }

    private func zipFiles(urls: [URL]) {
        guard !urls.isEmpty else { return }
        updateStatusWorking(true)
        Task {
            let dir = urls[0].deletingLastPathComponent()
            let zipURL = generateUniqueURL(dir: dir, baseName: "Archive", ext: "zip")

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            process.currentDirectoryURL = dir
            var args = ["-q", "-r", zipURL.path]
            args.append(contentsOf: urls.map { $0.lastPathComponent })
            process.arguments = args
            try? process.run()
            process.waitUntilExit()

            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()
                if FileManager.default.fileExists(atPath: zipURL.path) {
                    NSWorkspace.shared.activateFileViewerSelecting([zipURL])
                }
            }
        }
    }

    private func joinVideosInPlace(urls: [URL]) {
        guard urls.count > 1 else { return }
        updateStatusWorking(true)
        Task {
            let dir = urls[0].deletingLastPathComponent()
            let outURL = generateUniqueURL(dir: dir, baseName: "Joined_Video", ext: "mp4")
            do {
                try await AudioVideoProcessor.joinVideos(inputURLs: urls, outputURL: outURL)
                await MainActor.run {
                    self.updateStatusWorking(false)
                    SoundManager.shared.playActionComplete()
                    NSWorkspace.shared.activateFileViewerSelecting([outURL])
                }
            } catch {
                NSLog("[FileCraft] Join videos failed: \(error)")
                await MainActor.run { self.updateStatusWorking(false) }
            }
        }
    }

    private func splitVideoInPlace(urls: [URL]) {
        guard let firstURL = urls.first else { return }
        updateStatusWorking(true)
        Task {
            let dir = firstURL.deletingLastPathComponent()
            let baseName = firstURL.deletingPathExtension().lastPathComponent
            let out1 = generateUniqueURL(dir: dir, baseName: "\(baseName)_Part1", ext: "mp4")
            let out2 = generateUniqueURL(dir: dir, baseName: "\(baseName)_Part2", ext: "mp4")
            do {
                try await AudioVideoProcessor.splitVideo(inputURL: firstURL, outputURL1: out1, outputURL2: out2)
                await MainActor.run {
                    self.updateStatusWorking(false)
                    SoundManager.shared.playActionComplete()
                    NSWorkspace.shared.activateFileViewerSelecting([out1, out2])
                }
            } catch {
                NSLog("[FileCraft] Split video failed: \(error)")
                await MainActor.run { self.updateStatusWorking(false) }
            }
        }
    }

    private func normalizeAudioInPlace(urls: [URL]) {
        updateStatusWorking(true)
        Task {
            var outURLs: [URL] = []
            for url in urls {
                let dir = url.deletingLastPathComponent()
                let baseName = url.deletingPathExtension().lastPathComponent
                let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Normalized", ext: "m4a")
                do {
                    try await AudioVideoProcessor.normalizeAudio(inputURL: url, outputURL: outURL)
                    outURLs.append(outURL)
                } catch {
                    NSLog("[FileCraft] Audio normalize failed: \(error)")
                }
            }
            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()
                if !outURLs.isEmpty {
                    NSWorkspace.shared.activateFileViewerSelecting(outURLs)
                }
            }
        }
    }

    private func convertAudioChannelsInPlace(urls: [URL]) {
        updateStatusWorking(true)
        Task {
            var outURLs: [URL] = []
            for url in urls {
                let dir = url.deletingLastPathComponent()
                let baseName = url.deletingPathExtension().lastPathComponent
                let outURL = generateUniqueURL(dir: dir, baseName: "\(baseName)_Mono", ext: "m4a")
                do {
                    try await AudioVideoProcessor.convertAudioToMono(inputURL: url, outputURL: outURL)
                    outURLs.append(outURL)
                } catch {
                    NSLog("[FileCraft] Audio mono failed: \(error)")
                }
            }
            await MainActor.run {
                self.updateStatusWorking(false)
                SoundManager.shared.playActionComplete()
                if !outURLs.isEmpty {
                    NSWorkspace.shared.activateFileViewerSelecting(outURLs)
                }
            }
        }
    }

    private func generateUniqueURL(dir: URL, baseName: String, ext: String) -> URL {
        var outURL = dir.appendingPathComponent("\(baseName).\(ext)")
        var counter = 1
        while FileManager.default.fileExists(atPath: outURL.path) {
            outURL = dir.appendingPathComponent("\(baseName)_\(counter).\(ext)")
            counter += 1
        }
        return outURL
    }

    // MARK: - Tool Windows
    public func openRadialWheelAtMouse() {
        RadialFanOverlayController.shared.show { [weak self] action, urls in
            self?.executeAction(action, urls: urls)
        }
    }

    public func openImageFrameStudio(with url: URL? = nil) {
        let initialImg = url != nil ? NSImage(contentsOf: url!) : nil
        presentWindow(id: "ImageFrame", title: "FileCraft — Mockup Frame Studio", size: CGSize(width: 820, height: 560)) {
            ImageFrameEditorView(initialImage: initialImg)
        }
    }

    public func openPhotoEditorStudio(with url: URL? = nil) {
        presentWindow(id: "PhotoEditor", title: "FileCraft — Photo Editor", size: CGSize(width: 780, height: 540)) {
            PhotoEditorStudioView(imageURL: url)
        }
    }

    public func openCropStudio(with url: URL? = nil) {
        presentWindow(id: "CropStudio", title: "FileCraft — Crop Image", size: CGSize(width: 740, height: 520)) {
            CropStudioView(imageURL: url)
        }
    }

    public func openRedactStudio(with url: URL? = nil) {
        presentWindow(id: "RedactStudio", title: "FileCraft — Redact Image", size: CGSize(width: 760, height: 520)) {
            RedactStudioView(imageURL: url)
        }
    }

    public func openAnnotationStudio(with url: URL? = nil) {
        presentWindow(id: "AnnotationStudio", title: "FileCraft — Annotate Image", size: CGSize(width: 780, height: 540)) {
            AnnotationStudioView(imageURL: url)
        }
    }

    public func openCollageStudio(with urls: [URL] = []) {
        presentWindow(id: "CollageStudio", title: "FileCraft — Photo Collage", size: CGSize(width: 760, height: 520)) {
            CollageStudioView(imageURLs: urls)
        }
    }

    public func openVideoTrimStudio(with url: URL? = nil) {
        presentWindow(id: "VideoTrimStudio", title: "FileCraft — Trim Video", size: CGSize(width: 780, height: 520)) {
            VideoTrimStudioView(videoURL: url)
        }
    }

    public func openVideoCropStudio(with url: URL? = nil) {
        presentWindow(id: "VideoCropStudio", title: "FileCraft — Crop Video", size: CGSize(width: 780, height: 520)) {
            VideoCropStudioView(videoURL: url)
        }
    }

    public func openMetadataCleanerStudio(with urls: [URL] = []) {
        presentWindow(id: "MetadataCleaner", title: "FileCraft — Privacy & Metadata Cleaner", size: CGSize(width: 720, height: 500)) {
            MetadataCleanerEditorView(initialURLs: urls)
        }
    }

    public func openPDFOrganizerStudio(with url: URL? = nil) {
        presentWindow(id: "PDFOrganizer", title: "FileCraft — PDF Organizer Studio", size: CGSize(width: 760, height: 540)) {
            PDFOrganizerEditorView(initialURL: url)
        }
    }

    public func openQRCodeOCRStudio() {
        presentWindow(id: "QRCodeOCR", title: "FileCraft — QR Code & OCR Studio", size: CGSize(width: 620, height: 500)) {
            QRCodeOCRStudioView()
        }
    }

    public func openMediaConverterStudio(with urls: [URL] = []) {
        presentWindow(id: "MediaConverter", title: "FileCraft — Media & Format Converter", size: CGSize(width: 660, height: 480)) {
            MediaConverterEditorView(initialURLs: urls)
        }
    }

    public func openSettingsWindow() {
        presentWindow(id: "Settings", title: "FileCraft — Settings", size: CGSize(width: 460, height: 340)) {
            SettingsView()
        }
    }

    public func openAboutWindow() {
        presentWindow(id: "About", title: "About FileCraft", size: CGSize(width: 400, height: 280)) {
            AboutView()
        }
    }

    private func presentWindow<Content: View>(
        id: String,
        title: String,
        size: CGSize,
        @ViewBuilder content: () -> Content
    ) {
        if let existing = activeWindows[id] {
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = title
        window.titlebarAppearsTransparent = false
        window.contentView = NSHostingView(rootView: content())
        window.isReleasedWhenClosed = false

        let controller = NSWindowController(window: window)
        activeWindows[id] = controller

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.activeWindows.removeValue(forKey: id)
            }
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - NSMenuDelegate
extension AppDelegate: NSMenuDelegate {
    public func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        // 1. Status Indicator Header
        let statusTitle = isWorking ? "FileCraft is working..." : "FileCraft is ready"
        let statusIcon = isWorking ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill"
        let statusItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusItem.image = NSImage(systemSymbolName: statusIcon, accessibilityDescription: "Status")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        // 2. Floating Shelf Action
        let shelfItem = NSMenuItem(title: "Toggle Drop Shelf", action: #selector(menuToggleShelf), keyEquivalent: "f")
        shelfItem.keyEquivalentModifierMask = [.option, .command]
        shelfItem.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: nil)
        shelfItem.target = self
        menu.addItem(shelfItem)

        // 3. Tool Wheel Action
        let wheelItem = NSMenuItem(title: "Show Tool Wheel", action: #selector(menuShowWheel), keyEquivalent: "w")
        wheelItem.keyEquivalentModifierMask = [.option, .command]
        wheelItem.image = NSImage(systemSymbolName: "circle.hexagongrid.fill", accessibilityDescription: nil)
        wheelItem.target = self
        menu.addItem(wheelItem)

        menu.addItem(NSMenuItem.separator())

        // 4. Creative Utilities
        let frameItem = NSMenuItem(title: "Mockup Frame Studio...", action: #selector(menuOpenImageFrame), keyEquivalent: "i")
        frameItem.keyEquivalentModifierMask = [.option, .command]
        frameItem.image = NSImage(systemSymbolName: "photo.artframe", accessibilityDescription: nil)
        frameItem.target = self
        menu.addItem(frameItem)

        let metadataItem = NSMenuItem(title: "Clean Privacy & EXIF...", action: #selector(menuOpenMetadataCleaner), keyEquivalent: "m")
        metadataItem.keyEquivalentModifierMask = [.option, .command]
        metadataItem.image = NSImage(systemSymbolName: "tag", accessibilityDescription: nil)
        metadataItem.target = self
        menu.addItem(metadataItem)

        let pdfItem = NSMenuItem(title: "PDF Organizer Studio...", action: #selector(menuOpenPDFOrganizer), keyEquivalent: "p")
        pdfItem.keyEquivalentModifierMask = [.option, .command]
        pdfItem.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: nil)
        pdfItem.target = self
        menu.addItem(pdfItem)

        let qrItem = NSMenuItem(title: "QR Code & OCR Studio...", action: #selector(menuOpenQRCodeOCR), keyEquivalent: "q")
        qrItem.keyEquivalentModifierMask = [.option, .command]
        qrItem.image = NSImage(systemSymbolName: "qrcode.viewfinder", accessibilityDescription: nil)
        qrItem.target = self
        menu.addItem(qrItem)

        let convertItem = NSMenuItem(title: "Batch Format Converter...", action: #selector(menuOpenMediaConverter), keyEquivalent: "c")
        convertItem.keyEquivalentModifierMask = [.option, .command]
        convertItem.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)
        convertItem.target = self
        menu.addItem(convertItem)

        menu.addItem(NSMenuItem.separator())

        // 5. Settings, About, Quit
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(menuOpenSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        settingsItem.target = self
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(title: "About FileCraft", action: #selector(menuOpenAbout), keyEquivalent: "")
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit FileCraft", action: #selector(menuQuit), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func menuToggleShelf() {
        FloatingShelfPanel.shared.toggle()
    }

    @objc private func menuShowWheel() {
        openRadialWheelAtMouse()
    }

    @objc private func menuOpenImageFrame() {
        openImageFrameStudio()
    }

    @objc private func menuOpenMetadataCleaner() {
        openMetadataCleanerStudio()
    }

    @objc private func menuOpenPDFOrganizer() {
        openPDFOrganizerStudio()
    }

    @objc private func menuOpenQRCodeOCR() {
        openQRCodeOCRStudio()
    }

    @objc private func menuOpenMediaConverter() {
        openMediaConverterStudio()
    }

    @objc private func menuOpenSettings() {
        openSettingsWindow()
    }

    @objc private func menuOpenAbout() {
        openAboutWindow()
    }

    @objc private func menuQuit() {
        NSApp.terminate(nil)
    }
}

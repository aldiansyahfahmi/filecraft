import AppKit
import PDFKit

public struct PDFPageItem: Identifiable, @unchecked Sendable {
    public let id = UUID()
    public var pageIndex: Int
    public var page: PDFPage
    public var thumbnail: NSImage
    public var rotation: Int
}

public enum PDFProcessor {

    public static func loadPages(from documentURL: URL, thumbnailSize: CGSize = CGSize(width: 160, height: 220)) -> [PDFPageItem] {
        guard let document = PDFDocument(url: documentURL) else { return [] }

        var items: [PDFPageItem] = []
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                let thumb = page.thumbnail(of: thumbnailSize, for: .mediaBox)
                items.append(PDFPageItem(
                    pageIndex: i,
                    page: page,
                    thumbnail: thumb,
                    rotation: page.rotation
                ))
            }
        }
        return items
    }

    public static func exportDocument(
        from pages: [PDFPageItem],
        to outputURL: URL
    ) throws {
        let newDoc = PDFDocument()
        for (index, item) in pages.enumerated() {
            let pageCopy = item.page
            pageCopy.rotation = item.rotation
            newDoc.insert(pageCopy, at: index)
        }
        guard newDoc.write(to: outputURL) else {
            throw NSError(domain: "PDFProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to write PDF file to destination."])
        }
    }

    public static func mergePDFs(urls: [URL], to outputURL: URL) throws {
        let mergedDoc = PDFDocument()
        var pageInsertIndex = 0

        for url in urls {
            guard let doc = PDFDocument(url: url) else { continue }
            for i in 0..<doc.pageCount {
                if let page = doc.page(at: i) {
                    mergedDoc.insert(page, at: pageInsertIndex)
                    pageInsertIndex += 1
                }
            }
        }

        guard mergedDoc.write(to: outputURL) else {
            throw NSError(domain: "PDFProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to write merged PDF."])
        }
    }
}

import AppKit
import CoreImage
import Vision

public struct RecognizedBarcode: Sendable {
    public let payload: String
    public let symbology: String
}

public enum VisionService {

    // MARK: - Detect Barcodes / QR Codes
    public static func detectBarcodes(in image: NSImage) async -> [RecognizedBarcode] {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return []
        }

        return await withCheckedContinuation { continuation in
            let request = VNDetectBarcodesRequest { req, error in
                guard error == nil, let results = req.results as? [VNBarcodeObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let barcodes = results.compactMap { obs -> RecognizedBarcode? in
                    guard let payload = obs.payloadStringValue else { return nil }
                    return RecognizedBarcode(
                        payload: payload,
                        symbology: obs.symbology.rawValue
                    )
                }
                continuation.resume(returning: barcodes)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    // MARK: - Recognize Text (OCR)
    public static func recognizeText(in image: NSImage) async -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return ""
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, error in
                guard error == nil, let results = req.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let recognizedStrings = results.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }

    // MARK: - Generate QR Code
    public static func generateQRCode(from string: String, size: CGSize = CGSize(width: 512, height: 512)) -> NSImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let outputCI = filter.outputImage else { return nil }

        let scaleX = size.width / outputCI.extent.size.width
        let scaleY = size.height / outputCI.extent.size.height
        let transformed = outputCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let rep = NSCIImageRep(ciImage: transformed)
        let nsImage = NSImage(size: size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
}

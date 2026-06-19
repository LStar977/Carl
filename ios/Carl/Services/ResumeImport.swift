import Foundation
import PDFKit
import Vision
import UIKit

/// Pulls plain text out of a résumé the user picks — a PDF, a text file, or a
/// photo (via on-device OCR) — so it can be sent to the parse endpoint.
enum ResumeImport {

    /// Extract text from a file URL (PDF or plain text).
    static func extractText(from url: URL) async -> String {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        if url.pathExtension.lowercased() == "pdf" {
            return pdfText(url)
        }
        if let data = try? Data(contentsOf: url), let s = String(data: data, encoding: .utf8) {
            return s
        }
        return ""
    }

    static func pdfText(_ url: URL) -> String {
        guard let doc = PDFDocument(url: url) else { return "" }
        var out = ""
        for i in 0..<doc.pageCount {
            out += (doc.page(at: i)?.string ?? "")
            out += "\n"
        }
        return out
    }

    /// OCR a photographed résumé using Vision.
    static func ocr(_ image: UIImage) async -> String {
        guard let cg = image.cgImage else { return "" }
        return await withCheckedContinuation { cont in
            let request = VNRecognizeTextRequest { req, _ in
                let text = (req.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                cont.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([request])
            }
        }
    }
}

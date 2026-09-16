import Foundation
import Vision

struct RecognizedTextBlock: Sendable, Identifiable {
    let id = UUID()
    let text: String
    let confidence: Double
}

struct OCRResult: Sendable {
    let fullText: String
    let blocks: [RecognizedTextBlock]
    var averageConfidence: Double {
        guard !blocks.isEmpty else { return 0 }
        return blocks.map(\.confidence).reduce(0, +) / Double(blocks.count)
    }
}

/// Thin asynchronous wrapper around Vision's entirely on-device text recognizer.
enum OCRService {
    static func recognize(imageData: Data) async throws -> OCRResult {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = PlatformImage(data: imageData), let cgImage = image.extractaCGImage else {
                    continuation.resume(throwing: ExtractaError.invalidImage)
                    return
                }

                let request = VNRecognizeTextRequest { request, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let blocks = (request.results as? [VNRecognizedTextObservation] ?? []).compactMap { observation -> RecognizedTextBlock? in
                        guard let candidate = observation.topCandidates(1).first else { return nil }
                        return RecognizedTextBlock(text: candidate.string, confidence: Double(candidate.confidence))
                    }
                    continuation.resume(returning: OCRResult(
                        fullText: blocks.map(\.text).joined(separator: "\n"),
                        blocks: blocks
                    ))
                }
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["en-US"]

                do { try VNImageRequestHandler(cgImage: cgImage).perform([request]) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }
}

enum ExtractaError: LocalizedError {
    case invalidImage
    case noPhotoData

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "This image could not be read."
        case .noPhotoData: return "Photo data was unavailable."
        }
    }
}

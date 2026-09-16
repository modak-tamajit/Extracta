import Foundation
import Vision

struct ImageClassification: Sendable {
    let label: String
    let confidence: Double
}

/// Vision image classification is a supplementary signal; user text remains the strongest signal.
enum ImageClassificationService {
    static func classify(imageData: Data) async -> ImageClassification? {
        guard #available(iOS 17.0, macOS 14.0, *) else { return nil }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                guard let image = PlatformImage(data: imageData), let cgImage = image.extractaCGImage else {
                    continuation.resume(returning: nil)
                    return
                }
                let request = VNClassifyImageRequest { request, _ in
                    let top = (request.results as? [VNClassificationObservation])?.first
                    continuation.resume(returning: top.map { ImageClassification(label: $0.identifier, confidence: Double($0.confidence)) })
                }
                do { try VNImageRequestHandler(cgImage: cgImage).perform([request]) }
                catch { continuation.resume(returning: nil) }
            }
        }
    }
}

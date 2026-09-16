import Foundation

struct ScreenshotAnalysis: Sendable {
    let ocr: OCRResult
    let entities: [DetectedEntity]
    let category: ScreenshotCategory
    let confidence: Double
    let tags: [String]
    let insight: String
    let evidence: [String]
    let needsReview: Bool
}

/// Coordinates every local intelligence step. No call leaves the device.
enum AnalysisService {
    static func analyze(imageData: Data) async throws -> ScreenshotAnalysis {
        async let textResult = OCRService.recognize(imageData: imageData)
        async let imageResult = ImageClassificationService.classify(imageData: imageData)
        let ocr = try await textResult
        let entities = EntityDetectionService.detect(in: ocr.fullText)
        let classification = await imageResult
        let decision = ScreenshotCategorizationService.categorize(text: ocr.fullText, entities: entities, imageLabel: classification)
        let combined = max(0.1, min(1, (ocr.averageConfidence * 0.7) + (decision.confidence * 0.3)))
        return ScreenshotAnalysis(
            ocr: ocr,
            entities: entities,
            category: decision.category,
            confidence: combined,
            tags: decision.tags,
            insight: decision.insight,
            evidence: decision.evidence,
            needsReview: combined < 0.72 || decision.category == .general
        )
    }

    static func thumbnail(for imageData: Data) -> Data {
        guard let image = PlatformImage(data: imageData) else { return imageData }
        return image.extractaThumbnailData() ?? imageData
    }
}

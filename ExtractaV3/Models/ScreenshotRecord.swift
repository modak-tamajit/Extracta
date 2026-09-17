import Foundation
import SwiftData

@Model
final class ScreenshotRecord {
    var assetIdentifier: String
    var category: String
    var matchStrength: Double   // 0...1 — fraction of a category's keywords found in the OCR text.
                                 // This is a lexical match ratio, NOT an AI/ML confidence score.
    var extractedText: String
    var correctedCategory: String?
    var analyzedAt: Date

    init(
        assetIdentifier: String,
        category: String,
        matchStrength: Double,
        extractedText: String,
        analyzedAt: Date = .now
    ) {
        self.assetIdentifier = assetIdentifier
        self.category = category
        self.matchStrength = matchStrength
        self.extractedText = extractedText
        self.analyzedAt = analyzedAt
    }

    /// The category to display: the user's correction takes precedence over the original classification.
    var displayCategory: String { correctedCategory ?? category }
}

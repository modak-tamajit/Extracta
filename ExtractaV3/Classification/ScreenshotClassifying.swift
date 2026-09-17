import Foundation

/// A category call plus how strongly the input text matched it.
struct ClassificationResult {
    let category: String
    let matchStrength: Double // 0...1 — a lexical match ratio. Not a probability, not AI confidence.
}

/// Anything that can turn extracted text into a `ClassificationResult`.
///
/// Kept as a single-method protocol on purpose: today it's backed by keyword
/// matching (`KeywordClassifier`). Swapping in a Core ML or NaturalLanguage-based
/// classifier later means writing one new conforming type — no other file in
/// the app needs to change.
protocol ScreenshotClassifying {
    func classify(text: String) -> ClassificationResult
}

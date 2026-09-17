import Foundation

/// Deterministic, on-device classification by keyword overlap.
///
/// This is the whole "intelligence engine" for the demo: no ML model, no
/// network call, no NaturalLanguage framework. It exists to prove the
/// pipeline (Photos → OCR → categorize → display → correct) end to end.
/// Replace it by writing a new `ScreenshotClassifying` conformance when
/// keyword matching visibly can't carry a category.
struct KeywordClassifier: ScreenshotClassifying {
    static let categoryKeywords: [String: [String]] = [
        "Study": [
            "lecture", "notes", "chapter", "theorem", "definition", "exam",
            "syllabus", "algorithm", "equation", "formula", "assignment",
            "homework", "quiz", "professor", "textbook"
        ],
        "Entertainment": [
            "movie", "episode", "season", "netflix", "trailer", "director",
            "cast", "imdb", "rating", "soundtrack", "streaming"
        ],
        "Shopping": [
            "price", "cart", "checkout", "delivery", "order", "discount",
            "add to bag", "buy now", "shipping", "sale", "coupon"
        ],
        "Social": [
            "like", "comment", "share", "follow", "retweet", "story",
            "reply", "dm", "post", "mentioned you"
        ],
        "Travel": [
            "flight", "boarding", "gate", "itinerary", "hotel",
            "reservation", "check-in", "departure", "terminal", "booking"
        ],
        "Web/Reference": [
            "wikipedia", "http://", "https://", "www.", "article", "source",
            "search results"
        ]
    ]

    private static let fallbackCategory = "Miscellaneous"

    func classify(text: String) -> ClassificationResult {
        let lowered = text.lowercased()

        var bestCategory = Self.fallbackCategory
        var bestHits = 0
        var bestTotal = 1

        for (category, keywords) in Self.categoryKeywords {
            let hits = keywords.filter { lowered.contains($0) }.count
            if hits > bestHits {
                bestCategory = category
                bestHits = hits
                bestTotal = keywords.count
            }
        }

        guard bestHits > 0 else {
            return ClassificationResult(category: Self.fallbackCategory, matchStrength: 0)
        }

        // ponytail: scaled x2 because a real screenshot rarely contains more than
        // half of any one category's keyword list. Naive ratio alone clusters
        // every real result under ~20%, which reads as "low confidence" even for
        // a clean match. Revisit with a proper scoring function if this ever
        // needs to be more than a demo-grade signal.
        let strength = min(Double(bestHits) / Double(bestTotal) * 2, 1.0)
        return ClassificationResult(category: bestCategory, matchStrength: strength)
    }
}

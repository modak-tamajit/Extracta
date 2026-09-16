import Foundation

struct CategorizationDecision: Sendable {
    let category: ScreenshotCategory
    let confidence: Double
    let tags: [String]
    let evidence: [String]

    var insight: String {
        "This looks like \(category.rawValue.lowercased())."
    }
}

/// Deterministic, inspectable local rules turn OCR, entities, and visual labels into a category.
enum ScreenshotCategorizationService {
    static func categorize(text: String, entities: [DetectedEntity], imageLabel: ImageClassification?) -> CategorizationDecision {
        let body = text.lowercased()
        let hasDate = entities.contains { $0.type == .date }
        let rules: [(ScreenshotCategory, [String])] = [
            (.receipts, ["receipt", "subtotal", "total", "tax", "amount paid", "invoice"]),
            (.assignments, ["assignment", "submission", "submit", "homework", "coursework", "project due"]),
            (.grocery, ["grocery", "groceries", "milk", "vegetables", "supermarket"]),
            (.shopping, ["wishlist", "buy", "price", "add to cart", "order now", "product"]),
            (.movies, ["movie", "film", "cinema", "watchlist", "director", "starring"]),
            (.events, ["event", "concert", "workshop", "rsvp", "tickets", "venue"]),
            (.travel, ["flight", "boarding", "hotel", "itinerary", "departure", "arrival"]),
            (.contacts, ["contact", "phone", "email", "linkedin", "call me"]),
            (.studyNotes, ["lecture", "chapter", "definition", "theorem", "notes", "exam", "semester"])
        ]

        if let hit = rules.first(where: { _, keywords in keywords.contains(where: body.contains) }) {
            let matched = hit.1.filter(body.contains)
            return CategorizationDecision(
                category: hit.0,
                confidence: min(0.96, 0.68 + Double(matched.count) * 0.09),
                tags: matched,
                evidence: matched.map { "Found keyword: \($0)" }
            )
        }
        if hasDate {
            let values = entities.filter { $0.type == .date }.map(\.value)
            return CategorizationDecision(category: .deadlines, confidence: 0.67, tags: ["date"], evidence: values.map { "Found date: \($0)" })
        }
        if entities.contains(where: { $0.type == .phone || $0.type == .email }) {
            return CategorizationDecision(category: .contacts, confidence: 0.65, tags: ["contact"], evidence: ["Found contact information"])
        }
        if let imageLabel {
            let label = imageLabel.label.lowercased()
            let evidence = ["Visual hint: \(imageLabel.label)"]
            if label.contains("document") || label.contains("text") {
                return CategorizationDecision(category: .studyNotes, confidence: imageLabel.confidence * 0.65, tags: [imageLabel.label], evidence: evidence)
            }
            if label.contains("food") {
                return CategorizationDecision(category: .grocery, confidence: imageLabel.confidence * 0.65, tags: [imageLabel.label], evidence: evidence)
            }
            return CategorizationDecision(category: .general, confidence: imageLabel.confidence * 0.45, tags: [imageLabel.label], evidence: evidence)
        }
        return CategorizationDecision(category: .general, confidence: text.isEmpty ? 0 : 0.45, tags: [], evidence: [])
    }
}

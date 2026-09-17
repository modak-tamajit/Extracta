import XCTest
@testable import ExtractaV3

final class KeywordClassifierTests: XCTestCase {
    private let classifier = KeywordClassifier()

    func testStudyContentIsClassifiedAsStudy() {
        let result = classifier.classify(
            text: "DATA STRUCTURES\nLECTURE 4\nAlgorithm complexity, exam review, homework due Friday"
        )
        XCTAssertEqual(result.category, "Study")
        XCTAssertGreaterThan(result.matchStrength, 0)
    }

    func testShoppingContentIsClassifiedAsShopping() {
        let result = classifier.classify(
            text: "Add to Cart — $49.99 — Free delivery — Checkout now, 20% discount applied"
        )
        XCTAssertEqual(result.category, "Shopping")
    }

    func testEmptyTextFallsBackToMiscellaneousWithZeroStrength() {
        let result = classifier.classify(text: "")
        XCTAssertEqual(result.category, "Miscellaneous")
        XCTAssertEqual(result.matchStrength, 0)
    }

    func testUnmatchedTextFallsBackToMiscellaneous() {
        let result = classifier.classify(text: "asdf qwer zxcv")
        XCTAssertEqual(result.category, "Miscellaneous")
        XCTAssertEqual(result.matchStrength, 0)
    }

    func testMatchStrengthNeverExceedsOne() {
        // Every keyword for Study, concatenated — should saturate at 1.0, not overshoot.
        let allKeywords = KeywordClassifier.categoryKeywords["Study"]!.joined(separator: " ")
        let result = classifier.classify(text: allKeywords)
        XCTAssertEqual(result.category, "Study")
        XCTAssertLessThanOrEqual(result.matchStrength, 1.0)
    }
}

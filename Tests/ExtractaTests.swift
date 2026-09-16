import XCTest
import Foundation
@testable import Extracta

final class ExtractaTests: XCTestCase {
    func testAssignmentRuleUsesRecognizedEvidence() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let entities = [DetectedEntity(type: .date, value: "28 September, 11:59 PM", dateValue: date)]

        let result = ScreenshotCategorizationService.categorize(
            text: "DBMS Assignment Submission\n28 September, 11:59 PM",
            entities: entities,
            imageLabel: nil
        )

        XCTAssertEqual(result.category, .assignments)
        XCTAssertGreaterThan(result.confidence, 0.7)
        XCTAssertTrue(result.evidence.contains("Found keyword: assignment"))
    }

    func testDateOnlyScreenshotEntersDeadlineCategory() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let entities = [DetectedEntity(type: .date, value: "28 September", dateValue: date)]

        let result = ScreenshotCategorizationService.categorize(text: "28 September", entities: entities, imageLabel: nil)

        XCTAssertEqual(result.category, .deadlines)
        XCTAssertEqual(result.evidence, ["Found date: 28 September"])
    }

    func testTaskRequiresActionableDeadline() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let deadline = DetectedEntity(type: .date, value: "28 September", dateValue: date)

        let task = TaskGenerationService.task(
            for: "DBMS Assignment Submission\n28 September",
            category: .assignments,
            entities: [deadline],
            sourceID: id
        )

        XCTAssertEqual(task?.title, "DBMS Assignment Submission")
        XCTAssertEqual(task?.dueDate, date)
        XCTAssertNil(TaskGenerationService.task(for: "Lecture note", category: .studyNotes, entities: [], sourceID: id))
    }

    func testContactEntitiesClassifyWithoutKeyword() {
        let entities = [DetectedEntity(type: .email, value: "student@example.com", dateValue: nil)]

        let result = ScreenshotCategorizationService.categorize(text: "student@example.com", entities: entities, imageLabel: nil)

        XCTAssertEqual(result.category, .contacts)
        XCTAssertTrue(result.evidence.contains("Found contact information"))
    }

    func testVisualHintOnlySupportsButDoesNotOverstateDecision() {
        let hint = ImageClassification(label: "document", confidence: 0.9)

        let result = ScreenshotCategorizationService.categorize(text: "", entities: [], imageLabel: hint)

        XCTAssertEqual(result.category, .studyNotes)
        XCTAssertEqual(result.confidence, 0.585, accuracy: 0.001)
        XCTAssertEqual(result.evidence, ["Visual hint: document"])
    }
}

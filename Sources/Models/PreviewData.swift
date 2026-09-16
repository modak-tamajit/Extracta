import Foundation
import SwiftData

/// Fixture data for SwiftUI canvas previews and UI demonstrations without Photos access.
enum PreviewData {
    static var container: ModelContainer {
        let schema = Schema([ScreenshotItem.self, ExtractedEntity.self, GeneratedTask.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        let item = ScreenshotItem(
            imageData: Data(),
            thumbnailData: Data(),
            recognizedText: "DBMS Assignment Submission\n28 September, 11:59 PM\nSubmit through the course portal.",
            category: .assignments,
            confidence: 0.91,
            tags: ["assignment", "submission"],
            insight: "This looks like an assignment.",
            evidence: ["Found keyword: assignment", "Found date: 28 September, 11:59 PM"],
            needsReview: false
        )
        let date = Calendar.current.date(byAdding: .day, value: 7, to: .now)
        let entity = ExtractedEntity(type: .date, value: "28 September, 11:59 PM", dateValue: date)
        entity.screenshot = item
        item.entities.append(entity)
        let task = GeneratedTask(title: "DBMS Assignment Submission", dueDate: date, sourceScreenshotID: item.id)
        task.sourceScreenshot = item
        item.tasks.append(task)
        container.mainContext.insert(item)
        return container
    }
}

import Foundation

/// Creates one useful task when screenshot content expresses an actionable deadline.
enum TaskGenerationService {
    static func task(for text: String, category: ScreenshotCategory, entities: [DetectedEntity], sourceID: UUID) -> GeneratedTask? {
        guard category == .assignments || category == .deadlines else { return nil }
        let dueDate = entities.first(where: { $0.type == .date })?.dateValue
        guard dueDate != nil || text.lowercased().contains("due") || text.lowercased().contains("submit") else { return nil }
        let title = text.split(whereSeparator: \.isNewline)
            .map(String.init)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Screenshot task"
        return GeneratedTask(title: String(title.prefix(90)), dueDate: dueDate, sourceScreenshotID: sourceID)
    }
}

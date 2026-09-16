import Foundation
import SwiftData

/// The human-readable organization buckets used throughout Extracta.
enum ScreenshotCategory: String, CaseIterable, Identifiable, Codable {
    case studyNotes = "Study Notes"
    case assignments = "Assignments"
    case deadlines = "Deadlines"
    case events = "Events"
    case movies = "Movies"
    case shopping = "Shopping"
    case grocery = "Grocery"
    case contacts = "Contacts"
    case receipts = "Receipts"
    case travel = "Travel"
    case general = "General"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .studyNotes: return "book.closed"
        case .assignments: return "checklist"
        case .deadlines: return "calendar.badge.clock"
        case .events: return "ticket"
        case .movies: return "film"
        case .shopping: return "bag"
        case .grocery: return "cart"
        case .contacts: return "person.crop.circle"
        case .receipts: return "receipt"
        case .travel: return "airplane"
        case .general: return "square.grid.2x2"
        }
    }
}

enum EntityType: String, CaseIterable, Codable {
    case date, email, phone, address, url

    var symbol: String {
        switch self {
        case .date: return "calendar"
        case .email: return "envelope"
        case .phone: return "phone"
        case .address: return "mappin.and.ellipse"
        case .url: return "link"
        }
    }
}

/// A locally stored screenshot and the intelligence derived from it on-device.
@Model
final class ScreenshotItem {
    @Attribute(.unique) var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    @Attribute(.externalStorage) var thumbnailData: Data
    var createdDate: Date
    var recognizedText: String
    var recognizedBlocks: [String]
    var blockConfidences: [Double]
    var category: String
    var confidence: Double
    var tags: [String]
    var insight: String
    var evidence: [String]
    var needsReview: Bool
    @Relationship(deleteRule: .cascade, inverse: \ExtractedEntity.screenshot) var entities: [ExtractedEntity]
    @Relationship(deleteRule: .cascade, inverse: \GeneratedTask.sourceScreenshot) var tasks: [GeneratedTask]

    init(
        id: UUID = UUID(),
        imageData: Data,
        thumbnailData: Data,
        createdDate: Date = .now,
        recognizedText: String = "",
        recognizedBlocks: [String] = [],
        blockConfidences: [Double] = [],
        category: ScreenshotCategory = .general,
        confidence: Double = 0,
        tags: [String] = [],
        insight: String = "Saved privately on this device.",
        evidence: [String] = [],
        needsReview: Bool = true
    ) {
        self.id = id
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.createdDate = createdDate
        self.recognizedText = recognizedText
        self.recognizedBlocks = recognizedBlocks
        self.blockConfidences = blockConfidences
        self.category = category.rawValue
        self.confidence = confidence
        self.tags = tags
        self.insight = insight
        self.evidence = evidence
        self.needsReview = needsReview
        self.entities = []
        self.tasks = []
    }

    var categoryKind: ScreenshotCategory { ScreenshotCategory(rawValue: category) ?? .general }

    var displayTitle: String {
        recognizedBlocks.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            ?? "Untitled screenshot"
    }
}

/// A structured value found inside a screenshot's recognized text.
@Model
final class ExtractedEntity {
    @Attribute(.unique) var id: UUID
    var type: String
    var value: String
    var dateValue: Date?
    var screenshot: ScreenshotItem?

    init(id: UUID = UUID(), type: EntityType, value: String, dateValue: Date? = nil) {
        self.id = id
        self.type = type.rawValue
        self.value = value
        self.dateValue = dateValue
    }

    var kind: EntityType { EntityType(rawValue: type) ?? .url }
}

/// An on-device task created from an assignment, deadline, or explicit reminder action.
@Model
final class GeneratedTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var dueDate: Date?
    var sourceScreenshotID: UUID
    var completed: Bool
    var isSuggested: Bool
    var sourceScreenshot: ScreenshotItem?

    init(
        id: UUID = UUID(),
        title: String,
        dueDate: Date? = nil,
        sourceScreenshotID: UUID,
        completed: Bool = false,
        isSuggested: Bool = true
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.sourceScreenshotID = sourceScreenshotID
        self.completed = completed
        self.isSuggested = isSuggested
    }
}

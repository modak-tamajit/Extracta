import Foundation
import PhotosUI
import SwiftData
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var items: [ScreenshotItem] = []
    @Published private(set) var tasks: [GeneratedTask] = []
    @Published var isImporting = false
    @Published var importProgress = ""
    @Published var errorMessage: String?

    private var modelContext: ModelContext?

    func configure(with context: ModelContext) {
        guard modelContext == nil else { return }
        modelContext = context
        refresh()
    }

    func refresh() {
        guard let modelContext else { return }
        let itemsDescriptor = FetchDescriptor<ScreenshotItem>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
        let tasksDescriptor = FetchDescriptor<GeneratedTask>(sortBy: [SortDescriptor(\.dueDate)])
        items = (try? modelContext.fetch(itemsDescriptor)) ?? []
        tasks = (try? modelContext.fetch(tasksDescriptor)) ?? []
    }

    func importPhotos(_ selections: [PhotosPickerItem]) async {
        guard !selections.isEmpty else { return }
        isImporting = true
        defer { isImporting = false; importProgress = ""; refresh() }
        for (index, selection) in selections.enumerated() {
            importProgress = "Analyzing \(index + 1) of \(selections.count)…"
            do {
                guard let data = try await selection.loadTransferable(type: Data.self) else { throw ExtractaError.noPhotoData }
                try await importImage(data)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func importImage(_ data: Data) async throws {
        let thumbnail = AnalysisService.thumbnail(for: data)
        let analysis = try await AnalysisService.analyze(imageData: data)
        guard let modelContext else { return }
        let item = ScreenshotItem(
            imageData: data,
            thumbnailData: thumbnail,
            recognizedText: analysis.ocr.fullText,
            recognizedBlocks: analysis.ocr.blocks.map(\.text),
            blockConfidences: analysis.ocr.blocks.map(\.confidence),
            category: analysis.category,
            confidence: analysis.confidence,
            tags: analysis.tags,
            insight: analysis.insight,
            evidence: analysis.evidence,
            needsReview: analysis.needsReview
        )
        analysis.entities.forEach { detected in
            let entity = ExtractedEntity(type: detected.type, value: detected.value, dateValue: detected.dateValue)
            entity.screenshot = item
            item.entities.append(entity)
        }
        if analysis.confidence >= 0.78, let task = TaskGenerationService.task(for: analysis.ocr.fullText, category: analysis.category, entities: analysis.entities, sourceID: item.id) {
            task.sourceScreenshot = item
            item.tasks.append(task)
        }
        modelContext.insert(item)
        try modelContext.save()
    }

    func delete(_ item: ScreenshotItem) {
        guard let modelContext else { return }
        modelContext.delete(item)
        try? modelContext.save()
        refresh()
    }

    func toggle(_ task: GeneratedTask) {
        task.completed.toggle()
        try? modelContext?.save()
        refresh()
    }

    func createReminder(for item: ScreenshotItem) {
        guard let modelContext else { return }
        let date = item.entities.first(where: { $0.kind == .date })?.dateValue
        let title = item.recognizedText.split(whereSeparator: \.isNewline).first.map(String.init) ?? "Review screenshot"
        let task = GeneratedTask(title: String(title.prefix(90)), dueDate: date, sourceScreenshotID: item.id, isSuggested: false)
        task.sourceScreenshot = item
        item.tasks.append(task)
        modelContext.insert(task)
        try? modelContext.save()
        refresh()
    }

    func reprocessLibrary() async {
        guard let modelContext, !items.isEmpty else { return }
        isImporting = true
        defer { isImporting = false; importProgress = ""; refresh() }

        for (index, item) in items.enumerated() {
            importProgress = "Reprocessing \(index + 1) of \(items.count)…"
            do {
                let analysis = try await AnalysisService.analyze(imageData: item.imageData)
                item.recognizedText = analysis.ocr.fullText
                item.recognizedBlocks = analysis.ocr.blocks.map(\.text)
                item.blockConfidences = analysis.ocr.blocks.map(\.confidence)
                item.category = analysis.category.rawValue
                item.confidence = analysis.confidence
                item.tags = analysis.tags
                item.insight = analysis.insight
                item.evidence = analysis.evidence
                item.needsReview = analysis.needsReview

                let oldEntities = item.entities
                oldEntities.forEach { modelContext.delete($0) }
                item.entities = []
                analysis.entities.forEach { detected in
                    let entity = ExtractedEntity(type: detected.type, value: detected.value, dateValue: detected.dateValue)
                    entity.screenshot = item
                    item.entities.append(entity)
                }
                let oldSuggestions = item.tasks.filter(\.isSuggested)
                oldSuggestions.forEach { modelContext.delete($0) }
                item.tasks.removeAll { $0.isSuggested }
                if analysis.confidence >= 0.78, let task = TaskGenerationService.task(for: analysis.ocr.fullText, category: analysis.category, entities: analysis.entities, sourceID: item.id) {
                    task.sourceScreenshot = item
                    item.tasks.append(task)
                }
            } catch {
                errorMessage = "Could not reprocess one screenshot: \(error.localizedDescription)"
            }
        }
        try? modelContext.save()
    }

    var storageDescription: String {
        let bytes = items.reduce(0) { $0 + $1.imageData.count + $1.thumbnailData.count }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}

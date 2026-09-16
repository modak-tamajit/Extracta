import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""

    func results(in items: [ScreenshotItem]) -> [ScreenshotItem] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return items }
        return items.filter { item in
            [item.recognizedText, item.category, item.tags.joined(separator: " ")]
                .contains { $0.localizedCaseInsensitiveContains(needle) }
                || item.entities.contains { $0.value.localizedCaseInsensitiveContains(needle) }
                || item.tasks.contains { $0.title.localizedCaseInsensitiveContains(needle) }
        }
    }
}

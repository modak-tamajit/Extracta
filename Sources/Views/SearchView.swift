import SwiftUI

struct SearchView: View {
    @ObservedObject var library: LibraryViewModel
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        let results = viewModel.results(in: library.items)
        Group {
            if results.isEmpty && !viewModel.query.isEmpty {
                EmptyState(symbol: "magnifyingglass", title: "No matches", message: "Try text from the screenshot, a category, email, website, or task.")
            } else if results.isEmpty {
                EmptyState(symbol: "text.viewfinder", title: "Search your screenshots", message: "OCR text, categories, detected entities, and tasks are indexed locally.")
            } else {
                List(results) { item in
                    NavigationLink { ScreenshotDetailView(item: item, library: library) } label: {
                        HStack(spacing: 12) {
                            ScreenshotThumbnail(item: item).frame(width: 68, height: 68).clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.recognizedText.isEmpty ? "Untitled screenshot" : item.recognizedText).lineLimit(2).font(.subheadline.weight(.medium))
                                CategoryPill(category: item.categoryKind)
                            }
                        }.padding(.vertical, 3)
                    }
                }.listStyle(.plain)
            }
        }
        .navigationTitle("Search")
        .searchable(text: $viewModel.query, prompt: "Search text, people, links, tasks")
    }
}

import SwiftUI

struct LibraryView: View {
    @ObservedObject var library: LibraryViewModel
    @State private var scope: LibraryScope = .all
    @State private var showingImport = false

    private var filteredItems: [ScreenshotItem] {
        library.items.filter(scope.includes)
    }

    var body: some View {
        Group {
            if filteredItems.isEmpty {
                EmptyState(symbol: "photo.on.rectangle.angled", title: "No screenshots yet", message: "Import screenshots and Extracta will make them searchable.")
            } else {
                LibraryGrid(items: filteredItems, library: library, delete: library.delete)
            }
        }
        .navigationTitle("Library")
        .safeAreaInset(edge: .top) {
            Picker("Library scope", selection: $scope) {
                ForEach(LibraryScope.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented).padding(.horizontal).padding(.vertical, 8)
            .background(.bar)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingImport = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingImport) { ImportView(library: library) }
        .overlay { if library.isImporting { ProgressOverlay(message: library.importProgress) } }
        .alert("Import issue", isPresented: Binding(get: { library.errorMessage != nil }, set: { if !$0 { library.errorMessage = nil } })) { Button("OK", role: .cancel) {} } message: { Text(library.errorMessage ?? "") }
    }
}

private enum LibraryScope: String, CaseIterable, Identifiable {
    case all = "All"
    case study = "Study"
    case life = "Life"
    case review = "Review"
    var id: String { rawValue }

    func includes(_ item: ScreenshotItem) -> Bool {
        switch self {
        case .all: return true
        case .study: return [.studyNotes, .assignments, .deadlines].contains(item.categoryKind)
        case .life: return [.events, .movies, .shopping, .grocery, .contacts, .receipts, .travel].contains(item.categoryKind)
        case .review: return item.needsReview
        }
    }
}

struct LibraryGrid: View {
    let items: [ScreenshotItem]
    var library: LibraryViewModel? = nil
    var delete: ((ScreenshotItem) -> Void)? = nil
    private let columns = [GridItem(.flexible(), spacing: 13), GridItem(.flexible(), spacing: 13)]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(items) { item in
                    NavigationLink { ScreenshotDetailView(item: item, library: library) } label: { ScreenshotCard(item: item) }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if let delete { Button("Delete screenshot", role: .destructive) { delete(item) } }
                        }
                }
            }.padding()
        }
    }
}

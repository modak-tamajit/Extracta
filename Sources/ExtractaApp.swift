import SwiftUI
import SwiftData

@main
struct ExtractaApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(for: [ScreenshotItem.self, ExtractedEntity.self, GeneratedTask.self])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var library = LibraryViewModel()
    @AppStorage("extracta.hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        TabView {
            NavigationStack { TodayView(library: library) }
                .tabItem { Label("Today", systemImage: "sparkles") }
            NavigationStack { LibraryView(library: library) }
                .tabItem { Label("Library", systemImage: "photo.on.rectangle.angled") }
            NavigationStack { SearchView(library: library) }
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            NavigationStack { TaskListView(library: library) }
                .tabItem { Label("Tasks", systemImage: "checkmark.circle") }
            NavigationStack { SettingsView(library: library) }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.indigo)
        .task { library.configure(with: modelContext) }
        .fullScreenCover(isPresented: Binding(get: { !hasSeenWelcome }, set: { hasSeenWelcome = !$0 })) {
            WelcomeView { hasSeenWelcome = true }
        }
    }
}

#Preview {
    RootView().modelContainer(PreviewData.container)
}

import SwiftUI
import SwiftData

@main
struct ExtractaV3App: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: ScreenshotRecord.self)
    }
}

/// Pulls the environment's ModelContext to hand to HomeView/ScreenshotScanner —
/// kept as a separate tiny view so ExtractaV3App itself stays a one-liner.
private struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HomeView(modelContext: modelContext)
    }
}

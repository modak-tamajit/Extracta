import SwiftUI

struct SettingsView: View {
    @ObservedObject var library: LibraryViewModel
    @State private var showingPrivacy = false
    @State private var confirmingReprocess = false

    var body: some View {
        List {
            Section("On this device") {
                LabeledContent("Screenshots", value: "\(library.items.count)")
                LabeledContent("Storage", value: library.storageDescription)
                Text("Images, recognition, and organization data remain on this device.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Intelligence") {
                Button { confirmingReprocess = true } label: { Label("Reprocess library", systemImage: "arrow.clockwise") }
                    .disabled(library.items.isEmpty || library.isImporting)
                Text("Run on-device recognition again. Personal reminders stay unchanged.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Privacy") {
                Button { showingPrivacy = true } label: { Label("Privacy promise", systemImage: "hand.raised") }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPrivacy) { PrivacyView() }
        .alert("Reprocess library?", isPresented: $confirmingReprocess) {
            Button("Reprocess", role: .destructive) { Task { await library.reprocessLibrary() } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Extracta will read each saved screenshot again on this device. Suggested tasks may update.") }
        .overlay { if library.isImporting { ProgressOverlay(message: library.importProgress) } }
    }
}

import SwiftUI
import PhotosUI

/// A focused multi-photo importer. PhotosPicker grants scoped access without browsing the library directly.
struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var library: LibraryViewModel
    @State private var selectedPhotos: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 48)).foregroundStyle(.indigo)
                    .accessibilityHidden(true)
                VStack(spacing: 8) {
                    Text("Import screenshots").font(.title2.weight(.bold))
                    Text("Choose one or many images. Text recognition, categorization, and entity extraction stay on this device.")
                        .multilineTextAlignment(.center).foregroundStyle(.secondary)
                }
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 30, matching: .images) {
                    Label("Choose photos", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                Text("Up to 30 images per import").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(28)
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .onChange(of: selectedPhotos) { _, newItems in
                Task { await library.importPhotos(newItems); selectedPhotos = []; dismiss() }
            }
        }
    }
}

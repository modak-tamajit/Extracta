import SwiftUI
import UniformTypeIdentifiers

struct ImageImporterButton<Label: View>: View {
    let onImport: ([Data]) -> Void
    let label: () -> Label
    @State private var showingImporter = false

    init(onImport: @escaping ([Data]) -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.onImport = onImport
        self.label = label
    }

    var body: some View {
        #if canImport(UIKit)
        Button(action: { showingImporter = true }, label: label)
            .sheet(isPresented: $showingImporter) {
                NativePhotoPicker { data in
                    showingImporter = false
                    onImport(data)
                }
            }
        #elseif canImport(AppKit)
        Button(action: { showingImporter = true }, label: label)
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.image], allowsMultipleSelection: true) { result in
                guard case let .success(urls) = result else { return }
                let images = urls.compactMap { url -> Data? in
                    let allowed = url.startAccessingSecurityScopedResource()
                    defer { if allowed { url.stopAccessingSecurityScopedResource() } }
                    return try? Data(contentsOf: url)
                }
                onImport(images)
            }
        #endif
    }
}

#if canImport(UIKit)
import UIKit
import PhotosUI

private struct NativePhotoPicker: UIViewControllerRepresentable {
    let onImport: ([Data]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImport: onImport) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 30
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImport: ([Data]) -> Void

        init(onImport: @escaping ([Data]) -> Void) {
            self.onImport = onImport
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let group = DispatchGroup()
            let lock = NSLock()
            var images: [Data] = []

            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    defer { group.leave() }
                    guard let image = object as? UIImage, let data = image.jpegData(compressionQuality: 0.95) else { return }
                    lock.lock()
                    images.append(data)
                    lock.unlock()
                }
            }

            group.notify(queue: .main) { self.onImport(images) }
        }
    }
}
#endif

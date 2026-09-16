import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    private let promises: [(String, String, String)] = [
        ("airplane", "Works offline", "Recognition and organization work in Airplane Mode."),
        ("lock.shield", "On-device processing", "Your images and text are processed using Apple frameworks on your device."),
        ("icloud.slash", "No cloud processing", "No screenshot or extracted information is uploaded anywhere."),
        ("eye.slash", "No tracking", "Extracta has no accounts, analytics, or advertising identifiers.")
    ]
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "hand.raised.fill").font(.largeTitle).foregroundStyle(.indigo)
                        Text("Privacy is the feature.").font(.title2.weight(.bold))
                        Text("Extracta turns screenshots into useful information without sending your personal library to a server.").foregroundStyle(.secondary)
                    }.padding(.vertical, 8)
                }
                Section("Our promise") {
                    ForEach(promises, id: \.1) { item in
                        Label { VStack(alignment: .leading) { Text(item.1).fontWeight(.semibold); Text(item.2).font(.caption).foregroundStyle(.secondary) } } icon: { Image(systemName: item.0).foregroundStyle(.indigo) }
                    }
                }
            }
            .navigationTitle("Privacy")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

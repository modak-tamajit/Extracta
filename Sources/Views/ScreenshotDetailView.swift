import SwiftUI

struct ScreenshotDetailView: View {
    let item: ScreenshotItem
    var library: LibraryViewModel? = nil
    @StateObject private var viewModel = ScreenshotDetailViewModel()
    @State private var showingFullText = false

    private var primaryEntity: ExtractedEntity? { item.entities.first { [.phone, .email, .url].contains($0.kind) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let image = Image(extractaData: item.imageData) {
                    image.resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .accessibilityLabel("Imported screenshot")
                }

                HStack(alignment: .center) {
                    CategoryPill(category: item.categoryKind)
                    Spacer()
                    Label(item.needsReview ? "Needs review" : "High confidence", systemImage: item.needsReview ? "exclamationmark.circle" : "checkmark.seal")
                        .font(.caption).foregroundStyle(item.needsReview ? .orange : .secondary)
                }

                DetailSection(title: "What Extracta found") {
                    Text(item.insight).font(.body.weight(.medium))
                    if item.needsReview { Text("Check this result before relying on it.").font(.subheadline).foregroundStyle(.orange) }
                    if !item.evidence.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Evidence").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            ForEach(item.evidence, id: \.self) { Text($0).font(.subheadline) }
                        }
                    }
                    Text("Recognition confidence: \(Int(item.confidence * 100))%")
                        .font(.caption).foregroundStyle(.secondary)
                }

                if primaryEntity != nil || library != nil || !item.recognizedText.isEmpty {
                    VStack(spacing: 10) {
                        if let primaryEntity {
                            Button { viewModel.open(primaryEntity) } label: { Label(actionTitle(for: primaryEntity), systemImage: primaryEntity.kind.symbol).frame(maxWidth: .infinity) }
                                .buttonStyle(.borderedProminent)
                        } else if let library {
                            Button { library.createReminder(for: item); viewModel.copiedMessage = "Saved to Extracta Tasks" } label: { Label("Save reminder", systemImage: "bell").frame(maxWidth: .infinity) }
                                .buttonStyle(.borderedProminent)
                        }
                        if !item.recognizedText.isEmpty {
                            Button { viewModel.copy(item.recognizedText, label: "Text copied") } label: { Label("Copy recognized text", systemImage: "doc.on.doc").frame(maxWidth: .infinity) }
                                .buttonStyle(.bordered)
                        }
                    }
                }

                DetailSection(title: "Recognized Text") {
                    Text(item.recognizedText.isEmpty ? "No text was detected in this screenshot." : item.recognizedText)
                        .font(.body).textSelection(.enabled)
                        .lineLimit(showingFullText ? nil : 9)
                    if item.recognizedText.count > 350 {
                        Button(showingFullText ? "Show less" : "Show all text") { showingFullText.toggle() }.font(.subheadline.weight(.semibold))
                    }
                }

                if !item.entities.isEmpty {
                    DetailSection(title: "Detected Information") {
                        ForEach(item.entities) { entity in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: entity.kind.symbol).foregroundStyle(.indigo).frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entity.type.capitalized).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                    Text(entity.value).textSelection(.enabled).lineLimit(3)
                                }
                                Spacer()
                            }
                            if entity.id != item.entities.last?.id { Divider() }
                        }
                    }
                }

                if !item.tasks.isEmpty {
                    DetailSection(title: "Generated Tasks") {
                        ForEach(item.tasks) { task in
                            HStack {
                                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle").foregroundStyle(.indigo)
                                VStack(alignment: .leading) {
                                    Text(task.title)
                                    if task.isSuggested { Text("Suggested from this screenshot").font(.caption).foregroundStyle(.secondary) }
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Screenshot")
        .alert("Extracta", isPresented: Binding(get: { viewModel.copiedMessage != nil }, set: { if !$0 { viewModel.copiedMessage = nil } })) { Button("OK", role: .cancel) {} } message: { Text(viewModel.copiedMessage ?? "") }
    }

    private func actionTitle(for entity: ExtractedEntity) -> String {
        switch entity.kind {
        case .phone: return "Call"
        case .email: return "Email"
        case .url: return "Open Website"
        default: return "Open"
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3.weight(.bold))
            content
        }
        .padding(16).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

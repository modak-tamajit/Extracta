import SwiftUI
import SwiftData

struct ResultsView: View {
    // Ascending match strength: within a category, the ones worth double-checking
    // float to the top instead of needing a separate "Review" screen.
    @Query(sort: \ScreenshotRecord.matchStrength, order: .forward) private var records: [ScreenshotRecord]

    private var grouped: [(category: String, items: [ScreenshotRecord])] {
        Dictionary(grouping: records, by: \.displayCategory)
            .map { (category: $0.key, items: $0.value) }
            .sorted { $0.category < $1.category }
    }

    var body: some View {
        List {
            if records.isEmpty {
                ContentUnavailableView(
                    "No Screenshots Yet",
                    systemImage: "photo.on.rectangle",
                    description: Text("Run a scan from Home to see results here.")
                )
            }

            ForEach(grouped, id: \.category) { group in
                Section(group.category) {
                    ForEach(group.items) { record in
                        NavigationLink {
                            ScreenshotDetailView(record: record)
                        } label: {
                            HStack {
                                Text(firstLine(of: record.extractedText))
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int(record.matchStrength * 100))% match")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .accessibilityLabel("\(Int(record.matchStrength * 100)) percent keyword match")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Results")
    }

    private func firstLine(of text: String) -> String {
        text.split(separator: "\n").first.map(String.init) ?? "Screenshot"
    }
}

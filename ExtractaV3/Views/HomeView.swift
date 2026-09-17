import SwiftUI
import SwiftData

struct HomeView: View {
    @StateObject private var scanner: ScreenshotScanner
    @Query(sort: \ScreenshotRecord.analyzedAt, order: .reverse) private var records: [ScreenshotRecord]

    init(modelContext: ModelContext) {
        _scanner = StateObject(wrappedValue: ScreenshotScanner(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Text("Extracta")
                    .font(.largeTitle.bold())

                Text("Understands and organizes your screenshots — entirely on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if scanner.isScanning {
                    ProgressView(
                        value: scanner.total > 0 ? Double(scanner.processed) / Double(scanner.total) : 0
                    )
                    .padding(.horizontal, 32)

                    Text("\(scanner.processed) of \(scanner.total) analyzed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Scan Screenshots") {
                        Task { await scanner.requestAccessAndScan() }
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("Finds screenshots in your photo library and organizes them by what they contain")

                    if !records.isEmpty {
                        NavigationLink {
                            ResultsView()
                        } label: {
                            Text("View Results (\(records.count))")
                        }
                        .padding(.top, 4)
                    }
                }

                Spacer()
                Spacer()
            }
            .padding()
        }
    }
}

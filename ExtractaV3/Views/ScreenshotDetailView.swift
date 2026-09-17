import SwiftUI
import Photos

struct ScreenshotDetailView: View {
    @Bindable var record: ScreenshotRecord
    @State private var uiImage: UIImage?

    // Matches KeywordClassifier's category set plus the fallback. Duplicated here
    // rather than exposed from the classifier — the picker needs a fixed list of
    // options regardless of which classifier produced the original call.
    private let categories = [
        "Study", "Entertainment", "Shopping", "Social", "Travel",
        "Web/Reference", "Miscellaneous"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    if let uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Category")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Category", selection: Binding(
                        get: { record.correctedCategory ?? record.category },
                        set: { newValue in
                            record.correctedCategory = newValue == record.category ? nil : newValue
                        }
                    )) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .accessibilityHint("Corrects Extracta's category if it got this one wrong")

                    // Deliberately labeled "keyword match", not "confidence" —
                    // this is a lexical overlap score, not a claim the app is
                    // confident in an AI sense.
                    Text("Keyword match: \(Int(record.matchStrength * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !record.extractedText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Extracted Text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(record.extractedText)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Screenshot")
        .task { await loadImage() }
    }

    private func loadImage() async {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [record.assetIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false

        uiImage = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 900, height: 900),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

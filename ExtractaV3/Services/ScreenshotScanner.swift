import Foundation
import Photos
import Vision
import SwiftData
import CoreGraphics

/// Drives the whole pipeline: find screenshots → OCR → classify → persist.
/// Deliberately sequential (not a `TaskGroup`) — at demo scale this is fast
/// enough, and it avoids races writing to `processed`/`ModelContext` from
/// multiple tasks at once. Revisit if scan times on real libraries are a problem.
@MainActor
final class ScreenshotScanner: ObservableObject {
    @Published private(set) var isScanning = false
    @Published private(set) var processed = 0
    @Published private(set) var total = 0

    private let classifier: ScreenshotClassifying
    private let modelContext: ModelContext

    init(modelContext: ModelContext, classifier: ScreenshotClassifying = KeywordClassifier()) {
        self.modelContext = modelContext
        self.classifier = classifier
    }

    /// Requests Photos access if needed, then scans. No-ops silently if denied —
    /// the Home screen's empty state already covers "nothing scanned yet".
    func requestAccessAndScan() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else { return }
        await scan()
    }

    private func scan() async {
        isScanning = true
        defer { isScanning = false }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "mediaSubtype == %d",
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        let assets = PHAsset.fetchAssets(with: .image, options: options)

        let existingIDs = Set(
            (try? modelContext.fetch(FetchDescriptor<ScreenshotRecord>()))?
                .map(\.assetIdentifier) ?? []
        )

        total = assets.count
        processed = 0

        for index in 0..<assets.count {
            let asset = assets.object(at: index)
            if !existingIDs.contains(asset.localIdentifier) {
                // A failure analyzing one screenshot must not stop the scan.
                await analyze(asset: asset)
            }
            processed += 1
        }
    }

    private func analyze(asset: PHAsset) async {
        guard let image = await requestCGImage(for: asset) else { return }

        let text = (try? recognizeText(in: image)) ?? ""
        let result = classifier.classify(text: text)

        let record = ScreenshotRecord(
            assetIdentifier: asset.localIdentifier,
            category: result.category,
            matchStrength: result.matchStrength,
            extractedText: text
        )
        modelContext.insert(record)
        try? modelContext.save()
    }

    private func requestCGImage(for asset: PHAsset) async -> CGImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image?.cgImage)
            }
        }
    }

    private func recognizeText(in image: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        return (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}

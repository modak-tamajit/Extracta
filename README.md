# Extracta

Extracta is a Swift Playgrounds / SwiftUI application that turns screenshots into a private student timeline. It imports images from Photos, runs Vision OCR and image classification entirely on-device, finds useful entities, explains its decisions with evidence, and stores results with SwiftData.

## Privacy

There are no accounts, network requests, cloud processing, analytics, trackers, third-party packages, or API keys. Extracta is designed to work in Airplane Mode.

## Open in Swift Playgrounds

Open `Extracta.swiftpm` in Swift Playgrounds 4.6+ on iPad or macOS, or in Xcode 26+. The app targets iOS 17 and uses only Apple frameworks: SwiftUI, SwiftData, Vision, PhotosUI, Foundation, and UIKit.

## Architecture

- `Models`: SwiftData screenshots, entities, and generated tasks.
- `Services`: independent OCR, image classification, entity detection, categorization, task generation, and orchestration services.
- `ViewModels`: library import/persistence, detail actions, and instant local search state.
- `Views`: privacy-first welcome, Today timeline, focused library scopes, search, evidence-backed detail, tasks, and settings UI.

## Performance notes

OCR and classification run off the main queue. Images are persisted as external SwiftData storage and lightweight JPEG thumbnails are used in library grids. Low-confidence results enter Review instead of quietly creating suggested tasks. The views use `LazyVGrid` so scrolling remains efficient as the library grows.

## Checks

`Tests/ExtractaTests.swift` covers deterministic categorization and task-generation rules. Run tests in Xcode against an iOS Simulator or device; Vision and Photos import require that Apple runtime.

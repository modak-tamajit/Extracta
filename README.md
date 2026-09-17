# Extracta V3 — lazy build

## What this is
Source files only — no `.xcodeproj`. I don't have Xcode/a Swift toolchain in
this environment, so a generated project file is a bigger risk (silently
malformed pbxproj) than it's worth. Wiring these into a project takes ~2 minutes.

## Setup (2 min)
1. Xcode → File → New → Project → iOS → App. Interface: SwiftUI. Name: `ExtractaV3`.
2. Delete the generated `ContentView.swift` and the default `ExtractaV3App.swift`.
3. Drag in `ExtractaV3/Models`, `ExtractaV3/Classification`, `ExtractaV3/Services`,
   `ExtractaV3/Views`, and `ExtractaV3/ExtractaV3App.swift` (check "Copy items if needed").
4. Drag `ExtractaV3Tests/KeywordClassifierTests.swift` into your test target
   (or create one: File → New → Target → Unit Testing Bundle).
5. In `Info.plist` (or the Info tab of your target), add:
   - `Privacy - Photo Library Usage Description` → e.g. "Extracta analyzes your
     screenshots on-device to organize them."
   - `Privacy - Photo Library Additions Usage Description` (needed for `.readWrite`
     authorization) → same text works.
6. Build. Run on a simulator with screenshots in its Photos app, or a device.

## What's here
- `Models/ScreenshotRecord.swift` — one SwiftData model.
- `Classification/ScreenshotClassifying.swift` — the swap point. Add a Core ML
  or NaturalLanguage classifier later by writing a new conformance; nothing
  else in the app changes.
- `Classification/KeywordClassifier.swift` — the only classifier that exists.
  Deterministic keyword matching. Not ML. Not pretending to be.
- `Services/ScreenshotScanner.swift` — Photos fetch → Vision OCR → classify → persist.
  Sequential on purpose; one bad asset can't kill the scan.
- `Views/` — Home (scan), Results (grouped list, low-match items sort first),
  Detail (image + category picker + extracted text).

## Deliberately not built
Everything outside the three-screen demo: secondary categories, entity
extraction, evidence arrays, a separate Review screen, sample/mock data
infrastructure, Core ML. Add any of these only when the keyword classifier
demonstrably can't carry your actual demo footage — not before.

## Constraints honored
1. **Classifier is isolated** — `ScreenshotClassifying` protocol, one conformance.
2. **No fake AI confidence** — every UI label says "keyword match," never "confidence."
3. **Scope is exactly the three screens** — Home, Results, Detail. Nothing else.

## Not verified
I could not run `xcodebuild` or the simulator in this sandbox — no Xcode
here. The code is straightforward SwiftUI/Photos/Vision/SwiftData with no
exotic APIs, but treat first build as a real first build: check target
membership after dragging files in, and watch for the usual "forgot to add
file to target" issue. Report back any compiler errors and I'll fix them.

## Original project
Nothing to inspect — no existing project was uploaded to this chat, so this
was built fresh rather than merged with prior code. If you do have an
existing `V3` Xcode project, upload it (zipped) and I'll diff this against
it and reconcile rather than you replacing files blind.

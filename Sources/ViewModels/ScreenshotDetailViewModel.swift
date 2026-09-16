import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class ScreenshotDetailViewModel: ObservableObject {
    @Published var copiedMessage: String?

    func copy(_ value: String, label: String = "Copied") {
        #if canImport(UIKit)
        UIPasteboard.general.string = value
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        #endif
        copiedMessage = "\(label) to clipboard"
    }

    func open(_ entity: ExtractedEntity) {
        let candidate: String
        switch entity.kind {
        case .phone: candidate = "tel://\(entity.value.filter { $0.isNumber || $0 == "+" })"
        case .email: candidate = "mailto:\(entity.value)"
        case .url: candidate = entity.value.hasPrefix("http") ? entity.value : "https://\(entity.value)"
        default: return
        }
        guard let url = URL(string: candidate) else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
}

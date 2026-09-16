import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage

extension PlatformImage {
    var extractaCGImage: CGImage? { cgImage }

    func extractaThumbnailData() -> Data? {
        let target = CGSize(width: 360, height: 360)
        let renderer = UIGraphicsImageRenderer(size: target)
        let thumbnail = renderer.image { _ in
            let scale = max(target.width / size.width, target.height / size.height)
            let drawSize = CGSize(width: size.width * scale, height: size.height * scale)
            let origin = CGPoint(x: (target.width - drawSize.width) / 2, y: (target.height - drawSize.height) / 2)
            draw(in: CGRect(origin: origin, size: drawSize))
        }
        return thumbnail.jpegData(compressionQuality: 0.76)
    }
}

extension Image {
    init?(extractaData: Data) {
        guard let image = UIImage(data: extractaData) else { return nil }
        self.init(uiImage: image)
    }
}
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage

extension PlatformImage {
    var extractaCGImage: CGImage? {
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    func extractaThumbnailData() -> Data? {
        let target = NSSize(width: 360, height: 360)
        let thumbnail = NSImage(size: target)
        thumbnail.lockFocus()
        let scale = max(target.width / size.width, target.height / size.height)
        let drawSize = NSSize(width: size.width * scale, height: size.height * scale)
        let origin = NSPoint(x: (target.width - drawSize.width) / 2, y: (target.height - drawSize.height) / 2)
        draw(in: NSRect(origin: origin, size: drawSize))
        thumbnail.unlockFocus()
        guard let tiff = thumbnail.tiffRepresentation, let representation = NSBitmapImageRep(data: tiff) else { return nil }
        return representation.representation(using: .jpeg, properties: [.compressionFactor: 0.76])
    }
}

extension Image {
    init?(extractaData: Data) {
        guard let image = NSImage(data: extractaData) else { return nil }
        self.init(nsImage: image)
    }
}
#endif

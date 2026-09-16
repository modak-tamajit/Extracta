import SwiftUI

struct ScreenshotThumbnail: View {
    let item: ScreenshotItem
    var body: some View {
        Group {
            if let image = Image(extractaData: item.thumbnailData) {
                image.resizable().scaledToFill()
            } else {
                Color.secondary.opacity(0.15).overlay { Image(systemName: "photo") }
            }
        }
        .clipped()
    }
}

struct CategoryPill: View {
    let category: ScreenshotCategory
    var body: some View {
        Label(category.rawValue, systemImage: category.symbol)
            .font(.caption.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(.indigo.opacity(0.12), in: Capsule())
            .foregroundStyle(.indigo)
    }
}

struct ScreenshotCard: View {
    let item: ScreenshotItem
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScreenshotThumbnail(item: item)
                .frame(height: 142)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            CategoryPill(category: item.categoryKind)
            Text(item.displayTitle)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
            Text(item.createdDate, format: .dateTime.month(.abbreviated).day())
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: { Text(message) }
    }
}

import SwiftUI

struct TodayView: View {
    @ObservedObject var library: LibraryViewModel

    private var openTasks: [GeneratedTask] { library.tasks.filter { !$0.completed } }
    private var tomorrow: Date { Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .distantFuture }
    private var urgentTasks: [GeneratedTask] {
        openTasks.filter { ($0.dueDate ?? .distantFuture) <= tomorrow }
    }
    private var weekTasks: [GeneratedTask] {
        let limit = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .distantFuture
        return openTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate > tomorrow && dueDate <= limit
        }
    }
    private var reviewItems: [ScreenshotItem] { library.items.filter(\.needsReview) }
    private var recentItems: [ScreenshotItem] { Array(library.items.prefix(4)) }
    private var weeklyItems: [ScreenshotItem] {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        return library.items.filter { $0.createdDate >= start }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if library.items.isEmpty {
                    TodayEmptyState(library: library)
                } else {
                    if !urgentTasks.isEmpty { TimelineSection(title: "Needs attention", subtitle: "Due in the next day", tasks: urgentTasks, library: library) }
                    if !weekTasks.isEmpty { TimelineSection(title: "This week", subtitle: "Extracted from your screenshots", tasks: weekTasks, library: library) }
                    if !reviewItems.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Review").font(.title3.weight(.bold))
                            Text("These need your confirmation before Extracta acts on them.").font(.subheadline).foregroundStyle(.secondary)
                            ForEach(reviewItems.prefix(3)) { item in
                                NavigationLink { ScreenshotDetailView(item: item, library: library) } label: { InsightRow(item: item) }.buttonStyle(.plain)
                            }
                        }
                    }
                    if !recentItems.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recently understood").font(.title3.weight(.bold))
                            ForEach(recentItems) { item in
                                NavigationLink { ScreenshotDetailView(item: item, library: library) } label: { InsightRow(item: item) }.buttonStyle(.plain)
                            }
                        }
                    }
                    if !weeklyItems.isEmpty {
                        Text("This week, Extracta saved \(weeklyItems.count) screenshot\(weeklyItems.count == 1 ? "" : "s") privately on this device.")
                            .font(.footnote).foregroundStyle(.secondary).padding(.top, 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem {
                ImageImporterButton(onImport: importImages) { Image(systemName: "plus") }
                    .accessibilityLabel("Import screenshots")
            }
        }
        .overlay { if library.isImporting { ProgressOverlay(message: library.importProgress) } }
    }

    private func importImages(_ images: [Data]) {
        Task { await library.importImages(images) }
    }
}

struct TodayEmptyState: View {
    @ObservedObject var library: LibraryViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "text.viewfinder").font(.system(size: 44)).foregroundStyle(.indigo)
            Text("Remember what matters.").font(.title2.weight(.bold))
            Text("Import screenshots. Extracta reads them on-device, finds important dates and links, and brings useful things back when needed.")
                .foregroundStyle(.secondary)
            ImageImporterButton(onImport: { images in Task { await library.importImages(images) } }) {
                Label("Import screenshots", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
        }
        .padding(.vertical, 40)
    }
}

struct TimelineSection: View {
    let title: String
    let subtitle: String
    let tasks: [GeneratedTask]
    @ObservedObject var library: LibraryViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.title3.weight(.bold))
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            ForEach(tasks) { task in
                TaskRow(task: task, toggle: library.toggle)
                    .padding(12).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

struct InsightRow: View {
    let item: ScreenshotItem
    var body: some View {
        HStack(spacing: 12) {
            ScreenshotThumbnail(item: item).frame(width: 54, height: 54).clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayTitle).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(item.insight).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

struct ProgressOverlay: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) { ProgressView(); Text(message).font(.subheadline) }
            .padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .shadow(radius: 12)
            .accessibilityElement(children: .combine)
    }
}

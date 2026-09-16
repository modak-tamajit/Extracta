import SwiftUI

struct TaskListView: View {
    @ObservedObject var library: LibraryViewModel
    private var activeTasks: [GeneratedTask] { library.tasks.filter { !$0.completed } }
    private var completedTasks: [GeneratedTask] { library.tasks.filter { $0.completed } }

    var body: some View {
        Group {
            if library.tasks.isEmpty {
                EmptyState(symbol: "checkmark.circle", title: "No tasks yet", message: "Assignments and deadlines found in screenshots become tasks here.")
            } else {
                List {
                    if !activeTasks.isEmpty { Section("Open") { ForEach(activeTasks) { TaskRow(task: $0, toggle: library.toggle) } } }
                    if !completedTasks.isEmpty { Section("Completed") { ForEach(completedTasks) { TaskRow(task: $0, toggle: library.toggle) } } }
                }
            }
        }
        .navigationTitle("Tasks")
    }
}

struct TaskRow: View {
    let task: GeneratedTask
    let toggle: (GeneratedTask) -> Void
    var body: some View {
        Button { toggle(task) } label: {
            HStack(spacing: 12) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(task.completed ? .green : .indigo)
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title).strikethrough(task.completed).foregroundStyle(.primary)
                    if let dueDate = task.dueDate { Text(dueDate, format: .dateTime.month(.abbreviated).day().hour().minute()).font(.caption).foregroundStyle(.secondary) }
                }
                Spacer()
            }
        }.buttonStyle(.plain)
    }
}

//
//  TodayView.swift
//  Nudge
//
//  Day tab: live day ring + tasks due today. No weekly letter here.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<NudgeTask> { !$0.isArchived }, sort: \NudgeTask.title)
    private var tasks: [NudgeTask]
    @Query(filter: #Predicate<NudgeCategory> { !$0.isHidden }, sort: \NudgeCategory.name)
    private var categories: [NudgeCategory]

    private let calendar = Calendar.nudge
    /// Fixed header height so the task list doesn't jump when ring/text updates.
    private let headerHeight: CGFloat = 168

    private var today: Date { calendar.startOfDay(for: Date()) }

    private var dueToday: [NudgeTask] {
        tasks.filter { TaskSchedule.isDue($0, on: today, calendar: calendar) }
    }

    private var dayProgress: DayProgress {
        GradeCalculator.dayProgress(for: tasks, on: today, calendar: calendar)
    }

    private var groupedDueToday: [(category: NudgeCategory?, tasks: [NudgeTask])] {
        let grouped = Dictionary(grouping: dueToday) { $0.category?.id }
        var sections: [(category: NudgeCategory?, tasks: [NudgeTask])] = []

        for category in categories {
            if let items = grouped[category.id], !items.isEmpty {
                sections.append((category, items.sorted { $0.title < $1.title }))
            }
        }

        if let orphaned = grouped[nil], !orphaned.isEmpty {
            sections.append((nil, orphaned.sorted { $0.title < $1.title }))
        }

        return sections
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayHeader
                    .frame(height: headerHeight)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .background(.background)

                Divider()

                List {
                    if dueToday.isEmpty {
                        ContentUnavailableView(
                            "Nothing due today",
                            systemImage: "sun.max",
                            description: Text("Add a sample task with + to try the Today loop (real Add form comes in Step 4).")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(Array(groupedDueToday.enumerated()), id: \.offset) { _, section in
                            Section {
                                ForEach(section.tasks, id: \.id) { task in
                                    TodayTaskRow(
                                        task: task,
                                        isCompleted: isCompleted(task),
                                        onToggle: { toggle(task) }
                                    )
                                }
                            } header: {
                                Text(section.category?.name ?? "Uncategorized")
                                    .foregroundStyle(Color(hex: section.category?.colorHex ?? "888888"))
                            }
                        }
                    }

                    if dayProgress.completed < dayProgress.due {
                        Section {
                            Text(
                                "\(dayProgress.due - dayProgress.completed) remaining — today’s ring locks when the day ends"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addSampleTask()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add sample task")
                }
            }
        }
    }

    private var dayHeader: some View {
        HStack(spacing: 20) {
            DayRingView(
                label: "Today",
                progress: dayProgress,
                state: dayProgress.hasTasks ? .active : .noTasks,
                size: 88,
                lineWidth: 8
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(today, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.headline)

                if dayProgress.hasTasks {
                    Text("\(dayProgress.fractionLabel) done")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                    Text("Ring fills as you complete tasks. Weekly grade waits until the week ends.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No tasks due")
                        .font(.title3.weight(.semibold))
                    Text("Add a habit to start filling today’s ring.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func isCompleted(_ task: NudgeTask) -> Bool {
        TaskSchedule.instance(for: task, on: today, calendar: calendar)?.statusKind == .completed
    }

    private func toggle(_ task: NudgeTask) {
        if let existing = TaskSchedule.instance(for: task, on: today, calendar: calendar) {
            modelContext.delete(existing)
        } else {
            let instance = TaskInstance(
                dueDate: today,
                status: .completed,
                completedAt: Date(),
                source: .manual,
                task: task
            )
            modelContext.insert(instance)
        }
        try? modelContext.save()
    }

    /// Temporary until Step 4 Add Task form exists.
    private func addSampleTask() {
        let category = categories.first { $0.name == "Health" } ?? categories.first
        let task = NudgeTask(
            title: "Sample habit",
            emoji: "💊",
            frequency: .daily,
            category: category
        )
        modelContext.insert(task)
        try? modelContext.save()
    }
}

private struct TodayTaskRow: View {
    let task: NudgeTask
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Text(task.emoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .strikethrough(isCompleted)
                    Text(task.frequencyKind.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [NudgeCategory.self, NudgeTask.self, TaskInstance.self], inMemory: true)
}

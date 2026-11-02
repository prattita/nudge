//
//  TodayView.swift
//  Nudge
//
//  Day tab — Fitness-style hero ring + task list.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<NudgeTask> { !$0.isArchived }, sort: \NudgeTask.title)
    private var tasks: [NudgeTask]
    @Query(filter: #Predicate<NudgeCategory> { !$0.isHidden }, sort: \NudgeCategory.name)
    private var categories: [NudgeCategory]

    @State private var showTaskForm = false

    private let calendar = Calendar.nudge
    private let headerHeight: CGFloat = 220

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
                fitnessHeader
                    .frame(height: headerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))

                List {
                    if dueToday.isEmpty {
                        ContentUnavailableView(
                            "Nothing due today",
                            systemImage: "sun.max",
                            description: Text("Tap + to add a habit.")
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(Array(groupedDueToday.enumerated()), id: \.offset) { _, section in
                            Section {
                                ForEach(section.tasks, id: \.id) { task in
                                    TodayTaskRow(
                                        task: task,
                                        isCompleted: isCompleted(task),
                                        onToggle: { toggle(task) }
                                    )
                                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                }
                            } header: {
                                Text((section.category?.name ?? "Uncategorized").uppercased())
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(hex: section.category?.colorHex ?? "888888"))
                                    .tracking(0.6)
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
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showTaskForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add task")
                }
            }
            .sheet(isPresented: $showTaskForm) {
                TaskFormView(taskToEdit: nil)
            }
        }
    }

    /// Fitness-like centered hero ring with quiet supporting copy.
    private var fitnessHeader: some View {
        VStack(spacing: 16) {
            Text(today, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            DayRingView(
                label: "",
                progress: dayProgress,
                state: dayProgress.hasTasks ? .active : .noTasks,
                size: 132,
                lineWidth: 14,
                showsLabel: false,
                showsCenterPercent: true
            )

            VStack(spacing: 4) {
                if dayProgress.hasTasks {
                    Text("\(dayProgress.fractionLabel) Done")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                    Text("Keep moving — the week grade waits until Sunday.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No Tasks Due")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                    Text("Add a habit to start today’s ring.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func isCompleted(_ task: NudgeTask) -> Bool {
        TaskSchedule.instance(for: task, on: today, calendar: calendar)?.statusKind == .completed
    }

    private func toggle(_ task: NudgeTask) {
        if let existing = TaskSchedule.instance(for: task, on: today, calendar: calendar) {
            modelContext.delete(existing)
            try? modelContext.save()
            // Unchecked — put today’s reminder back if still relevant.
            NotificationManager.refresh(for: task, calendar: calendar)
        } else {
            let instance = TaskInstance(
                dueDate: today,
                status: .completed,
                completedAt: Date(),
                source: .manual,
                task: task
            )
            modelContext.insert(instance)
            try? modelContext.save()
            NotificationManager.cancelToday(for: task, calendar: calendar)
        }
    }
}

private struct TodayTaskRow: View {
    let task: NudgeTask
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                Text(task.emoji)
                    .font(.title2)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .strikethrough(isCompleted)
                    Text(task.frequencyKind.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? Color(red: 0.20, green: 0.78, blue: 0.35) : .secondary.opacity(0.5))
            }
            .contentShape(Rectangle())
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [NudgeCategory.self, NudgeTask.self, TaskInstance.self], inMemory: true)
}

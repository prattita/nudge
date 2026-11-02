//
//  GoalsView.swift
//  Nudge
//
//  Per-habit roster: expand for week dots, edit, archive (no mid-week letters).
//

import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<NudgeTask> { !$0.isArchived }, sort: \NudgeTask.title)
    private var tasks: [NudgeTask]

    @State private var showCreateForm = false
    @State private var showEditForm = false
    @State private var taskBeingEdited: NudgeTask?
    @State private var expandedTaskIDs: Set<UUID> = []

    private let calendar = Calendar.nudge
    private let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        NavigationStack {
            Group {
                if tasks.isEmpty {
                    ContentUnavailableView(
                        "No goals yet",
                        systemImage: "target",
                        description: Text("Tap + to add your first habit.")
                    )
                } else {
                    List {
                        ForEach(tasks, id: \.id) { task in
                            GoalTaskRow(
                                task: task,
                                weekdayLabels: weekdayLabels,
                                isExpanded: expandedTaskIDs.contains(task.id),
                                onToggleExpand: { toggleExpand(task.id) },
                                onEdit: {
                                    taskBeingEdited = task
                                    showEditForm = true
                                }
                            )
                        }
                        .onDelete(perform: archive)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add task")
                }
            }
            .sheet(isPresented: $showCreateForm) {
                TaskFormView(taskToEdit: nil)
            }
            .sheet(isPresented: $showEditForm) {
                TaskFormView(taskToEdit: taskBeingEdited)
            }
        }
    }

    private func toggleExpand(_ id: UUID) {
        if expandedTaskIDs.contains(id) {
            expandedTaskIDs.remove(id)
        } else {
            expandedTaskIDs.insert(id)
        }
    }

    private func archive(at offsets: IndexSet) {
        for index in offsets {
            let task = tasks[index]
            task.isArchived = true
            expandedTaskIDs.remove(task.id)
        }
        try? modelContext.save()
    }
}

private struct GoalTaskRow: View {
    let task: NudgeTask
    let weekdayLabels: [String]
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onEdit: () -> Void

    private let calendar = Calendar.nudge

    private var dots: [TaskDayDot] {
        TaskWeekStatus.dots(for: task, calendar: calendar)
    }

    private var fraction: (completed: Int, due: Int) {
        TaskWeekStatus.weekFraction(for: task, calendar: calendar)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onToggleExpand) {
                    HStack(spacing: 12) {
                        Text(task.emoji)
                            .font(.title2)
                            .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.title)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 8)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Edit \(task.title)")
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    weekDots

                    Text(fractionLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 48)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private var subtitle: String {
        let category = task.category?.name ?? "Uncategorized"
        return "\(category) · \(task.frequencyKind.displayName)"
    }

    private var fractionLabel: String {
        if fraction.due == 0 {
            return "Nothing due yet this week"
        }
        return "\(fraction.completed) of \(fraction.due) due this week"
    }

    private var weekDots: some View {
        HStack(spacing: 0) {
            ForEach(Array(dots.enumerated()), id: \.offset) { index, dot in
                VStack(spacing: 6) {
                    DayDotView(kind: dot.kind)
                    Text(weekdayLabels[index])
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}

private struct DayDotView: View {
    let kind: DayDotKind

    private let green = Color(red: 0.20, green: 0.78, blue: 0.35)

    var body: some View {
        ZStack {
            switch kind {
            case .notScheduled:
                Circle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 10, height: 10)
            case .upcoming:
                Circle()
                    .stroke(Color.secondary.opacity(0.45), lineWidth: 1.5)
                    .frame(width: 14, height: 14)
            case .todayOpen:
                Circle()
                    .stroke(green, lineWidth: 2)
                    .frame(width: 16, height: 16)
                Circle()
                    .fill(green.opacity(0.25))
                    .frame(width: 8, height: 8)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(green)
            case .missed:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.red.opacity(0.85))
            }
        }
        .frame(height: 20)
        .accessibilityLabel(label)
    }

    private var label: String {
        switch kind {
        case .notScheduled: return "Not scheduled"
        case .upcoming: return "Upcoming"
        case .todayOpen: return "Due today"
        case .completed: return "Completed"
        case .missed: return "Missed"
        }
    }
}

#Preview {
    GoalsView()
        .modelContainer(for: [NudgeCategory.self, NudgeTask.self, TaskInstance.self], inMemory: true)
}

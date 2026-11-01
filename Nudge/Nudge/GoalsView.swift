//
//  GoalsView.swift
//  Nudge
//
//  Lightweight task list for Add/Edit (full Goals detail lands in Step 5).
//

import SwiftUI
import SwiftData

struct GoalsView: View {
    @Query(filter: #Predicate<NudgeTask> { !$0.isArchived }, sort: \NudgeTask.title)
    private var tasks: [NudgeTask]

    @State private var showCreateForm = false
    @State private var showEditForm = false
    @State private var taskBeingEdited: NudgeTask?

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
                            Button {
                                taskBeingEdited = task
                                showEditForm = true
                            } label: {
                                HStack(spacing: 14) {
                                    Text(task.emoji)
                                        .font(.title2)
                                        .frame(width: 36, height: 36)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(task.title)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Text(subtitle(for: task))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "pencil.circle")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
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

    private func subtitle(for task: NudgeTask) -> String {
        let category = task.category?.name ?? "Uncategorized"
        return "\(category) · \(task.frequencyKind.displayName)"
    }
}

#Preview {
    GoalsView()
        .modelContainer(for: [NudgeCategory.self, NudgeTask.self, TaskInstance.self], inMemory: true)
}

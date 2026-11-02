//
//  TaskFormView.swift
//  Nudge
//
//  Sheet for creating or editing a task (Step 4).
//

import SwiftUI
import SwiftData

struct TaskFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<NudgeCategory> { !$0.isHidden }, sort: \NudgeCategory.name)
    private var categories: [NudgeCategory]

    /// `nil` = create mode; non-nil = edit mode.
    let taskToEdit: NudgeTask?

    @State private var title: String = ""
    @State private var emoji: String = "💊"
    @State private var frequency: TaskFrequency = .daily
    @State private var selectedWeekdays: Set<Int> = [1, 3, 5]
    @State private var monthlyDay: Int = 1
    @State private var yearlyDate: Date = Date()
    @State private var selectedCategoryID: UUID?
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    ) ?? Date()

    @State private var showNewCategory: Bool = false
    @State private var newCategoryName: String = ""
    @State private var newCategoryColor: String = "6BAF7A"
    @State private var validationMessage: String?

    private let calendar = Calendar.nudge
    private let emojiChoices = ["💊", "💧", "📚", "🏃", "🧘", "🐶", "🦷", "🧹", "✅", "💪", "🛏️", "🍎"]
    private let weekdayChoices: [(Int, String)] = [
        (1, "Mon"), (2, "Tue"), (3, "Wed"), (4, "Thu"), (5, "Fri"), (6, "Sat"), (7, "Sun"),
    ]
    private let colorChoices = ["6BAF7A", "E8614A", "F5A623", "4A9EE8", "9B59B6", "1ABC9C"]

    private var isEditing: Bool { taskToEdit != nil }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedCategoryID != nil
            && frequencyValid
    }

    private var frequencyValid: Bool {
        switch frequency {
        case .daily: return true
        case .nTimesPerWeek: return !selectedWeekdays.isEmpty
        case .monthly: return (1...31).contains(monthlyDay)
        case .yearly: return true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Title", text: $title)
                    emojiPicker
                }

                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(TaskFrequency.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }

                    switch frequency {
                    case .daily:
                        EmptyView()
                    case .nTimesPerWeek:
                        weekdayPicker
                    case .monthly:
                        Stepper("Day of month: \(monthlyDay)", value: $monthlyDay, in: 1...31)
                    case .yearly:
                        DatePicker("Date", selection: $yearlyDate, displayedComponents: .date)
                    }
                }

                Section("Category") {
                    categoryPicker
                    Button("New Category") {
                        showNewCategory = true
                    }
                }

                Section("Reminder") {
                    Toggle("Remind me", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadIfEditing)
            .sheet(isPresented: $showNewCategory) {
                newCategorySheet
            }
        }
    }

    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Emoji")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                ForEach(emojiChoices, id: \.self) { choice in
                    Text(choice)
                        .font(.title2)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(emoji == choice ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                        )
                        .onTapGesture { emoji = choice }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var weekdayPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Days")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(weekdayChoices, id: \.0) { day, label in
                    let selected = selectedWeekdays.contains(day)
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selected ? Color.accentColor : Color.secondary.opacity(0.12))
                        )
                        .foregroundStyle(selected ? .white : .primary)
                        .onTapGesture {
                            if selected {
                                selectedWeekdays.remove(day)
                            } else {
                                selectedWeekdays.insert(day)
                            }
                        }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryPicker: some View {
        Picker("Category", selection: $selectedCategoryID) {
            Text("Select…").tag(Optional<UUID>.none)
            ForEach(categories, id: \.id) { category in
                Text(category.name).tag(Optional(category.id))
            }
        }
    }

    private var newCategorySheet: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $newCategoryName)
                HStack(spacing: 12) {
                    ForEach(colorChoices, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 32, height: 32)
                            .overlay {
                                if newCategoryColor == hex {
                                    Circle().strokeBorder(.primary, lineWidth: 2)
                                }
                            }
                            .onTapGesture { newCategoryColor = hex }
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showNewCategory = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCategory()
                    }
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func loadIfEditing() {
        guard let task = taskToEdit else {
            selectedCategoryID = categories.first { $0.name == "Health" }?.id ?? categories.first?.id
            return
        }

        title = task.title
        emoji = task.emoji
        frequency = task.frequencyKind
        selectedWeekdays = Set(task.weekdayNumbers)
        monthlyDay = task.monthlyDay ?? 1
        if let month = task.yearlyMonth, let day = task.yearlyDay {
            var comps = DateComponents()
            comps.year = calendar.component(.year, from: Date())
            comps.month = month
            comps.day = day
            yearlyDate = calendar.date(from: comps) ?? Date()
        }
        selectedCategoryID = task.category?.id
        if let reminder = task.reminderTime {
            reminderEnabled = true
            reminderTime = reminder
        }
    }

    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let category = NudgeCategory(name: trimmed, colorHex: newCategoryColor, isPreset: false)
        modelContext.insert(category)
        try? modelContext.save()
        selectedCategoryID = category.id
        newCategoryName = ""
        showNewCategory = false
    }

    private func save() {
        validationMessage = nil
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = "Title is required."
            return
        }
        guard let categoryID = selectedCategoryID,
              let category = categories.first(where: { $0.id == categoryID }) else {
            validationMessage = "Pick a category."
            return
        }
        guard frequencyValid else {
            validationMessage = "Finish the schedule settings."
            return
        }

        let weekdaysString = selectedWeekdays.sorted().map(String.init).joined(separator: ",")
        let yearMonth = calendar.component(.month, from: yearlyDate)
        let yearDay = calendar.component(.day, from: yearlyDate)
        let reminder = reminderEnabled ? reminderTime : nil

        let savedTask: NudgeTask
        if let task = taskToEdit {
            let scheduleChanged = didScheduleChange(task)
            task.title = trimmed
            task.emoji = emoji
            task.frequencyKind = frequency
            task.scheduledWeekdays = frequency == .nTimesPerWeek ? weekdaysString : ""
            task.monthlyDay = frequency == .monthly ? monthlyDay : nil
            task.yearlyMonth = frequency == .yearly ? yearMonth : nil
            task.yearlyDay = frequency == .yearly ? yearDay : nil
            task.reminderTime = reminder
            task.category = category
            if scheduleChanged {
                // Spec: schedule edits apply from tomorrow; history stays as-is.
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
                task.scheduleEffectiveFrom = tomorrow
            }
            savedTask = task
        } else {
            let now = Date()
            let task = NudgeTask(
                title: trimmed,
                emoji: emoji,
                frequency: frequency,
                scheduledWeekdays: frequency == .nTimesPerWeek ? weekdaysString : "",
                monthlyDay: frequency == .monthly ? monthlyDay : nil,
                yearlyMonth: frequency == .yearly ? yearMonth : nil,
                yearlyDay: frequency == .yearly ? yearDay : nil,
                reminderTime: reminder,
                createdAt: now,
                scheduleEffectiveFrom: now,
                category: category
            )
            modelContext.insert(task)
            savedTask = task
        }

        try? modelContext.save()
        NotificationManager.refresh(for: savedTask, calendar: calendar)
        dismiss()
    }

    private func didScheduleChange(_ task: NudgeTask) -> Bool {
        let weekdaysString = selectedWeekdays.sorted().map(String.init).joined(separator: ",")
        let yearMonth = calendar.component(.month, from: yearlyDate)
        let yearDay = calendar.component(.day, from: yearlyDate)

        if task.frequencyKind != frequency { return true }
        if frequency == .nTimesPerWeek, task.scheduledWeekdays != weekdaysString { return true }
        if frequency == .monthly, task.monthlyDay != monthlyDay { return true }
        if frequency == .yearly, task.yearlyMonth != yearMonth || task.yearlyDay != yearDay { return true }
        return false
    }
}

#Preview {
    TaskFormView(taskToEdit: nil)
        .modelContainer(for: [NudgeCategory.self, NudgeTask.self, TaskInstance.self], inMemory: true)
}

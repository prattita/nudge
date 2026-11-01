//
//  NudgeTask.swift
//  Nudge
//
//  A recurring trackable habit / accountability item.
//

import Foundation
import SwiftData

@Model
final class NudgeTask {
    var id: UUID = UUID()
    var title: String = ""
    var emoji: String = "✅"
    /// Persisted `TaskFrequency.rawValue`
    var frequency: String = TaskFrequency.daily.rawValue
    /// Comma-separated weekday numbers: 1=Mon … 7=Sun. Empty when not n-times/week.
    var scheduledWeekdays: String = ""
    var monthlyDay: Int?
    var yearlyMonth: Int?
    var yearlyDay: Int?
    /// Optional reminder time; nil means no reminder.
    var reminderTime: Date?
    var autoCompleteFromHealthKit: Bool = false
    var isArchived: Bool = false
    var createdAt: Date = Date()

    var category: NudgeCategory?

    @Relationship(deleteRule: .cascade, inverse: \TaskInstance.task)
    var instances: [TaskInstance]? = []

    init(
        title: String,
        emoji: String = "✅",
        frequency: TaskFrequency = .daily,
        scheduledWeekdays: String = "",
        monthlyDay: Int? = nil,
        yearlyMonth: Int? = nil,
        yearlyDay: Int? = nil,
        reminderTime: Date? = nil,
        autoCompleteFromHealthKit: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        category: NudgeCategory? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.emoji = emoji
        self.frequency = frequency.rawValue
        self.scheduledWeekdays = scheduledWeekdays
        self.monthlyDay = monthlyDay
        self.yearlyMonth = yearlyMonth
        self.yearlyDay = yearlyDay
        self.reminderTime = reminderTime
        self.autoCompleteFromHealthKit = autoCompleteFromHealthKit
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.category = category
    }

    /// Typed view of the stored frequency string.
    var frequencyKind: TaskFrequency {
        get { TaskFrequency(rawValue: frequency) ?? .daily }
        set { frequency = newValue.rawValue }
    }

    /// Parsed weekday numbers from `scheduledWeekdays`.
    var weekdayNumbers: [Int] {
        scheduledWeekdays
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }
}

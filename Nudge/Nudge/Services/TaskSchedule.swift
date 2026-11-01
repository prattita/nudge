//
//  TaskSchedule.swift
//  Nudge
//
//  Answers: "Is this task due on this calendar day?"
//

import Foundation

enum TaskSchedule {
    /// Whether `task` should appear on `day` (respects frequency, schedule, and `createdAt`).
    static func isDue(
        _ task: NudgeTask,
        on day: Date,
        calendar: Calendar = .nudge
    ) -> Bool {
        guard !task.isArchived else { return false }

        let dayStart = calendar.startOfDay(for: day)
        let createdStart = calendar.startOfDay(for: task.createdAt)
        guard dayStart >= createdStart else { return false }

        switch task.frequencyKind {
        case .daily:
            return true

        case .nTimesPerWeek:
            let weekday = calendar.nudgeWeekday(for: dayStart)
            return task.weekdayNumbers.contains(weekday)

        case .monthly:
            guard let monthlyDay = task.monthlyDay else { return false }
            let effective = calendar.clampedDayOfMonth(monthlyDay, inMonthOf: dayStart)
            return calendar.component(.day, from: dayStart) == effective

        case .yearly:
            guard let month = task.yearlyMonth, let dayOfMonth = task.yearlyDay else { return false }
            guard calendar.component(.month, from: dayStart) == month else { return false }
            // Build a reference date in this year/month to clamp day (e.g. Feb 29).
            var components = calendar.dateComponents([.year, .month], from: dayStart)
            components.day = 1
            let monthStart = calendar.date(from: components) ?? dayStart
            let effective = calendar.clampedDayOfMonth(dayOfMonth, inMonthOf: monthStart)
            return calendar.component(.day, from: dayStart) == effective
        }
    }

    /// All due dates for `task` from `start` through `end` (inclusive), start-of-day values.
    static func dueDates(
        for task: NudgeTask,
        from start: Date,
        through end: Date,
        calendar: Calendar = .nudge
    ) -> [Date] {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        guard startDay <= endDay else { return [] }

        var dates: [Date] = []
        var cursor = startDay
        while cursor <= endDay {
            if isDue(task, on: cursor, calendar: calendar) {
                dates.append(cursor)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return dates
    }

    /// Existing instance for `task` on the same calendar day as `day`, if any.
    static func instance(
        for task: NudgeTask,
        on day: Date,
        calendar: Calendar = .nudge
    ) -> TaskInstance? {
        task.instances?.first { calendar.isDate($0.dueDate, inSameDayAs: day) }
    }
}

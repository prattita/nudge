//
//  GradeCalculator.swift
//  Nudge
//
//  Day rings narrate progress; letter grades appear only for *completed* weeks.
//  Callers pass the task set (include archived for history; active-only for Today).
//

import Foundation
import SwiftUI

struct GradeResult: Equatable {
    let completed: Int
    let due: Int
    let percentage: Double
    let letter: String

    var hasWork: Bool { due > 0 }

    var fractionLabel: String {
        "\(completed) of \(due)"
    }
}

struct DayProgress: Equatable, Identifiable {
    let date: Date
    let completed: Int
    let due: Int

    var id: Date { date }

    var fill: Double {
        guard due > 0 else { return 0 }
        return min(1, Double(completed) / Double(due))
    }

    var hasTasks: Bool { due > 0 }

    var fractionLabel: String {
        "\(completed) of \(due)"
    }
}

struct WeekHistoryPoint: Identifiable, Equatable {
    let weekStart: Date
    let result: GradeResult
    let isComplete: Bool
    let isCurrent: Bool

    var id: Date { weekStart }

    /// Bar height 0...100. Current week uses through-today aggregate (no letter implied).
    var chartPercentage: Double {
        result.hasWork ? result.percentage : 0
    }

    var shortLabel: String {
        weekStart.formatted(.dateTime.month(.abbreviated).day())
    }
}

struct BreakdownItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let emoji: String?
    let result: GradeResult
}

enum GradeCalculator {
    static func letter(for percentage: Double) -> String {
        switch percentage {
        case 97...: return "A+"
        case 93..<97: return "A"
        case 90..<93: return "A-"
        case 87..<90: return "B+"
        case 83..<87: return "B"
        case 80..<83: return "B-"
        case 77..<80: return "C+"
        case 73..<77: return "C"
        case 70..<73: return "C-"
        case 60..<70: return "D"
        default: return "F"
        }
    }

    static func grade(completed: Int, due: Int) -> GradeResult {
        guard due > 0 else {
            return GradeResult(completed: 0, due: 0, percentage: 0, letter: "—")
        }
        let percentage = (Double(completed) / Double(due)) * 100
        return GradeResult(
            completed: completed,
            due: due,
            percentage: percentage,
            letter: letter(for: percentage)
        )
    }

    /// Color hint for completed-week bars (Fitness-adjacent greens / warm falls).
    static func barColor(for result: GradeResult, isComplete: Bool) -> Color {
        guard isComplete, result.hasWork else {
            return Color.secondary.opacity(0.45)
        }
        switch result.percentage {
        case 90...: return Color(red: 0.20, green: 0.78, blue: 0.35)
        case 80..<90: return Color(red: 0.35, green: 0.72, blue: 0.45)
        case 70..<80: return Color(red: 0.95, green: 0.65, blue: 0.14)
        case 60..<70: return Color(red: 0.95, green: 0.45, blue: 0.20)
        default: return Color(red: 0.90, green: 0.30, blue: 0.30)
        }
    }

    static func dayProgress(
        for tasks: [NudgeTask],
        on day: Date,
        calendar: Calendar = .nudge
    ) -> DayProgress {
        let dayStart = calendar.startOfDay(for: day)
        var completed = 0
        var due = 0

        for task in tasks {
            guard TaskSchedule.isDue(task, on: dayStart, calendar: calendar) else { continue }
            due += 1
            if let instance = TaskSchedule.instance(for: task, on: dayStart, calendar: calendar),
               instance.statusKind == .completed {
                completed += 1
            }
        }

        return DayProgress(date: dayStart, completed: completed, due: due)
    }

    static func weekDayProgress(
        for tasks: [NudgeTask],
        weekStarting weekStart: Date,
        calendar: Calendar = .nudge
    ) -> [DayProgress] {
        let start = calendar.startOfDay(for: weekStart)
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return dayProgress(for: tasks, on: day, calendar: calendar)
        }
    }

    static func isWeekComplete(
        weekStarting weekStart: Date,
        asOf date: Date = Date(),
        calendar: Calendar = .nudge
    ) -> Bool {
        let start = calendar.startOfDay(for: weekStart)
        guard let sunday = calendar.date(byAdding: .day, value: 6, to: start) else { return false }
        return calendar.startOfDay(for: date) > calendar.startOfDay(for: sunday)
    }

    /// Aggregate for a full Mon–Sun week (use for completed weeks / report card).
    static func weekGrade(
        for tasks: [NudgeTask],
        weekStarting weekStart: Date,
        calendar: Calendar = .nudge
    ) -> GradeResult {
        let start = calendar.startOfDay(for: weekStart)
        guard let end = calendar.date(byAdding: .day, value: 6, to: start) else {
            return grade(completed: 0, due: 0)
        }
        return aggregate(for: tasks, from: start, through: end, calendar: calendar)
    }

    /// Aggregate through `asOf` within the week (current week progress — no letter in UI).
    static func weekProgressThrough(
        for tasks: [NudgeTask],
        weekStarting weekStart: Date,
        asOf date: Date = Date(),
        calendar: Calendar = .nudge
    ) -> GradeResult {
        let start = calendar.startOfDay(for: weekStart)
        let today = calendar.startOfDay(for: date)
        guard let sunday = calendar.date(byAdding: .day, value: 6, to: start) else {
            return grade(completed: 0, due: 0)
        }
        let end = min(today, sunday)
        guard end >= start else { return grade(completed: 0, due: 0) }
        return aggregate(for: tasks, from: start, through: end, calendar: calendar)
    }

    /// History from the earliest task `createdAt` week through the current week (min 1 bar).
    static func weekHistory(
        for tasks: [NudgeTask],
        asOf date: Date = Date(),
        calendar: Calendar = .nudge
    ) -> [WeekHistoryPoint] {
        let today = calendar.startOfDay(for: date)
        let currentWeekStart = calendar.startOfNudgeWeek(for: today)

        let earliestCreated = tasks.map(\.createdAt).min() ?? today
        var cursor = calendar.startOfNudgeWeek(for: earliestCreated)

        var points: [WeekHistoryPoint] = []
        while cursor <= currentWeekStart {
            let complete = isWeekComplete(weekStarting: cursor, asOf: today, calendar: calendar)
            let isCurrent = calendar.isDate(cursor, inSameDayAs: currentWeekStart)
            let result: GradeResult
            if complete {
                result = weekGrade(for: tasks, weekStarting: cursor, calendar: calendar)
            } else {
                result = weekProgressThrough(for: tasks, weekStarting: cursor, asOf: today, calendar: calendar)
            }
            points.append(
                WeekHistoryPoint(
                    weekStart: cursor,
                    result: result,
                    isComplete: complete,
                    isCurrent: isCurrent
                )
            )
            guard let next = calendar.date(byAdding: .day, value: 7, to: cursor) else { break }
            cursor = next
        }

        if points.isEmpty {
            points.append(
                WeekHistoryPoint(
                    weekStart: currentWeekStart,
                    result: weekProgressThrough(for: tasks, weekStarting: currentWeekStart, asOf: today, calendar: calendar),
                    isComplete: false,
                    isCurrent: true
                )
            )
        }

        return points
    }

    static func taskBreakdown(
        for tasks: [NudgeTask],
        weekStarting weekStart: Date,
        asOf date: Date = Date(),
        calendar: Calendar = .nudge
    ) -> [BreakdownItem] {
        let range = weekRange(weekStarting: weekStart, asOf: date, calendar: calendar)
        return tasks.compactMap { task in
            let result = aggregate(for: [task], from: range.start, through: range.end, calendar: calendar)
            guard result.hasWork else { return nil }
            let category = task.category?.name ?? "Uncategorized"
            let archivedNote = task.isArchived ? " · archived" : ""
            return BreakdownItem(
                id: task.id,
                title: task.title,
                subtitle: category + archivedNote,
                emoji: task.emoji,
                result: result
            )
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    static func categoryBreakdown(
        for tasks: [NudgeTask],
        weekStarting weekStart: Date,
        asOf date: Date = Date(),
        calendar: Calendar = .nudge
    ) -> [BreakdownItem] {
        let range = weekRange(weekStarting: weekStart, asOf: date, calendar: calendar)
        let grouped = Dictionary(grouping: tasks) { $0.category?.id }
        return grouped.compactMap { _, group -> BreakdownItem? in
            let result = aggregate(for: group, from: range.start, through: range.end, calendar: calendar)
            guard result.hasWork else { return nil }
            let name = group.first?.category?.name ?? "Uncategorized"
            let id = group.first?.category?.id ?? UUID()
            return BreakdownItem(
                id: id,
                title: name,
                subtitle: "\(group.count) habit\(group.count == 1 ? "" : "s")",
                emoji: nil,
                result: result
            )
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    // MARK: - Private

    private static func weekRange(
        weekStarting weekStart: Date,
        asOf date: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        let start = calendar.startOfDay(for: weekStart)
        let today = calendar.startOfDay(for: date)
        let sunday = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        if isWeekComplete(weekStarting: start, asOf: today, calendar: calendar) {
            return (start, sunday)
        }
        return (start, min(today, sunday))
    }

    private static func aggregate(
        for tasks: [NudgeTask],
        from start: Date,
        through end: Date,
        calendar: Calendar
    ) -> GradeResult {
        var completed = 0
        var due = 0
        for task in tasks {
            let slots = TaskSchedule.dueDates(for: task, from: start, through: end, calendar: calendar)
            due += slots.count
            for slot in slots {
                if let instance = TaskSchedule.instance(for: task, on: slot, calendar: calendar),
                   instance.statusKind == .completed {
                    completed += 1
                }
            }
        }
        return grade(completed: completed, due: due)
    }
}

//
//  GradeCalculator.swift
//  Nudge
//
//  Day rings narrate progress; letter grades appear only for *completed* weeks.
//  Day fill is capped at 100% (Option A). Shortcomings stay on day rings;
//  week letter uses aggregate completed/due for that Mon–Sun.
//

import Foundation

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

    /// 0...1 fill for the ring (capped at 100%).
    var fill: Double {
        guard due > 0 else { return 0 }
        return min(1, Double(completed) / Double(due))
    }

    var hasTasks: Bool { due > 0 }

    var fractionLabel: String {
        "\(completed) of \(due)"
    }
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

    /// Completion for a single calendar day (live today, locked truth for past once backfilled).
    static func dayProgress(
        for tasks: [NudgeTask],
        on day: Date,
        calendar: Calendar = .nudge
    ) -> DayProgress {
        let dayStart = calendar.startOfDay(for: day)
        var completed = 0
        var due = 0

        for task in tasks where !task.isArchived {
            guard TaskSchedule.isDue(task, on: dayStart, calendar: calendar) else { continue }
            due += 1
            if let instance = TaskSchedule.instance(for: task, on: dayStart, calendar: calendar),
               instance.statusKind == .completed {
                completed += 1
            }
        }

        return DayProgress(date: dayStart, completed: completed, due: due)
    }

    /// Seven day-progress values for the week starting Monday `weekStart`.
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

    /// True when Sunday of that week is fully in the past (week can show a letter).
    static func isWeekComplete(
        weekStarting weekStart: Date,
        asOf date: Date = Date(),
        calendar: Calendar = .nudge
    ) -> Bool {
        let start = calendar.startOfDay(for: weekStart)
        guard let sunday = calendar.date(byAdding: .day, value: 6, to: start) else { return false }
        return calendar.startOfDay(for: date) > calendar.startOfDay(for: sunday)
    }

    /// Aggregate letter for a Mon–Sun week. Only meaningful when `isWeekComplete` is true.
    static func weekGrade(
        for tasks: [NudgeTask],
        weekStarting weekStart: Date,
        calendar: Calendar = .nudge
    ) -> GradeResult {
        let days = weekDayProgress(for: tasks, weekStarting: weekStart, calendar: calendar)
        let completed = days.reduce(0) { $0 + $1.completed }
        let due = days.reduce(0) { $0 + $1.due }
        return grade(completed: completed, due: due)
    }
}

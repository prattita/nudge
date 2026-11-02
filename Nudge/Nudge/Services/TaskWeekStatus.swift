//
//  TaskWeekStatus.swift
//  Nudge
//
//  Per-task week strip: dots + "X of Y due this week" (no mid-week letter).
//

import Foundation

enum DayDotKind: Equatable {
    /// Not scheduled that day.
    case notScheduled
    /// Due today and still open.
    case todayOpen
    /// Due and completed.
    case completed
    /// Due in the past and not completed (miss / unlocked past day).
    case missed
    /// Due on a future day this week.
    case upcoming
}

struct TaskDayDot: Equatable, Identifiable {
    let date: Date
    let kind: DayDotKind

    var id: Date { date }
}

enum TaskWeekStatus {
    /// Seven dots Mon→Sun for the week containing `asOf`.
    static func dots(
        for task: NudgeTask,
        asOf date: Date = Date(),
        calendar: Calendar = .nudge
    ) -> [TaskDayDot] {
        let today = calendar.startOfDay(for: date)
        let weekStart = calendar.startOfNudgeWeek(for: today)

        return (0..<7).compactMap { offset -> TaskDayDot? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else {
                return nil
            }
            let dayStart = calendar.startOfDay(for: day)
            let due = TaskSchedule.isDue(task, on: dayStart, calendar: calendar)

            if !due {
                return TaskDayDot(date: dayStart, kind: .notScheduled)
            }

            let instance = TaskSchedule.instance(for: task, on: dayStart, calendar: calendar)
            let completed = instance?.statusKind == .completed

            if completed {
                return TaskDayDot(date: dayStart, kind: .completed)
            }
            if dayStart > today {
                return TaskDayDot(date: dayStart, kind: .upcoming)
            }
            if dayStart == today {
                return TaskDayDot(date: dayStart, kind: .todayOpen)
            }
            return TaskDayDot(date: dayStart, kind: .missed)
        }
    }

    /// Due slots this week through today (settled + open today), and how many are completed.
    static func weekFraction(
        for task: NudgeTask,
        asOf date: Date = Date(),
        calendar: Calendar = .nudge
    ) -> (completed: Int, due: Int) {
        let today = calendar.startOfDay(for: date)
        let weekStart = calendar.startOfNudgeWeek(for: today)
        let slots = TaskSchedule.dueDates(
            for: task,
            from: weekStart,
            through: today,
            calendar: calendar
        )
        let completed = slots.filter { slot in
            TaskSchedule.instance(for: task, on: slot, calendar: calendar)?.statusKind == .completed
        }.count
        return (completed, slots.count)
    }
}

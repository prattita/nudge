//
//  MissBackfill.swift
//  Nudge
//
//  On app open: record misses for past due days that have no TaskInstance.
//  Never backfills today (day still open). First launch seeds lastBackfill = today.
//

import Foundation
import SwiftData

struct MissBackfillResult: Equatable {
    /// Misses created this run, keyed by start-of-day.
    let missesByDay: [Date: Int]

    var totalMisses: Int {
        missesByDay.values.reduce(0, +)
    }

    var isEmpty: Bool { totalMisses == 0 }

    /// Short lines for a summary alert, newest day last.
    var summaryLines: [String] {
        let formatted = missesByDay.keys.sorted().map { day -> String in
            let count = missesByDay[day] ?? 0
            let label = day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
            let noun = count == 1 ? "task" : "tasks"
            return "\(count) \(noun) missed on \(label)"
        }
        return formatted
    }
}

enum MissBackfill {
    /// Runs a backfill pass. Returns the new `lastBackfillDate` to persist and any new misses.
    ///
    /// - Parameters:
    ///   - lastBackfillDate: `nil` = first launch → set to today, create nothing.
    ///   - asOf: “now” (injectable for tests).
    static func run(
        context: ModelContext,
        tasks: [NudgeTask],
        lastBackfillDate: Date?,
        asOf: Date = Date(),
        calendar: Calendar = .nudge
    ) -> (newLastBackfill: Date, result: MissBackfillResult) {
        let today = calendar.startOfDay(for: asOf)

        // First launch: catch up marker = today, invent no history.
        guard let lastBackfillDate else {
            return (today, MissBackfillResult(missesByDay: [:]))
        }

        let last = calendar.startOfDay(for: lastBackfillDate)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            return (last, MissBackfillResult(missesByDay: [:]))
        }

        // Nothing to do if we're already caught up (last > yesterday), e.g. same calendar day as install.
        guard last <= yesterday else {
            return (last, MissBackfillResult(missesByDay: [:]))
        }

        var missesByDay: [Date: Int] = [:]
        var cursor = last

        while cursor <= yesterday {
            var dayCount = 0
            for task in tasks {
                guard TaskSchedule.isDue(task, on: cursor, calendar: calendar) else { continue }
                if TaskSchedule.instance(for: task, on: cursor, calendar: calendar) != nil {
                    continue
                }
                let miss = TaskInstance(
                    dueDate: cursor,
                    status: .missed,
                    completedAt: nil,
                    source: .manual,
                    task: task
                )
                context.insert(miss)
                dayCount += 1
            }
            if dayCount > 0 {
                missesByDay[cursor] = dayCount
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        try? context.save()
        // Spec: after processing, lastBackfill = yesterday (all days through yesterday are done).
        return (yesterday, MissBackfillResult(missesByDay: missesByDay))
    }
}

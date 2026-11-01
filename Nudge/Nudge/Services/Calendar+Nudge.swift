//
//  Calendar+Nudge.swift
//  Nudge
//
//  Date helpers: Monday-based weeks and Mon=1…Sun=7 weekdays (design doc).
//

import Foundation

extension Calendar {
    /// Calendar with Monday as the first day of the week (ISO-style weeks).
    static var nudge: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    /// Start of the Monday–Sunday week containing `value`.
    func startOfNudgeWeek(for value: Date) -> Date {
        let day = startOfDay(for: value)
        let weekday = component(.weekday, from: day) // 1=Sun … 7=Sat
        let daysFromMonday = (weekday + 5) % 7
        return self.date(byAdding: .day, value: -daysFromMonday, to: day) ?? day
    }

    /// Design-doc weekday: 1=Monday … 7=Sunday.
    func nudgeWeekday(for date: Date) -> Int {
        let weekday = component(.weekday, from: date) // 1=Sun … 7=Sat
        return weekday == 1 ? 7 : weekday - 1
    }

    /// Last day-of-month number for the month containing `date`.
    func daysInMonth(for date: Date) -> Int {
        range(of: .day, in: .month, for: date)?.count ?? 30
    }

    /// Effective day-of-month when the chosen day may not exist (e.g. 31 in April).
    func clampedDayOfMonth(_ desiredDay: Int, inMonthOf date: Date) -> Int {
        min(desiredDay, daysInMonth(for: date))
    }
}

//
//  NotificationManager.swift
//  Nudge
//
//  Local notifications for optional per-task reminder times.
//  Schedules one-shot alerts for the next several due days (refreshed on launch/save).
//

import Foundation
import UserNotifications

enum NotificationManager {
    private static let center = UNUserNotificationCenter.current()
    private static let horizonDays = 21

    /// Ask the system once; safe to call repeatedly.
    static func requestPermissionIfNeeded() async {
        do {
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .notDetermined else { return }
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Permission denied or unavailable — reminders simply won't fire.
        }
    }

    /// Cancel every pending notification for this task, then reschedule if needed.
    static func refresh(for task: NudgeTask, calendar: Calendar = .nudge) {
        cancelAll(for: task.id, calendar: calendar)

        guard !task.isArchived, let reminderTime = task.reminderTime else { return }

        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        let now = Date()
        let today = calendar.startOfDay(for: now)

        for offset in 0..<horizonDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            guard TaskSchedule.isDue(task, on: day, calendar: calendar) else { continue }

            // Skip today if already completed.
            if calendar.isDate(day, inSameDayAs: today),
               TaskSchedule.instance(for: task, on: day, calendar: calendar)?.statusKind == .completed {
                continue
            }

            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = hour
            components.minute = minute

            guard let fireDate = calendar.date(from: components), fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Nudge"
            content.body = "\(task.emoji) \(task.title)"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = identifier(taskID: task.id, day: day, calendar: calendar)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
        }
    }

    static func refreshAll(tasks: [NudgeTask], calendar: Calendar = .nudge) {
        for task in tasks {
            refresh(for: task, calendar: calendar)
        }
    }

    static func cancelAll(for taskID: UUID, calendar: Calendar = .nudge) {
        // Remove a window of known IDs synchronously (avoids race with immediate reschedule).
        let today = calendar.startOfDay(for: Date())
        var ids: [String] = []
        for offset in -7..<(horizonDays + 7) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            ids.append(identifier(taskID: taskID, day: day, calendar: calendar))
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Drop today’s reminder after the user completes the task (future days stay).
    static func cancelToday(for task: NudgeTask, calendar: Calendar = .nudge) {
        let today = calendar.startOfDay(for: Date())
        let id = identifier(taskID: task.id, day: today, calendar: calendar)
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    private static func identifier(taskID: UUID, day: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        let y = parts.year ?? 0
        let m = parts.month ?? 0
        let d = parts.day ?? 0
        return String(format: "nudge.%@.%04d%02d%02d", taskID.uuidString, y, m, d)
    }
}

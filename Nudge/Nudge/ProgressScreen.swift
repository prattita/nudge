//
//  ProgressScreen.swift
//  Nudge
//
//  Week tab: Mon–Sun day rings. Letter grade only for completed (past) weeks.
//

import SwiftUI
import SwiftData

struct ProgressScreen: View {
    @Query(filter: #Predicate<NudgeTask> { !$0.isArchived }, sort: \NudgeTask.title)
    private var tasks: [NudgeTask]

    @State private var weekOffset: Int = 0 // 0 = current week, -1 = previous, etc.

    private let calendar = Calendar.nudge
    private let weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var today: Date { calendar.startOfDay(for: Date()) }

    private var displayedWeekStart: Date {
        let currentStart = calendar.startOfNudgeWeek(for: today)
        return calendar.date(byAdding: .day, value: weekOffset * 7, to: currentStart) ?? currentStart
    }

    private var displayedWeekEnd: Date {
        calendar.date(byAdding: .day, value: 6, to: displayedWeekStart) ?? displayedWeekStart
    }

    private var isCurrentWeek: Bool { weekOffset == 0 }

    private var isCompletedWeek: Bool {
        GradeCalculator.isWeekComplete(weekStarting: displayedWeekStart, asOf: today, calendar: calendar)
    }

    private var dayProgresses: [DayProgress] {
        GradeCalculator.weekDayProgress(for: tasks, weekStarting: displayedWeekStart, calendar: calendar)
    }

    private var weekGrade: GradeResult? {
        guard isCompletedWeek else { return nil }
        return GradeCalculator.weekGrade(for: tasks, weekStarting: displayedWeekStart, calendar: calendar)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    weekNavigator
                    weekRings
                }

                Section {
                    if let weekGrade, isCompletedWeek {
                        HStack(alignment: .firstTextBaseline) {
                            Text(weekGrade.letter)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Week grade")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if weekGrade.hasWork {
                                    Text("\(Int(weekGrade.percentage.rounded()))% · \(weekGrade.fractionLabel)")
                                        .font(.subheadline)
                                } else {
                                    Text("No tasks were due this week")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("In progress")
                                .font(.title2.weight(.semibold))
                            Text("Day rings fill as you go. A letter grade appears after this week ends (Sunday locks).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(isCompletedWeek ? "Report card" : "This week")
                }
            }
            .navigationTitle("Week")
        }
    }

    private var weekNavigator: some View {
        HStack {
            Button {
                weekOffset -= 1
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Previous week")

            Spacer()

            VStack(spacing: 2) {
                Text(weekTitle)
                    .font(.headline)
                Text(weekDateRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                weekOffset = min(weekOffset + 1, 0)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(weekOffset >= 0)
            .accessibilityLabel("Next week")
        }
        .buttonStyle(.borderless)
    }

    private var weekRings: some View {
        HStack(spacing: 8) {
            ForEach(Array(dayProgresses.enumerated()), id: \.offset) { index, progress in
                DayRingView(
                    label: weekdayLabels[index],
                    progress: progress,
                    state: ringState(for: progress.date, progress: progress),
                    size: 40,
                    lineWidth: 4
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }

    private var weekTitle: String {
        if isCurrentWeek { return "Current week" }
        if weekOffset == -1 { return "Last week" }
        return "\(abs(weekOffset)) weeks ago"
    }

    private var weekDateRange: String {
        let start = displayedWeekStart.formatted(.dateTime.month(.abbreviated).day())
        let end = displayedWeekEnd.formatted(.dateTime.month(.abbreviated).day())
        return "\(start) – \(end)"
    }

    private func ringState(for day: Date, progress: DayProgress) -> DayRingState {
        let dayStart = calendar.startOfDay(for: day)
        if dayStart > today { return .future }
        if !progress.hasTasks { return .noTasks }
        if dayStart == today { return .active }
        return .locked
    }
}

#Preview {
    ProgressScreen()
        .modelContainer(for: [NudgeCategory.self, NudgeTask.self, TaskInstance.self], inMemory: true)
}

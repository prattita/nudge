//
//  ProgressScreen.swift
//  Nudge
//
//  Week tab — Fitness-style day rings; letter only for completed weeks.
//

import SwiftUI
import SwiftData

struct ProgressScreen: View {
    @Query(filter: #Predicate<NudgeTask> { !$0.isArchived }, sort: \NudgeTask.title)
    private var tasks: [NudgeTask]

    @State private var weekOffset: Int = 0

    private let calendar = Calendar.nudge
    private let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]

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
            ScrollView {
                VStack(spacing: 28) {
                    weekNavigator
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    weekRings
                        .padding(.horizontal, 16)

                    reportCard
                        .padding(.horizontal, 20)

                    Spacer(minLength: 24)
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Week")
        }
    }

    private var weekNavigator: some View {
        HStack {
            Button {
                weekOffset -= 1
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("Previous week")

            Spacer()

            VStack(spacing: 4) {
                Text(weekTitle)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                Text(weekDateRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                weekOffset = min(weekOffset + 1, 0)
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(weekOffset >= 0)
            .opacity(weekOffset >= 0 ? 0.35 : 1)
            .accessibilityLabel("Next week")
        }
        .buttonStyle(.plain)
    }

    private var weekRings: some View {
        HStack(spacing: 6) {
            ForEach(Array(dayProgresses.enumerated()), id: \.offset) { index, progress in
                DayRingView(
                    label: weekdayLabels[index],
                    progress: progress,
                    state: ringState(for: progress.date, progress: progress),
                    size: 44,
                    lineWidth: 5
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var reportCard: some View {
        Group {
            if let weekGrade, isCompletedWeek {
                VStack(alignment: .leading, spacing: 12) {
                    Text("REPORT CARD")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.8)

                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        Text(weekGrade.letter)
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Week grade")
                                .font(.subheadline.weight(.medium))
                            if weekGrade.hasWork {
                                Text("\(Int(weekGrade.percentage.rounded()))% · \(weekGrade.fractionLabel)")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No tasks were due")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("IN PROGRESS")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.8)
                    Text("Build your week")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                    Text("Rings fill as days lock. A letter grade shows up after Sunday.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
    }

    private var weekTitle: String {
        if isCurrentWeek { return "This Week" }
        if weekOffset == -1 { return "Last Week" }
        return "\(abs(weekOffset)) Weeks Ago"
    }

    private var weekDateRange: String {
        let start = displayedWeekStart.formatted(.dateTime.month(.abbreviated).day())
        let end = displayedWeekEnd.formatted(.dateTime.month(.abbreviated).day())
        return "\(start)–\(end)"
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

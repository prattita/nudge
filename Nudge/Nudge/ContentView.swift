//
//  ContentView.swift
//  Nudge
//
//  Root UI + miss backfill on appear.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NudgeTask.title) private var allTasks: [NudgeTask]

    /// Start-of-day time interval; `0` means uninitialized (first launch).
    @AppStorage("lastBackfillDay") private var lastBackfillDay: Double = 0

    @State private var backfillMessage: String?
    @State private var showBackfillAlert = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }

            ProgressScreen()
                .tabItem {
                    Label("Week", systemImage: "calendar")
                }
        }
        .task {
            runBackfillIfNeeded()
        }
        .alert("Misses recorded", isPresented: $showBackfillAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(backfillMessage ?? "")
        }
    }

    private func runBackfillIfNeeded() {
        let calendar = Calendar.nudge
        let previous: Date? = lastBackfillDay == 0
            ? nil
            : Date(timeIntervalSince1970: lastBackfillDay)

        let (newLast, result) = MissBackfill.run(
            context: modelContext,
            tasks: allTasks,
            lastBackfillDate: previous,
            calendar: calendar
        )

        lastBackfillDay = calendar.startOfDay(for: newLast).timeIntervalSince1970

        if !result.isEmpty {
            backfillMessage = result.summaryLines.joined(separator: "\n")
            showBackfillAlert = true
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [NudgeCategory.self, NudgeTask.self, TaskInstance.self], inMemory: true)
}

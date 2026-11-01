//
//  ContentView.swift
//  Nudge
//
//  Root UI: Today (day ring) · Goals (later) · Week (rings + past grades).
//

import SwiftUI

struct ContentView: View {
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
    }
}

#Preview {
    ContentView()
}

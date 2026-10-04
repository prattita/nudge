//
//  ContentView.swift
//  Nudge
//
//  Root UI: bottom tab bar with Today, Goals, and Progress.
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
                    Label("Progress", systemImage: "chart.bar.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}

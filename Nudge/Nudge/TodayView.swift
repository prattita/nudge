//
//  TodayView.swift
//  Nudge
//
//  Primary tab: tasks due today (placeholder for Step 1).
//

import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            Text("Today View")
                .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
}

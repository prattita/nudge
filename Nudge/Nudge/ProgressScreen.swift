//
//  ProgressScreen.swift
//  Nudge
//
//  Progress tab: weekly report card (placeholder for Step 1).
//
//  Note: SwiftUI also has a built-in type named ProgressView (a loading spinner /
//  progress bar). Our screen is named ProgressScreen for now to avoid a name clash
//  while we keep the tab label "Progress".
//

import SwiftUI

struct ProgressScreen: View {
    var body: some View {
        NavigationStack {
            Text("Progress View")
                .navigationTitle("Progress")
        }
    }
}

#Preview {
    ProgressScreen()
}

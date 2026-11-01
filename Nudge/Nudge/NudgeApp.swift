//
//  NudgeApp.swift
//  Nudge
//
//  App entry point: opens the SwiftData store and shows the root UI.
//

import SwiftUI
import SwiftData

@main
struct NudgeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            NudgeCategory.self,
            NudgeTask.self,
            TaskInstance.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            // Seed presets once the store exists (first launch only).
            let context = ModelContext(container)
            DataSeeder.seedPresetsIfNeeded(context: context)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

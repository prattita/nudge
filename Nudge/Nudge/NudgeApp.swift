//
//  NudgeApp.swift
//  Nudge
//
//  App entry point: SwiftData store with CloudKit when available.
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

        // Private iCloud DB for this Apple ID (container: iCloud.com.prattita.Nudge).
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.prattita.Nudge")
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [cloudConfig])
            let context = ModelContext(container)
            DataSeeder.seedPresetsIfNeeded(context: context)
            return container
        } catch {
            // Fallback: local-only if CloudKit isn't signed in / container not ready yet.
            // Common on first Simulator boot before iCloud + Team are configured in Xcode.
            assertionFailure("CloudKit ModelContainer failed (\(error)). Falling back to local store.")
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            do {
                let container = try ModelContainer(for: schema, configurations: [localConfig])
                let context = ModelContext(container)
                DataSeeder.seedPresetsIfNeeded(context: context)
                return container
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

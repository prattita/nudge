//
//  DataSeeder.swift
//  Nudge
//
//  First-launch seed for preset categories.
//

import Foundation
import SwiftData

enum DataSeeder {
    /// Inserts Health / Fitness / Pet Care / Mind if the category store is empty.
    static func seedPresetsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<NudgeCategory>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let presets: [(name: String, colorHex: String)] = [
            ("Health", "6BAF7A"),
            ("Fitness", "E8614A"),
            ("Pet Care", "F5A623"),
            ("Mind", "4A9EE8"),
        ]

        for preset in presets {
            context.insert(
                NudgeCategory(
                    name: preset.name,
                    colorHex: preset.colorHex,
                    isPreset: true
                )
            )
        }

        try? context.save()
    }
}

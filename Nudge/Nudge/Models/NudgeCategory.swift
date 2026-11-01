//
//  NudgeCategory.swift
//  Nudge
//
//  Groups related tasks (presets + user-created).
//

import Foundation
import SwiftData

@Model
final class NudgeCategory {
    var id: UUID = UUID()
    var name: String = ""
    /// Hex without '#', e.g. "6BAF7A"
    var colorHex: String = "6BAF7A"
    var isPreset: Bool = false
    var isHidden: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \NudgeTask.category)
    var tasks: [NudgeTask]? = []

    init(
        name: String,
        colorHex: String,
        isPreset: Bool = false,
        isHidden: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.isPreset = isPreset
        self.isHidden = isHidden
    }
}

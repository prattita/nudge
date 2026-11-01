//
//  TaskEnums.swift
//  Nudge
//
//  Typed enums for app logic. Persisted on models as String raw values
//  (CloudKit / SwiftData sync–friendly).
//

import Foundation

/// How often a task is scheduled to appear.
enum TaskFrequency: String, CaseIterable, Identifiable {
    case daily
    case nTimesPerWeek
    case monthly
    case yearly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .nTimesPerWeek: return "N times / week"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

/// Lifecycle state of one scheduled occurrence.
enum InstanceStatus: String, CaseIterable {
    case pending
    case completed
    case missed
}

/// How the instance was completed (or recorded).
enum InstanceSource: String, CaseIterable {
    case manual
    case healthKit
    case makeup
    case rollover
}

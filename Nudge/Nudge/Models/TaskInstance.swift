//
//  TaskInstance.swift
//  Nudge
//
//  One scheduled occurrence of a task (due date + outcome).
//

import Foundation
import SwiftData

@Model
final class TaskInstance {
    var id: UUID = UUID()
    /// Start-of-day for the originally scheduled due date.
    var dueDate: Date = Date()
    /// Persisted `InstanceStatus.rawValue`
    var status: String = InstanceStatus.pending.rawValue
    /// When the user actually completed it; nil if missed or pending.
    var completedAt: Date?
    /// Persisted `InstanceSource.rawValue`
    var source: String = InstanceSource.manual.rawValue

    var task: NudgeTask?

    init(
        dueDate: Date,
        status: InstanceStatus = .pending,
        completedAt: Date? = nil,
        source: InstanceSource = .manual,
        task: NudgeTask? = nil
    ) {
        self.id = UUID()
        self.dueDate = dueDate
        self.status = status.rawValue
        self.completedAt = completedAt
        self.source = source.rawValue
        self.task = task
    }

    var statusKind: InstanceStatus {
        get { InstanceStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }

    var sourceKind: InstanceSource {
        get { InstanceSource(rawValue: source) ?? .manual }
        set { source = newValue.rawValue }
    }
}

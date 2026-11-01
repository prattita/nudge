//
//  DayRingView.swift
//  Nudge
//
//  Activity-style circular day progress (0–100% fill).
//

import SwiftUI

enum DayRingState {
    /// Day is still in the future.
    case future
    /// No tasks scheduled that day.
    case noTasks
    /// Today — still editable.
    case active
    /// Past day — treated as locked (finalized by backfill later).
    case locked
}

struct DayRingView: View {
    let label: String
    let progress: DayProgress
    let state: DayRingState
    var size: CGFloat = 56
    var lineWidth: CGFloat = 6

    private var ringColor: Color {
        switch state {
        case .future: return .secondary.opacity(0.25)
        case .noTasks: return .secondary.opacity(0.2)
        case .active: return .accentColor
        case .locked: return progress.fill >= 1 ? .green : .accentColor.opacity(0.85)
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: lineWidth)

                switch state {
                case .future:
                    EmptyView()
                case .noTasks:
                    Circle()
                        .stroke(Color.secondary.opacity(0.25), style: StrokeStyle(lineWidth: lineWidth, dash: [3, 3]))
                case .active, .locked:
                    Circle()
                        .trim(from: 0, to: progress.fill)
                        .stroke(
                            ringColor,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.25), value: progress.fill)
                }

                if state == .noTasks {
                    Text("–")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                } else if state != .future, progress.hasTasks {
                    Text("\(Int((progress.fill * 100).rounded()))")
                        .font(.system(size: size * 0.22, weight: .semibold, design: .rounded))
                        .foregroundStyle(state == .future ? .secondary : .primary)
                }
            }
            .frame(width: size, height: size)

            Text(label)
                .font(.caption2.weight(state == .active ? .bold : .regular))
                .foregroundStyle(state == .active ? .primary : .secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        switch state {
        case .future:
            return "\(label), upcoming"
        case .noTasks:
            return "\(label), no tasks"
        case .active, .locked:
            return "\(label), \(progress.fractionLabel) complete"
        }
    }
}

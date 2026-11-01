//
//  DayRingView.swift
//  Nudge
//
//  Fitness/Activity-style circular day progress (0–100% fill).
//

import SwiftUI

enum DayRingState {
    case future
    case noTasks
    case active
    case locked
}

struct DayRingView: View {
    let label: String
    let progress: DayProgress
    let state: DayRingState
    var size: CGFloat = 56
    var lineWidth: CGFloat = 6
    var showsLabel: Bool = true
    var showsCenterPercent: Bool = true

    /// Exercise-ring green (Fitness-adjacent).
    private let activityGreen = Color(red: 0.20, green: 0.78, blue: 0.35)

    private var ringColor: Color {
        switch state {
        case .future: return Color.secondary.opacity(0.2)
        case .noTasks: return Color.secondary.opacity(0.25)
        case .active: return activityGreen
        case .locked: return progress.fill >= 1 ? activityGreen : activityGreen.opacity(0.75)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)

                switch state {
                case .future:
                    EmptyView()
                case .noTasks:
                    Circle()
                        .stroke(
                            Color.secondary.opacity(0.3),
                            style: StrokeStyle(lineWidth: lineWidth, dash: [4, 4])
                        )
                case .active, .locked:
                    Circle()
                        .trim(from: 0, to: progress.fill)
                        .stroke(
                            ringColor,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress.fill)
                }

                if showsCenterPercent {
                    centerLabel
                }
            }
            .frame(width: size, height: size)

            if showsLabel {
                Text(label)
                    .font(.system(size: 12, weight: state == .active ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(state == .active ? .primary : .secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var centerLabel: some View {
        switch state {
        case .noTasks:
            Text("–")
                .font(.system(size: size * 0.22, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        case .future:
            EmptyView()
        case .active, .locked:
            if progress.hasTasks {
                Text("\(Int((progress.fill * 100).rounded()))")
                    .font(.system(size: size * 0.22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var accessibilityText: String {
        switch state {
        case .future: return "\(label), upcoming"
        case .noTasks: return "\(label), no tasks"
        case .active, .locked: return "\(label), \(progress.fractionLabel) complete"
        }
    }
}

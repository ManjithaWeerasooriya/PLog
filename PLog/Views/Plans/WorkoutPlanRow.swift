//
//  WorkoutPlanRow.swift
//  PLog
//
//  One row in the Plans list: name, day count, and a status pill.
//

import SwiftUI
import SwiftData

struct WorkoutPlanRow: View {
    let plan: WorkoutPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(plan.name.isEmpty ? "Plan" : plan.name)
                    .font(.headline)
                Spacer()
                PlanStatusPill(status: plan.status)
            }

            HStack(spacing: 12) {
                Label("\(plan.days.count) days", systemImage: "calendar")
                if let dateLabel {
                    Label(dateLabel, systemImage: "clock")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !plan.days.isEmpty {
                Text(plan.orderedDays.map(\.name).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var dateLabel: String? {
        switch plan.status {
        case .notStarted:
            return nil
        case .active:
            return plan.startedAt.map { "Since \($0.shortDateLabel)" }
        case .ended:
            guard let start = plan.startedAt, let end = plan.endedAt else { return nil }
            return "\(start.shortDateLabel) – \(end.shortDateLabel)"
        }
    }
}

/// A tinted capsule showing a plan's lifecycle state. Colour on the dot and fill, text
/// label-coloured — same rule as `TrendBadge`/`CategoryChip`.
struct PlanStatusPill: View {
    let status: PlanStatus

    @ScaledMetric(relativeTo: .caption) private var dotSize = 6

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(status.color)
                .frame(width: dotSize, height: dotSize)
            Text(status.displayName)
                .foregroundStyle(.primary)
        }
        .lineLimit(1)
        .fixedSize()
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.15), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.displayName)
    }
}

#Preview {
    List {
        WorkoutPlanRow(plan: SampleData.plan)
    }
    .modelContainer(SampleData.container)
}

//
//  PlanExerciseRow.swift
//  PLog
//
//  One exercise slot in a day template. Collapsed it shows a "3 × 8" summary; tap it to
//  reveal steppers for target sets × reps. Styled and behaved the same as `SetRow` — a
//  plain row, expansion controlled by the parent so only one slot is open at a time.
//

import SwiftUI
import SwiftData

struct PlanExerciseRow: View {
    /// `@Bindable` gives the steppers two-way bindings straight into the model.
    @Bindable var planExercise: PlanExercise
    /// Controlled by the parent so only one slot is expanded at a time (accordion-style) —
    /// see `PlanDayDetailView`.
    @Binding var isExpanded: Bool

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                header
            }
            // Keeps the List row highlight, but text resolves against the label color rather
            // than the accent tint the default button style applies to its label.
            .tint(.primary)
            .accessibilityAddTraits(isExpanded ? [.isSelected] : [])
            .accessibilityHint("Double-tap to edit target sets and reps")

            if isExpanded {
                // Side by side while they fit; stacked at accessibility type sizes.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 24) { steppers }
                    VStack(spacing: 16) { steppers }
                }
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var steppers: some View {
        NumberStepper(title: "Sets", intValue: $planExercise.targetSets, range: 1...20)
        NumberStepper(title: "Reps", intValue: $planExercise.targetReps, range: 1...100)
    }

    private var header: some View {
        HStack {
            // Stacked at accessibility sizes so the name doesn't wrap word by word.
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    nameAndChip
                    targets
                }
                Spacer()
            } else {
                nameAndChip
                Spacer()
                targets
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .contentShape(Rectangle())
    }

    private var nameAndChip: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(planExercise.exercise?.name ?? "Exercise")
                .font(.headline)
                .foregroundStyle(.primary)
            if let category = planExercise.exercise?.category {
                CategoryChip(category: category)
            }
        }
    }

    private var targets: some View {
        Text("\(planExercise.targetSets) × \(planExercise.targetReps)")
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
            .contentTransition(.numericText())
    }
}

#Preview {
    struct Demo: View {
        @State private var isExpanded = true
        var body: some View {
            List {
                PlanExerciseRow(
                    planExercise: SampleData.pushDay.orderedExercises.first!,
                    isExpanded: $isExpanded
                )
            }
        }
    }
    return Demo()
        .modelContainer(SampleData.container)
}

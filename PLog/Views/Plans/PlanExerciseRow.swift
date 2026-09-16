//
//  PlanExerciseRow.swift
//  PLog
//
//  One exercise slot in a day template. Collapsed it shows a "3 × 8" summary; tap it to
//  reveal wheel pickers for target sets × reps. Styled and behaved the same as
//  `SetEditorRow`/`ExerciseEntryCard` — a plain row, expansion controlled by the parent so
//  only one slot is open at a time.
//

import SwiftUI
import SwiftData

struct PlanExerciseRow: View {
    /// `@Bindable` gives the wheels two-way bindings straight into the model.
    @Bindable var planExercise: PlanExercise
    /// Controlled by the parent so only one slot is expanded at a time (accordion-style) —
    /// see `PlanDayDetailView`.
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy) { isExpanded.toggle() }
                }

            if isExpanded {
                HStack(spacing: 20) {
                    NumberPickerWheel(
                        title: "Sets",
                        intValue: $planExercise.targetSets,
                        range: 1...20
                    )
                    NumberPickerWheel(
                        title: "Reps",
                        intValue: $planExercise.targetReps,
                        range: 1...100
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(planExercise.exercise?.name ?? "Exercise")
                    .font(.headline)
                if let category = planExercise.exercise?.category {
                    CategoryChip(category: category)
                }
            }
            Spacer()
            Text("\(planExercise.targetSets) × \(planExercise.targetReps)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
    }
}

#Preview {
    struct Demo: View {
        @State private var isExpanded = true
        var body: some View {
            Form {
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

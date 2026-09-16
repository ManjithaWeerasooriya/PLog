//
//  PlanExerciseRow.swift
//  PLog
//
//  One exercise slot in a day template: name, category, and steppers for target sets × reps.
//

import SwiftUI
import SwiftData

struct PlanExerciseRow: View {
    /// `@Bindable` gives the steppers two-way bindings straight into the model.
    @Bindable var planExercise: PlanExercise

    var body: some View {
        VStack(spacing: 12) {
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
            }

            HStack(spacing: 16) {
                ValueStepper(
                    title: "Sets",
                    intValue: $planExercise.targetSets,
                    range: 1...20,
                    buttonSize: 34,
                    valueMinWidth: 44
                )
                ValueStepper(
                    title: "Reps",
                    intValue: $planExercise.targetReps,
                    range: 1...100,
                    buttonSize: 34,
                    valueMinWidth: 44
                )
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    Form {
        PlanExerciseRow(planExercise: SampleData.pushDay.orderedExercises.first!)
    }
    .modelContainer(SampleData.container)
}

//
//  PlanExerciseRow.swift
//  PLog
//
//  One exercise slot in a day template: name, category, and wheel pickers for target
//  sets × reps.
//

import SwiftUI
import SwiftData

struct PlanExerciseRow: View {
    /// `@Bindable` gives the wheels two-way bindings straight into the model.
    @Bindable var planExercise: PlanExercise

    var body: some View {
        VStack(spacing: 8) {
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
        .padding(.vertical, 4)
    }
}

#Preview {
    Form {
        PlanExerciseRow(planExercise: SampleData.pushDay.orderedExercises.first!)
    }
    .modelContainer(SampleData.container)
}

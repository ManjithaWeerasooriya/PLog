//
//  PlanExercise.swift
//  PLog
//
//  An exercise slot inside a `PlanDay` template with its target set and rep counts.
//  When the day is logged, each slot becomes an `ExerciseEntry` with `targetSets` sets.
//

import Foundation
import SwiftData

@Model
final class PlanExercise {
    /// The master-list exercise. Optional so the slot survives if the exercise is deleted.
    var exercise: Exercise?

    /// The owning day template. Inverse of `PlanDay.exercises`.
    var planDay: PlanDay?

    /// Position within the day.
    var order: Int

    /// How many sets to pre-create when logging this day.
    var targetSets: Int

    /// Target reps per set, used to prefill each created set.
    var targetReps: Int

    init(
        exercise: Exercise? = nil,
        planDay: PlanDay? = nil,
        order: Int = 0,
        targetSets: Int = 3,
        targetReps: Int = 10
    ) {
        self.exercise = exercise
        self.planDay = planDay
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
    }
}

//
//  SetEntry.swift
//  PLog
//
//  A single set within an `ExerciseEntry`: the weight, reps, and completion state.
//

import Foundation
import SwiftData

@Model
final class SetEntry {
    /// 1-based position of this set within its exercise entry.
    var setNumber: Int

    /// Weight lifted, in the user's preferred unit (kg by default).
    var weight: Double

    /// Number of repetitions performed.
    var reps: Int

    /// Whether the set has been completed (for live in-session ticking).
    var completed: Bool

    /// Optional Rate of Perceived Exertion (typically 1...10).
    var rpe: Double?

    /// Optional per-set note (e.g. "last rep grinder").
    var notes: String?

    /// The entry this set belongs to. Inverse of `ExerciseEntry.sets`.
    var entry: ExerciseEntry?

    init(
        setNumber: Int,
        weight: Double = 0,
        reps: Int = 0,
        completed: Bool = false,
        rpe: Double? = nil,
        notes: String? = nil,
        entry: ExerciseEntry? = nil
    ) {
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.completed = completed
        self.rpe = rpe
        self.notes = notes
        self.entry = entry
    }
}

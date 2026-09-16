//
//  SetEntry.swift
//  PLog
//
//  A single set within an `ExerciseEntry`: the weight and reps. Its existence in the list
//  IS the "added" state — there's no separate completion toggle.
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
        rpe: Double? = nil,
        notes: String? = nil,
        entry: ExerciseEntry? = nil
    ) {
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.notes = notes
        self.entry = entry
    }
}

//
//  WorkoutDay.swift
//  PLog
//
//  A single training session on a given date (e.g. "Push Day"), containing the
//  exercises logged that day.
//

import Foundation
import SwiftData

@Model
final class WorkoutDay {
    /// The calendar date of the session.
    var date: Date

    /// A short label for the session, e.g. "Push Day", "Leg Day".
    var name: String

    /// Freeform notes for the whole session (how you felt, sleep, etc.).
    var notes: String

    /// The plan template this session was logged from, if any. Plain (non-cascading)
    /// reference; the inverse lives on `PlanDay.loggedDays`.
    var planDay: PlanDay?

    /// The exercises logged during this session.
    ///
    /// Cascade delete: removing a `WorkoutDay` removes its `ExerciseEntry` rows (and, in turn,
    /// their `SetEntry` rows). The inverse lives on `ExerciseEntry.workoutDay`.
    @Relationship(deleteRule: .cascade, inverse: \ExerciseEntry.workoutDay)
    var entries: [ExerciseEntry] = []

    init(
        date: Date = .now,
        name: String = "",
        notes: String = "",
        planDay: PlanDay? = nil
    ) {
        self.date = date
        self.name = name
        self.notes = notes
        self.planDay = planDay
    }

    /// Entries in a stable, user-defined order.
    var orderedEntries: [ExerciseEntry] {
        entries.sorted { $0.order < $1.order }
    }
}

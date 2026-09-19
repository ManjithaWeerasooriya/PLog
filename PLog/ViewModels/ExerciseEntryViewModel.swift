//
//  ExerciseEntryViewModel.swift
//  PLog
//
//  Drives one exercise's inline set list on the session screen: adding/duplicating sets,
//  removing them, and classifying each set against the previous session for progressive
//  overload. Edits to individual sets bind straight into the `SetEntry` models (autosave).
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ExerciseEntryViewModel {
    /// The entry being edited. Its `SetEntry` objects are edited in place by the steppers.
    let entry: ExerciseEntry

    /// The top set from the previous session — used for the "Last time" hint and trends.
    let previousTopSet: SetSnapshot?

    private let context: ModelContext

    init(entry: ExerciseEntry, context: ModelContext) {
        self.entry = entry
        self.context = context
        self.previousTopSet = entry.exercise.flatMap {
            WorkoutHistory.previousTopSet(for: $0, excluding: entry)
        }
    }

    /// Sets sorted for display.
    var sets: [SetEntry] { entry.orderedSets }

    var exerciseName: String { entry.exercise?.name ?? "Exercise" }

    /// The inline hint string, e.g. "Last time: 62.5kg × 8".
    var lastTimeLabel: String? {
        ProgressiveOverload.lastTimeLabel(for: previousTopSet)
    }

    // MARK: - Mutations

    /// Seeds a brand-new entry with one set prefilled from last time (or sensible defaults)
    /// so the user can immediately nudge the numbers up. Called once, when the exercise is
    /// added to the day — not on every view model creation, so an entry whose sets were all
    /// deleted stays empty rather than silently regrowing a set.
    static func prefill(_ entry: ExerciseEntry, in context: ModelContext) {
        guard entry.sets.isEmpty else { return }
        let previous = entry.exercise.flatMap { WorkoutHistory.previousTopSet(for: $0, excluding: entry) }
        let seed = previous ?? SetSnapshot(weight: 20, reps: 10)
        let first = SetEntry(setNumber: 1, weight: seed.weight, reps: seed.reps)
        context.insert(first)
        entry.sets.append(first)
    }

    /// Adds a set, duplicating the last set's numbers (the common "another set, same load"
    /// flow). Returns it so the caller can expand it.
    @discardableResult
    func addDuplicateSet() -> SetEntry {
        let template = sets.last
        let next = SetEntry(
            setNumber: (template?.setNumber ?? 0) + 1,
            weight: template?.weight ?? previousTopSet?.weight ?? 20,
            reps: template?.reps ?? previousTopSet?.reps ?? 10
        )
        context.insert(next)
        entry.sets.append(next)
        try? context.save()
        return next
    }

    /// Removes a set and renumbers the remainder so `setNumber` stays 1-based and contiguous.
    func removeSet(_ set: SetEntry) {
        entry.sets.removeAll { $0 === set }
        context.delete(set)
        for (index, remaining) in entry.orderedSets.enumerated() {
            remaining.setNumber = index + 1
        }
        try? context.save()
    }

    /// Progressive-overload classification for a given set versus last session's top set.
    func trend(for set: SetEntry) -> ProgressTrend {
        ProgressiveOverload.trend(
            current: SetSnapshot(weight: set.weight, reps: set.reps),
            previous: previousTopSet
        )
    }
}

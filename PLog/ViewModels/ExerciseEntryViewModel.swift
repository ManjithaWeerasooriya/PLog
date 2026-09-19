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

    /// The top set from the previous session — the "Last time" hint, and the fallback
    /// comparison for a set the previous session didn't have.
    let previousTopSet: SetSnapshot?

    /// The previous session's sets in order, so set *n* is graded against set *n*.
    let previousSets: [SetSnapshot]

    private let context: ModelContext

    init(entry: ExerciseEntry, context: ModelContext) {
        self.entry = entry
        self.context = context
        self.previousTopSet = entry.exercise.flatMap {
            WorkoutHistory.previousTopSet(for: $0, excluding: entry)
        }
        self.previousSets = entry.exercise.map {
            WorkoutHistory.previousSets(for: $0, excluding: entry)
        } ?? []
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

    /// Adds the next set. It's seeded from the same-numbered set last session when there was
    /// one (so a planned back-off set comes in at its usual load), otherwise it duplicates
    /// the last set (the "another set, same load" flow). Returns it so the caller can expand it.
    @discardableResult
    func addSet() -> SetEntry {
        let number = (sets.last?.setNumber ?? 0) + 1
        let seed = previousSet(number: number)
            ?? sets.last.map { SetSnapshot(weight: $0.weight, reps: $0.reps) }
            ?? previousTopSet
            ?? SetSnapshot(weight: 20, reps: 10)
        let next = SetEntry(setNumber: number, weight: seed.weight, reps: seed.reps)
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

    /// Progressive-overload classification for a set versus the **same-numbered** set last
    /// session — so a deliberate back-off third set isn't graded against your heaviest set
    /// and painted red. A set the previous session didn't have falls back to the top set.
    func trend(for set: SetEntry) -> ProgressTrend {
        ProgressiveOverload.trend(
            current: SetSnapshot(weight: set.weight, reps: set.reps),
            previous: previousSet(number: set.setNumber) ?? previousTopSet
        )
    }

    private func previousSet(number: Int) -> SetSnapshot? {
        let index = number - 1
        return previousSets.indices.contains(index) ? previousSets[index] : nil
    }
}

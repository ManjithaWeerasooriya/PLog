//
//  ExerciseEntryViewModel.swift
//  PLog
//
//  Drives the quick-entry screen: prefilling from the last session, adding/duplicating
//  sets, and classifying each set against the previous session for progressive overload.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ExerciseEntryViewModel {
    /// The entry being edited. Its `SetEntry` objects are edited in place and bound to steppers.
    let entry: ExerciseEntry

    /// The top set from the previous session — used for prefill and the "Last time" hint.
    let previousTopSet: SetSnapshot?

    private let context: ModelContext

    init(entry: ExerciseEntry, context: ModelContext) {
        self.entry = entry
        self.context = context
        self.previousTopSet = entry.exercise.flatMap {
            WorkoutHistory.previousTopSet(for: $0, excluding: entry)
        }
        prefillIfNeeded()
    }

    /// Sets sorted for display.
    var sets: [SetEntry] { entry.orderedSets }

    var exerciseName: String { entry.exercise?.name ?? "Exercise" }

    /// The inline hint string, e.g. "Last time: 62.5kg × 8".
    var lastTimeLabel: String? {
        ProgressiveOverload.lastTimeLabel(for: previousTopSet)
    }

    // MARK: - Mutations

    /// If the entry is brand new, seed it with one set prefilled from last time (or sensible
    /// defaults) so the user can immediately tweak the numbers up.
    private func prefillIfNeeded() {
        guard entry.sets.isEmpty else { return }
        let seed = previousTopSet ?? SetSnapshot(weight: 20, reps: 10)
        let first = SetEntry(setNumber: 1, weight: seed.weight, reps: seed.reps, entry: entry)
        context.insert(first)
    }

    /// Adds a set, duplicating the last set's numbers (the common "another set, same load" flow).
    func addDuplicateSet() {
        let template = sets.last
        let next = SetEntry(
            setNumber: (sets.last?.setNumber ?? 0) + 1,
            weight: template?.weight ?? previousTopSet?.weight ?? 20,
            reps: template?.reps ?? previousTopSet?.reps ?? 10,
            entry: entry
        )
        context.insert(next)
    }

    /// Removes a set and renumbers the remainder so `setNumber` stays 1-based and contiguous.
    func removeSet(_ set: SetEntry) {
        context.delete(set)
        for (index, remaining) in entry.orderedSets.filter({ $0 !== set }).enumerated() {
            remaining.setNumber = index + 1
        }
    }

    /// Progressive-overload classification for a given set versus last session's top set.
    func trend(for set: SetEntry) -> ProgressTrend {
        ProgressiveOverload.trend(
            current: SetSnapshot(weight: set.weight, reps: set.reps),
            previous: previousTopSet
        )
    }

    /// Persist changes. SwiftData autosaves, but saving explicitly keeps previews/tests deterministic.
    func save() {
        try? context.save()
    }

    /// Discards the whole entry (used when the user cancels a freshly created entry).
    func discard() {
        context.delete(entry)
        try? context.save()
    }
}

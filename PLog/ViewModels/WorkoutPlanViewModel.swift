//
//  WorkoutPlanViewModel.swift
//  PLog
//
//  Owns the mutations for one plan: start/end lifecycle, day-template management, and
//  stamping a `WorkoutDay` out of a template so the user doesn't add exercises one by one.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class WorkoutPlanViewModel {
    let plan: WorkoutPlan

    private let context: ModelContext

    init(plan: WorkoutPlan, context: ModelContext) {
        self.plan = plan
        self.context = context
    }

    var days: [PlanDay] { plan.orderedDays }

    /// The template to suggest next: the one after the most recently logged day in the
    /// rotation (wrapping), or the first day if nothing has been logged yet.
    var suggestedNextDay: PlanDay? {
        let ordered = days
        guard !ordered.isEmpty else { return nil }
        let lastLogged = ordered
            .flatMap(\.loggedDays)
            .max { $0.date < $1.date }
        guard
            let lastDay = lastLogged?.planDay,
            let index = ordered.firstIndex(where: { $0 === lastDay })
        else { return ordered.first }
        return ordered[(index + 1) % ordered.count]
    }

    // MARK: - Lifecycle

    /// Starts (or restarts) the plan. Only one plan runs at a time, so any other active plan
    /// is ended first.
    func start() {
        let allPlans = (try? context.fetch(FetchDescriptor<WorkoutPlan>())) ?? []
        for other in allPlans where other !== plan && other.isActive {
            other.endedAt = .now
        }
        plan.startedAt = .now
        plan.endedAt = nil
        save()
    }

    func end() {
        plan.endedAt = .now
        save()
    }

    // MARK: - Day templates

    // Relationship mutations go through the to-many side (`plan.days.append`) rather than
    // setting the inverse (`day.plan = plan`): only the former fires Observation on the plan,
    // so views reading `plan.days` refresh.

    @discardableResult
    func addDay(named name: String) -> PlanDay {
        let day = PlanDay(name: name, order: plan.days.count)
        context.insert(day)
        plan.days.append(day)
        save()
        return day
    }

    func removeDays(at offsets: IndexSet) {
        let ordered = days
        for index in offsets {
            let day = ordered[index]
            plan.days.removeAll { $0 === day }
            context.delete(day)
        }
        renumber(ordered.enumerated().filter { !offsets.contains($0.offset) }.map(\.element))
        save()
    }

    /// Persists a new rotation order. The view does the `move(fromOffsets:)` (a SwiftUI API).
    func reorderDays(_ ordered: [PlanDay]) {
        renumber(ordered)
        save()
    }

    private func renumber(_ ordered: [PlanDay]) {
        for (index, day) in ordered.enumerated() {
            day.order = index
        }
    }

    // MARK: - Logging

    /// Creates a `WorkoutDay` from a template: one entry per exercise slot, each with
    /// `targetSets` sets at `targetReps`, and the weight prefilled from the last session.
    @discardableResult
    func logWorkout(for planDay: PlanDay, on date: Date = .now) -> WorkoutDay {
        let day = WorkoutDay(date: date, name: planDay.name)
        context.insert(day)
        planDay.loggedDays.append(day)

        for (order, slot) in planDay.orderedExercises.enumerated() {
            guard let exercise = slot.exercise else { continue }
            let entry = ExerciseEntry(exercise: exercise, order: order)
            context.insert(entry)
            day.entries.append(entry)

            let lastWeight = WorkoutHistory.previousTopSet(for: exercise, excluding: entry)?.weight ?? 0
            for setNumber in stride(from: 1, through: slot.targetSets, by: 1) {
                let set = SetEntry(
                    setNumber: setNumber,
                    weight: lastWeight,
                    reps: slot.targetReps
                )
                context.insert(set)
                entry.sets.append(set)
            }
        }

        save()
        return day
    }

    func save() {
        try? context.save()
    }
}

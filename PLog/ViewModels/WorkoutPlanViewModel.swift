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

    /// The template to suggest next in the rotation.
    var suggestedNextDay: PlanDay? {
        WorkoutLogger.suggestedNextDay(in: plan)
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

    /// Stamps a template into a new session. See `WorkoutLogger.logWorkout`.
    @discardableResult
    func logWorkout(for planDay: PlanDay, on date: Date = .now) -> WorkoutDay {
        WorkoutLogger.logWorkout(for: planDay, on: date, in: context)
    }

    func save() {
        try? context.save()
    }
}

//
//  PlanTimeline.swift
//  PLog
//
//  Builds the day-by-day log for a plan: every calendar date from the plan's start to its
//  end (or today), with logged sessions filled in and the gaps marked as rest days.
//

import Foundation

/// One row in the plan log — either a logged session or a rest day.
struct PlanLogItem: Identifiable {
    let id: String
    /// Start of the calendar day this row represents.
    let date: Date
    /// `nil` means no session was logged on this date (a rest day).
    let workout: WorkoutDay?

    var isRestDay: Bool { workout == nil }
}

enum PlanTimeline {
    /// Rows from newest to oldest. Dates with more than one session get one row per session.
    /// Returns an empty list for a plan that hasn't been started.
    static func items(
        for plan: WorkoutPlan,
        workouts: [WorkoutDay],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> [PlanLogItem] {
        guard let startedAt = plan.startedAt else { return [] }

        let start = calendar.startOfDay(for: startedAt)
        let end = calendar.startOfDay(for: plan.endedAt ?? today)
        guard start <= end else { return [] }

        let endExclusive = calendar.date(byAdding: .day, value: 1, to: end) ?? end
        let inRange = workouts.filter { $0.date >= start && $0.date < endExclusive }
        let byDay = Dictionary(grouping: inRange) { calendar.startOfDay(for: $0.date) }

        var items: [PlanLogItem] = []
        var cursor = end
        while cursor >= start {
            let key = Int(cursor.timeIntervalSinceReferenceDate)
            let sessions = (byDay[cursor] ?? []).sorted { $0.date > $1.date }
            if sessions.isEmpty {
                items.append(PlanLogItem(id: "\(key)-rest", date: cursor, workout: nil))
            } else {
                for (index, session) in sessions.enumerated() {
                    items.append(PlanLogItem(id: "\(key)-\(index)", date: cursor, workout: session))
                }
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return items
    }
}

//
//  PlanStatus.swift
//  PLog
//
//  Lifecycle state of a `WorkoutPlan`, derived from its start/end dates.
//

import SwiftUI

/// `nonisolated` so the synthesized `Equatable` can be used from any context (the project
/// defaults to main-actor isolation).
nonisolated enum PlanStatus: Equatable {
    case notStarted
    case active
    case ended

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .active: return "Active"
        case .ended: return "Ended"
        }
    }

    var color: Color {
        switch self {
        case .notStarted: return .secondary
        case .active: return .green
        case .ended: return .orange
        }
    }
}

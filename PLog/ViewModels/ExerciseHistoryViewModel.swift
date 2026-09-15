//
//  ExerciseHistoryViewModel.swift
//  PLog
//
//  Prepares an exercise's logged history for the Swift Charts trend screen.
//

import Foundation

@MainActor
@Observable
final class ExerciseHistoryViewModel {
    let exercise: Exercise

    /// The metric currently plotted.
    enum Metric: String, CaseIterable, Identifiable {
        case weight = "Top Weight"
        case reps = "Top Set Reps"
        case volume = "Total Volume"
        case oneRepMax = "Est. 1RM"

        var id: String { rawValue }
        var unit: String {
            switch self {
            case .weight, .volume, .oneRepMax: return "kg"
            case .reps: return "reps"
            }
        }
    }

    var selectedMetric: Metric = .weight

    init(exercise: Exercise) {
        self.exercise = exercise
    }

    /// All logged sessions for this exercise, oldest → newest.
    var points: [ExerciseHistoryPoint] {
        WorkoutHistory.historyPoints(for: exercise)
    }

    var hasEnoughDataForChart: Bool { points.count >= 1 }

    /// The value for the currently selected metric at a given point.
    func value(for point: ExerciseHistoryPoint) -> Double {
        switch selectedMetric {
        case .weight: return point.topWeight
        case .reps: return Double(point.topSetReps)
        case .volume: return point.totalVolume
        case .oneRepMax: return point.estimatedOneRepMax
        }
    }

    /// Overall trend across the whole history (first vs last logged value).
    var overallTrend: ProgressTrend {
        guard let first = points.first, let last = points.last, points.count >= 2 else {
            return .none
        }
        let start = value(for: first)
        let end = value(for: last)
        if end > start { return .improved }
        if end < start { return .regressed }
        return .matched
    }
}

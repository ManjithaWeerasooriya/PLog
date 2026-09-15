//
//  MuscleGroup.swift
//  PLog
//
//  The muscle-group category used to organize the master exercise list.
//

import SwiftUI

/// A muscle-group category for an `Exercise`.
///
/// Stored on `Exercise` as a `Codable` enum. SwiftData persists `RawRepresentable`/`Codable`
/// enums directly, so we can use a strongly-typed property instead of a raw `String`.
enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest
    case back
    case legs
    case shoulders
    case arms
    case core
    case cardio
    case fullBody
    case other

    var id: String { rawValue }

    /// Human-facing label shown in the UI.
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .legs: return "Legs"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .core: return "Core"
        case .cardio: return "Cardio"
        case .fullBody: return "Full Body"
        case .other: return "Other"
        }
    }

    /// SF Symbol used as a lightweight visual tag for the category.
    var systemImage: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .legs: return "figure.strengthtraining.functional"
        case .shoulders: return "figure.arms.open"
        case .arms: return "dumbbell"
        case .core: return "figure.core.training"
        case .cardio: return "figure.run"
        case .fullBody: return "figure.mixed.cardio"
        case .other: return "questionmark.circle"
        }
    }

    /// Accent color used to tint category chips and chart legends.
    var color: Color {
        switch self {
        case .chest: return .red
        case .back: return .blue
        case .legs: return .green
        case .shoulders: return .orange
        case .arms: return .purple
        case .core: return .yellow
        case .cardio: return .pink
        case .fullBody: return .teal
        case .other: return .gray
        }
    }
}

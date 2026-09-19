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
    /// Raw value kept as "arms" (the case's old name) so any exercise already persisted
    /// with that category still decodes correctly — only the label changed.
    case biceps = "arms"
    case traps
    case triceps
    case forearms
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
        case .biceps: return "Biceps"
        case .traps: return "Traps"
        case .triceps: return "Triceps"
        case .forearms: return "Forearms"
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
        case .biceps: return "dumbbell"
        case .traps: return "figure.boxing"
        case .triceps: return "dumbbell.fill"
        case .forearms: return "hand.raised.fill"
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
        case .biceps: return .purple
        case .traps: return .indigo
        case .triceps: return .mint
        case .forearms: return .cyan
        case .core: return .brown  // not yellow: unusable even as a fill/icon on a light card
        case .cardio: return .pink
        case .fullBody: return .teal
        case .other: return .gray
        }
    }
}

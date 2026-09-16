//
//  AppTheme.swift
//  PLog
//
//  The app-wide light/dark mode preference, set in Settings. Persisted via `@AppStorage`
//  rather than `UserProfile`/SwiftData — this is a UI preference, not user data, and needs
//  to be readable the instant the app launches, before any SwiftData query resolves.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "Use Device Theme"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// `nil` tells SwiftUI to follow the system appearance instead of forcing one.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

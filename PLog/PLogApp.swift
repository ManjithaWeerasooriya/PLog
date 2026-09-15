//
//  PLogApp.swift
//  PLog
//
//  Created by Manjitha Weerasooriya on 2026-09-16.
//

import SwiftUI
import SwiftData

@main
struct PLogApp: App {
    /// The app-wide SwiftData container. Listing every model is explicit and future-proof;
    /// SwiftData wires up the relationships from here.
    let container: ModelContainer = {
        let schema = Schema([
            WorkoutDay.self,
            Exercise.self,
            ExerciseEntry.self,
            SetEntry.self,
        ])
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

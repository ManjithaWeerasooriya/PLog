//
//  SampleData.swift
//  PLog
//
//  An in-memory SwiftData container seeded with realistic data, used by SwiftUI previews
//  so every screen has something to render without touching the on-disk store.
//

import Foundation
import SwiftData

@MainActor
enum SampleData {
    /// A shared, in-memory container seeded once for previews.
    static let container: ModelContainer = {
        let schema = Schema([
            WorkoutDay.self,
            Exercise.self,
            ExerciseEntry.self,
            SetEntry.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            seed(into: container.mainContext)
            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }()

    /// Convenience accessor for the seeded context.
    static var context: ModelContext { container.mainContext }

    /// A sample exercise that has multiple sessions of history (good for charts).
    static var benchPress: Exercise {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.name == "Bench Press" }
        )
        return (try? context.fetch(descriptor))?.first ?? Exercise(name: "Bench Press", category: .chest)
    }

    /// The most recent seeded workout day.
    static var recentDay: WorkoutDay {
        let descriptor = FetchDescriptor<WorkoutDay>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.first ?? WorkoutDay(name: "Push Day")
    }

    // MARK: - Seeding

    private static func seed(into context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()

        // Master exercise list.
        let bench = Exercise(name: "Bench Press", category: .chest)
        let squat = Exercise(name: "Back Squat", category: .legs)
        let row = Exercise(name: "Barbell Row", category: .back)
        let ohp = Exercise(name: "Overhead Press", category: .shoulders)
        let curl = Exercise(name: "Bicep Curl", category: .arms)
        [bench, squat, row, ohp, curl].forEach(context.insert)

        // Three "push" sessions showing steady progression on the bench press.
        let pushProgressions: [(daysAgo: Int, weight: Double, reps: Int)] = [
            (daysAgo: 14, weight: 60, reps: 8),
            (daysAgo: 7, weight: 62.5, reps: 8),
            (daysAgo: 1, weight: 62.5, reps: 9),
        ]

        for progression in pushProgressions {
            let date = calendar.date(byAdding: .day, value: -progression.daysAgo, to: today) ?? today
            let day = WorkoutDay(date: date, name: "Push Day", notes: "")
            context.insert(day)

            let benchEntry = ExerciseEntry(exercise: bench, workoutDay: day, order: 0)
            context.insert(benchEntry)
            for setNumber in 1...3 {
                let set = SetEntry(
                    setNumber: setNumber,
                    weight: progression.weight,
                    reps: progression.reps,
                    completed: true,
                    entry: benchEntry
                )
                context.insert(set)
            }

            let ohpEntry = ExerciseEntry(exercise: ohp, workoutDay: day, order: 1)
            context.insert(ohpEntry)
            for setNumber in 1...3 {
                let set = SetEntry(
                    setNumber: setNumber,
                    weight: 40,
                    reps: 10,
                    completed: true,
                    entry: ohpEntry
                )
                context.insert(set)
            }
        }

        // A leg session for variety on the home screen.
        let legDate = calendar.date(byAdding: .day, value: -3, to: today) ?? today
        let legDay = WorkoutDay(date: legDate, name: "Leg Day", notes: "Felt strong")
        context.insert(legDay)
        let squatEntry = ExerciseEntry(exercise: squat, workoutDay: legDay, order: 0)
        context.insert(squatEntry)
        for setNumber in 1...4 {
            let set = SetEntry(
                setNumber: setNumber,
                weight: 100,
                reps: 5,
                completed: true,
                rpe: 8,
                entry: squatEntry
            )
            context.insert(set)
        }

        try? context.save()
        _ = row
        _ = curl
    }
}

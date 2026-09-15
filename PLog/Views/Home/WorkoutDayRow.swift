//
//  WorkoutDayRow.swift
//  PLog
//
//  A single row in the Home list summarizing one logged session.
//

import SwiftUI
import SwiftData

struct WorkoutDayRow: View {
    let day: WorkoutDay

    private var exerciseCount: Int { day.entries.count }
    private var setCount: Int { day.entries.reduce(0) { $0 + $1.sets.count } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(day.name.isEmpty ? "Workout" : day.name)
                    .font(.headline)
                Spacer()
                Text(day.date.mediumDayLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label("\(exerciseCount) exercises", systemImage: "list.bullet")
                Label("\(setCount) sets", systemImage: "number")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !day.entries.isEmpty {
                Text(exerciseSummary)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    /// A compact "Bench Press · Overhead Press" preview of the day's exercises.
    private var exerciseSummary: String {
        day.orderedEntries
            .compactMap { $0.exercise?.name }
            .joined(separator: " · ")
    }
}

#Preview {
    List {
        WorkoutDayRow(day: SampleData.recentDay)
    }
    .modelContainer(SampleData.container)
}

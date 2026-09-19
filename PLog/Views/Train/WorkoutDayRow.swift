//
//  WorkoutDayRow.swift
//  PLog
//
//  A single row summarizing one logged session: name and date, then what was done. Two
//  lines — a row exists to be recognized and tapped, and the exercise list is what makes a
//  session recognizable. (For a session stamped from a plan the name already *is* the plan
//  day's name, so there's no separate plan label.)
//

import SwiftUI
import SwiftData

struct WorkoutDayRow: View {
    let day: WorkoutDay

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Name and date share a line until accessibility sizes, where they'd wrap into
            // a column of single words; then the date drops under the name.
            if typeSize.isAccessibilitySize {
                title
                date
            } else {
                HStack(alignment: .firstTextBaseline) {
                    title
                    Spacer()
                    date
                }
            }
            Text(summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var title: some View {
        Text(day.name.isEmpty ? "Workout" : day.name)
            .font(.headline)
    }

    private var date: some View {
        Text(day.date.mediumDayLabel)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    /// e.g. "Bench Press · Overhead Press · Lateral Raise".
    private var summary: String {
        let names = day.orderedEntries.compactMap { $0.exercise?.name }
        return names.isEmpty ? "No exercises" : names.joined(separator: " · ")
    }
}

#Preview {
    List {
        WorkoutDayRow(day: SampleData.recentDay)
    }
    .modelContainer(SampleData.container)
}

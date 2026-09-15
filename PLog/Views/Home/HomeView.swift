//
//  HomeView.swift
//  PLog
//
//  The app's home screen: a reverse-chronological list of logged workout days, grouped by
//  month. Tap a day to view/edit it; tap "+" to start a new session.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context

    /// All logged days, newest first. `@Query` keeps this list live as data changes.
    @Query(sort: \WorkoutDay.date, order: .reverse) private var days: [WorkoutDay]

    /// Navigation path so we can push a freshly-created day straight into its detail screen.
    @State private var path: [WorkoutDay] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if days.isEmpty {
                    emptyState
                } else {
                    dayList
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: startNewWorkout) {
                        Label("New Workout", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: WorkoutDay.self) { day in
                DayDetailView(day: day)
            }
        }
    }

    // MARK: - Subviews

    private var dayList: some View {
        List {
            ForEach(groupedDays, id: \.title) { section in
                Section(section.title) {
                    ForEach(section.days) { day in
                        NavigationLink(value: day) {
                            WorkoutDayRow(day: day)
                        }
                    }
                    .onDelete { offsets in
                        delete(from: section.days, at: offsets)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Workouts Yet", systemImage: "figure.strengthtraining.traditional")
        } description: {
            Text("Tap + to log your first session and start tracking progressive overload.")
        } actions: {
            Button("Start a Workout", action: startNewWorkout)
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Grouping

    private struct DaySection {
        let title: String
        let days: [WorkoutDay]
    }

    /// Groups days into month sections (e.g. "September 2026"), preserving newest-first order.
    private var groupedDays: [DaySection] {
        let groups = Dictionary(grouping: days) { day in
            day.date.formatted(.dateTime.month(.wide).year())
        }
        return groups
            .map { DaySection(title: $0.key, days: $0.value.sorted { $0.date > $1.date }) }
            .sorted { ($0.days.first?.date ?? .distantPast) > ($1.days.first?.date ?? .distantPast) }
    }

    // MARK: - Actions

    private func startNewWorkout() {
        let day = WorkoutDay(date: .now, name: "New Workout")
        context.insert(day)
        try? context.save()
        path.append(day)
    }

    private func delete(from sectionDays: [WorkoutDay], at offsets: IndexSet) {
        for index in offsets {
            context.delete(sectionDays[index])
        }
        try? context.save()
    }
}

#Preview {
    HomeView()
        .modelContainer(SampleData.container)
}

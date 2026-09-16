//
//  HomeView.swift
//  PLog
//
//  The Logs tab: a reverse-chronological list of logged sessions, grouped by month. Tap a
//  session to view/edit it. "+" offers the active plan's days (pre-filled from the template)
//  or a blank workout.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context

    /// All logged sessions, newest first. `@Query` keeps this list live as data changes.
    @Query(sort: \WorkoutDay.date, order: .reverse) private var days: [WorkoutDay]

    /// At most one plan is active at a time (starting one ends the others), so `first` is safe.
    @Query private var plans: [WorkoutPlan]

    /// Navigation path so we can push a freshly-created session straight into its detail screen.
    @State private var path: [WorkoutDay] = []

    private var activePlan: WorkoutPlan? {
        plans.first(where: \.isActive)
    }

    /// The active plan, only if it actually has days to log against.
    private var loggablePlan: WorkoutPlan? {
        guard let plan = activePlan, !plan.days.isEmpty else { return nil }
        return plan
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if days.isEmpty {
                    emptyState
                } else {
                    dayList
                }
            }
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    newLogControl {
                        Label("Log Workout", systemImage: "plus")
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
            Label("No Logs Yet", systemImage: "figure.strengthtraining.traditional")
        } description: {
            if loggablePlan != nil {
                Text("Pick a day from your plan and its exercises and sets are filled in — you just update the weights.")
            } else {
                Text("Log your first session to start tracking progressive overload. Start a plan to have sessions pre-filled.")
            }
        } actions: {
            newLogControl {
                Text("Log a Workout")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    /// A menu of the active plan's days (plus "Blank Workout"), or a plain button when
    /// there's no active plan to log against.
    @ViewBuilder
    private func newLogControl<L: View>(@ViewBuilder label: () -> L) -> some View {
        if let plan = loggablePlan {
            Menu {
                planDayButtons(for: plan)
            } label: {
                label()
            }
        } else {
            Button(action: startBlankWorkout, label: label)
        }
    }

    @ViewBuilder
    private func planDayButtons(for plan: WorkoutPlan) -> some View {
        let next = WorkoutLogger.suggestedNextDay(in: plan)
        Section(plan.name.isEmpty ? "Plan" : plan.name) {
            ForEach(plan.orderedDays) { day in
                Button {
                    log(day)
                } label: {
                    if day === next {
                        Label("\(day.name) · Up next", systemImage: "arrow.right.circle.fill")
                    } else {
                        Text(day.name.isEmpty ? "Day" : day.name)
                    }
                }
            }
        }
        Button {
            startBlankWorkout()
        } label: {
            Label("Blank Workout", systemImage: "square.dashed")
        }
    }

    // MARK: - Grouping

    private struct DaySection {
        let title: String
        let days: [WorkoutDay]
    }

    /// Groups sessions into month sections (e.g. "September 2026"), preserving newest-first order.
    private var groupedDays: [DaySection] {
        let groups = Dictionary(grouping: days) { day in
            day.date.formatted(.dateTime.month(.wide).year())
        }
        return groups
            .map { DaySection(title: $0.key, days: $0.value.sorted { $0.date > $1.date }) }
            .sorted { ($0.days.first?.date ?? .distantPast) > ($1.days.first?.date ?? .distantPast) }
    }

    // MARK: - Actions

    /// Stamps the plan day's template into a new session and opens it.
    private func log(_ planDay: PlanDay) {
        let day = WorkoutLogger.logWorkout(for: planDay, in: context)
        path.append(day)
    }

    private func startBlankWorkout() {
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

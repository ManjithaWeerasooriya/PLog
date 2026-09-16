//
//  PlanLogView.swift
//  PLog
//
//  The day-by-day log for a plan: every date from the start of the plan until today (or its
//  end), with logged sessions as tappable rows and untrained dates marked "Rest Day".
//  Logging a new session stamps out the chosen day template and opens it for editing.
//

import SwiftUI
import SwiftData

struct PlanLogView: View {
    @State private var viewModel: WorkoutPlanViewModel

    /// The Plans tab's navigation path, so a freshly logged session can be pushed straight
    /// into its editor. (A local `navigationDestination(item:)` would shadow the root's
    /// `WorkoutDay` destination and break the value-based row links.)
    @Binding var path: NavigationPath

    /// All sessions, filtered to the plan's window in `timeline`. `@Query` keeps the log live
    /// whether a session is logged here or from the Workouts tab.
    @Query(sort: \WorkoutDay.date, order: .reverse) private var allDays: [WorkoutDay]

    init(plan: WorkoutPlan, context: ModelContext, path: Binding<NavigationPath>) {
        _viewModel = State(initialValue: WorkoutPlanViewModel(plan: plan, context: context))
        _path = path
    }

    var body: some View {
        Group {
            if viewModel.plan.status == .notStarted {
                notStartedState
            } else {
                logList
            }
        }
        .navigationTitle("Workout Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.plan.isActive {
                ToolbarItem(placement: .primaryAction) {
                    logMenu
                }
            }
        }
    }

    // MARK: - Subviews

    private var logList: some View {
        List {
            if viewModel.plan.isActive, let next = viewModel.suggestedNextDay {
                Section("Up Next") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(next.name.isEmpty ? "Day" : next.name)
                                .font(.headline)
                            Text("\(next.exercises.count) exercises")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Log") { log(next) }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
            }

            ForEach(sections, id: \.title) { section in
                Section(section.title) {
                    ForEach(section.items) { item in
                        if let workout = item.workout {
                            NavigationLink(value: workout) {
                                WorkoutDayRow(day: workout)
                            }
                        } else {
                            restDayRow(for: item.date)
                        }
                    }
                }
            }
        }
    }

    private func restDayRow(for date: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(date)
        return HStack {
            Label(
                isToday ? "Today" : "Rest Day",
                systemImage: isToday ? "sun.max" : "bed.double"
            )
            .foregroundStyle(isToday ? .primary : .secondary)
            Spacer()
            if isToday {
                Text("Not logged yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(date.mediumDayLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var logMenu: some View {
        Menu {
            ForEach(viewModel.days) { day in
                Button(day.name.isEmpty ? "Day" : day.name) { log(day) }
            }
        } label: {
            Label("Log Workout", systemImage: "plus")
        }
        .disabled(viewModel.days.isEmpty)
    }

    private var notStartedState: some View {
        ContentUnavailableView {
            Label("Plan Not Started", systemImage: "play.circle")
        } description: {
            Text("Start the plan to begin logging days against it.")
        } actions: {
            Button("Start Plan") {
                withAnimation(.snappy) { viewModel.start() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Timeline

    private struct LogSection {
        let title: String
        let items: [PlanLogItem]
    }

    /// Month sections in newest-first order, built sequentially so ordering is preserved.
    private var sections: [LogSection] {
        let items = PlanTimeline.items(for: viewModel.plan, workouts: allDays)
        var result: [LogSection] = []
        for item in items {
            let title = item.date.formatted(.dateTime.month(.wide).year())
            if let last = result.indices.last, result[last].title == title {
                result[last] = LogSection(title: title, items: result[last].items + [item])
            } else {
                result.append(LogSection(title: title, items: [item]))
            }
        }
        return result
    }

    // MARK: - Actions

    private func log(_ day: PlanDay) {
        path.append(viewModel.logWorkout(for: day))
    }
}

#Preview {
    struct Demo: View {
        @State private var path = NavigationPath()
        var body: some View {
            NavigationStack(path: $path) {
                PlanLogView(plan: SampleData.plan, context: SampleData.context, path: $path)
                    .navigationDestination(for: WorkoutDay.self) { day in
                        DayDetailView(day: day)
                    }
            }
        }
    }
    return Demo()
        .modelContainer(SampleData.container)
}

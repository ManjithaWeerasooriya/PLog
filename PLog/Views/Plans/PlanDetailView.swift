//
//  PlanDetailView.swift
//  PLog
//
//  Edit one plan: name, start/end lifecycle, the ordered list of day templates, and a link
//  into the day-by-day workout log.
//

import SwiftUI
import SwiftData

struct PlanDetailView: View {
    @State private var viewModel: WorkoutPlanViewModel

    @State private var showingAddDay = false
    @State private var newDayName = ""
    @State private var confirmingEnd = false

    /// Context is passed in explicitly because `@Environment` isn't available during `init`.
    init(plan: WorkoutPlan, context: ModelContext) {
        _viewModel = State(initialValue: WorkoutPlanViewModel(plan: plan, context: context))
    }

    var body: some View {
        @Bindable var plan = viewModel.plan

        List {
            Section("Plan") {
                TextField("Plan name", text: $plan.name)
                    .font(.headline)
                TextField("Notes", text: $plan.notes, axis: .vertical)
                    .lineLimit(1...4)
                statusRow
            }

            Section {
                lifecycleButton
            }

            Section {
                NavigationLink(value: PlanRoute.log(viewModel.plan)) {
                    Label("Workout Log", systemImage: "calendar.day.timeline.left")
                }
            }

            daysSection
        }
        .navigationTitle(plan.name.isEmpty ? "Plan" : plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
        .alert("New Day", isPresented: $showingAddDay) {
            TextField("e.g. Push Day", text: $newDayName)
            Button("Add") {
                let name = newDayName.trimmingCharacters(in: .whitespaces)
                viewModel.addDay(named: name.isEmpty ? "Day \(viewModel.days.count + 1)" : name)
                newDayName = ""
            }
            Button("Cancel", role: .cancel) { newDayName = "" }
        } message: {
            Text("Name the training day, then add its exercises.")
        }
        // `.alert` rather than `.confirmationDialog`: the latter renders (at least on this
        // iOS version) as a small anchored callout that latches onto an arbitrary ancestor
        // view instead of appearing near the button that triggered it. A centered alert has
        // no anchor to get wrong.
        .alert(
            "End this plan?",
            isPresented: $confirmingEnd
        ) {
            Button("End Plan", role: .destructive) { viewModel.end() }
        } message: {
            Text("Your logged workouts are kept. You can restart the plan later.")
        }
    }

    // MARK: - Sections

    private var statusRow: some View {
        HStack {
            Text("Status")
            Spacer()
            PlanStatusPill(status: viewModel.plan.status)
            if let dates = dateRangeLabel {
                Text(dates)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dateRangeLabel: String? {
        guard let start = viewModel.plan.startedAt else { return nil }
        if let end = viewModel.plan.endedAt {
            return "\(start.shortDateLabel) – \(end.shortDateLabel)"
        }
        return "since \(start.shortDateLabel)"
    }

    @ViewBuilder
    private var lifecycleButton: some View {
        switch viewModel.plan.status {
        case .notStarted:
            Button {
                withAnimation(.snappy) { viewModel.start() }
            } label: {
                Label("Start Plan", systemImage: "play.fill")
            }
        case .active:
            Button(role: .destructive) {
                confirmingEnd = true
            } label: {
                Label("End Plan", systemImage: "stop.fill")
                    .foregroundStyle(.red)
            }
        case .ended:
            Button {
                withAnimation(.snappy) { viewModel.start() }
            } label: {
                Label("Restart Plan", systemImage: "arrow.counterclockwise")
            }
        }
    }

    @ViewBuilder
    private var daysSection: some View {
        Section {
            ForEach(viewModel.days) { day in
                NavigationLink(value: day) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.name.isEmpty ? "Day" : day.name)
                        Text(exerciseSummary(for: day))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .onDelete(perform: viewModel.removeDays)
            .onMove(perform: moveDays)

            Button {
                showingAddDay = true
            } label: {
                Label("Add Day", systemImage: "plus.circle")
            }
        } header: {
            Text("Days")
        } footer: {
            if viewModel.days.isEmpty {
                Text("Add the days you rotate through, e.g. Push, Pull, Legs.")
            }
        }
    }

    private func moveDays(from source: IndexSet, to destination: Int) {
        var ordered = viewModel.days
        ordered.move(fromOffsets: source, toOffset: destination)
        viewModel.reorderDays(ordered)
    }

    private func exerciseSummary(for day: PlanDay) -> String {
        let names = day.orderedExercises.compactMap { $0.exercise?.name }
        return names.isEmpty ? "No exercises yet" : names.joined(separator: " · ")
    }
}

#Preview {
    NavigationStack {
        PlanDetailView(plan: SampleData.plan, context: SampleData.context)
    }
    .modelContainer(SampleData.container)
}

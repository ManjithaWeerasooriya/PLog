//
//  DayDetailView.swift
//  PLog
//
//  Shows one workout day: editable name/notes plus the exercises logged, each collapsible
//  (accordion-style, one open at a time) with its sets edited inline. Everything autosaves
//  — there's no separate editor to open and nothing to confirm on the way out.
//

import SwiftUI
import SwiftData

struct DayDetailView: View {
    @Environment(\.modelContext) private var context

    /// `@Bindable` lets us edit the model's name/notes directly through TextFields.
    @Bindable var day: WorkoutDay

    @State private var showingExercisePicker = false
    /// The one exercise currently expanded (accordion-style — see `ExerciseEntryRows`).
    @State private var expandedEntryID: PersistentIdentifier?
    /// The one set currently open for editing, across the whole day — see `SetRow`.
    @State private var expandedSetID: PersistentIdentifier?
    /// The exercise whose history sheet is showing.
    @State private var historyExercise: Exercise?
    /// A just-added exercise to scroll into view once its rows exist.
    @State private var scrollTarget: PersistentIdentifier?

    var body: some View {
        ScrollViewReader { proxy in
            List {
                detailsSection
                exercisesSection
            }
            .onChange(of: scrollTarget) { _, target in
                guard let target else { return }
                withAnimation(.snappy) { proxy.scrollTo(target, anchor: .top) }
                scrollTarget = nil
            }
        }
        .navigationTitle(day.date.mediumDayLabel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(onSelect: addExercise)
        }
        // A sheet rather than a push: this screen lives in three different stacks (Logs,
        // Calendar, Library) and has no path of its own to push onto.
        .sheet(item: $historyExercise) { exercise in
            NavigationStack {
                ExerciseHistoryView(exercise: exercise)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { historyExercise = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section("Session") {
            TextField("Workout name", text: $day.name)
                .font(.headline)
            DatePicker("Date", selection: $day.date, displayedComponents: .date)
            if let planDay = day.planDay {
                LabeledContent("Plan Day") {
                    Text(planDayLabel(planDay))
                        .foregroundStyle(.secondary)
                }
            }
            TextField("Notes", text: $day.notes, axis: .vertical)
                .lineLimit(1...4)
        }
    }

    @ViewBuilder
    private var exercisesSection: some View {
        if day.entries.isEmpty {
            Section {
                ContentUnavailableView {
                    Label("No Exercises", systemImage: "dumbbell")
                } description: {
                    Text("Add an exercise to start logging sets.")
                }
            }
        } else {
            Section("Exercises") {
                ForEach(day.orderedEntries) { entry in
                    ExerciseEntryRows(
                        entry: entry,
                        context: context,
                        isExpanded: isExpanded(entry),
                        expandedSetID: $expandedSetID,
                        onHistory: { historyExercise = $0 },
                        onDelete: { delete(entry) }
                    )
                }
            }
        }
    }

    private func isExpanded(_ entry: ExerciseEntry) -> Binding<Bool> {
        Binding(
            get: { expandedEntryID == entry.persistentModelID },
            set: { expanded in
                expandedEntryID = expanded ? entry.persistentModelID : nil
                // Collapsing an exercise also closes whichever of its sets was open.
                if !expanded { expandedSetID = nil }
            }
        )
    }

    /// e.g. "Push Day · Push / Pull / Legs".
    private func planDayLabel(_ planDay: PlanDay) -> String {
        let dayName = planDay.name.isEmpty ? "Day" : planDay.name
        guard let planName = planDay.plan?.name, !planName.isEmpty else { return dayName }
        return "\(dayName) · \(planName)"
    }

    // MARK: - Actions

    /// Creates a new entry for the chosen exercise with its first set prefilled from last
    /// time, then opens it in place — no second sheet.
    private func addExercise(_ exercise: Exercise) {
        let entry = ExerciseEntry(exercise: exercise, order: day.entries.count)
        context.insert(entry)
        day.entries.append(entry)
        ExerciseEntryViewModel.prefill(entry, in: context)
        try? context.save()
        withAnimation(.snappy) {
            expandedEntryID = entry.persistentModelID
            expandedSetID = entry.orderedSets.first?.persistentModelID
        }
        scrollTarget = entry.persistentModelID
    }

    private func delete(_ entry: ExerciseEntry) {
        withAnimation(.snappy) {
            if expandedEntryID == entry.persistentModelID {
                expandedEntryID = nil
                expandedSetID = nil
            }
            day.entries.removeAll { $0 === entry }
            context.delete(entry)
        }
        try? context.save()
    }
}

#Preview {
    NavigationStack {
        DayDetailView(day: SampleData.recentDay)
    }
    .modelContainer(SampleData.container)
}

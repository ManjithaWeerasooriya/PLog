//
//  DayDetailView.swift
//  PLog
//
//  Shows one workout day: editable name/notes plus the exercises logged, each an
//  expandable card. Add exercises from the master library and jump into quick entry.
//

import SwiftUI
import SwiftData

struct DayDetailView: View {
    @Environment(\.modelContext) private var context

    /// `@Bindable` lets us edit the model's name/notes directly through TextFields.
    @Bindable var day: WorkoutDay

    @State private var showingExercisePicker = false
    /// The entry currently open in the quick-entry editor (drives the sheet).
    @State private var editingEntry: ExerciseEntry?

    var body: some View {
        List {
            detailsSection
            exercisesSection
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
        .sheet(item: $editingEntry) { entry in
            AddEditExerciseEntryView(entry: entry, context: context)
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
                    ExerciseEntryCard(entry: entry, initiallyExpanded: day.planDay != nil) {
                        editingEntry = entry
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: deleteEntries)
            }
        }
    }

    /// e.g. "Push Day · Push / Pull / Legs".
    private func planDayLabel(_ planDay: PlanDay) -> String {
        let dayName = planDay.name.isEmpty ? "Day" : planDay.name
        guard let planName = planDay.plan?.name, !planName.isEmpty else { return dayName }
        return "\(dayName) · \(planName)"
    }

    // MARK: - Actions

    /// Creates a new entry for the chosen exercise and immediately opens the quick editor.
    private func addExercise(_ exercise: Exercise) {
        let entry = ExerciseEntry(exercise: exercise, workoutDay: day, order: day.entries.count)
        context.insert(entry)
        try? context.save()
        editingEntry = entry
    }

    private func deleteEntries(at offsets: IndexSet) {
        let ordered = day.orderedEntries
        for index in offsets {
            context.delete(ordered[index])
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

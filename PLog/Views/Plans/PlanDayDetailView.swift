//
//  PlanDayDetailView.swift
//  PLog
//
//  Edit one day template: its name and the exercises with target sets × reps that get
//  pre-created every time this day is logged.
//

import SwiftUI
import SwiftData

struct PlanDayDetailView: View {
    @Environment(\.modelContext) private var context

    @Bindable var day: PlanDay

    @State private var showingExercisePicker = false

    var body: some View {
        List {
            Section("Day") {
                TextField("Day name", text: $day.name)
                    .font(.headline)
            }

            exercisesSection
        }
        .navigationTitle(day.name.isEmpty ? "Day" : day.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(onSelect: addExercise)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var exercisesSection: some View {
        if day.exercises.isEmpty {
            Section {
                ContentUnavailableView {
                    Label("No Exercises", systemImage: "dumbbell")
                } description: {
                    Text("Add exercises with target sets and reps. They'll be pre-filled every time you log this day.")
                }
            }
        } else {
            Section("Exercises") {
                ForEach(day.orderedExercises) { slot in
                    PlanExerciseRow(planExercise: slot)
                }
                .onDelete(perform: deleteExercises)
                .onMove(perform: moveExercises)
            }
        }
    }

    // MARK: - Actions

    /// Appends through `day.exercises` (not by setting `slot.planDay`) so Observation fires
    /// on the day and this screen refreshes; setting only the inverse side doesn't notify.
    private func addExercise(_ exercise: Exercise) {
        let slot = PlanExercise(exercise: exercise, order: day.exercises.count)
        context.insert(slot)
        day.exercises.append(slot)
        try? context.save()
    }

    private func deleteExercises(at offsets: IndexSet) {
        let ordered = day.orderedExercises
        for index in offsets {
            let slot = ordered[index]
            day.exercises.removeAll { $0 === slot }
            context.delete(slot)
        }
        renumber(ordered.enumerated().filter { !offsets.contains($0.offset) }.map(\.element))
        try? context.save()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var ordered = day.orderedExercises
        ordered.move(fromOffsets: source, toOffset: destination)
        renumber(ordered)
        try? context.save()
    }

    private func renumber(_ ordered: [PlanExercise]) {
        for (index, slot) in ordered.enumerated() {
            slot.order = index
        }
    }
}

#Preview {
    NavigationStack {
        PlanDayDetailView(day: SampleData.pushDay)
    }
    .modelContainer(SampleData.container)
}

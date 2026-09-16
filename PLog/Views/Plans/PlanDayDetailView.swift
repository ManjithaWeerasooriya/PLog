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
    /// The one exercise slot currently expanded (accordion-style — see `PlanExerciseRow`).
    @State private var expandedSlotID: PersistentIdentifier?

    /// Baseline the day's name and each slot's target sets/reps are compared against to
    /// decide whether the back button should confirm before leaving. Structural changes
    /// (adding/removing/reordering exercises) are excluded — those already save immediately,
    /// same as before this screen had a "Save"/"Discard" concept at all.
    @State private var originalName: String
    @State private var originalTargets: [PersistentIdentifier: (sets: Int, reps: Int)]

    init(day: PlanDay) {
        _day = Bindable(wrappedValue: day)
        _originalName = State(initialValue: day.name)
        _originalTargets = State(
            initialValue: Dictionary(uniqueKeysWithValues: day.exercises.map {
                ($0.persistentModelID, ($0.targetSets, $0.targetReps))
            })
        )
    }

    var body: some View {
        List {
            Section("Day") {
                TextField("Day name", text: $day.name)
                    .font(.headline)
            }

            exercisesSection
        }
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
        .confirmBeforeLeaving(
            title: day.name.isEmpty ? "Day" : day.name,
            hasChanges: hasChanges,
            onSave: saveChanges,
            onDiscard: discardChanges
        )
    }

    // MARK: - Unsaved changes

    private var hasChanges: Bool {
        if day.name != originalName { return true }
        for slot in day.exercises {
            guard let original = originalTargets[slot.persistentModelID] else { continue }
            if slot.targetSets != original.sets || slot.targetReps != original.reps { return true }
        }
        return false
    }

    private func saveChanges() {
        try? context.save()
    }

    private func discardChanges() {
        day.name = originalName
        for slot in day.exercises {
            guard let original = originalTargets[slot.persistentModelID] else { continue }
            slot.targetSets = original.sets
            slot.targetReps = original.reps
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
                    PlanExerciseRow(planExercise: slot, isExpanded: isExpanded(slot))
                }
                .onDelete(perform: deleteExercises)
                .onMove(perform: moveExercises)
            }
        }
    }

    private func isExpanded(_ slot: PlanExercise) -> Binding<Bool> {
        Binding(
            get: { expandedSlotID == slot.persistentModelID },
            set: { expanded in expandedSlotID = expanded ? slot.persistentModelID : nil }
        )
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

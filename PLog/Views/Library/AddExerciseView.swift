//
//  AddExerciseView.swift
//  PLog
//
//  A form for adding a new exercise to the master library, or editing an existing one.
//

import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// The exercise being edited. `nil` means this is the "New Exercise" flow.
    var exercise: Exercise? = nil
    var prefilledName: String = ""
    /// Optional callback fired with the newly created (or edited) exercise (used by the
    /// picker flow to select whatever the user just made).
    var onCreate: ((Exercise) -> Void)? = nil

    @State private var name: String = ""
    @State private var category: MuscleGroup = .chest
    @State private var notes: String = ""

    private var isEditing: Bool { exercise != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Muscle Group") {
                    Picker("Category", selection: $category) {
                        ForEach(MuscleGroup.allCases) { group in
                            Label(group.displayName, systemImage: group.systemImage)
                                .tag(group)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Notes") {
                    TextField("Form cues, machine settings, etc.", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(isEditing ? "Edit Exercise" : "New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear(perform: populateFromExistingExercise)
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func populateFromExistingExercise() {
        guard let exercise else {
            if name.isEmpty { name = prefilledName }
            return
        }
        name = exercise.name
        category = exercise.category
        notes = exercise.notes
    }

    private func save() {
        if let exercise {
            exercise.name = trimmedName
            exercise.category = category
            exercise.notes = notes
            try? context.save()
            onCreate?(exercise)
        } else {
            let created = Exercise(name: trimmedName, category: category, notes: notes)
            context.insert(created)
            try? context.save()
            onCreate?(created)
        }
        dismiss()
    }
}

#Preview("New Exercise") {
    AddExerciseView()
        .modelContainer(SampleData.container)
}

#Preview("Edit Exercise") {
    AddExerciseView(exercise: SampleData.benchPress)
        .modelContainer(SampleData.container)
}

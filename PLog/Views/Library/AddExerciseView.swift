//
//  AddExerciseView.swift
//  PLog
//
//  A small form for adding a new exercise to the master library.
//

import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var prefilledName: String = ""
    /// Optional callback fired with the newly created exercise (used by the picker flow).
    var onCreate: ((Exercise) -> Void)? = nil

    @State private var name: String = ""
    @State private var category: MuscleGroup = .chest

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
            }
            .navigationTitle("New Exercise")
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
            .onAppear {
                if name.isEmpty { name = prefilledName }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        let exercise = Exercise(name: trimmedName, category: category)
        context.insert(exercise)
        try? context.save()
        onCreate?(exercise)
        dismiss()
    }
}

#Preview {
    AddExerciseView()
        .modelContainer(SampleData.container)
}

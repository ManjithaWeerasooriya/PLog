//
//  AddEditExerciseEntryView.swift
//  PLog
//
//  The fast data-entry screen. Prefills from the last session so the user just nudges the
//  numbers up, shows "Last time: …" inline, and offers a one-tap "duplicate last set".
//

import SwiftUI
import SwiftData

struct AddEditExerciseEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExerciseEntryViewModel

    /// Context is passed in explicitly because `@Environment` isn't available during `init`,
    /// and the view model needs it to insert/delete sets.
    init(entry: ExerciseEntry, context: ModelContext) {
        _viewModel = State(initialValue: ExerciseEntryViewModel(entry: entry, context: context))
    }

    var body: some View {
        NavigationStack {
            Form {
                if let lastTime = viewModel.lastTimeLabel {
                    Section {
                        Label(lastTime, systemImage: "clock.arrow.circlepath")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Sets") {
                    ForEach(viewModel.sets) { set in
                        SetEditorRow(set: set, trend: viewModel.trend(for: set))
                    }
                    .onDelete(perform: deleteSets)

                    Button {
                        withAnimation(.snappy) { viewModel.addDuplicateSet() }
                    } label: {
                        Label("Duplicate Last Set", systemImage: "plus.square.on.square")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        viewModel.discard()
                        dismiss()
                    } label: {
                        Label("Remove Exercise from Day", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(viewModel.exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func deleteSets(at offsets: IndexSet) {
        let sets = viewModel.sets
        for index in offsets {
            viewModel.removeSet(sets[index])
        }
    }
}

#Preview {
    AddEditExerciseEntryView(
        entry: SampleData.recentDay.orderedEntries.first!,
        context: SampleData.context
    )
    .modelContainer(SampleData.container)
}

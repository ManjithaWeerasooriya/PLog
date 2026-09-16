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
    /// The one set currently expanded (accordion-style — see `SetEditorRow`). Starts on the
    /// first set so opening the sheet doesn't require an extra tap to adjust it.
    @State private var expandedSetID: PersistentIdentifier?

    /// The set list as it stood when the sheet opened (including the auto-prefilled first
    /// set), for the "unsaved changes" confirmation on Cancel/swipe-dismiss.
    @State private var originalSets: [SetFieldSnapshot]
    @State private var confirmingDiscard = false

    /// Context is passed in explicitly because `@Environment` isn't available during `init`,
    /// and the view model needs it to insert/delete sets.
    init(entry: ExerciseEntry, context: ModelContext) {
        let viewModel = ExerciseEntryViewModel(entry: entry, context: context)
        _viewModel = State(initialValue: viewModel)
        _expandedSetID = State(initialValue: viewModel.sets.first?.persistentModelID)
        _originalSets = State(initialValue: viewModel.currentSnapshot)
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
                        SetEditorRow(
                            set: set,
                            trend: viewModel.trend(for: set),
                            isExpanded: isExpanded(set)
                        )
                    }
                    .onDelete(perform: deleteSets)

                    Button {
                        withAnimation(.snappy) {
                            viewModel.addDuplicateSet()
                            expandedSetID = viewModel.sets.last?.persistentModelID
                        }
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges {
                            confirmingDiscard = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text(viewModel.exerciseName).font(.headline)
                        if hasChanges { UnsavedTag() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            // Forces the user through Cancel/Done instead of silently keeping whatever's on
            // screen — swiping away used to apply live-bound edits with no way to back out.
            .interactiveDismissDisabled(hasChanges)
            .alert("Save Changes?", isPresented: $confirmingDiscard) {
                Button("Save") {
                    viewModel.save()
                    dismiss()
                }
                Button("Discard Changes", role: .destructive) {
                    viewModel.revert(to: originalSets)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You have unsaved changes to \(viewModel.exerciseName).")
            }
        }
    }

    // MARK: - Unsaved changes

    private var hasChanges: Bool {
        viewModel.currentSnapshot != originalSets
    }

    private func deleteSets(at offsets: IndexSet) {
        let sets = viewModel.sets
        for index in offsets {
            viewModel.removeSet(sets[index])
        }
    }

    private func isExpanded(_ set: SetEntry) -> Binding<Bool> {
        Binding(
            get: { expandedSetID == set.persistentModelID },
            set: { expanded in expandedSetID = expanded ? set.persistentModelID : nil }
        )
    }
}

#Preview {
    AddEditExerciseEntryView(
        entry: SampleData.recentDay.orderedEntries.first!,
        context: SampleData.context
    )
    .modelContainer(SampleData.container)
}

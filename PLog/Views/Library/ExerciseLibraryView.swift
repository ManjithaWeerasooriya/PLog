//
//  ExerciseLibraryView.swift
//  PLog
//
//  The master exercise list: searchable, grouped by muscle group, with add/delete.
//  Tapping an exercise opens its progress history.
//

import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var categoryFilter: MuscleGroup?
    @State private var showingAddExercise = false

    /// Exercises staged for deletion, pending the confirmation dialog below.
    @State private var pendingDeleteExercises: [Exercise] = []
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if exercises.isEmpty {
                    emptyState
                } else {
                    libraryList
                }
            }
            .navigationTitle("Exercises")
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddExercise = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    categoryMenu
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView()
            }
            .confirmationDialog(
                deleteConfirmationTitle,
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive, action: confirmDelete)
                Button("Cancel", role: .cancel) { pendingDeleteExercises = [] }
            } message: {
                Text("Logged sets that used it are kept, just no longer linked to an exercise.")
            }
        }
    }

    // MARK: - List

    private var libraryList: some View {
        List {
            ForEach(groupedResults, id: \.group) { section in
                Section {
                    ForEach(section.items) { exercise in
                        NavigationLink {
                            ExerciseHistoryView(exercise: exercise)
                        } label: {
                            row(for: exercise)
                        }
                    }
                    .onDelete { offsets in
                        requestDelete(from: section.items, at: offsets)
                    }
                } header: {
                    Label(section.group.displayName, systemImage: section.group.systemImage)
                }
            }
        }
    }

    private func row(for exercise: Exercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                let sessions = exercise.entries.filter { $0.workoutDay != nil }.count
                Text(sessions == 0 ? "No sessions yet" : "\(sessions) sessions logged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var categoryMenu: some View {
        Menu {
            Button("All Muscle Groups") { categoryFilter = nil }
            Divider()
            ForEach(MuscleGroup.allCases) { group in
                Button {
                    categoryFilter = group
                } label: {
                    Label(group.displayName, systemImage: group.systemImage)
                }
            }
        } label: {
            Label(
                categoryFilter?.displayName ?? "Filter",
                systemImage: categoryFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
            )
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Exercises", systemImage: "dumbbell")
        } description: {
            Text("Build your master list of exercises to log during workouts.")
        } actions: {
            Button("Add Exercise") { showingAddExercise = true }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Filtering

    private var groupedResults: [(group: MuscleGroup, items: [Exercise])] {
        let filtered = exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty
                || exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = categoryFilter == nil || exercise.category == categoryFilter
            return matchesSearch && matchesCategory
        }
        return MuscleGroup.allCases.compactMap { group in
            let items = filtered.filter { $0.category == group }
            return items.isEmpty ? nil : (group, items)
        }
    }

    private func requestDelete(from items: [Exercise], at offsets: IndexSet) {
        pendingDeleteExercises = offsets.map { items[$0] }
        showingDeleteConfirmation = true
    }

    private func confirmDelete() {
        for exercise in pendingDeleteExercises {
            context.delete(exercise)
        }
        pendingDeleteExercises = []
        try? context.save()
    }

    private var deleteConfirmationTitle: String {
        if pendingDeleteExercises.count == 1 {
            let name = pendingDeleteExercises[0].name
            return "Delete “\(name.isEmpty ? "Exercise" : name)”?"
        }
        return "Delete \(pendingDeleteExercises.count) Exercises?"
    }
}

#Preview {
    ExerciseLibraryView()
        .modelContainer(SampleData.container)
}

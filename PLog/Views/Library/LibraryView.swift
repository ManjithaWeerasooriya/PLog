//
//  LibraryView.swift
//  PLog
//
//  The Library tab: Plans and Exercises behind one segmented sub-nav. Owns the single
//  `NavigationStack` both sections push onto, so every destination is registered here.
//

import SwiftUI
import SwiftData

enum LibrarySection: String, CaseIterable, Identifiable {
    case plans = "Plans"
    case exercises = "Exercises"

    var id: String { rawValue }
}

struct LibraryView: View {
    @Environment(\.modelContext) private var context

    @State private var section: LibrarySection = .plans

    /// Mixed-type path shared by both sections: plans, day templates, logged sessions,
    /// `PlanRoute`s and exercises all push onto it. Push everything by value — see AGENT.md.
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch section {
                case .plans:
                    PlanListView(path: $path)
                case .exercises:
                    ExerciseLibraryView()
                }
            }
            // The picker sits in the nav bar (replacing the title) rather than above the
            // list: Exercises' search field lives in the nav bar too, so a picker in the
            // content would jump down by a search bar's height when switching sections.
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    sectionPicker
                }
            }
            .navigationDestination(for: WorkoutPlan.self) { plan in
                PlanDetailView(plan: plan, context: context)
            }
            .navigationDestination(for: PlanDay.self) { day in
                PlanDayDetailView(day: day)
            }
            .navigationDestination(for: WorkoutDay.self) { day in
                DayDetailView(day: day)
            }
            .navigationDestination(for: PlanRoute.self) { route in
                switch route {
                case .log(let plan):
                    PlanLogView(plan: plan, context: context, path: $path)
                }
            }
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseHistoryView(exercise: exercise)
            }
        }
    }

    private var sectionPicker: some View {
        Picker("Section", selection: $section) {
            ForEach(LibrarySection.allCases) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 220)
    }
}

#Preview {
    LibraryView()
        .modelContainer(SampleData.container)
}

//
//  PlanListView.swift
//  PLog
//
//  The Plans section of the Library tab: the currently active plan on top, every other plan
//  below. Tap "+" to create a plan and jump straight into editing it. The owning
//  `NavigationStack` (and every `navigationDestination`) lives in `LibraryView`.
//

import SwiftUI
import SwiftData

/// Non-model screens reachable in the Library stack. Everything is pushed by value so that
/// value-based links keep working from any depth (a view-builder `NavigationLink` would
/// leave its destination outside the path and break `NavigationLink(value:)` inside it).
enum PlanRoute: Hashable {
    case log(WorkoutPlan)
    /// A plan freshly created by "+", pushed straight into editing. Distinct from the plain
    /// `WorkoutPlan.self` destination (used for normal row taps) so `PlanDetailView` knows to
    /// offer discarding it if the user backs out before adding anything — see
    /// `PlanDetailView.isNewlyCreated`.
    case newPlan(WorkoutPlan)
}

struct PlanListView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]

    /// The Library tab's shared path, so "+" can push the new plan straight into editing.
    @Binding var path: NavigationPath

    /// Plans staged for deletion, pending the confirmation dialog below.
    @State private var pendingDeletePlans: [WorkoutPlan] = []
    @State private var showingDeleteConfirmation = false
    /// Shown instead of the confirmation dialog when a swipe targets the active plan.
    @State private var showingActivePlanBlockedAlert = false

    var body: some View {
        Group {
            if plans.isEmpty {
                emptyState
            } else {
                planList
            }
        }
        .navigationTitle("Plans")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: createPlan) {
                    Label("New Plan", systemImage: "plus")
                }
            }
        }
        // `.alert` rather than `.confirmationDialog`: the latter renders (at least on
        // this iOS version) as a small anchored callout that latches onto an arbitrary
        // ancestor view instead of the swiped row, landing near the top of the list and
        // pointing at the wrong plan entirely. A centered alert has no anchor to get wrong.
        .alert(
            deleteConfirmationTitle,
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive, action: confirmDelete)
            Button("Cancel", role: .cancel) { pendingDeletePlans = [] }
        } message: {
            Text("This removes its day templates. Workouts you've already logged are kept.")
        }
        .alert("Can't Delete an Active Plan", isPresented: $showingActivePlanBlockedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("End the plan before deleting it.")
        }
    }

    // MARK: - Subviews

    private var planList: some View {
        List {
            if !activePlans.isEmpty {
                Section("Active") {
                    ForEach(activePlans) { plan in
                        NavigationLink(value: plan) {
                            WorkoutPlanRow(plan: plan)
                        }
                        .swipeActions(edge: .leading) {
                            duplicateButton(for: plan)
                        }
                    }
                    .onDelete { offsets in requestDelete(from: activePlans, at: offsets) }
                }
            }
            if !otherPlans.isEmpty {
                Section(activePlans.isEmpty ? "All Plans" : "Other Plans") {
                    ForEach(otherPlans) { plan in
                        NavigationLink(value: plan) {
                            WorkoutPlanRow(plan: plan)
                        }
                        .swipeActions(edge: .leading) {
                            duplicateButton(for: plan)
                        }
                    }
                    .onDelete { offsets in requestDelete(from: otherPlans, at: offsets) }
                }
            }
        }
    }

    private func duplicateButton(for plan: WorkoutPlan) -> some View {
        Button {
            duplicate(plan)
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        .tint(.indigo)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Plans Yet", systemImage: "list.clipboard")
        } description: {
            Text("Build a plan of days like Push, Pull and Legs, then start it to log against it.")
        } actions: {
            Button("Create a Plan", action: createPlan)
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Grouping

    private var activePlans: [WorkoutPlan] { plans.filter(\.isActive) }
    private var otherPlans: [WorkoutPlan] { plans.filter { !$0.isActive } }

    // MARK: - Actions

    private func createPlan() {
        let plan = WorkoutPlan(name: "New Plan")
        context.insert(plan)
        try? context.save()
        path.append(PlanRoute.newPlan(plan))
    }

    /// Copies the plan's days and exercise slots into a new, inactive plan; stays on the
    /// list so the user can see it land in "Other Plans" rather than jumping away.
    private func duplicate(_ plan: WorkoutPlan) {
        WorkoutPlanViewModel.duplicate(plan, in: context)
    }

    /// Stages the swiped plans for deletion, unless one of them is currently active — an
    /// active plan must be ended first so it can't be lost mid-program by accident.
    private func requestDelete(from sectionPlans: [WorkoutPlan], at offsets: IndexSet) {
        let targeted = offsets.map { sectionPlans[$0] }
        guard !targeted.contains(where: \.isActive) else {
            showingActivePlanBlockedAlert = true
            return
        }
        pendingDeletePlans = targeted
        showingDeleteConfirmation = true
    }

    private func confirmDelete() {
        for plan in pendingDeletePlans {
            context.delete(plan)
        }
        pendingDeletePlans = []
        try? context.save()
    }

    private var deleteConfirmationTitle: String {
        if pendingDeletePlans.count == 1 {
            let name = pendingDeletePlans[0].name
            return "Delete “\(name.isEmpty ? "Plan" : name)”?"
        }
        return "Delete \(pendingDeletePlans.count) Plans?"
    }
}

#Preview {
    struct Demo: View {
        @State private var path = NavigationPath()
        var body: some View {
            NavigationStack(path: $path) {
                PlanListView(path: $path)
            }
        }
    }
    return Demo()
        .modelContainer(SampleData.container)
}

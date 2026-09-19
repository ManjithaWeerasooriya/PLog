//
//  TrainHeroCard.swift
//  PLog
//
//  The first thing on the Train tab: what to do today. With an active plan it names the
//  suggested next day and offers one prominent "Start …" button, with the other days and a
//  blank workout behind a secondary menu. With no plan it offers a blank workout and points
//  at the Library. The daily action lives on-screen, not behind a toolbar menu.
//

import SwiftUI
import SwiftData

struct TrainHeroCard: View {
    /// The active plan, only if it has days to log against; `nil` shows the no-plan state.
    let plan: WorkoutPlan?
    var onLog: (PlanDay) -> Void
    var onBlankWorkout: () -> Void

    var body: some View {
        AnalyticsCard {
            VStack(alignment: .leading, spacing: 12) {
                if let plan, let next = WorkoutLogger.suggestedNextDay(in: plan) {
                    planContent(plan: plan, next: next)
                } else {
                    noPlanContent
                }
            }
        }
    }

    // MARK: - Active plan

    @ViewBuilder
    private func planContent(plan: WorkoutPlan, next: PlanDay) -> some View {
        eyebrow("Up next · \(plan.name.isEmpty ? "Plan" : plan.name)")

        VStack(alignment: .leading, spacing: 4) {
            Text(next.name.isEmpty ? "Day" : next.name)
                .font(.title2.weight(.bold))
            Text(exerciseSummary(for: next))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }

        Button {
            onLog(next)
        } label: {
            Text("Start \(next.name.isEmpty ? "Workout" : next.name)")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)

        Menu {
            Section(plan.name.isEmpty ? "Plan" : plan.name) {
                ForEach(plan.orderedDays) { day in
                    if day !== next {
                        Button(day.name.isEmpty ? "Day" : day.name) { onLog(day) }
                    }
                }
            }
            Button(action: onBlankWorkout) {
                Label("Blank Workout", systemImage: "square.dashed")
            }
        } label: {
            Label("Different day", systemImage: "chevron.down")
                .labelStyle(.titleAndIconTrailing)
                .font(.subheadline.weight(.medium))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - No plan

    @ViewBuilder
    private var noPlanContent: some View {
        eyebrow("Today")

        VStack(alignment: .leading, spacing: 4) {
            Text("No active plan")
                .font(.title2.weight(.bold))
            Text("Start one in Library to have sessions pre-filled.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        Button(action: onBlankWorkout) {
            Text("Log a Workout")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    // MARK: - Helpers

    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    /// e.g. "Bench Press · Overhead Press · Lateral Raise".
    private func exerciseSummary(for day: PlanDay) -> String {
        let names = day.orderedExercises.compactMap { $0.exercise?.name }
        return names.isEmpty ? "No exercises yet" : names.joined(separator: " · ")
    }
}

/// Icon after the title, for a "Different day ⌄" style menu label.
private struct TitleAndIconTrailingLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
                .font(.caption.weight(.semibold))
        }
    }
}

private extension LabelStyle where Self == TitleAndIconTrailingLabelStyle {
    static var titleAndIconTrailing: TitleAndIconTrailingLabelStyle { .init() }
}

#Preview("Active plan") {
    List {
        Section {
            TrainHeroCard(plan: SampleData.plan, onLog: { _ in }, onBlankWorkout: {})
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
    }
    .modelContainer(SampleData.container)
}

#Preview("No plan") {
    List {
        Section {
            TrainHeroCard(plan: nil, onLog: { _ in }, onBlankWorkout: {})
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
    }
}

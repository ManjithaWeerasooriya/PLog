//
//  ExerciseEntryCard.swift
//  PLog
//
//  An expandable card for one exercise on a workout day. Collapsed it shows a summary;
//  expanded it lists each set with a progressive-overload badge versus the previous session.
//

import SwiftUI
import SwiftData

struct ExerciseEntryCard: View {
    let entry: ExerciseEntry
    /// Called when the user taps "Edit" to open the quick-entry editor.
    var onEdit: () -> Void

    @State private var isExpanded: Bool

    /// Plan-logged sessions start expanded so every pre-filled set is visible at a glance.
    init(entry: ExerciseEntry, initiallyExpanded: Bool = false, onEdit: @escaping () -> Void) {
        self.entry = entry
        self.onEdit = onEdit
        _isExpanded = State(initialValue: initiallyExpanded)
    }

    /// The previous session's top set, cached for per-set comparisons.
    private var previousTopSet: SetSnapshot? {
        entry.exercise.flatMap { WorkoutHistory.previousTopSet(for: $0, excluding: entry) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Only the header toggles expansion; a card-wide tap gesture would swallow the
            // Edit/History buttons below.
            header
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy) { isExpanded.toggle() }
                }

            if isExpanded {
                Divider()
                setList
                actionRow
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.exercise?.name ?? "Exercise")
                    .font(.headline)
                if let category = entry.exercise?.category {
                    CategoryChip(category: category)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.sets.count) sets")
                    .font(.subheadline.weight(.medium))
                if entry.topWeight > 0 {
                    Text("Top: \(WeightFormatter.string(entry.topWeight))kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
    }

    // MARK: - Expanded content

    private var setList: some View {
        VStack(spacing: 8) {
            ForEach(entry.orderedSets) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .leading)

                    Text("\(WeightFormatter.string(set.weight))kg × \(set.reps)")
                        .font(.body.monospacedDigit())

                    if let rpe = set.rpe {
                        Text("RPE \(WeightFormatter.string(rpe))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    TrendBadge(
                        trend: ProgressiveOverload.trend(
                            current: SetSnapshot(weight: set.weight, reps: set.reps),
                            previous: previousTopSet
                        )
                    )
                }
            }
        }
    }

    private var actionRow: some View {
        HStack {
            Button(action: onEdit) {
                Label("Edit", systemImage: "square.and.pencil")
            }
            .buttonStyle(.borderless)
            Spacer()
            if let exercise = entry.exercise {
                NavigationLink {
                    ExerciseHistoryView(exercise: exercise)
                } label: {
                    Label("History", systemImage: "chart.xyaxis.line")
                }
            }
        }
        .font(.subheadline)
        .padding(.top, 2)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ExerciseEntryCard(entry: SampleData.recentDay.orderedEntries.first!, onEdit: {})
                .padding()
        }
    }
    .modelContainer(SampleData.container)
}

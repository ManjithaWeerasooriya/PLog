//
//  SetEditorRow.swift
//  PLog
//
//  One editable set in the quick-entry screen. Collapsed it shows a compact summary; tap it
//  to reveal the weight & reps wheel pickers. A set counts as "added" simply by existing in
//  the list — there's no separate completion toggle.
//

import SwiftUI

struct SetEditorRow: View {
    /// `@Bindable` gives us two-way bindings into the SwiftData model for the wheels.
    @Bindable var set: SetEntry
    let trend: ProgressTrend
    /// Controlled by the parent so only one set is expanded at a time (accordion-style) —
    /// see `AddEditExerciseEntryView`.
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 8) {
            header
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy) { isExpanded.toggle() }
                }

            if isExpanded {
                HStack(spacing: 20) {
                    NumberPickerWheel(
                        title: "Weight",
                        value: $set.weight,
                        step: 2.5,
                        range: 0...500,
                        unit: "kg",
                        width: 120
                    )
                    NumberPickerWheel(
                        title: "Reps",
                        intValue: $set.reps,
                        range: 0...100
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }

    private var header: some View {
        HStack {
            Text("Set \(set.setNumber)")
                .font(.subheadline.weight(.semibold))
            TrendBadge(trend: trend)
            Spacer(minLength: 8)
            Text("\(WeightFormatter.string(set.weight))kg × \(set.reps)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
    }
}

#Preview {
    struct Demo: View {
        @State private var isExpanded = true
        var body: some View {
            Form {
                SetEditorRow(
                    set: SetEntry(setNumber: 1, weight: 62.5, reps: 8),
                    trend: .improved,
                    isExpanded: $isExpanded
                )
            }
        }
    }
    return Demo()
}

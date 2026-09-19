//
//  SetRow.swift
//  PLog
//
//  One set on the session screen. Collapsed it's a one-line summary with a trend badge;
//  tap it to reveal the weight and reps steppers right below, in the same row. Edits bind
//  straight into the model — there's no separate save step.
//

import SwiftUI
import SwiftData

struct SetRow: View {
    /// `@Bindable` gives the steppers two-way bindings into the SwiftData model.
    @Bindable var set: SetEntry
    let trend: ProgressTrend
    /// Controlled by the parent so only one set is expanded at a time (accordion-style) —
    /// see `DayDetailView.expandedSetID`.
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                summary
            }
            // Keeps the List row highlight, but text resolves against the label color rather
            // than the accent tint the default button style applies to its label.
            .tint(.primary)
            .accessibilityAddTraits(isExpanded ? [.isSelected] : [])
            .accessibilityHint("Double-tap to edit")

            if isExpanded {
                HStack(alignment: .top, spacing: 24) {
                    NumberStepper(title: "Weight", value: $set.weight, step: 2.5, range: 0...500, unit: "kg")
                    NumberStepper(title: "Reps", intValue: $set.reps, range: 0...100)
                }
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private var summary: some View {
        HStack {
            Text("Set \(set.setNumber)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            TrendBadge(trend: trend)
            Spacer(minLength: 8)
            Text("\(WeightFormatter.string(set.weight)) kg × \(set.reps)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    struct Demo: View {
        @State private var isExpanded = true
        var body: some View {
            List {
                SetRow(
                    set: SetEntry(setNumber: 1, weight: 62.5, reps: 8),
                    trend: .improved,
                    isExpanded: $isExpanded
                )
            }
        }
    }
    return Demo()
}

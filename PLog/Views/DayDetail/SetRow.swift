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

    @Environment(\.dynamicTypeSize) private var typeSize

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
                // Side by side, stacked only at accessibility type sizes. Not `ViewThatFits`:
                // it judges by *ideal* width and ignores the number's `minimumScaleFactor`,
                // so a wider value like 102.5 silently tipped the pair into the stack.
                Group {
                    if typeSize.isAccessibilitySize {
                        VStack(spacing: 16) { steppers }
                    } else {
                        HStack(alignment: .top, spacing: 16) { steppers }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 4)
                // Fade in, but vanish instantly on collapse: the List row's height closes
                // faster than a fade runs, so a fading removal left the labels hanging over
                // the next row (or, with a move transition, sliding over the header).
                .transition(.asymmetric(insertion: .opacity, removal: .identity))
            }
        }
        .padding(.vertical, 4)
        .clipped()
    }

    @ViewBuilder
    private var steppers: some View {
        NumberStepper(title: "Weight", value: $set.weight, step: 2.5, range: 0...500, unit: "kg")
        NumberStepper(title: "Reps", intValue: $set.reps, range: 0...100)
    }

    private var summary: some View {
        HStack {
            if typeSize.isAccessibilitySize {
                // Stacked at accessibility sizes so the numbers don't wrap word by word.
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        setLabel
                        TrendBadge(trend: trend)
                    }
                    numbers
                }
                Spacer(minLength: 8)
            } else {
                setLabel
                TrendBadge(trend: trend)
                Spacer(minLength: 8)
                numbers
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .contentShape(Rectangle())
    }

    private var setLabel: some View {
        Text("Set \(set.setNumber)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    private var numbers: some View {
        Text("\(WeightFormatter.string(set.weight)) kg × \(set.reps)")
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
            .contentTransition(.numericText())
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

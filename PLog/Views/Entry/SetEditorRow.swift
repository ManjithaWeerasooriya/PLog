//
//  SetEditorRow.swift
//  PLog
//
//  One editable set in the quick-entry screen: weight & reps steppers and a live
//  progressive-overload badge versus the previous session. A set counts as "added" simply
//  by existing in the list — there's no separate completion toggle.
//

import SwiftUI

struct SetEditorRow: View {
    /// `@Bindable` gives us two-way bindings into the SwiftData model for the steppers.
    @Bindable var set: SetEntry
    let trend: ProgressTrend

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Set \(set.setNumber)")
                    .font(.subheadline.weight(.semibold))
                TrendBadge(trend: trend)
                Spacer(minLength: 0)
            }

            // Compact button/label sizing so two steppers fit side by side inside an
            // inset-grouped Form row without clipping (default sizing is too wide here).
            HStack(spacing: 16) {
                ValueStepper(
                    title: "Weight",
                    value: $set.weight,
                    step: 2.5,
                    range: 0...500,
                    unit: "kg",
                    buttonSize: 34,
                    valueMinWidth: 50
                )
                ValueStepper(
                    title: "Reps",
                    intValue: $set.reps,
                    range: 0...100,
                    buttonSize: 34,
                    valueMinWidth: 44
                )
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    Form {
        SetEditorRow(set: SetEntry(setNumber: 1, weight: 62.5, reps: 8), trend: .improved)
    }
}

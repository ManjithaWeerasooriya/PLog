//
//  SetEditorRow.swift
//  PLog
//
//  One editable set in the quick-entry screen: weight & reps steppers, completion toggle,
//  and a live progressive-overload badge versus the previous session.
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
                Spacer()
                Button {
                    withAnimation(.snappy) { set.completed.toggle() }
                } label: {
                    Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(set.completed ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 20) {
                ValueStepper(title: "Weight", value: $set.weight, step: 2.5, range: 0...500, unit: "kg")
                ValueStepper(title: "Reps", intValue: $set.reps, range: 0...100)
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

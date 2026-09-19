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

    /// Local text buffer for the weight field, seeded once from the model in `init` (not
    /// re-synced from `set.weight` afterwards). Re-deriving the displayed text from the model
    /// on every keystroke would reformat mid-entry (e.g. `WeightFormatter` drops a trailing
    /// "." the instant it's typed), making it impossible to type a decimal like "62.5". Since
    /// this field is the only writer of `set.weight` while this row is alive, one-way seeding
    /// is safe — see the `AddExerciseView` "seed from init" note in AGENT.md.
    @State private var weightText: String
    @FocusState private var weightFieldFocused: Bool

    init(set: SetEntry, trend: ProgressTrend, isExpanded: Binding<Bool>) {
        self._set = Bindable(wrappedValue: set)
        self.trend = trend
        self._isExpanded = isExpanded
        self._weightText = State(initialValue: WeightFormatter.string(set.weight))
    }

    var body: some View {
        VStack(spacing: 8) {
            header
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy) { isExpanded.toggle() }
                }

            if isExpanded {
                HStack(spacing: 20) {
                    weightField
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

    private var weightField: some View {
        VStack(spacing: 2) {
            Text("Weight")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.body.monospacedDigit())
                    .focused($weightFieldFocused)
                    .onChange(of: weightText) { _, newValue in
                        if let parsed = Double(newValue.replacingOccurrences(of: ",", with: ".")), parsed >= 0 {
                            set.weight = parsed
                        }
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { weightFieldFocused = false }
                        }
                    }
                Text("kg")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .frame(width: 120)
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

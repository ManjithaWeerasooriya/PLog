//
//  ValueStepper.swift
//  PLog
//
//  A fast, tappable +/- stepper optimized for gym use — big touch targets, no free typing
//  required. Works on any Double value with a configurable step; a reps convenience wraps Int.
//

import SwiftUI

struct ValueStepper: View {
    let title: String
    @Binding var value: Double
    var step: Double = 2.5
    var range: ClosedRange<Double> = 0...10_000
    var unit: String? = nil
    /// Diameter of the +/- buttons. Shrink for rows that must fit two steppers side by side.
    var buttonSize: CGFloat = 40
    /// Minimum width reserved for the value label.
    var valueMinWidth: CGFloat = 70
    /// How to render the current value (e.g. drop trailing ".0").
    var format: (Double) -> String = { WeightFormatter.string($0) }

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                stepButton(systemName: "minus", disabled: value - step < range.lowerBound) {
                    value = max(range.lowerBound, value - step)
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(format(value))
                        .font(.title2.monospacedDigit().weight(.semibold))
                        .contentTransition(.numericText())
                    if let unit {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minWidth: valueMinWidth)

                stepButton(systemName: "plus", disabled: value + step > range.upperBound) {
                    value = min(range.upperBound, value + step)
                }
            }
        }
    }

    private func stepButton(systemName: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { action() }
        } label: {
            Image(systemName: systemName)
                .font(.headline)
                .frame(width: buttonSize, height: buttonSize)
                .background(.tint.opacity(0.15), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }
}

extension ValueStepper {
    /// Convenience initializer for an integer value (e.g. reps).
    init(
        title: String,
        intValue: Binding<Int>,
        step: Int = 1,
        range: ClosedRange<Int> = 0...999,
        unit: String? = nil,
        buttonSize: CGFloat = 40,
        valueMinWidth: CGFloat = 70
    ) {
        self.title = title
        self._value = Binding(
            get: { Double(intValue.wrappedValue) },
            set: { intValue.wrappedValue = Int($0.rounded()) }
        )
        self.step = Double(step)
        self.range = Double(range.lowerBound)...Double(range.upperBound)
        self.unit = unit
        self.buttonSize = buttonSize
        self.valueMinWidth = valueMinWidth
        self.format = { String(Int($0)) }
    }
}

#Preview {
    struct Demo: View {
        @State private var weight = 62.5
        @State private var reps = 8
        var body: some View {
            HStack(spacing: 24) {
                ValueStepper(title: "Weight", value: $weight, step: 2.5, unit: "kg")
                ValueStepper(title: "Reps", intValue: $reps)
            }
            .padding()
        }
    }
    return Demo()
}

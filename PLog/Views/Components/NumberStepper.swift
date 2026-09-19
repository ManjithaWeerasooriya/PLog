//
//  NumberStepper.swift
//  PLog
//
//  The app's numeric input for weight, reps, sets, age, height… A big ⊖ / number / ⊕ control:
//  tap a button to step, hold it to repeat (accelerating), tap the number to type an exact
//  value. Every step ticks a haptic. Replaced the old wheel picker, which was the wrong tool
//  for nudging a number you already know and fought the enclosing List for scroll gestures.
//

import SwiftUI

struct NumberStepper: View {
    enum Style {
        /// Title above, large number between the buttons. For set rows and plan slots.
        case hero
        /// A single form row: title leading, compact control trailing. For Settings.
        case row
    }

    let title: String
    @Binding var value: Double
    var step: Double = 1
    var range: ClosedRange<Double> = 0...999
    var unit: String? = nil
    var style: Style = .hero
    /// How to render the number (e.g. drop a trailing ".0").
    var format: (Double) -> String = { WeightFormatter.string($0) }
    /// Keyboard for direct entry; `.numberPad` for integer values.
    var keyboard: UIKeyboardType = .decimalPad

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Direct-entry state. The text is seeded once from `value` when editing begins, not
    /// re-derived on every keystroke — reformatting mid-entry would drop a just-typed "."
    /// and make "62.5" impossible to type.
    @State private var isTyping = false
    @State private var draft = ""
    @FocusState private var draftFocused: Bool

    var body: some View {
        Group {
            switch style {
            case .hero: heroLayout
            case .row: rowLayout
            }
        }
        .sensoryFeedback(.increase, trigger: value) { old, new in new > old }
        .sensoryFeedback(.decrease, trigger: value) { old, new in new < old }
        .onChange(of: draftFocused) { _, focused in
            if !focused { commitDraft() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValueText)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: apply(step)
            case .decrement: apply(-step)
            @unknown default: break
            }
        }
    }

    // MARK: - Layouts

    private var heroLayout: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            HStack(spacing: 12) {
                stepButton(systemImage: "minus", delta: -step)
                numberView(font: .system(.title, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                stepButton(systemImage: "plus", delta: step)
            }
            if let unit {
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var rowLayout: some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 8) {
                stepButton(systemImage: "minus", delta: -step, size: 32)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    numberView(font: .body.weight(.semibold))
                    if let unit {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minWidth: 64)
                stepButton(systemImage: "plus", delta: step, size: 32)
            }
        }
    }

    // MARK: - Number

    @ViewBuilder
    private func numberView(font: Font) -> some View {
        if isTyping {
            TextField("", text: $draft)
                .keyboardType(keyboard)
                .multilineTextAlignment(.center)
                .font(font.monospacedDigit())
                .focused($draftFocused)
                .submitLabel(.done)
                .onSubmit { draftFocused = false }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { draftFocused = false }
                    }
                }
        } else {
            Button {
                draft = format(value)
                isTyping = true
                draftFocused = true
            } label: {
                Text(format(value))
                    .font(font.monospacedDigit())
                    .foregroundStyle(.primary)
                    .contentTransition(reduceMotion ? .identity : .numericText(value: value))
                    .animation(reduceMotion ? nil : .snappy, value: value)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Step buttons

    private func stepButton(systemImage: String, delta: Double, size: CGFloat = 44) -> some View {
        RepeatButton(size: size) {
            apply(delta)
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
        }
        .disabled(delta > 0 ? value >= range.upperBound : value <= range.lowerBound)
    }

    private func apply(_ delta: Double) {
        value = min(max(value + delta, range.lowerBound), range.upperBound)
    }

    private func commitDraft() {
        defer { isTyping = false }
        let normalized = draft.replacingOccurrences(of: ",", with: ".")
        guard let parsed = Double(normalized) else { return }
        value = min(max(parsed, range.lowerBound), range.upperBound)
    }

    private var accessibilityValueText: String {
        [format(value), unit].compactMap { $0 }.joined(separator: " ")
    }
}

extension NumberStepper {
    /// Convenience initializer for an integer value (e.g. reps, sets, age).
    init(
        title: String,
        intValue: Binding<Int>,
        step: Int = 1,
        range: ClosedRange<Int> = 0...999,
        unit: String? = nil,
        style: Style = .hero
    ) {
        self.title = title
        self._value = Binding(
            get: { Double(intValue.wrappedValue) },
            set: { intValue.wrappedValue = Int($0.rounded()) }
        )
        self.step = Double(step)
        self.range = Double(range.lowerBound)...Double(range.upperBound)
        self.unit = unit
        self.style = style
        self.format = { String(Int($0.rounded())) }
        self.keyboard = .numberPad
    }
}

/// A round button that fires once on tap and repeats while held, accelerating after a
/// moment — the feel of holding a physical stepper. The pressed state comes from the
/// `ButtonStyle` (set on touch-down, and reliably cleared if the enclosing List's scroll
/// cancels the touch), which is what starts and stops the repeat loop.
private struct RepeatButton<Label: View>: View {
    let size: CGFloat
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isPressed = false
    @State private var repeatTask: Task<Void, Never>?
    /// True once the hold loop has fired at least once, so the tap-up action doesn't add
    /// one more step on top of the repeats.
    @State private var didRepeat = false

    var body: some View {
        Button {
            if !didRepeat { action() }
        } label: {
            label()
        }
        .buttonStyle(RoundPressStyle(size: size, isPressed: $isPressed))
        .onChange(of: isPressed) { _, pressed in
            pressed ? startRepeating() : stopRepeating()
        }
    }

    private func startRepeating() {
        didRepeat = false
        repeatTask?.cancel()
        repeatTask = Task { @MainActor in
            try? await Task.sleep(for: RepeatTiming.holdDelay)
            var ticks = 0
            while !Task.isCancelled {
                didRepeat = true
                action()
                ticks += 1
                let interval = ticks < RepeatTiming.accelerateAfter ? RepeatTiming.slowInterval : RepeatTiming.fastInterval
                try? await Task.sleep(for: interval)
            }
        }
    }

    private func stopRepeating() {
        repeatTask?.cancel()
        repeatTask = nil
    }
}

/// Hold-to-repeat timing (kept outside the generic button, which can't hold static state).
private enum RepeatTiming {
    static let holdDelay: Duration = .milliseconds(400)
    static let slowInterval: Duration = .milliseconds(80)
    static let fastInterval: Duration = .milliseconds(40)
    /// Ticks at the slow interval (~1 s) before speeding up.
    static let accelerateAfter = 12
}

/// Circular fill, instant press feedback, and a binding that mirrors `isPressed` outward.
private struct RoundPressStyle: ButtonStyle {
    let size: CGFloat
    @Binding var isPressed: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? Color.primary : Color.secondary)
            .frame(width: size, height: size)
            .background(.fill.secondary, in: Circle())
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.spring(duration: 0.18, bounce: 0), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
            }
    }
}

#Preview("Hero") {
    struct Demo: View {
        @State private var weight = 62.5
        @State private var reps = 8
        var body: some View {
            List {
                HStack(spacing: 24) {
                    NumberStepper(title: "Weight", value: $weight, step: 2.5, range: 0...500, unit: "kg")
                    NumberStepper(title: "Reps", intValue: $reps, range: 0...100)
                }
                .padding(.vertical, 8)
            }
        }
    }
    return Demo()
}

#Preview("Row") {
    struct Demo: View {
        @State private var age = 25
        @State private var weight = 70.0
        var body: some View {
            Form {
                NumberStepper(title: "Age", intValue: $age, range: 10...100, unit: "yrs", style: .row)
                NumberStepper(title: "Weight", value: $weight, step: 0.5, range: 30...300, unit: "kg", style: .row)
            }
        }
    }
    return Demo()
}

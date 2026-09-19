//
//  NameEntrySheet.swift
//  PLog
//
//  A small sheet that asks for a name before something is created (a plan, a plan day) —
//  the Reminders "New List" pattern. Nothing is inserted until the user confirms, so
//  backing out never leaves an unnamed placeholder record behind.
//

import SwiftUI

struct NameEntrySheet: View {
    let title: String
    let placeholder: String
    var confirmLabel: String = "Create"
    /// Called with the trimmed, non-empty name; the sheet dismisses itself afterward.
    let onConfirm: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var nameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(placeholder, text: $name)
                    .textInputAutocapitalization(.words)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit(confirm)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmLabel, action: confirm)
                        .fontWeight(.semibold)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear { nameFocused = true }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func confirm() {
        guard !trimmedName.isEmpty else { return }
        onConfirm(trimmedName)
        dismiss()
    }
}

#Preview {
    NameEntrySheet(title: "New Plan", placeholder: "e.g. Push / Pull / Legs") { _ in }
}

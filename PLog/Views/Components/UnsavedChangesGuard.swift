//
//  UnsavedChangesGuard.swift
//  PLog
//
//  Shared "confirm before leaving" behavior for pushed detail screens that live-bind
//  @Model properties (DayDetailView, PlanDetailView, PlanDayDetailView). Without this,
//  tapping the system back button silently applies whatever's on screen — there's no save
//  step to skip and no way to back out of an accidental edit.
//
//  Replaces the default back button with one that pops immediately when nothing changed,
//  or asks Save / Discard Changes / Cancel when something did. Also shows an `UnsavedTag`
//  next to the title while dirty.
//

import SwiftUI

private struct UnsavedChangesGuard: ViewModifier {
    let title: String
    let hasChanges: Bool
    let onSave: () -> Void
    let onDiscard: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var confirmingLeave = false

    func body(content: Content) -> some View {
        content
            // Kept in sync for accessibility/system use (e.g. the label a further-pushed
            // screen's own back button would show); the visible title is the principal
            // toolbar item below, since a plain String can't carry the tag.
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        if hasChanges {
                            confirmingLeave = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.backward")
                            Text("Back")
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text(title).font(.headline)
                        if hasChanges { UnsavedTag() }
                    }
                }
            }
            // `.alert`, not `.confirmationDialog` — see the note on PlanDetailView's "End
            // this plan?" alert for why.
            .alert("Save Changes?", isPresented: $confirmingLeave) {
                Button("Save") {
                    onSave()
                    dismiss()
                }
                Button("Discard Changes", role: .destructive) {
                    onDiscard()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You have unsaved changes to \(title.isEmpty ? "this screen" : title).")
            }
    }
}

extension View {
    /// Intercepts the back button on a pushed screen: pops immediately when `hasChanges` is
    /// false, otherwise offers Save / Discard Changes / Cancel. `onSave`/`onDiscard` only
    /// need to handle the fields this screen edits — SwiftData's autosave and other screens'
    /// own guards are unaffected.
    func confirmBeforeLeaving(
        title: String,
        hasChanges: Bool,
        onSave: @escaping () -> Void,
        onDiscard: @escaping () -> Void
    ) -> some View {
        modifier(UnsavedChangesGuard(title: title, hasChanges: hasChanges, onSave: onSave, onDiscard: onDiscard))
    }
}

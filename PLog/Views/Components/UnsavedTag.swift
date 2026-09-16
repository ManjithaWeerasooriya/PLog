//
//  UnsavedTag.swift
//  PLog
//
//  A small capsule tag shown next to a title while a screen has unsaved edits — same
//  visual language as `PlanStatusPill`/`CategoryChip`/`TrendBadge`, so it reads as part of
//  the app rather than a bolted-on indicator.
//

import SwiftUI

struct UnsavedTag: View {
    var body: some View {
        Text("Unsaved")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.15), in: Capsule())
    }
}

#Preview {
    UnsavedTag()
        .padding()
}

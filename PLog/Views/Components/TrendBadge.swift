//
//  TrendBadge.swift
//  PLog
//
//  A small colored pill that shows whether a set/session beat the previous one —
//  green for improvement, red for regression.
//

import SwiftUI

struct TrendBadge: View {
    let trend: ProgressTrend
    var text: String? = nil

    var body: some View {
        if trend != .none, let symbol = trend.systemImage {
            HStack(spacing: 3) {
                Image(systemName: symbol)
                if let text {
                    Text(text)
                }
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(trend.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(trend.color.opacity(0.15), in: Capsule())
        }
    }
}

/// A tinted chip for a muscle-group category.
struct CategoryChip: View {
    let category: MuscleGroup

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.systemImage)
            Text(category.displayName)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(category.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.15), in: Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        TrendBadge(trend: .improved, text: "Improved")
        TrendBadge(trend: .regressed, text: "Down")
        TrendBadge(trend: .matched, text: "Same")
        CategoryChip(category: .chest)
        CategoryChip(category: .legs)
    }
    .padding()
}

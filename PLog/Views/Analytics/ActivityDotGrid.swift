//
//  ActivityDotGrid.swift
//  PLog
//
//  A compact "did I train?" grid: one block per month, weeks as columns and weekdays as
//  rows, with a bright dot on every training day. The same cells drive the Calendar tab.
//

import SwiftUI
import SwiftData

struct ActivityMonth: Identifiable {
    /// Start of the month.
    let id: Date
    let label: String
    let weeks: [[CalendarDayCell?]]
}

struct ActivityDotGrid: View {
    let months: [ActivityMonth]

    private let dotSize: CGFloat = 7
    private let spacing: CGFloat = 5

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(months) { month in
                VStack(spacing: 10) {
                    Text(month.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: spacing) {
                        ForEach(Array(month.weeks.enumerated()), id: \.offset) { _, week in
                            VStack(spacing: spacing) {
                                ForEach(Array(week.enumerated()), id: \.offset) { _, cell in
                                    dot(for: cell)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func dot(for cell: CalendarDayCell?) -> some View {
        Circle()
            .fill(color(for: cell))
            .frame(width: dotSize, height: dotSize)
    }

    private func color(for cell: CalendarDayCell?) -> Color {
        guard let cell else { return .clear }
        switch cell.status {
        case .trained: return .accentColor
        case .rest: return Color.primary.opacity(0.18)
        case .pending: return Color.primary.opacity(0.18)
        case .inactive: return Color.primary.opacity(0.06)
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let months = (0..<3).reversed().compactMap { back -> ActivityMonth? in
        guard let month = calendar.date(byAdding: .month, value: -back, to: .now) else { return nil }
        let start = WorkoutCalendar.startOfMonth(month)
        let cells = WorkoutCalendar.monthCells(
            for: start,
            workouts: [SampleData.recentDay],
            historyStart: calendar.date(byAdding: .month, value: -2, to: .now)
        )
        return ActivityMonth(
            id: start,
            label: start.formatted(.dateTime.month(.abbreviated)),
            weeks: WorkoutCalendar.weeks(cells)
        )
    }
    return AnalyticsCard {
        ActivityDotGrid(months: months)
    }
    .padding()
    .modelContainer(SampleData.container)
}

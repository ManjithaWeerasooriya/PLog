//
//  WorkoutCalendar.swift
//  PLog
//
//  Lays a month of logged sessions out as a calendar grid, classifying every date as a
//  training day, a rest day, or not yet relevant (in the future, or before any history).
//  Shared by the Calendar tab and the Analytics activity grid so both agree on what counts
//  as a rest day.
//

import Foundation

/// How a calendar date relates to the user's training.
enum WorkoutDayStatus: Equatable {
    /// One or more sessions were logged on this date.
    case trained(sessions: Int)
    /// A past date inside the user's history with no session logged.
    case rest
    /// Today, with nothing logged yet — not a rest day until the day is over.
    case pending
    /// A future date, or one before the user's first session / plan start.
    case inactive
}

struct CalendarDayCell: Identifiable {
    /// Start of the calendar day.
    let date: Date
    let dayNumber: Int
    let status: WorkoutDayStatus
    let isToday: Bool
    /// Sessions logged on this date, earliest first.
    let workouts: [WorkoutDay]

    var id: Date { date }
}

enum WorkoutCalendar {
    static func startOfMonth(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))
            ?? calendar.startOfDay(for: date)
    }

    /// When the user's history begins: their earliest session or earliest plan start,
    /// whichever is first. `nil` means there's no history yet, so nothing is a rest day —
    /// a brand-new install shouldn't open onto a month full of "rest days".
    static func historyStart(
        workouts: [WorkoutDay],
        plans: [WorkoutPlan],
        calendar: Calendar = .current
    ) -> Date? {
        let candidates = workouts.map(\.date) + plans.compactMap(\.startedAt)
        return candidates.min().map { calendar.startOfDay(for: $0) }
    }

    /// Cells for a month grid, oldest first. Leading `nil`s pad the first week so day 1 lands
    /// under its weekday column.
    static func monthCells(
        for month: Date,
        workouts: [WorkoutDay],
        historyStart: Date?,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> [CalendarDayCell?] {
        let first = startOfMonth(month, calendar: calendar)
        guard let dayCount = calendar.range(of: .day, in: .month, for: first)?.count else { return [] }

        let byDay = Dictionary(grouping: workouts) { calendar.startOfDay(for: $0.date) }
        let todayStart = calendar.startOfDay(for: today)
        let leadingBlanks = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7

        var cells: [CalendarDayCell?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<dayCount {
            guard let date = calendar.date(byAdding: .day, value: offset, to: first) else { continue }
            let sessions = (byDay[date] ?? []).sorted { $0.date < $1.date }
            cells.append(
                CalendarDayCell(
                    date: date,
                    dayNumber: offset + 1,
                    status: status(for: date, sessions: sessions.count, historyStart: historyStart, today: todayStart),
                    isToday: date == todayStart,
                    workouts: sessions
                )
            )
        }
        return cells
    }

    /// Splits grid cells into 7-wide weeks, padding the last one with `nil`.
    static func weeks(_ cells: [CalendarDayCell?]) -> [[CalendarDayCell?]] {
        stride(from: 0, to: cells.count, by: 7).map { start in
            var week = Array(cells[start..<min(start + 7, cells.count)])
            week.append(contentsOf: Array(repeating: nil, count: 7 - week.count))
            return week
        }
    }

    /// One-letter weekday labels starting from the calendar's first weekday (Mon or Sun
    /// depending on locale), matching the column order `monthCells` produces.
    static func weekdaySymbols(calendar: Calendar = .current) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private static func status(
        for day: Date,
        sessions: Int,
        historyStart: Date?,
        today: Date
    ) -> WorkoutDayStatus {
        if sessions > 0 { return .trained(sessions: sessions) }
        if day == today { return .pending }
        guard day < today, let historyStart, day >= historyStart else { return .inactive }
        return .rest
    }
}

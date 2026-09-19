//
//  CalendarView.swift
//  PLog
//
//  The month calendar, pushed from the Progress tab's activity card: one month at a time
//  with training days filled in. Tapping a date lists the sessions logged that day (or says
//  it was a rest day). Plain stack content — the owning `NavigationStack` (and the
//  `WorkoutDay` destination its rows push) lives in `AnalyticsView`.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \WorkoutDay.date, order: .reverse) private var workouts: [WorkoutDay]
    @Query private var plans: [WorkoutPlan]

    @State private var displayedMonth = WorkoutCalendar.startOfMonth(.now)
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)

    private let calendar = Calendar.current

    // Scaled with the type size so the day circles and dots keep pace with their numbers.
    @ScaledMetric(relativeTo: .callout) private var cellSize = 34
    @ScaledMetric(relativeTo: .callout) private var statusDotSize = 5

    var body: some View {
        List {
            Section {
                monthHeader
                monthGrid
            }
            .listRowSeparator(.hidden)

            Section(selectedDayTitle) {
                selectedDayContent
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Today", action: jumpToToday)
                    .disabled(isShowingCurrentMonth && calendar.isDateInToday(selectedDate))
            }
        }
    }

    // MARK: - Month grid

    private var monthHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Button { shiftMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(displayedMonth.monthYearLabel)
                    .font(.title3.weight(.semibold))
                Spacer()
                Button { shiftMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(isShowingCurrentMonth)
            }
            .buttonStyle(.borderless)

            Text(monthSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var monthGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        return VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 0) {
                // Enumerated: "T" and "S" each appear twice, so the symbol itself isn't a
                // usable identity.
                ForEach(Array(WorkoutCalendar.weekdaySymbols(calendar: calendar).enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            LazyVGrid(columns: columns, spacing: 6) {
                // Enumerated so the leading blank cells (nil) still get a stable identity.
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, cell in
                    if let cell {
                        dayCell(cell)
                    } else {
                        Color.clear.frame(height: cellSize + 10)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    /// iOS Calendar's language: a trained day is a filled accent circle, today is an accent
    /// number, the selected day is a filled label-coloured circle with an inverted number
    /// (plus a small accent dot beneath when it was also trained). Rest days get nothing —
    /// absence is the marker, so the grid reads at a glance.
    private func dayCell(_ cell: CalendarDayCell) -> some View {
        let isSelected = cell.date == selectedDate
        let isTrained: Bool = {
            if case .trained = cell.status { return true }
            return false
        }()

        return Button {
            withAnimation(.snappy) { selectedDate = cell.date }
        } label: {
            VStack(spacing: 3) {
                Text("\(cell.dayNumber)")
                    .font(.callout.weight(cell.isToday || isSelected || isTrained ? .semibold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(numberColor(for: cell, isSelected: isSelected, isTrained: isTrained))
                    .frame(width: cellSize, height: cellSize)
                    .background {
                        if isSelected {
                            Circle().fill(Color.primary)
                        } else if isTrained {
                            Circle().fill(Color.accentColor)
                        }
                    }

                Circle()
                    .fill(isSelected && isTrained ? Color.accentColor : Color.clear)
                    .frame(width: statusDotSize, height: statusDotSize)
            }
            .frame(maxWidth: .infinity, minHeight: max(44, cellSize + 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: cell))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func numberColor(for cell: CalendarDayCell, isSelected: Bool, isTrained: Bool) -> Color {
        if isSelected { return Color(uiColor: .systemBackground) }
        if isTrained { return .white }
        switch cell.status {
        case .inactive: return Color(uiColor: .tertiaryLabel)
        case .rest, .pending, .trained: return cell.isToday ? .accentColor : .primary
        }
    }

    // MARK: - Selected day

    @ViewBuilder
    private var selectedDayContent: some View {
        switch selectedCell?.status {
        case .trained:
            ForEach(selectedCell?.workouts ?? []) { workout in
                NavigationLink(value: workout) {
                    WorkoutDayRow(day: workout)
                }
            }
        case .rest:
            Label("Rest day", systemImage: "bed.double")
                .foregroundStyle(.secondary)
        case .pending:
            Label("Nothing logged yet today", systemImage: "sun.max")
                .foregroundStyle(.secondary)
        case .inactive, .none:
            Label(
                selectedDate > Date.now ? "Upcoming" : "Before your first workout",
                systemImage: "calendar"
            )
            .foregroundStyle(.secondary)
        }
    }

    private var selectedDayTitle: String {
        if calendar.isDateInToday(selectedDate) { return "Today" }
        if calendar.isDateInYesterday(selectedDate) { return "Yesterday" }
        return selectedDate.weekdayDateLabel
    }

    // MARK: - Derived data

    private var historyStart: Date? {
        WorkoutCalendar.historyStart(workouts: workouts, plans: plans, calendar: calendar)
    }

    private var monthCells: [CalendarDayCell?] {
        WorkoutCalendar.monthCells(
            for: displayedMonth,
            workouts: workouts,
            historyStart: historyStart,
            calendar: calendar
        )
    }

    /// The selected date's cell, built on its own so it stays correct when the selection is
    /// in a month other than the one displayed.
    private var selectedCell: CalendarDayCell? {
        WorkoutCalendar.monthCells(
            for: selectedDate,
            workouts: workouts,
            historyStart: historyStart,
            calendar: calendar
        )
        .compactMap { $0 }
        .first { $0.date == selectedDate }
    }

    private var monthSummary: String {
        let cells = monthCells.compactMap { $0 }
        let trained = cells.filter { if case .trained = $0.status { return true } else { return false } }.count
        let rest = cells.filter { $0.status == .rest }.count
        if trained == 0 && rest == 0 { return "No training logged" }
        return "\(trained) workout\(trained == 1 ? "" : "s") · \(rest) rest day\(rest == 1 ? "" : "s")"
    }

    private var isShowingCurrentMonth: Bool {
        displayedMonth == WorkoutCalendar.startOfMonth(.now, calendar: calendar)
    }

    private func accessibilityLabel(for cell: CalendarDayCell) -> String {
        let date = cell.date.weekdayDateLabel
        switch cell.status {
        case .trained(let sessions): return "\(date), \(sessions) workout\(sessions == 1 ? "" : "s")"
        case .rest: return "\(date), rest day"
        case .pending: return "\(date), nothing logged yet"
        case .inactive: return date
        }
    }

    // MARK: - Actions

    private func shiftMonth(by months: Int) {
        guard let next = calendar.date(byAdding: .month, value: months, to: displayedMonth) else { return }
        withAnimation(.snappy) { displayedMonth = WorkoutCalendar.startOfMonth(next, calendar: calendar) }
    }

    private func jumpToToday() {
        withAnimation(.snappy) {
            displayedMonth = WorkoutCalendar.startOfMonth(.now, calendar: calendar)
            selectedDate = calendar.startOfDay(for: .now)
        }
    }
}

#Preview {
    NavigationStack {
        CalendarView()
            .navigationDestination(for: WorkoutDay.self) { day in
                DayDetailView(day: day)
            }
    }
    .modelContainer(SampleData.container)
}

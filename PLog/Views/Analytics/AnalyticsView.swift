//
//  AnalyticsView.swift
//  PLog
//
//  The Progress tab (the type keeps its old name — `ProgressView` is SwiftUI's): a card
//  dashboard — active-plan progress, body weight, a three-month activity grid that pushes the
//  full calendar, volume lifted this week, then weekly trend charts, a muscle-group split, and
//  the user's best lifts. Everything is derived from `@Query` results via `WorkoutStats`.
//

import SwiftUI
import SwiftData
import Charts

/// How far back the weekly trend charts look.
enum AnalyticsRange: Int, CaseIterable, Identifiable {
    case eightWeeks = 8
    case twelveWeeks = 12
    case halfYear = 26

    var id: Int { rawValue }
    var weeks: Int { rawValue }
    var label: String { "\(rawValue)W" }
}

/// Non-model screens reachable from the Progress stack.
enum ProgressRoute: Hashable {
    case calendar
}

struct AnalyticsView: View {
    @Query(sort: \WorkoutDay.date, order: .reverse) private var workouts: [WorkoutDay]
    @Query private var plans: [WorkoutPlan]
    @Query private var profiles: [UserProfile]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var range: AnalyticsRange = .twelveWeeks

    // Scaled with the type size so the ring and legend dots keep pace with their labels.
    // The donut stays fixed: it's a chart, and at accessibility sizes its legend drops
    // beneath it instead.
    @ScaledMetric(relativeTo: .title2) private var ringSize = 64
    @ScaledMetric(relativeTo: .caption) private var legendDot = 7
    private let donutSize: CGFloat = 136

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    emptyState
                } else {
                    dashboard
                }
            }
            .navigationTitle("Progress")
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseHistoryView(exercise: exercise)
            }
            .navigationDestination(for: ProgressRoute.self) { route in
                switch route {
                case .calendar:
                    CalendarView()
                }
            }
            // The calendar's session rows push through this stack.
            .navigationDestination(for: WorkoutDay.self) { day in
                DayDetailView(day: day)
            }
        }
    }

    // MARK: - Layout

    private var dashboard: some View {
        ScrollView {
            // 16-pt gaps between cards (8-pt grid); 12 inside them.
            VStack(spacing: 16) {
                // Side by side while they fit; stacked at accessibility type sizes.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) {
                        planCard
                        bodyWeightCard
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    VStack(spacing: 16) {
                        planCard
                        bodyWeightCard
                    }
                }

                activityCard
                weekVolumeCard
                totalsRow

                trendsHeader
                weeklyVolumeCard
                sessionsCard
                muscleSplitCard
                bestLiftsCard
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Analytics Yet", systemImage: "chart.bar.xaxis")
        } description: {
            Text("Log a few workouts and your volume, consistency and best lifts will show up here.")
        }
    }

    // MARK: - Plan & body weight

    private var planCard: some View {
        AnalyticsCard {
            VStack(alignment: .leading, spacing: 12) {
                if let plan = activePlan {
                    let target = max(plan.days.count, 1)
                    let done = thisWeek?.sessions ?? 0
                    ProgressRing(progress: Double(done) / Double(target)) {
                        Text("\(done)")
                            .font(.title2.bold())
                            .monospacedDigit()
                    }
                    .frame(width: ringSize, height: ringSize)
                    Spacer(minLength: 0)
                    AnalyticsCardTitle(
                        title: plan.name.isEmpty ? "Plan" : plan.name,
                        subtitle: planSubtitle(for: plan, done: done, target: target)
                    )
                } else {
                    ProgressRing(progress: 0) {
                        Image(systemName: "pause.fill")
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: ringSize, height: ringSize)
                    Spacer(minLength: 0)
                    AnalyticsCardTitle(title: "No active plan", subtitle: "Start one in Library")
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private func planSubtitle(for plan: WorkoutPlan, done: Int, target: Int) -> String {
        var parts = ["\(done) of \(target) this week"]
        if let next = WorkoutLogger.suggestedNextDay(in: plan), !next.name.isEmpty {
            parts.append("Next: \(next.name)")
        }
        return parts.joined(separator: " · ")
    }

    private var bodyWeightCard: some View {
        AnalyticsCard {
            VStack(alignment: .leading, spacing: 12) {
                if let weight = profiles.first?.weightKg {
                    BigStat(value: WeightFormatter.string(weight), unit: "kg")
                } else {
                    BigStat(value: "—", unit: "kg")
                }
                Spacer(minLength: 0)
                AnalyticsCardTitle(
                    title: "Body weight",
                    subtitle: profiles.first?.weightKg == nil ? "Set it in Settings" : "From your profile"
                )
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: - Activity grid

    /// Tappable: pushes the full month calendar.
    private var activityCard: some View {
        NavigationLink(value: ProgressRoute.calendar) {
            AnalyticsCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        AnalyticsCardTitle(title: "Activity", subtitle: "Last 3 months")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    ActivityDotGrid(months: activityMonths)
                    HStack(spacing: 14) {
                        legendItem(color: .accentColor, text: "Workout")
                        legendItem(color: Color.primary.opacity(0.18), text: "Rest day")
                        Spacer()
                        Text("\(recentWorkoutCount) workout\(recentWorkoutCount == 1 ? "" : "s")")
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: legendDot, height: legendDot)
            Text(text)
        }
    }

    // MARK: - Last 7 days volume

    private var weekVolumeCard: some View {
        AnalyticsCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: "Volume lifted", subtitle: "Last 7 days") {
                    BigStat(value: WeightFormatter.volumeString(last7Volume), unit: "kg", style: .title)
                    if let change = WorkoutStats.percentChange(from: previous7Volume, to: last7Volume) {
                        TrendBadge(
                            trend: change > 0.5 ? .improved : (change < -0.5 ? .regressed : .matched),
                            text: "\(change > 0 ? "+" : "")\(Int(change.rounded()))% vs prior week"
                        )
                    }
                }

                Chart(last7Days) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Volume", day.volume)
                    )
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 72)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
        }
    }

    // MARK: - Totals

    private var totalsRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                totalStats
            }
            .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 16) {
                totalStats
            }
        }
    }

    @ViewBuilder
    private var totalStats: some View {
        miniStat(value: "\(workouts.count)", label: "Workouts")
        miniStat(value: WeightFormatter.volumeString(Double(totalSets)), label: "Sets")
        miniStat(value: "\(streak)", label: streak == 1 ? "Week streak" : "Weeks streak")
    }

    private func miniStat(value: String, label: String) -> some View {
        AnalyticsCard {
            VStack(alignment: .leading, spacing: 4) {
                BigStat(value: value, style: .title2)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: - Trends

    private var trendsHeader: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                trendsTitle
                Spacer()
                rangePicker
                    .fixedSize()
            }
            VStack(alignment: .leading, spacing: 8) {
                trendsTitle
                rangePicker
            }
        }
        .padding(.top, 8)
    }

    private var trendsTitle: some View {
        Text("Trends")
            .font(.title3.weight(.semibold))
    }

    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            ForEach(AnalyticsRange.allCases) { range in
                Text(range.label).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private var weeklyVolumeCard: some View {
        AnalyticsCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: "Weekly volume", subtitle: "kg lifted per week") {
                    BigStat(value: WeightFormatter.volumeString(averageWeeklyVolume), unit: "kg avg", style: .title2)
                }
                Chart(weekly) { week in
                    BarMark(
                        x: .value("Week", week.weekStart, unit: .weekOfYear),
                        y: .value("Volume", week.volume)
                    )
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(3)
                }
                .chartXAxis { weeklyAxis }
                .frame(height: 160)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
        }
    }

    private var sessionsCard: some View {
        AnalyticsCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: "Sessions per week", subtitle: "Consistency") {
                    BigStat(value: String(format: "%.1f", averageWeeklySessions), unit: "avg", style: .title2)
                }
                Chart {
                    ForEach(weekly) { week in
                        BarMark(
                            x: .value("Week", week.weekStart, unit: .weekOfYear),
                            y: .value("Sessions", week.sessions)
                        )
                        .foregroundStyle(Color.accentColor)
                        .cornerRadius(3)
                    }
                    if let target = activePlan?.days.count, target > 0 {
                        RuleMark(y: .value("Plan", target))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(.secondary)
                            .annotation(position: .top, alignment: .leading) {
                                Text("Plan: \(target)/wk")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .chartXAxis { weeklyAxis }
                .chartYAxis {
                    AxisMarks(values: Array(0...sessionsAxisMax)) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 160)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
        }
    }

    private var weeklyAxis: some AxisContent {
        AxisMarks(values: .stride(by: .weekOfYear, count: max(1, range.weeks / 4))) { _ in
            AxisGridLine()
            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
        }
    }

    // MARK: - Muscle split

    @ViewBuilder
    private var muscleSplitCard: some View {
        let split = muscleSplit
        let total = split.reduce(0) { $0 + $1.sets }
        AnalyticsCard {
            VStack(alignment: .leading, spacing: 12) {
                AnalyticsCardTitle(title: "Muscle groups", subtitle: "Sets in the last \(range.weeks) weeks")
                if split.isEmpty {
                    Text("No sets logged in this range.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 20) { muscleSplitContent(split, total: total) }
                        VStack(alignment: .leading, spacing: 16) { muscleSplitContent(split, total: total) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func muscleSplitContent(_ split: [WorkoutStats.MuscleGroupShare], total: Int) -> some View {
        Chart(split) { share in
            SectorMark(
                angle: .value("Sets", share.sets),
                innerRadius: .ratio(0.66),
                angularInset: 1.5
            )
            .foregroundStyle(share.group.color)
            .cornerRadius(3)
        }
        .chartLegend(.hidden)
        .frame(width: donutSize, height: donutSize)
        .overlay {
            VStack(spacing: 0) {
                Text("\(total)")
                    .font(.title2.bold())
                    .monospacedDigit()
                Text("sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            ForEach(split.prefix(5)) { share in
                HStack(spacing: 8) {
                    Circle().fill(share.group.color).frame(width: legendDot, height: legendDot)
                    Text(share.group.displayName)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int((Double(share.sets) / Double(max(total, 1)) * 100).rounded()))%")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            if split.count > 5 {
                Text("+\(split.count - 5) more")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    /// Title/subtitle leading with a stat trailing — or, when the stat no longer fits
    /// beside the title at large type sizes, the stat beneath it.
    private func cardHeader<Trailing: View>(
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top) {
                AnalyticsCardTitle(title: title, subtitle: subtitle)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) { trailing() }
            }
            VStack(alignment: .leading, spacing: 8) {
                AnalyticsCardTitle(title: title, subtitle: subtitle)
                VStack(alignment: .leading, spacing: 4) { trailing() }
            }
        }
    }

    // MARK: - Best lifts

    @ViewBuilder
    private var bestLiftsCard: some View {
        let lifts = bestLifts
        if !lifts.isEmpty {
            AnalyticsCard {
                VStack(alignment: .leading, spacing: 12) {
                    AnalyticsCardTitle(title: "Best lifts", subtitle: "Estimated one-rep max")
                    VStack(spacing: 0) {
                        ForEach(Array(lifts.enumerated()), id: \.element.id) { index, lift in
                            NavigationLink(value: lift.exercise) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lift.exercise.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Text(lift.exercise.category.displayName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    TrendBadge(trend: lift.trend)
                                    Text("\(WeightFormatter.string(lift.estimatedOneRepMax)) kg")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(.primary)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if index < lifts.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Derived data

    private var activePlan: WorkoutPlan? {
        plans.first(where: \.isActive)
    }

    private var weekly: [WorkoutStats.WeekSummary] {
        WorkoutStats.weeklySummaries(workouts: workouts, weeks: range.weeks, calendar: calendar)
    }

    private var thisWeek: WorkoutStats.WeekSummary? {
        WorkoutStats.weeklySummaries(workouts: workouts, weeks: 1, calendar: calendar).first
    }

    private var averageWeeklyVolume: Double {
        guard !weekly.isEmpty else { return 0 }
        return weekly.reduce(0) { $0 + $1.volume } / Double(weekly.count)
    }

    private var averageWeeklySessions: Double {
        guard !weekly.isEmpty else { return 0 }
        return Double(weekly.reduce(0) { $0 + $1.sessions }) / Double(weekly.count)
    }

    private var sessionsAxisMax: Int {
        let peak = weekly.map(\.sessions).max() ?? 0
        return max(peak, activePlan?.days.count ?? 0, 1)
    }

    private var last7Days: [WorkoutStats.DailyVolume] {
        WorkoutStats.dailyVolumes(workouts: workouts, days: 7, calendar: calendar)
    }

    private var last7Volume: Double {
        last7Days.reduce(0) { $0 + $1.volume }
    }

    private var previous7Volume: Double {
        let todayStart = calendar.startOfDay(for: .now)
        guard
            let end = calendar.date(byAdding: .day, value: -6, to: todayStart),
            let start = calendar.date(byAdding: .day, value: -7, to: end)
        else { return 0 }
        return WorkoutStats.workouts(workouts, from: start, before: end)
            .reduce(0) { $0 + WorkoutStats.volume(of: $1) }
    }

    private var totalSets: Int {
        workouts.reduce(0) { $0 + WorkoutStats.setCount(of: $1) }
    }

    private var streak: Int {
        WorkoutStats.weekStreak(workouts: workouts, calendar: calendar)
    }

    private var muscleSplit: [WorkoutStats.MuscleGroupShare] {
        guard let start = weekly.first?.weekStart else { return [] }
        return WorkoutStats.muscleGroupSplit(
            workouts: WorkoutStats.workouts(workouts, from: start, before: .distantFuture)
        )
    }

    private var bestLifts: [WorkoutStats.ExerciseBest] {
        WorkoutStats.bestLifts(exercises: exercises)
    }

    /// The current month and the two before it, oldest first.
    private var activityMonths: [ActivityMonth] {
        let historyStart = WorkoutCalendar.historyStart(workouts: workouts, plans: plans, calendar: calendar)
        let thisMonth = WorkoutCalendar.startOfMonth(.now, calendar: calendar)
        return (0..<3).reversed().compactMap { back in
            guard let month = calendar.date(byAdding: .month, value: -back, to: thisMonth) else { return nil }
            let cells = WorkoutCalendar.monthCells(
                for: month,
                workouts: workouts,
                historyStart: historyStart,
                calendar: calendar
            )
            return ActivityMonth(
                id: month,
                label: month.formatted(.dateTime.month(.abbreviated)),
                weeks: WorkoutCalendar.weeks(cells)
            )
        }
    }

    private var recentWorkoutCount: Int {
        activityMonths
            .flatMap(\.weeks)
            .flatMap { $0 }
            .compactMap { $0 }
            .filter { if case .trained = $0.status { return true } else { return false } }
            .count
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(SampleData.container)
}

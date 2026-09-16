//
//  ExerciseHistoryView.swift
//  PLog
//
//  Visualizes progressive overload for one exercise as a Swift Charts line over time.
//  A segmented picker switches between top weight, top-set reps, total volume, and est. 1RM.
//

import SwiftUI
import SwiftData
import Charts

struct ExerciseHistoryView: View {
    @State private var viewModel: ExerciseHistoryViewModel
    @State private var showingEdit = false

    init(exercise: Exercise) {
        _viewModel = State(initialValue: ExerciseHistoryViewModel(exercise: exercise))
    }

    var body: some View {
        List {
            Section {
                Picker("Metric", selection: $viewModel.selectedMetric) {
                    ForEach(ExerciseHistoryViewModel.Metric.allCases) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)

                chartSection
            }

            if !viewModel.points.isEmpty {
                Section("Sessions") {
                    ForEach(viewModel.points.reversed()) { point in
                        HStack {
                            Text(point.date.mediumDayLabel)
                            Spacer()
                            Text(sessionLabel(for: point))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEdit = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddExerciseView(exercise: viewModel.exercise)
        }
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartSection: some View {
        if viewModel.hasEnoughDataForChart {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(viewModel.selectedMetric.rawValue)
                        .font(.headline)
                    TrendBadge(trend: viewModel.overallTrend)
                    Spacer()
                }

                Chart(viewModel.points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(viewModel.selectedMetric.rawValue, viewModel.value(for: point))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(viewModel.exercise.category.color)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(viewModel.selectedMetric.rawValue, viewModel.value(for: point))
                    )
                    .foregroundStyle(viewModel.exercise.category.color)
                }
                .frame(height: 220)
                .chartYScale(domain: .automatic(includesZero: false))
            }
            .padding(.vertical, 8)
            .listRowSeparator(.hidden)
        } else {
            ContentUnavailableView {
                Label("No History Yet", systemImage: "chart.xyaxis.line")
            } description: {
                Text("Log this exercise a few times to see your progress trend.")
            }
            .listRowSeparator(.hidden)
        }
    }

    private func sessionLabel(for point: ExerciseHistoryPoint) -> String {
        let value = viewModel.value(for: point)
        let unit = viewModel.selectedMetric.unit
        switch viewModel.selectedMetric {
        case .reps:
            return "\(Int(value)) \(unit)"
        default:
            return "\(WeightFormatter.string(value)) \(unit)"
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseHistoryView(exercise: SampleData.benchPress)
    }
    .modelContainer(SampleData.container)
}

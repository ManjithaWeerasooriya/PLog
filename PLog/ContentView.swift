//
//  ContentView.swift
//  PLog
//
//  Root tab bar: Train (today's workout + the session log), Progress (analytics, with the
//  calendar pushed from it), Plans and Exercises. Settings is a sheet behind Train's profile
//  button. Each tab owns its own NavigationStack.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            TrainView()
                .tabItem {
                    Label("Train", systemImage: "figure.strengthtraining.traditional")
                }

            AnalyticsView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            PlanListView()
                .tabItem {
                    Label("Plans", systemImage: "list.clipboard")
                }

            ExerciseLibraryView()
                .tabItem {
                    Label("Exercises", systemImage: "dumbbell")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.container)
}

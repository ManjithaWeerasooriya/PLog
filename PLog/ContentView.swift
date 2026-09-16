//
//  ContentView.swift
//  PLog
//
//  Root tab bar: logged workout days, your training plans, and the reusable exercise library.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Workouts", systemImage: "calendar")
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

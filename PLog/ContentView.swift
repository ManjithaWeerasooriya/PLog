//
//  ContentView.swift
//  PLog
//
//  Root tab bar: your session logs, your training plans, and the reusable exercise library.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Logs", systemImage: "list.bullet.rectangle")
                }

            PlanListView()
                .tabItem {
                    Label("Plans", systemImage: "list.clipboard")
                }

            ExerciseLibraryView()
                .tabItem {
                    Label("Exercises", systemImage: "dumbbell")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.container)
}

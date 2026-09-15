//
//  ContentView.swift
//  PLog
//
//  Root tab bar: your logged workout days on one tab, the reusable exercise library on the other.
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

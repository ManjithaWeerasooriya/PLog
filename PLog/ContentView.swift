//
//  ContentView.swift
//  PLog
//
//  Root tab bar: Train (today's workout + the session log), Progress (analytics, with the
//  calendar pushed from it) and the Library (plans and exercises behind a sub-nav). Settings
//  is a sheet behind Train's profile button.
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

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "square.grid.2x2")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.container)
}

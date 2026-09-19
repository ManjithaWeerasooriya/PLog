//
//  ContentView.swift
//  PLog
//
//  Root tab bar: session logs, the training calendar, analytics, the library (plans and
//  exercises behind a sub-nav), and settings.
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

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "square.grid.2x2")
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

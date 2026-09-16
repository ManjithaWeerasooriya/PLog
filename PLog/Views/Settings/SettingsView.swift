//
//  SettingsView.swift
//  PLog
//
//  The Settings tab: the user's own details. `UserProfile.ensureExists` guarantees a row
//  already exists by the time this view appears, so `profiles.first` is safe to force-unwrap
//  here (the one place in the app where that's true by construction).
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    form(for: profile)
                } else {
                    // Only reachable for an instant before UserProfile.ensureExists commits.
                    ProgressView()
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func form(for profile: UserProfile) -> some View {
        SettingsForm(profile: profile)
    }
}

/// Split out so `@Bindable` can attach to a guaranteed non-optional `UserProfile`.
private struct SettingsForm: View {
    @Bindable var profile: UserProfile

    /// Same `UserDefaults` key `PLogApp` reads — `@AppStorage` keeps this picker and the
    /// live app appearance in sync without any manual plumbing.
    @AppStorage("appTheme") private var appTheme = AppTheme.system

    var body: some View {
        Form {
            Section("Appearance") {
                // .navigationLink rather than .segmented: "Use Device Theme" is too long a
                // label to sit comfortably in a 3-way segmented control on a phone-width row.
                Picker("Theme", selection: $appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("About You") {
                TextField("Name", text: $profile.name)
                    .textInputAutocapitalization(.words)

                Picker("Gender", selection: $profile.gender) {
                    ForEach(Gender.allCases) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("Body") {
                HStack(spacing: 12) {
                    NumberPickerWheel(
                        title: "Age",
                        intValue: ageBinding,
                        range: 10...100,
                        unit: "yrs",
                        width: 84
                    )
                    NumberPickerWheel(
                        title: "Height",
                        value: heightBinding,
                        step: 1,
                        range: 100...250,
                        unit: "cm",
                        width: 100,
                        format: { String(Int($0)) }
                    )
                    NumberPickerWheel(
                        title: "Weight",
                        value: weightBinding,
                        step: 0.5,
                        range: 30...300,
                        unit: "kg",
                        width: 100
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
        }
        .onAppear(perform: seedDefaultsIfNeeded)
    }

    // MARK: - Optional <-> wheel bindings

    /// Seeds sensible starting values the first time Settings is opened, so the wheels never
    /// silently disagree with the (still-nil) model — see `UserProfile.age`'s doc comment.
    private func seedDefaultsIfNeeded() {
        if profile.age == nil { profile.age = 25 }
        if profile.heightCm == nil { profile.heightCm = 170 }
        if profile.weightKg == nil { profile.weightKg = 70 }
    }

    private var ageBinding: Binding<Int> {
        Binding(get: { profile.age ?? 25 }, set: { profile.age = $0 })
    }

    private var heightBinding: Binding<Double> {
        Binding(get: { profile.heightCm ?? 170 }, set: { profile.heightCm = $0 })
    }

    private var weightBinding: Binding<Double> {
        Binding(get: { profile.weightKg ?? 70 }, set: { profile.weightKg = $0 })
    }
}

#Preview {
    SettingsView()
        .modelContainer(SampleData.container)
}

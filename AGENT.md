# PLog — Agent Reference

iOS workout tracker for progressive overload. Lets the user log sets per exercise per session and see whether they improved versus the last time they did the same exercise. Workout plans (Push/Pull/Legs-style day templates) can be started/ended and stamp out pre-filled sessions. Four tabs: Logs, Plans, Exercises, Settings.

---

## Build & Run

**Do not run `xcodebuild` directly.** Use the `BuildProject` MCP tool to build, and `XcodeRefreshCodeIssuesInFile` for fast per-file diagnostics without a full build.

Before pushing any code change, run `XcodeRefreshCodeIssuesInFile` on every file you touched. Only use `BuildProject` to confirm the full target compiles.

The build currently fails on **code signing** (no development team is selected). This is a project setting the user must configure in Xcode → Target → Signing & Capabilities. It is not a code error. Every Swift file compiles cleanly — confirm this with `XcodeRefreshCodeIssuesInFile` when making changes.

The deployment target is set to **iOS 17.0** (updated in `project.pbxproj`). All APIs used are iOS 17+: SwiftData, Swift Charts, `@Observable`, `ContentUnavailableView`.

---

## Project Layout

```
PLog/                        ← repo root
├── .gitignore               ← excludes xcuserdata, DerivedData, .build, etc.
├── README.md
├── AGENT.md
├── CLAUDE.md                 ← pointer to this file
├── PLog.xcodeproj/
│   └── project.pbxproj      ← uses PBXFileSystemSynchronizedRootGroup (see below)
└── PLog/                    ← all Swift source lives here
    ├── PLogApp.swift         ← @main entry point, ModelContainer init
    ├── ContentView.swift     ← root TabView (Logs + Plans + Exercises tabs)
    ├── Models/
    │   ├── MuscleGroup.swift        ← Codable enum, drives category chips + chart colors
    │   ├── Exercise.swift           ← reusable master-list exercise
    │   ├── WorkoutDay.swift         ← one training session
    │   ├── ExerciseEntry.swift      ← exercise-within-a-day join record
    │   ├── SetEntry.swift           ← individual set (weight, reps, RPE)
    │   ├── WorkoutPlan.swift        ← a program: name, startedAt/endedAt, day templates
    │   ├── PlanDay.swift            ← one day template ("Push Day") with exercise slots
    │   ├── PlanExercise.swift       ← slot: exercise + targetSets × targetReps
    │   ├── PlanStatus.swift         ← notStarted / active / ended (nonisolated enum)
    │   ├── UserProfile.swift        ← the user's own details; singleton (ensureExists(in:))
    │   └── Gender.swift              ← plain enum incl. .preferNotToSay, not Optional<Gender>
    ├── ViewModels/
    │   ├── ExerciseEntryViewModel.swift   ← prefill, duplicate-set, per-set trend
    │   ├── ExerciseHistoryViewModel.swift ← metric picker, chart data, overall trend
    │   ├── ExerciseLibraryViewModel.swift ← search/filter/add/delete for master list
    │   └── WorkoutPlanViewModel.swift     ← start/end, day CRUD, logWorkout(for:) stamping
    ├── Views/
    │   ├── Components/
    │   │   ├── NumberPickerWheel.swift    ← scrollable wheel picker for weight/reps/sets/age/etc.
    │   │   ├── UnsavedChangesGuard.swift  ← .confirmBeforeLeaving(...) — see Architecture
    │   │   ├── UnsavedTag.swift     ← "Unsaved" capsule pill — same style as PlanStatusPill
    │   │   └── TrendBadge.swift     ← green/red/gray capsule pill; CategoryChip
    │   ├── Home/
    │   │   ├── HomeView.swift       ← Logs tab: sessions by month; "+" picks a plan day
    │   │   └── WorkoutDayRow.swift  ← one row: name, date, plan tag, exercise summary
    │   ├── DayDetail/
    │   │   ├── DayDetailView.swift       ← editable session header + exercise list
    │   │   └── ExerciseEntryCard.swift   ← collapsible card per exercise
    │   ├── Entry/
    │   │   ├── AddEditExerciseEntryView.swift ← quick-entry sheet; drives which set is expanded
    │   │   ├── SetEditorRow.swift             ← collapsible set row; wheel pickers when expanded
    │   │   └── ExercisePickerView.swift       ← searchable sheet to pick from library
    │   ├── History/
    │   │   └── ExerciseHistoryView.swift ← Swift Charts line chart per exercise; Edit button
    │   ├── Plans/
    │   │   ├── PlanListView.swift       ← Plans tab; owns NavigationPath + PlanRoute enum
    │   │   ├── WorkoutPlanRow.swift     ← plan row + PlanStatusPill
    │   │   ├── PlanDetailView.swift     ← name, Start/End button, day list, link to log
    │   │   ├── PlanDayDetailView.swift  ← day template: name + exercise slots
    │   │   ├── PlanExerciseRow.swift    ← slot row with sets/reps wheel pickers
    │   │   └── PlanLogView.swift        ← date-by-date log with Rest Day gaps, "Up Next"
    │   ├── Library/
    │   │   ├── ExerciseLibraryView.swift ← searchable master list, grouped by category
    │   │   └── AddExerciseView.swift     ← create OR edit (exercise: Exercise? param)
    │   └── Settings/
    │       └── SettingsView.swift    ← Settings tab: UserProfile form (name/gender/age/etc.)
    └── Utilities/
        ├── ProgressiveOverload.swift ← SetSnapshot, ProgressTrend, overload logic
        ├── WorkoutHistory.swift      ← read-only helpers: previousEntry, historyPoints
        ├── WorkoutLogger.swift       ← stamps a PlanDay into a WorkoutDay; suggestedNextDay
        ├── PlanTimeline.swift        ← builds PlanLogItem rows (sessions + rest days)
        ├── StarterData.swift         ← first-launch seed: exercise library + 2 sample plans
        ├── AppTheme.swift            ← system/light/dark @AppStorage preference
        ├── Formatters.swift          ← WeightFormatter, Date extensions
        └── SampleData.swift          ← in-memory ModelContainer for SwiftUI previews
```

### File system sync (important)

`project.pbxproj` uses `PBXFileSystemSynchronizedRootGroup` — any Swift file added under `PLog/PLog/` is **automatically compiled** into the target. You do not need to edit `project.pbxproj` when adding or moving files. Never hand-edit `project.pbxproj` while Xcode is open.

---

## Data Model

### Relationships & delete rules

```
WorkoutDay  ──cascade──►  ExerciseEntry  ──cascade──►  SetEntry
Exercise    ──nullify──►  ExerciseEntry
Exercise    ──nullify──►  PlanExercise
WorkoutPlan ──cascade──►  PlanDay  ──cascade──►  PlanExercise
PlanDay     ──nullify──►  WorkoutDay   (WorkoutDay.planDay = template it was logged from)
```

- Deleting a `WorkoutDay` cascades to its `ExerciseEntry` records, which cascade to their `SetEntry` records.
- Deleting an `Exercise` from the master library **nullifies** (does NOT cascade) the `ExerciseEntry.exercise` reference. Historical log entries survive with `exercise == nil`.
- Deleting a `WorkoutPlan` removes its templates but **never** the `WorkoutDay` sessions logged from it (`PlanDay.loggedDays` is nullify). An **active** plan can't be deleted at all — `PlanListView` blocks the swipe and shows an alert; end the plan first.
- `@Relationship` inverse declarations live on one side only (the convention SwiftData prefers to avoid ambiguity).

### Mutate relationships from the to-many side

Setting only the to-one side (`slot.planDay = day`, or passing it to the `init`) updates the inverse array in SwiftData but does **not** fire Observation on the parent, so a view reading `day.exercises` won't refresh. Always `context.insert(child)` then `parent.children.append(child)` (and `parent.children.removeAll { $0 === child }` before `context.delete`). `WorkoutPlanViewModel` and `PlanDayDetailView` follow this; the older `DayDetailView.addExercise` only works because it also flips a `@State`.

### Ordering

`ExerciseEntry` has an `order: Int` field for stable positioning within a day. `WorkoutDay.orderedEntries` and `ExerciseEntry.orderedSets` sort on this / on `setNumber`. Always use these computed properties in the UI instead of `.entries` or `.sets` directly.

### All eight models must be listed in the Schema

`PLogApp` and `SampleData` both construct `ModelContainer` with an explicit `Schema([WorkoutDay.self, Exercise.self, ExerciseEntry.self, SetEntry.self, WorkoutPlan.self, PlanDay.self, PlanExercise.self, UserProfile.self])`. Add any new `@Model` class here too.

### Light/Dark mode is an `@AppStorage` preference, not `UserProfile`

`AppTheme` (`Utilities/AppTheme.swift`: `.system`/`.light`/`.dark`) is read via `@AppStorage("appTheme")` in **both** `PLogApp` (applies `.preferredColorScheme(appTheme.colorScheme)` to the root view — `nil` for `.system` means "follow the device") and `SettingsView`'s `Picker`. Two independent `@AppStorage` properties with the same key stay in sync automatically because they share the same `UserDefaults` storage; there's no manual plumbing between them. This is deliberately **not** a `UserProfile` field — it's a UI preference, not user data, and `@AppStorage` (unlike a SwiftData `@Query`) is available synchronously the instant the App struct's `body` is evaluated, before the container/first query has resolved. Follow the same `@AppStorage` (not `UserProfile`) approach for any future pure-UI preference — the still-open weight-unit (kg/lbs) preference belongs here too.

### Gender is a plain two-case enum

`Gender` has exactly two cases, `.female` and `.male` — no "prefer not to say"/non-binary option; that was tried and deliberately walked back. `UserProfile`'s default is `.female`. If a third option is ever wanted, add the case back to `Gender.swift` and give `UserProfile.init` a real default again; don't special-case a `nil`/optional `Gender` for it.

### MuscleGroup categories

`biceps` / `traps` / `triceps` / `forearms` are all specific arm/shoulder-girdle categories — there's no generic "arms" catch-all anymore. `StarterData`'s "Tricep Pushdown" is tagged `.triceps`, "Bicep Curl"/"Hammer Curl" are `.biceps`; new seed/preset exercises should always prefer the most specific matching category. Every new `MuscleGroup` case needs a `displayName`, `systemImage`, and `color` — the three `switch` statements are exhaustive, so the compiler catches a missing case, but picking a `systemImage` that doesn't actually exist as an SF Symbol will still compile and just render blank at runtime; verify a new icon on-device/in a preview, don't just trust the compiler.

**Renaming a case**: `biceps` was originally `arms`, renamed for clarity once `triceps`/`forearms` existed and made the old generic name confusing. The case declaration explicitly pins the raw value to the old name (`case biceps = "arms"`) so any `Exercise` already persisted with that category — including on a device/simulator that had the app installed before the rename — still decodes correctly; only the displayed label changed. **Follow this pattern for any future enum-case rename on a `@Model` property** (`Gender`, `MuscleGroup`, `PlanStatus`, `AppTheme`): `case newName = "oldRawValue"`, never a bare rename — a bare rename changes the persisted raw string too, and existing rows with the old string silently fail to decode.

### UserProfile is a guaranteed singleton

`UserProfile.ensureExists(in:)` is called unconditionally at launch (`PLogApp`) and in `SampleData` — exactly one row always exists by the time `SettingsView` appears. `SettingsView` reads `profiles.first` and treats it as non-optional in practice (the `nil` branch is only reachable for the one frame before `ensureExists` commits). Don't add a second code path that creates a `UserProfile`.

### A set has no "completed" flag

`SetEntry` was simplified to drop its old `completed: Bool` tick box. A set's existence in `ExerciseEntry.orderedSets` **is** its "added" state — there's no separate in-progress/done toggle to manage. Don't reintroduce one without a concrete reason; it previously added UI weight (a checkbox in `SetEditorRow`, a checkmark in `ExerciseEntryCard`) without affecting `ProgressiveOverload` or any query.

---

## Architecture

### Pattern: MVVM with SwiftData constraints

`@Query` only works inside a `View` (`@Query` is a property wrapper tied to the SwiftUI environment). The split is:

- **List/read screens** (`HomeView`, `ExerciseLibraryView`, `ExercisePickerView`): use `@Query` directly, keep filtering/grouping inline as computed properties.
- **Mutation-heavy screens** (`AddEditExerciseEntryView`): use an `@Observable` view model (`ExerciseEntryViewModel`) that holds the `ModelContext` and owns all insert/delete logic.

### Passing ModelContext to view models

`@Environment(\.modelContext)` is not available during a view's `init`. The pattern used here is:

```swift
// In the View:
init(entry: ExerciseEntry, context: ModelContext) {
    _viewModel = State(initialValue: ExerciseEntryViewModel(entry: entry, context: context))
}

// Called from the parent:
.sheet(item: $editingEntry) { entry in
    AddEditExerciseEntryView(entry: entry, context: context)
}
```

Do not deviate from this pattern. Do not try to capture `@Environment` in an `init` — it will crash.

### Navigation

`HomeView` owns a `NavigationStack(path: $path)` with a typed `[WorkoutDay]` path. To push a newly created day immediately to its detail screen, call `path.append(day)` after inserting. Sheets are used for all editor flows (entry form, exercise picker, library actions).

`PlanListView` owns a `NavigationPath` (mixed types: `WorkoutPlan`, `PlanDay`, `WorkoutDay`, `PlanRoute`) and registers every `navigationDestination(for:)` at the stack root. **Push everything by value** in this stack. A view-builder `NavigationLink { … }` leaves its destination outside the path and `NavigationLink(value:)` rows inside it silently do nothing (row highlights, no push) — that's why the log screen is reached via `PlanRoute.log(plan)`. Screens that need to push programmatically (`PlanLogView` after logging) take `path: Binding<NavigationPath>`.

### Plans → sessions (the Logs tab)

`WorkoutLogger.logWorkout(for:on:in:)` stamps a `PlanDay` template into a `WorkoutDay`: one `ExerciseEntry` per slot with `targetSets` sets at `targetReps`, weight prefilled from `WorkoutHistory.previousTopSet` — so logging a plan day means only adjusting weights. It's called from two places that must stay in sync: the **Logs tab** (`HomeView`'s "+" is a `Menu` of the active plan's days, with `WorkoutLogger.suggestedNextDay` flagged "Up next", plus "Blank Workout"; it's a plain button when no plan is active) and the plan's own log screen via `WorkoutPlanViewModel`. `DayDetailView` shows a "Plan Day" row for stamped sessions and passes `initiallyExpanded: true` to their cards.

`PlanTimeline.items(for:workouts:)` produces the plan log rows: every calendar day from `startedAt` to `endedAt ?? today`; days with no session are rest days (today is shown as "Not logged yet" instead).

**Exactly one plan can be active.** `WorkoutPlanViewModel.start()` fetches every plan and sets `endedAt` on any other active one before starting this one. `HomeView` relies on this (`plans.first(where: \.isActive)`). Don't add another code path that sets `startedAt` without going through `start()`.

### Exercises are editable in place

`AddExerciseView` handles both create and edit: an optional `exercise: Exercise?` init param switches its title/behavior, and on save it mutates the passed-in `Exercise` directly rather than inserting a new one. Reached via a leading `.swipeActions` "Edit" button in `ExerciseLibraryView` and a toolbar Edit button on `ExerciseHistoryView` (both present the same sheet). Don't add a second exercise-editing form — extend this one.

**Seed `@State` from `init`, not `.onAppear`, for a form nested inside a `NavigationStack` with its own pushed screens.** `AddExerciseView`'s `category` used to be seeded via `.onAppear`, which reset it back to `exercise.category` every time the "Muscle Group" `.pickerStyle(.navigationLink)` screen was popped back to — `.onAppear` fires again on reappearance, not just on first appearance, so the just-picked category was silently stomped back to its original value before the user ever saw it stick. The fix is a custom `init(exercise:prefilledName:onCreate:)` that sets `_name`/`_category`/`_notes` directly (`State(initialValue:)`), which only ever runs once. Any future form with a sub-navigation picker (not just a `.sheet`-presented one) needs the same treatment.

### Duplicating a plan

`WorkoutPlanViewModel.duplicate(_:in:)` (static) deep-copies a plan's days and exercise slots into a new plan that is always inactive (`startedAt`/`endedAt` left `nil`) — the original plan's status is untouched. The copy's name is `"<base> (n)"`: `baseName(from:)` strips a trailing `" (N)"` suffix before appending the next free number, so duplicating "PPL (1)" produces "PPL (2)", not "PPL (1) (1)". Reached via a leading `.swipeActions` button in `PlanListView`.

### First-launch starter data

`PLogApp` calls `StarterData.seedIfNeeded(in:)` right after building the container. It seeds only when there are **zero** `Exercise` rows: a 20-exercise library across all muscle groups, an active "Push / Pull / Legs" plan (3 days, 5 slots each) and a not-started "Upper / Lower" plan. It never touches a store that already has data. This is distinct from `SampleData`, which is the in-memory preview fixture and also seeds workout history.

### Unsaved-changes confirmation on every live-editing screen

Every screen that live-binds `@Model` properties (so edits apply the instant the user types/scrolls, with no separate "save" step) confirms before letting the user navigate away with unsaved edits, and shows an `UnsavedTag` (`Views/Components/UnsavedTag.swift` — a capsule pill, same visual language as `PlanStatusPill`/`CategoryChip`/`TrendBadge`) next to the title while dirty. It sits in a custom `.principal` toolbar item beside the title text, not appended into the title string itself — `.navigationTitle` only takes a plain `String`, so it can't carry a colored/shaped tag. This covers `PlanDayDetailView` (day name + each slot's target sets/reps), `DayDetailView` (session name/date/notes), `PlanDetailView` (plan name/notes), `AddEditExerciseEntryView` (set weights/reps, plus adding/removing sets), and `AddExerciseView` (name/category/notes). **Do not add a new live-binding editor without this** — it's the whole point of the fix described below.

**Pushed screens** (`PlanDayDetailView`, `DayDetailView`, `PlanDetailView`) use the shared `.confirmBeforeLeaving(title:hasChanges:onSave:onDiscard:)` modifier (`Views/Components/UnsavedChangesGuard.swift`). It hides the system back button and replaces it with one that pops immediately when `hasChanges` is false, or shows an alert (Save / Discard Changes / Cancel) when true; it also renders the `.principal` title + `UnsavedTag` itself, so callers just pass `title:` as a plain string. Each screen supplies its own `hasChanges` (compare current model values to a baseline captured in `init`, **not** `.onAppear` — see the `AddExerciseView` note above for why that specifically breaks) and `onDiscard` (reassign the tracked scalar properties back to the baseline). **Trade-off**: hiding the back button also disables the edge-swipe-back gesture on these screens — an accepted cost of forcing the confirmation path; don't try to "fix" this by un-hiding the button, that defeats the guard.

**The Sets editor sheet** (`AddEditExerciseEntryView`) can't use the scalar-revert approach because sets can be *added and removed*, not just edited — reverting means restoring the whole list. `ExerciseEntryViewModel.currentSnapshot`/`revert(to:)` capture/restore the full set list by **deleting everything and recreating fresh `SetEntry` objects from the snapshot**, rather than diffing/matching old vs. new — this is what makes it correct regardless of which combination of edit/add/remove/reorder happened. The sheet adds an explicit "Cancel" (previously it only had "Done") that confirms via the same Save/Discard Changes/Cancel alert when dirty, plus `.interactiveDismissDisabled(hasChanges)` so swiping the sheet away can't bypass the prompt.

**`AddExerciseView`** already used a local-draft pattern (see the `.onAppear`-vs-`init` note above) where Cancel silently discarded correctly — it just didn't *ask* first. Added the same confirm-before-discard alert for consistency; no revert logic needed there since the model was never touched until Save.

**Deliberately excluded**: `SettingsView` (a root tab, not a pushed/sheeted editor — there's no "back" gesture to guard, and live-applying preferences instantly matches how Settings apps conventionally behave) and the explicit destructive buttons ("Remove Exercise from Day", swipe-to-delete elsewhere) — those are already unambiguous, already-confirmed (or single-purpose) actions, not the "silently saved by navigating away" failure mode this fix targets.

### Destructive actions confirm first — use `.alert`, not `.confirmationDialog`

Deleting a `WorkoutPlan` (`PlanListView`), ending a plan (`PlanDetailView`), or deleting an `Exercise` (`ExerciseLibraryView`) stages the target in `@State` and shows a confirmation before calling `context.delete`/mutating. Stage-then-confirm, not delete-then-undo, for any new destructive action.

**Use `.alert`, never `.confirmationDialog`, for these.** On the iOS version this app has been tested against, `.confirmationDialog` does not reliably render as the standard bottom action sheet — it can instead render as a small anchored callout that latches onto an arbitrary ancestor view (e.g. the top of a `List`) instead of the row that triggered it, pointing at the wrong item, and it can drop its `Cancel` button entirely. `.presentationCompactAdaptation(.sheet)` does **not** fix this. `.alert` sidesteps the whole problem — it's always a centered, unanchored modal, so there's no anchor to get wrong. This was root-caused and fixed for the plan-delete, plan-end, and exercise-delete confirmations; don't reintroduce `.confirmationDialog` for a destructive action without re-verifying on-device first.

Also prefer a single root-level (`NavigationStack`-level) `.alert` over one attached per-row inside a `ForEach`/`.swipeActions`: a per-row presentation attached to a row that a `.swipeActions` button just collapsed can silently fail to appear (the request seems to get lost in that transient teardown). `ExerciseLibraryView` and `PlanListView` both hold a single `pending…` `@State` (an optional model, or an array) and one alert at the stack root, gated by a computed `Binding<Bool>` when needed.

---

## Progressive Overload Logic

The core algorithm lives in `Utilities/ProgressiveOverload.swift` and `Utilities/WorkoutHistory.swift`.

**Do not compare weight or reps directly.** Use `SetSnapshot.estimatedOneRepMax` (Epley formula: `weight × (1 + reps/30)`) to classify improvement vs regression. This handles the case where a user trades weight for reps or vice versa — both register as the same 1RM and thus don't spuriously count as regression.

```
SetSnapshot(weight: 65, reps: 6).estimatedOneRepMax  ≈ 78
SetSnapshot(weight: 60, reps: 8).estimatedOneRepMax  ≈ 76
// → 65×6 is classified as .improved over 60×8
```

A tolerance of `0.01` is applied to avoid floating-point noise registering as a change.

**Prefill flow:**
1. `ExerciseEntryViewModel.init` calls `WorkoutHistory.previousTopSet(for:excluding:)`
2. `previousTopSet` is stored as `SetSnapshot?` (model-free; safe to pass around UI)
3. `prefillIfNeeded()` inserts the first `SetEntry` with those numbers if the entry is new
4. `addDuplicateSet()` clones the last set's numbers for quick multi-set entry

---

## SwiftUI Previews

Every screen has a `#Preview` using `SampleData`:

```swift
#Preview {
    HomeView()
        .modelContainer(SampleData.container)
}
```

`SampleData.container` is an **in-memory** `ModelContainer` (`isStoredInMemoryOnly: true`) seeded with:
- 3 Push Day sessions showing bench press progression: 60kg×8 → 62.5kg×8 → 62.5kg×9
- 1 Leg Day with 4×5 back squats at 100kg
- An active "Push / Pull / Legs" plan started 21 days ago; the Push and Leg sessions are linked to its templates
- One `UserProfile` row (via `UserProfile.ensureExists`), so `SettingsView`'s preview never hits the empty-state branch
- Convenience accessors: `SampleData.benchPress`, `SampleData.recentDay`, `SampleData.plan`, `SampleData.pushDay`

When adding a new screen, always wire up a `#Preview` using `SampleData.container`. Never use the production container in previews.

---

## Code Conventions

- **Swift version:** 5.0, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- **Naming:** PascalCase for types, camelCase for properties/methods
- **Models:** `final class`, `@Model`, explicit `init` with default arguments
- **View models:** `@MainActor @Observable final class`
- **Views:** `struct`, conforms to `View`, `body` as the sole entry point
- **State:** `@State private var` for local view state; `@Bindable var` to bind directly into `@Model` properties (e.g. `DayDetailView` editing `WorkoutDay.name`)
- **Imports:** only what is needed — `Foundation + SwiftData` for any file that references SwiftData types (including `PersistentIdentifier`); `SwiftUI + SwiftData` for views that use `@Query` or `.modelContainer`; add `import Charts` for any chart view. `PersistentIdentifier` is in SwiftData, not Foundation — missing this import is a common build failure.
- **Comments:** only when the WHY is non-obvious (e.g. the nullify vs cascade decision). No docstrings on obvious getters
- **No Combine** — use `async/await` and `@Observable` instead
- **No force unwrap** in production code; sample data accessors may use `!` only where the data is known-seeded

### WeightFormatter

Always use `WeightFormatter.string(_:)` to display weights — drops `.0` for whole numbers (`60` not `60.0`), keeps one decimal for halves (`62.5`). Do not use `String(format:)` or `.formatted()` on weight values directly.

### NumberPickerWheel

All weight/reps/sets/age/height/weight entry uses `NumberPickerWheel` (`Views/Components/NumberPickerWheel.swift`) — a scrollable `.pickerStyle(.wheel)` with a `.sensoryFeedback(.selection, trigger: value)` tick on every row change — not steppers or free text. It has a `Double` `init` (title, value, step, range, unit, width, height, format) and an `intValue:` convenience init mirroring it. **Argument order matters**: Swift requires call-site arguments in declaration order even for a mix of positional/labeled params here, so `format:` must come after `width:`/`height:`, not before. The wheel's row values are generated **by index** (`lowerBound + Double(i) * step`), not by repeated addition, so a fractional `step` (e.g. `2.5` for weight) never drifts out of exact alignment with the bound value — a `Picker` selection silently fails to highlight anything if the bound value doesn't exactly match one of the row tags. Any value bound into this component must land exactly on the step grid; `WorkoutLogger`/`ProgressiveOverload` always produce grid-aligned weights because they only ever copy numbers that came from this same picker.

For an `Int?`/`Double?` model field (`UserProfile.age`/`heightCm`/`weightKg`), bind through a computed `Binding` with a fallback default (e.g. `profile.age ?? 25`) and seed the real default into the model `onAppear` — see `SettingsView` — so the wheel's initial display never silently disagrees with the (still-`nil`) persisted value.

Two wheels side by side in one row (`SetEditorRow`, `PlanExerciseRow`) fit comfortably at their default sizing; this replaced the old `ValueStepper` (+/- buttons), which needed hand-tuned compact sizing to avoid clipping at this width and has been deleted.

### Sets, logged exercises, and plan-day slots are all collapsible, accordion-style — same pattern, same look

`SetEditorRow` (inside `AddEditExerciseEntryView`), `ExerciseEntryCard` (inside `DayDetailView`), and `PlanExerciseRow` (inside `PlanDayDetailView`) all take `isExpanded: Binding<Bool>` rather than owning their own `@State`. Each parent holds a single `expanded…ID: PersistentIdentifier?` and hands every row a computed `Binding` that compares against it, so **only one row is ever expanded at a time** in any of the three lists — these are three independent instances of the same pattern (one per list, not a single shared ID), so expanding a set doesn't affect which exercise or slot is expanded elsewhere. Both start with everything collapsed (`AddEditExerciseEntryView` is the one exception — it seeds `expandedSetID` to the first set's ID in `init` so opening the sheet needs no extra tap to adjust the set you almost certainly care about, and re-points it whenever "Duplicate Last Set" runs; `DayDetailView`'s `expandedEntryID` starts `nil` unconditionally, including for plan-logged sessions that used to auto-expand every card — don't reintroduce that).

Visually, both lists are **plain rows inside one shared `Section`** — a header (name/summary + trailing chevron that rotates on expand) that reveals more content below when tapped, no per-row card background or hidden separators. `ExerciseEntryCard` used to render each exercise as its own floating rounded-rect card (`.background(...,  in: RoundedRectangle(...))`, `.listRowSeparator(.hidden)`); that's gone specifically so the exercises list in `DayDetailView` matches the sets list's look. Keep any new expandable list in this style — a shared `Section`, `Binding`-driven per-row expansion, no individual card chrome — rather than reinventing a bespoke card look.

---

## Git

- Remote: `git@github.com:ManjithaWeerasooriya/PLog.git` (origin)
- Branch: `main`
- `xcuserdata/` is gitignored and untracked
- Commit message style: imperative subject line, bullet-point body for significant changes

---

## Known Issues / To-Do

- **Signing:** development team not configured — set in Xcode → Target → Signing & Capabilities before building to a device or submitting to TestFlight.
- **Deployment target:** currently `26.5` in the project-level build settings; the target-level override sets `17.0`. Unify to `17.0` in project-level settings when convenient.
- **Weight unit preference:** the app hardcodes `kg`; `UserProfile` also stores height in cm and weight in kg with no unit toggle. A kg/lbs (and cm/in) preference would need a `UserDefaults`-backed `@AppStorage` and threading it through `WeightFormatter`, `NumberPickerWheel` ranges, and all display sites.
- **`ExerciseLibraryViewModel`** is wired for mutations (add/delete) but the library and picker views inline their own `@Query`-based filtering. Consolidate if the filter logic grows complex.
- **`BuildProject` may target a physical device instead of the simulator** depending on Xcode's currently-selected scheme destination, with no MCP tool to switch it. If a simulator install/launch doesn't reflect a change you just built, check `PLog.app/PLog.debug.dylib`'s mtime in DerivedData's `Debug-iphonesimulator` products dir before assuming the app is broken — it may just be stale. Fall back to `xcodebuild -project PLog.xcodeproj -scheme PLog -configuration Debug -destination "platform=iOS Simulator,id=<UDID>" -derivedDataPath <tmp> build` to force a simulator build.

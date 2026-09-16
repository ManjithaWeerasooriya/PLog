# PLog — Agent Reference

iOS workout tracker for progressive overload. Lets the user log sets per exercise per session and see whether they improved versus the last time they did the same exercise. Workout plans (Push/Pull/Legs-style day templates) can be started/ended and stamp out pre-filled sessions.

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
    │   └── PlanStatus.swift         ← notStarted / active / ended (nonisolated enum)
    ├── ViewModels/
    │   ├── ExerciseEntryViewModel.swift   ← prefill, duplicate-set, per-set trend
    │   ├── ExerciseHistoryViewModel.swift ← metric picker, chart data, overall trend
    │   ├── ExerciseLibraryViewModel.swift ← search/filter/add/delete for master list
    │   └── WorkoutPlanViewModel.swift     ← start/end, day CRUD, logWorkout(for:) stamping
    ├── Views/
    │   ├── Components/
    │   │   ├── ValueStepper.swift   ← +/- stepper for weight (Double) and reps (Int)
    │   │   └── TrendBadge.swift     ← green/red/gray capsule pill; CategoryChip
    │   ├── Home/
    │   │   ├── HomeView.swift       ← Logs tab: sessions by month; "+" picks a plan day
    │   │   └── WorkoutDayRow.swift  ← one row: name, date, plan tag, exercise summary
    │   ├── DayDetail/
    │   │   ├── DayDetailView.swift       ← editable session header + exercise list
    │   │   └── ExerciseEntryCard.swift   ← collapsible card per exercise
    │   ├── Entry/
    │   │   ├── AddEditExerciseEntryView.swift ← quick-entry sheet (sets editor)
    │   │   ├── SetEditorRow.swift             ← one set row with steppers + trend badge
    │   │   └── ExercisePickerView.swift       ← searchable sheet to pick from library
    │   ├── History/
    │   │   └── ExerciseHistoryView.swift ← Swift Charts line chart per exercise
    │   ├── Plans/
    │   │   ├── PlanListView.swift       ← Plans tab; owns NavigationPath + PlanRoute enum
    │   │   ├── WorkoutPlanRow.swift     ← plan row + PlanStatusPill
    │   │   ├── PlanDetailView.swift     ← name, Start/End button, day list, link to log
    │   │   ├── PlanDayDetailView.swift  ← day template: name + exercise slots
    │   │   ├── PlanExerciseRow.swift    ← slot row with compact sets/reps steppers
    │   │   └── PlanLogView.swift        ← date-by-date log with Rest Day gaps, "Up Next"
    │   └── Library/
    │       ├── ExerciseLibraryView.swift ← searchable master list, grouped by category
    │       └── AddExerciseView.swift     ← form to create a new exercise
    └── Utilities/
        ├── ProgressiveOverload.swift ← SetSnapshot, ProgressTrend, overload logic
        ├── WorkoutHistory.swift      ← read-only helpers: previousEntry, historyPoints
        ├── WorkoutLogger.swift       ← stamps a PlanDay into a WorkoutDay; suggestedNextDay
        ├── PlanTimeline.swift        ← builds PlanLogItem rows (sessions + rest days)
        ├── StarterData.swift         ← first-launch seed: exercise library + 2 sample plans
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

### All seven models must be listed in the Schema

`PLogApp` and `SampleData` both construct `ModelContainer` with an explicit `Schema([WorkoutDay.self, Exercise.self, ExerciseEntry.self, SetEntry.self, WorkoutPlan.self, PlanDay.self, PlanExercise.self])`. Add any new `@Model` class here too.

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

### First-launch starter data

`PLogApp` calls `StarterData.seedIfNeeded(in:)` right after building the container. It seeds only when there are **zero** `Exercise` rows: a 20-exercise library across all muscle groups, an active "Push / Pull / Legs" plan (3 days, 5 slots each) and a not-started "Upper / Lower" plan. It never touches a store that already has data. This is distinct from `SampleData`, which is the in-memory preview fixture and also seeds workout history.

### Destructive actions confirm first

Deleting a `WorkoutPlan` (`PlanListView`) or an `Exercise` (`ExerciseLibraryView`) stages the target(s) in `@State` and shows a `confirmationDialog` before calling `context.delete`. Follow this pattern — stage-then-confirm, not delete-then-undo — for any new destructive swipe action.

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

### ValueStepper compact sizing

`ValueStepper` takes optional `buttonSize`/`valueMinWidth` (default `40`/`70`, sized for one stepper per row). Any row that must fit **two** steppers side by side inside an inset-grouped List/Form row (`SetEditorRow`, `PlanExerciseRow`) needs the compact values (`buttonSize: 34`, `valueMinWidth: 44–50`) or the row clips on a 393pt-wide phone — the default sizing needs ~348pt but the row only gives ~320pt.

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
- **Weight unit preference:** the app hardcodes `kg`. A user setting for kg/lbs would require a `UserDefaults`-backed `@AppStorage` preference and threading it through `WeightFormatter` and all display sites.
- **`ExerciseLibraryViewModel`** is wired for mutations (add/delete) but the library and picker views inline their own `@Query`-based filtering. Consolidate if the filter logic grows complex.

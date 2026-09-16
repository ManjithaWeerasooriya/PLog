# PLog

An iOS workout tracker built for progressive overload. Log your sets per exercise per session and instantly see whether you improved on the last time you trained that exercise.

## Features

- **Log workouts** — pick a day from your active plan and the session is created with every exercise and set pre-filled; you only update the weights. Or start from a blank workout
- **Progressive overload at a glance** — every set is compared against your last session using estimated one-rep max (Epley formula), so trading weight for reps (or vice versa) is still recognized as progress
- **Exercise library** — a reusable master list of exercises, organized by muscle group, with per-exercise history charts
- **Workout plans** — build a rotation of day templates (Push, Pull, Legs, …), each pre-filled with target sets × reps per exercise; start a plan to begin logging against it and end it when the program is over
- **Workout log** — a day-by-day timeline for an active plan, with gaps between sessions labeled as rest days
- **Starter content** — first launch seeds an exercise library and two sample plans (Push / Pull / Legs, Upper / Lower) so you can try it immediately

## Requirements

- Xcode 16+
- iOS 17.0+ (SwiftData, Swift Charts, `@Observable`, `ContentUnavailableView`)

## Getting started

1. Clone the repo and open `PLog.xcodeproj` in Xcode.
2. Select a development team under **Target → Signing & Capabilities** (the project ships without one configured).
3. Pick an iOS 17+ simulator or device and hit Run.

The project uses `PBXFileSystemSynchronizedRootGroup`, so any Swift file added under `PLog/PLog/` is picked up automatically — no manual target membership needed.

## Architecture

PLog is a SwiftUI + SwiftData app following MVVM, with `@Query`-driven read screens and `@Observable` view models for mutation-heavy flows. See [AGENT.md](AGENT.md) for the full project layout, data model, and conventions used throughout the codebase.

## License

MIT — see [LICENSE](LICENSE).

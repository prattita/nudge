# Nudge — build checklist

Living progress tracker for MVP and post-MVP work. **Update this file** as tasks complete so any agent (or future you) can pick up where you left off.

**Spec:** `docs/nudge-design-doc-v4.docx`  
**Personal agent rules:** `docs/AGENTS.md` (gitignored — local only)

---

## How to use this doc

| Symbol | Meaning |
|--------|---------|
| `- [ ]` | Not started |
| `- [x]` | Done |
| `- [~]` | In progress (optional) |

**When you finish work:** check boxes, set **Current focus** below, add date/notes if helpful.

### Current focus

<!-- Edit this line when you switch tasks -->

**Next up:** Step 5 — Goals detail (dot grid, archive); answer primer quiz first

### Notes / blockers

<!-- Agents: log anything that blocks the next step -->

- Xcode 26.6 installed; project at `Nudge/Nudge.xcodeproj`
- **UX pivot (v4.1):** Day rings narrate the week; letter grade only for *completed* weeks (Week tab → previous weeks). Today shows live day ring (0–100%). Goals tab kept as cheap placeholder for later.
- Day shortcomings stay on locked day rings; week letter = aggregate completed/due (can still be A+ after a weak day).

---

## Step 0 — Environment (pre-build)

- [x] Install Xcode from Mac App Store (~12 GB)
- [x] Open Xcode once; allow additional components to install
- [x] Confirm iOS Simulator works (any sample project or after Step 1)
- [ ] Optional: install SF Symbols app from [developer.apple.com/sf-symbols](https://developer.apple.com/sf-symbols)
- [x] Repo cloned; Cursor + Xcode workflow understood (edit in Cursor, build in Xcode)

---

## Step 1 — Xcode project & app scaffolding

**Goal:** App launches in simulator with three tabs (placeholder content).

- [x] Create new Xcode project: iOS → App → SwiftUI + SwiftData → name **Nudge**
- [x] Set minimum deployment target to **iOS 17** (template set iOS 26.5; meets minimum)
- [x] Add project to this repo (sensible folder, e.g. `Nudge/` or root — stay consistent)
- [x] Replace `ContentView` with `TabView`: Today, Goals, Progress
- [x] Create `TodayView.swift`, `GoalsView.swift`, `ProgressScreen.swift` (placeholder text)
- [x] Add SF Symbols tab icons
- [x] Add `.gitignore` entries for Xcode user state (if not already)
- [x] **Verify:** ⌘R runs app; all three tabs switch correctly

---

## Step 2 — Data models (SwiftData)

**Goal:** Local database with CloudKit-ready models; preset categories on first launch.

### Models

- [x] `NudgeTask` — all fields per spec (incl. `autoCompleteFromHealthKit`, `isArchived`, `createdAt`)
- [x] `TaskInstance` — `dueDate`, `status`, `completedAt`, `source`, relationship to task
- [x] `NudgeCategory` — `name`, `colorHex`, `isPreset`, `isHidden`
- [x] Enums stored as `String` in persistence; typed enums in code
- [x] `scheduledWeekdays` as comma-separated string (not `[Int]` array)
- [x] CloudKit rules: default values on properties; optional relationships
- [x] Wire models into `NudgeApp` / `ModelContainer`

### First launch

- [x] Seed 4 preset categories if none exist (Health, Fitness, Pet Care, Mind + colors)
- [x] **Verify:** app builds; container initializes without crash

---

## Step 3 — Today + Week rings (task list & completion)

**Goal:** Tasks due today with live day ring; Week tab with Mon–Sun rings; letter only on completed weeks.

- [x] Query tasks due **today** (respect frequency + `createdAt`)
- [x] Group by category (hide `isHidden` presets with no tasks — if applicable)
- [x] Task row: emoji, title, frequency label, checkbox
- [x] Check → create `TaskInstance` (`status: completed`, `completedAt: Date()`, `source: manual`)
- [x] Uncheck → delete instance (same calendar day only)
- [x] Today: fixed-height header + **day ring** (no live weekly letter)
- [x] `GradeCalculator` + `DayRingView` (day % capped at 100%; week letter for completed weeks only)
- [x] Week tab: 7 circles, prev-week navigation, letter on past weeks only
- [x] Goals tab kept as placeholder
- [x] Temporary + adds a sample daily task (until Step 4 Add form)
- [x] **Verify:** build succeeded; user to smoke-test rings in Simulator

---

## Step 4 — Add & edit task flow

**Goal:** `TaskFormView` sheet for create and edit.

- [x] “+” button on Today and Goals nav bars
- [x] Fields: title, emoji, frequency, day/date pickers, category, optional reminder time
- [x] “New category” inline (name + color)
- [x] Edit via Goals row / pencil (full expand/detail still Step 5)
- [x] Safe edits in place; **schedule edits apply from tomorrow** (`scheduleEffectiveFrom`)
- [x] Validation on save
- [x] Fitness-style padding/rings on Today + Week
- [x] Reminder time stored on task (delivery = Step 9)
- [x] **Verify:** Add/Edit form wired; user smoke-testing in Simulator

---

## Step 5 — Goals view

**Goal:** All active tasks, weekly grade, expandable detail.

- [ ] List non-archived tasks with weekly grade badge
- [ ] Expand row → 7-day dot grid (✓ / ✗ / dot for today / neutral for non-scheduled days)
- [ ] Completion fraction: “X of Y due this week”
- [ ] Pencil → edit sheet
- [ ] Swipe → archive (`isArchived = true`)
- [ ] **Verify:** dot grid matches instances; archive hides from Today/Goals

---

## Step 6 — Progress view

**Goal:** Weekly report card, history chart, breakdowns.

- [ ] Report card: large grade, week date range, completion %
- [ ] Multi-week bar chart (weeks since first task, min 1 bar; current week highlighted)
- [ ] Past weeks: full Mon–Sun denominator; current week: through today only
- [ ] Per-task breakdown with progress bar + grade
- [ ] Per-category grade summary
- [ ] Swift Charts or custom bars
- [ ] **Verify:** chart and grades match `GradeCalculator`

---

## Step 7 — Backfill & miss recording

**Goal:** No silent skips; misses recorded on app open.

- [ ] `lastBackfillDate` in `@AppStorage` (first launch: start of today, no backfill)
- [ ] On open: scan `lastBackfillDate` → yesterday for due tasks without instances
- [ ] Respect `createdAt` (no retroactive misses)
- [ ] Create `TaskInstance` with `status: missed` where needed
- [ ] Update `lastBackfillDate` after processing
- [ ] Brief UI summary when backfill records misses
- [ ] After backfill: missed days **final for MVP** (no makeup — Option D is post-MVP)
- [ ] **Verify:** don’t open app for 2+ days → misses appear; grades update

---

## Step 8 — CloudKit sync

**Goal:** iCloud backup and multi-device sync.

- [ ] Enable iCloud capability + CloudKit container
- [ ] Background Modes → Remote notifications
- [ ] `ModelConfiguration` with CloudKit container ID
- [ ] Test on two devices or simulator + device (same Apple ID)
- [ ] **Verify:** create task on one device → appears on other

---

## Step 9 — Local notifications

**Goal:** Optional per-task reminder time.

- [ ] Request notification permission (first launch)
- [ ] `NotificationManager` — schedule / cancel
- [ ] On save: schedule for task’s scheduled days at `reminderTime`
- [ ] On edit/archive/complete today: reschedule or cancel appropriately
- [ ] Monthly/yearly: one-shot triggers for next due date
- [ ] MVP: one time applies to all scheduled days (n-times/week)
- [ ] **Verify:** notification fires on scheduled day; cancels when task done

---

## MVP complete — smoke test

Run through once before calling MVP done:

- [ ] Create tasks: daily, n-times/week, monthly, yearly
- [ ] Complete and miss tasks; grades behave per spec
- [ ] Edit title vs edit schedule (tomorrow rule)
- [ ] Archive task; history still on Progress
- [ ] Backfill after not opening app
- [ ] Optional: CloudKit + notifications if Steps 8–9 done

---

# Post-MVP

Do **not** start these until MVP smoke test passes and you’ve used the app in real daily life for a while (unless explicitly requested).

## Option D — Smart rollover & makeup

- [ ] Rollover missed instance to next day (no conflict, same week only)
- [ ] No double rollover
- [ ] Ad-hoc makeup: complete missed instance later in week (`source: makeup`, `completedAt` ≠ `dueDate`)
- [ ] Goals dot grid: miss (✗) + recovery badge on makeup day
- [ ] Plug rules into `GradeCalculator` (no view rewrite)

## Companion (digital pet)

- [ ] Companion onboarding (species, name) — not at first app install
- [ ] Mood from weekly grade: thriving / steady / tired / struggling
- [ ] Supportive copy only (no guilt, no death, no pay-to-revive)
- [ ] Reads from `GradeCalculator` only — no separate XP economy
- [ ] Optional: cosmetics tied to achievements later

## HealthKit

- [ ] Enable HealthKit capability + privacy strings
- [ ] Per-task `autoCompleteFromHealthKit` opt-in UI
- [ ] `HealthKitManager` — read workouts for today
- [ ] Auto-complete with badge (not manual check)
- [ ] One workout ≠ complete all fitness tasks blindly

## Achievements / awards

- [ ] Milestone awards (first task, first perfect day/week)
- [ ] Consistency: consecutive weeks at B+ (not day-streaks)
- [ ] Category awards, recovery awards
- [ ] New tables only; no grade math changes

## Notifications & widgets (enhanced)

- [ ] Context-aware notifications (“You haven’t done Coco’s teeth today”)
- [ ] Per-day reminder times for n-times/week tasks
- [ ] Home screen widget: weekly grade + today’s remaining tasks (App Groups / cache if needed)

## Reports & data

- [ ] Monthly report card
- [ ] Yearly report card
- [ ] Export CSV or JSON
- [ ] Task archiving UI (view / restore archived — field exists in MVP)

## Polish

- [ ] Dark/light theme toggle (MVP uses system)
- [ ] Companion cosmetics (outfits, room decor)

---

## Changelog (optional)

| Date | What changed |
|------|----------------|
| 2026-06-20 | Initial checklist from design doc v4 |

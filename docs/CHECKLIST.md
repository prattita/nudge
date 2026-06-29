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

**Next up:** Step 0 — Install Xcode (if not installed), then Step 1 — Xcode project scaffolding

### Notes / blockers

<!-- Agents: log anything that blocks the next step -->

- Xcode install status: _unknown — confirm with user_
- No Xcode project in repo yet

---

## Step 0 — Environment (pre-build)

- [ ] Install Xcode from Mac App Store (~12 GB)
- [ ] Open Xcode once; allow additional components to install
- [ ] Confirm iOS Simulator works (any sample project or after Step 1)
- [ ] Optional: install SF Symbols app from [developer.apple.com/sf-symbols](https://developer.apple.com/sf-symbols)
- [ ] Repo cloned; Cursor + Xcode workflow understood (edit in Cursor, build in Xcode)

---

## Step 1 — Xcode project & app scaffolding

**Goal:** App launches in simulator with three tabs (placeholder content).

- [ ] Create new Xcode project: iOS → App → SwiftUI + SwiftData → name **Nudge**
- [ ] Set minimum deployment target to **iOS 17**
- [ ] Add project to this repo (sensible folder, e.g. `Nudge/` or root — stay consistent)
- [ ] Replace `ContentView` with `TabView`: Today, Goals, Progress
- [ ] Create `TodayView.swift`, `GoalsView.swift`, `ProgressView.swift` (placeholder text)
- [ ] Add SF Symbols tab icons
- [ ] Add `.gitignore` entries for Xcode user state (if not already)
- [ ] **Verify:** ⌘R runs app; all three tabs switch correctly

---

## Step 2 — Data models (SwiftData)

**Goal:** Local database with CloudKit-ready models; preset categories on first launch.

### Models

- [ ] `NudgeTask` — all fields per spec (incl. `autoCompleteFromHealthKit`, `isArchived`, `createdAt`)
- [ ] `TaskInstance` — `dueDate`, `status`, `completedAt`, `source`, relationship to task
- [ ] `NudgeCategory` — `name`, `colorHex`, `isPreset`, `isHidden`
- [ ] Enums stored as `String` in persistence; typed enums in code
- [ ] `scheduledWeekdays` as comma-separated string (not `[Int]` array)
- [ ] CloudKit rules: default values on properties; optional relationships
- [ ] Wire models into `NudgeApp` / `ModelContainer`

### First launch

- [ ] Seed 4 preset categories if none exist (Health, Fitness, Pet Care, Mind + colors)
- [ ] **Verify:** app builds; container initializes without crash

---

## Step 3 — Today view (task list & completion)

**Goal:** Tasks due today, grouped by category; weekly grade + today progress; check/uncheck.

- [ ] Query tasks due **today** (respect frequency + `createdAt`)
- [ ] Group by category (hide `isHidden` presets with no tasks — if applicable)
- [ ] Task row: emoji, title, frequency label, checkbox
- [ ] Check → create `TaskInstance` (`status: completed`, `completedAt: Date()`, `source: manual`)
- [ ] Uncheck → delete instance (same calendar day only)
- [ ] Header: date, “X of Y done today”, **weekly** letter grade badge
- [ ] Implement `GradeCalculator` (start minimal; full rules in Step 6/7 if split)
- [ ] Accountability nudge when tasks remain incomplete
- [ ] **Verify:** toggling tasks updates today bar and weekly grade live

---

## Step 4 — Add & edit task flow

**Goal:** `TaskFormView` sheet for create and edit.

- [ ] “+” button on Today and Goals nav bars
- [ ] Fields: title, emoji, frequency, day/date pickers, category, optional reminder time
- [ ] “New category” inline (name + color)
- [ ] Edit via pencil on Goals expanded row (not expand tap)
- [ ] Safe edits in place; **schedule edits apply from tomorrow** (history preserved)
- [ ] Validation on save
- [ ] **Verify:** new task appears on correct days; edit updates as specified

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

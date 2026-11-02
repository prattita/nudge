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

**Next up:** MVP smoke test + run on physical iPhone

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

**Goal:** All active tasks, expandable week dots (no mid-week letter badges).

- [x] List non-archived tasks with week fraction (not live letter)
- [x] Expand row → 7-day dot grid (✓ / ✗ / today / upcoming / not scheduled)
- [x] Completion fraction: “X of Y due this week”
- [x] Pencil → edit sheet (separate from expand)
- [x] Swipe → archive (`isArchived = true`)
- [x] **Verify:** built; smoke-test expand/dots/archive in Simulator

---

## Step 6 — Week history & breakdowns

**Goal:** Extend Week tab — multi-week chart + per-task/category breakdowns. (Live mid-week letters stay out; letters only for completed weeks.)

- [x] Report card for **completed** weeks (Week tab)
- [x] Multi-week bar chart (weeks since first task, min 1 bar; current week faded / no letter)
- [x] Completed weeks: full Mon–Sun aggregate; current week: through-today progress only
- [x] Per-task breakdown for selected week (fraction mid-week; letter if week completed)
- [x] Per-category summary for selected week
- [x] Swift Charts
- [x] History includes **archived** tasks (archive ≠ erase past)
- [ ] **Verify:** chart and grades match `GradeCalculator` in Simulator

---

## Step 7 — Backfill & miss recording

**Goal:** No silent skips; misses recorded on app open.

- [x] `lastBackfillDate` in `@AppStorage` (first launch: start of today, no backfill)
- [x] On open: scan `lastBackfillDate` → yesterday for due tasks without instances
- [x] Respect `scheduleEffectiveFrom` via `TaskSchedule.isDue` (no retroactive misses)
- [x] Create `TaskInstance` with `status: missed` where needed
- [x] Update `lastBackfillDate` to yesterday after processing
- [x] Brief UI summary alert when backfill records misses
- [x] After backfill: missed days **final for MVP** (no makeup — Option D is post-MVP)
- [ ] **Verify:** don’t open app for 2+ days → misses appear; grades update

---

## Step 8 — CloudKit sync

**Goal:** iCloud backup and multi-device sync.

- [x] Enable iCloud capability + CloudKit container (`Nudge.entitlements` → `iCloud.com.prattita.Nudge`)
- [x] Background Modes → Remote notifications (`INFOPLIST_KEY_UIBackgroundModes`)
- [x] `ModelConfiguration` with private CloudKit DB (+ local fallback if CloudKit unavailable)
- [ ] **Manual in Xcode:** select your Team on the Nudge target (Signing & Capabilities); confirm iCloud CloudKit shows the container
- [ ] Simulator/device signed into iCloud with same Apple ID
- [ ] Test on two devices or simulator + device (same Apple ID)
- [ ] **Verify:** create task on one device → appears on other
- [ ] Note: first enable may need deleting the app once (store migration local → CloudKit)

---

## Step 9 — Local notifications

**Goal:** Optional per-task reminder time.

- [x] Request notification permission (first launch / app open)
- [x] `NotificationManager` — schedule / cancel (21-day one-shot horizon, refreshed on launch)
- [x] On save: schedule for task’s scheduled days at `reminderTime`
- [x] On edit/archive/complete today: reschedule or cancel appropriately
- [x] Monthly/yearly: covered via due-day one-shots in horizon
- [x] MVP: one time applies to all scheduled days (n-times/week)
- [ ] **Verify:** Allow notifications → set reminder a minute ahead → fires; complete cancels today’s

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

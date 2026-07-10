# Dream Chaser — Design & Brainstorm

Codename: **Dream Chaser**. An iOS app for young men and women with a high
drive for success: you design your optimal day, execute it daily, and climb
toward one ultimate goal — while the app quietly guards the foundations
(fitness, diet, skincare, a clean space) that ambition burns out without.

## 1. Positioning & tone

- **Not a to-do app.** To-do apps manage chaos; Dream Chaser manages a
  *standard*. The user defines their ideal day once, then the app's only
  question every day is: did you live it?
- **Tone:** confident coach, not drill sergeant, not cheerleader. Short,
  declarative copy ("Win the day, one check at a time"). No guilt mechanics —
  a missed day is data, not shame.
- **Audience:** 16–30, ambitious, phone-native, motivated by progress
  visualization and streaks, allergic to bloated enterprise-y UI.
- **Name ideas** if "Dream Chaser" stays a codename: *Ascend, Momentum, Forge,
  NorthStar, Protocol, Summit, Relentless.*

## 2. Design language — Liquid Glass

Built natively on iOS 26's Liquid Glass so the app feels like part of the OS:

- **Content on glass:** every card (routine section, goal, stat tile) is a
  `glassEffect` surface floating over a soft aurora gradient (purple → indigo
  → teal). Glass needs color beneath it to refract — never flat gray.
- **Controls:** primary CTAs use `.buttonStyle(.glassProminent)`, secondary
  actions `.glass`. The tab bar is the system Liquid Glass bar and minimizes
  on scroll (`tabBarMinimizeBehavior(.onScrollDown)`) so content owns the
  screen.
- **Color:** one hero accent (electric purple) + per-section user-chosen
  colors from a 10-color palette. Dark mode is the "hero" appearance — this
  audience lives in dark mode; glass glows against it.
- **Type:** SF Pro; rounded design for all numbers (progress, streaks) so
  stats feel friendly; serif italic for quotes so they feel like epigraphs.
- **Motion & haptics:** checkmarks use symbol-replace transitions; progress
  rings spring; every completion fires `.sensoryFeedback(.success)`. Checking
  something off must feel *good* — that micro-reward is the retention loop.

## 3. Information architecture

| Tab | Job |
| --- | --- |
| **Today** | The daily contract: quote banner, progress ring + streak flame, cleaning prompt when due, every routine section as a checklist |
| **Goals** | Ultimate goal(s) → ordered mini-goal ladder; only the next rung is unlocked |
| **Wellbeing** | Apple Health tiles (steps, energy, exercise, sleep), diet check-in with 7-day strip, AM/PM skincare, space-reset cadence |
| **Quotes** | Hero quote of the day, internet refresh, favorites, full library |
| **Settings** | Reminders, health access, data reset |

## 4. Core feature decisions

**Routine engine.** Sections (Gym, Study, Work, Plan, Learn a Skill by
default) hold checkable items. Completions are stored per-day, so history,
streaks, and future weekly reviews come free. Everything is user-editable:
name, SF Symbol icon, color, items.

**Goal ladder.** Mini goals complete *in order* — a deliberate constraint.
Ambitious people scatter; the ladder forces sequencing and makes "what's
next?" always a one-word answer. The current rung wears a NEXT badge; later
rungs are locked. Unchecking is only allowed on the most recent rung.

**Wellbeing = foundations.** Read-only HealthKit (steps, active energy,
exercise minutes, last night's sleep). Diet is a deliberate one-tap binary —
"On track / Slipped" — because friction kills food logging; the 7-day dot
strip gives the trend at a glance. Skincare is split AM/PM with its own steps.

**Space reset.** Due every 7 days after the last completion. When due, a
prompt card appears on Today ("Done today / Already did it / Later") and an
optional weekly notification fires on the user's chosen day.

**Quote engine.** Seed JSON (drop-in replaceable with the user's database) +
one internet fetch per day, cached in the App Group so widgets show the same
quote. Deterministic seed rotation means offline users still get a "new"
quote daily.

**Widgets.** Three: routine progress ring (with *interactive* check-off in
the medium size via App Intents), daily quote (Home + Lock Screen), and goal
progress with the next mini goal. Widgets read the shared SwiftData store —
the Home Screen is the real front door of a habit app.

## 5. Suggested additions (the brainstorm) — now built ✅

All the software-only ideas from the original brainstorm are implemented:

1. ✅ **Momentum score** — 0–100 blending today's routine (45%), streak (20%,
   saturates at 14 days), 7-day diet adherence (20%), and last night's sleep
   vs. an 8h target (15%). Lives in the Today header, in a dedicated
   `MomentumWidget` (Home Screen + Lock Screen circular), and is cached in
   the App Group (`MomentumEngine`).
2. ✅ **Morning brief / evening shutdown** — `MorningBriefView` (quote → the
   plan → today's goal rung → "I commit to today") and `EveningReviewView`
   (day score → win of the day → reflection). Cards surface on Today before
   noon / after 6 PM until done; entries persist as `JournalEntry`.
3. ✅ **Weekly review report card** — `WeeklyReviewView` (chart icon on
   Today): per-section 7-day completion bars, diet %, sleep average, focus
   minutes, active days, goal rungs, streak → weekly score + letter grade,
   plus a shareable rendered report-card image.
4. ✅ **Focus timer with Live Activity** — "Start focus session" on any
   section (25/50/90 min). Countdown runs as a Live Activity on the Lock
   Screen and in the Dynamic Island; completed minutes log as
   `FocusSession` and feed the weekly review.
5. ✅ **Siri & Shortcuts** — `DreamChaserShortcuts`: "Log my diet", "I
   cleaned my room", "Complete my next step" (+ the widget toggle intent is
   Shortcuts-visible too).
6. ✅ **Routine templates / onboarding** — first launch presents five
   protocols: Balanced Chaser, 5 AM Club, Student Athlete, Founder Mode,
   Glow-Up Protocol. Reset-all-data sends you back through the picker.
7. ✅ **Streak insurance** — earn one freeze token per perfect week (every
   item, all 7 days; max 3 banked). A token auto-spends to bridge a missed
   day so one bad day can't torch the chain. Balance shows in the Today
   header, the Momentum widget, and Settings.
8. ✅ **Accountability partner (v1)** — the weekly report card renders to an
   image with a one-tap ShareLink ("send it to your accountability
   partner"). The full version (partner sees your misses) needs a backend —
   see below.
9. ✅ **Photo progress vault** — private on-device photos
   (`ProgressPhoto`, external storage), added via the system photo picker,
   with then-vs-now side-by-side compare. Linked from Wellbeing.
10. ✅ **Anti-burnout guardrails** — if last night's sleep was under 6h while
    you're 3+ days into a streak, Today shows a "Recovery mode suggested"
    card telling you to go lighter and protect the streak.
11. ✅ **Coach (v1, deterministic)** — "Coach's notes" in the weekly review:
    rule-based, on-device insights (strongest/weakest pillar, diet and sleep
    callouts, focus minutes, rungs climbed). Swappable later for a real AI
    coach via the Claude API without changing the UI.

### Still on the roadmap (need things code alone can't provide)

- **Apple Watch app** — requires adding a watchOS target, which Xcode
  generates far more reliably than a hand-written project file: File → New →
  Target → watchOS → App, check "Watch App for Existing iOS App", then share
  the `Shared/` folder with the new target. The models and engine are
  already target-agnostic, so the watch checklist is mostly UI.
- **True accountability partner** — needs a backend (or CloudKit sharing)
  so a friend can see your report automatically.
- **iCloud sync (CloudKit)** — add the iCloud capability + container, then
  make relationships optional and give every attribute a default (CloudKit's
  SwiftData rules) before switching the `ModelConfiguration` to CloudKit.
- **AI coach** — replace `coachNotes()` in `WeeklyReviewView` with a call to
  an LLM over the same weekly stats.
- **Monetization** — free: 3 sections, 1 goal, core widgets. Pro
  (subscription): unlimited everything, Watch app, report cards, AI coach.

## 6. Technical notes

- **Stack:** SwiftUI + SwiftData (iOS 26), WidgetKit + App Intents, HealthKit
  (read-only), UserNotifications. No third-party dependencies.
- **Sharing:** one App Group container holds the SwiftData store and quote
  cache; app and widget extension both mount it (`Shared/` folder is compiled
  into both targets).
- **Privacy:** everything on-device; the only network call is the daily quote
  fetch. This is a marketable feature for this audience — say it loudly.
- **Day keys:** completions are stored as `yyyy-MM-dd` strings in the user's
  time zone — streaks stay correct across travel and DST.

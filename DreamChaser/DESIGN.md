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

## 5. Suggested additions (the brainstorm)

Rough priority order — ✦ = highest leverage next:

1. ✦ **Momentum score** — a single 0–100 number blending routine completion,
   streak, diet adherence, and sleep. One number to protect daily; put it on
   the small widget. (The data model already records everything needed.)
2. ✦ **Morning brief / evening shutdown** — a 30-second guided flow: morning
   shows the quote + today's plan + "commit"; evening asks what won the day
   and one line of journaling. Bookends dramatically boost adherence.
3. ✦ **Weekly review report card** — every Sunday: completion % per section,
   diet ratio, sleep average, goal rungs climbed, letter grade. Sharable
   image → organic marketing.
4. **Focus timer per section** — tap Gym/Study to start a timed session with
   a Live Activity in the Dynamic Island; logged minutes feed the section.
5. **Siri & Shortcuts** — "Hey Siri, check off gym" (the App Intent already
   exists), plus suggested automations (when I arrive at the gym…).
6. **Apple Watch app** — the checklist on the wrist + complications; huge for
   gym and skincare moments where the phone is away.
7. **Routine templates** — onboarding quiz builds the first routine ("5 AM
   Club", "Student Athlete", "Founder Mode", "Glow-Up Protocol").
8. **Streak insurance** — one earned "freeze token" per perfect week protects
   a streak from a bad day. Keeps streaks motivating instead of fragile.
9. **Accountability partner** — share your report card with one friend;
   optional "they see if I skip" pressure toggle.
10. **Photo progress vault** — private monthly fitness/skincare photos,
    side-by-side compare. Pairs naturally with the wellbeing tab.
11. **Anti-burnout guardrails** — if sleep trends under 6h while completion
    is 100%, suggest a recovery day. Chasing dreams ≠ grinding to dust; this
    also differentiates the app ethically.
12. **AI coach (later)** — weekly natural-language summary and routine
    adjustment suggestions from on-device data.
13. **iCloud sync / CloudKit** — multi-device + backup, prerequisite for any
    social features.
14. **Monetization (later)** — free: 3 sections, 1 goal, core widgets. Pro
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

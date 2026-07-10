# Dream Chaser 🏔️ (codename)

A SwiftUI iOS app for people with a high drive for success: break your optimal
day into customizable routine sections, chase your ultimate goal one mini goal
at a time, track wellbeing (Apple Health, diet, skincare, weekly space reset),
and get a daily dose of discipline from the quote engine — with Home Screen
and Lock Screen widgets, styled with iOS 26 **Liquid Glass**.

On top of the core loop: an onboarding protocol picker (5 AM Club, Student
Athlete, Founder Mode, Glow-Up…), a 0–100 **momentum score** with streak
freeze tokens, morning brief / evening shutdown bookends, deep-focus timers
with **Live Activities** in the Dynamic Island, a weekly review with a letter
grade and shareable report card, a private progress-photo vault, Siri
shortcuts, and an anti-burnout recovery guardrail.

> The full product brainstorm (design language, feature specs, and suggested
> additions) lives in [DESIGN.md](DESIGN.md).

## Requirements

- **Xcode 26 or newer** (the UI uses iOS 26 Liquid Glass APIs: `glassEffect`,
  `GlassEffectContainer`, `.buttonStyle(.glass)`)
- iOS 26 simulator or device
- macOS with an Apple ID (free account is enough for the simulator)

## Getting started

1. Clone the repo and open `DreamChaser/DreamChaser.xcodeproj` in Xcode.
2. Pick the **DreamChaser** scheme and an iOS 26 simulator → **Run**. That's
   it for the simulator — the default bundle IDs and App Group work as-is.
3. Widgets: long-press the Home Screen → **Edit** → **Add Widget** → search
   "Dream Chaser". The medium routine widget has interactive checkboxes.

### Running on a real device

Personal identifiers are placeholders (`com.example.dreamchaser`). Change them
once, in these spots:

| What | Where |
| --- | --- |
| Bundle IDs | Both targets → Signing & Capabilities (keep the widget ID prefixed by the app ID) |
| Team | Both targets → Signing & Capabilities |
| App Group | `Shared/AppGroup.swift` **and** both `.entitlements` files (`DreamChaser/DreamChaser.entitlements`, `DreamChaserWidgets/DreamChaserWidgets.entitlements`) |

The App Group is what lets the app and widgets share the SwiftData database
and the cached daily quote. HealthKit requires the capability on your App ID —
Xcode's automatic signing handles this when you set your team.

## Project layout

```
DreamChaser/
├── DreamChaser.xcodeproj
├── DreamChaser/               # App target
│   ├── DreamChaserApp.swift   # Entry point, seeding, quote refresh
│   ├── RootView.swift         # Liquid Glass tab bar + onboarding cover
│   ├── DreamChaserShortcuts.swift  # Siri / Shortcuts phrases
│   ├── Theme/                 # Glass cards, progress rings, background
│   ├── Views/
│   │   ├── Onboarding/        # Routine template picker (5 AM Club, …)
│   │   ├── Today/             # Sections, checklists, morning/evening bookends
│   │   ├── Goals/             # Ultimate goal → ordered mini-goal ladder
│   │   ├── Focus/             # Deep-focus timer (Live Activity)
│   │   ├── Review/            # Weekly review, grade, shareable report card
│   │   ├── Wellbeing/         # HealthKit, diet, skincare, photo vault
│   │   ├── Quotes/            # Quote of the day + library + favorites
│   │   └── Settings/          # Reminders, tokens, data reset, about
│   └── Services/              # HealthKitService, NotificationService
├── DreamChaserWidgets/        # Widget extension target
│   ├── RoutineProgressWidget  # Progress ring + interactive check-off
│   ├── MomentumWidget         # 0–100 momentum score + streak + tokens
│   ├── QuoteWidget            # Daily quote (Home + Lock Screen)
│   ├── GoalWidget             # Goal progress + next mini goal
│   └── FocusLiveActivity      # Lock Screen + Dynamic Island countdown
└── Shared/                    # Compiled into BOTH targets
    ├── Models/                # SwiftData models (routine, goals, wellbeing,
    │                          #   journal, focus sessions, progress photos)
    ├── Quotes/                # Quote engine + quotes-seed.json
    ├── Intents/               # Widget toggle + Siri intents
    ├── MomentumEngine.swift   # Momentum score + streak freeze tokens
    └── SharedStore.swift      # App Group SwiftData container + seeding
```

## Plugging in your own quotes database

The bundled library is `Shared/Quotes/quotes-seed.json` — a plain array of
`{ "text": ..., "author": ... }`. Replace its contents with your own database
whenever you have it; nothing else needs to change. The daily internet quote
comes from ZenQuotes (`https://zenquotes.io/api/today`); to use a different
API or your own backend, edit `refreshFromInternet()` in
`Shared/Quotes/Quote.swift` — it's the single integration point.

## Notes & troubleshooting

- **Apple Health on the simulator** works: open the Health app in the
  simulator and add sample steps/sleep to see the tiles fill in. If numbers
  stay at zero on a device, check Health → Sharing → Apps → Dream Chaser.
- **First launch** opens the protocol picker — choose a routine template
  (every section and item is editable afterwards). Skincare steps and the
  weekly room-reset task are seeded automatically.
- **Live Activities** (focus timer in the Dynamic Island) can be disabled
  system-wide in Settings → Face ID & Passcode / per-app; the in-app timer
  works regardless.
- **Weekly cleaning reminder** defaults to Sunday 10:00; change the day in
  Settings. The Today tab also shows an in-app prompt whenever a reset is due,
  with "Done today / Already did it / Later" options.
- **All data stays on device** (SwiftData + App Group). No accounts, no
  servers; the only network call is the daily quote fetch.

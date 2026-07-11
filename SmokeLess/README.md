# SmokeLess 🌬️

A native iOS + watchOS app for cutting down and quitting smoking — cigarettes, vape / e-cigarettes, IQOS / heated tobacco, or anything else. Clone the repo, open the project in Xcode, press Run.

## Features

| Area | What it does |
|---|---|
| **Any smoking type** | Cigarettes, vape (pods), IQOS (sticks) or custom units, each with tailored defaults for consumption and price |
| **Two quit modes** | Quit completely (any slip resets the streak) or reduce gradually (a daily allowance; staying under it keeps the streak) |
| **Streak system** | Live streak ring, hours counter for day one, best-streak memory, and 15 unlockable badges |
| **Money saved** | Real-time savings ticker (updates every second) computed from your baseline habit minus honest slip logs |
| **Wishlist** | Add things you want to buy; each item fills up as savings grow, and "buying" it deducts from your pool |
| **Daily problems of smoking** | A rotating fact every day (32 facts across health, vaping, heated tobacco, money, environment…), an optional 9 AM notification, and a browsable fact library |
| **Craving SOS** | Guided 4-7-8 breathing animation, rotating distraction tips, and a "beat it" button that logs the win |
| **Apple Health / Fitness** | Reads today's active energy + exercise minutes onto the dashboard; writes completed breathing exercises as mindful minutes |
| **Body recovery timeline** | 11 health milestones (20 minutes → 1 year) with live progress since your last smoke |
| **Myth-check quiz** | 8 true/false questions busting common smoking and vaping myths |
| **3-color themes** | Three palettes — Fresh Mint, Deep Ocean, Warm Sunset — each defined by exactly three colors (primary / secondary / accent), applied across app, widgets and watch |
| **Home & lock screen widgets** | Streak widget (small + lock screen circular/rectangular/inline) and Savings widget (small/medium + lock screen), with deep links into Craving SOS and the wishlist |
| **Apple Watch app** | Streak ring, money saved, and one-tap "I resisted" / "I slipped" actions that sync back to the iPhone via WatchConnectivity |
| **Watch-face complications** | Streak and money-saved complications (circular, corner, inline, rectangular) |
| **Journal** | 7-day usage chart, full history of slips and beaten cravings, swipe to delete |

## Requirements

- **Xcode 16 or newer** (the project uses folder-synchronized groups)
- iOS 17+ device or simulator; watchOS 10+ for the watch app
- Xcode may prompt to download the watchOS simulator platform on first build — let it

## Getting started

1. Clone the repository and open `SmokeLess/SmokeLess.xcodeproj` in Xcode.
2. Select the **SmokeLess** scheme and an iPhone simulator, then Run. That's it for the simulator.
3. To run the watch app: select the **SmokeLessWatch** scheme and a paired watch simulator.

### Running on a real device

1. Select each target (SmokeLess, SmokeLessWidgets, SmokeLessWatch, SmokeLessWatchWidgets) and set **your team** under Signing & Capabilities.
2. Change the bundle identifiers from `com.fundable.smokeless*` to identifiers under your own domain (keep the same suffix pattern: `.widgets`, `.watchkitapp`, `.watchkitapp.widgets`).
3. The app uses two capabilities, declared in `Config/*.entitlements`:
   - **App Groups** (`group.com.fundable.smokeless`) — shares data between the app and its widgets. If you change the group id, also update `Persistence.appGroupID` in `Shared/Persistence.swift`.
   - **HealthKit** (iOS app only) — activity read + mindful-minutes write.
   If your (free) team can't provision these, delete the entries from the entitlements files; the app degrades gracefully (widgets fall back to standard defaults, Health features hide).

## Project layout

```
SmokeLess/
├── SmokeLess.xcodeproj      # 4 targets: app, widgets, watch app, watch widgets
├── SmokeLess/               # iOS app (SwiftUI)
│   ├── Home/                # Dashboard, streak ring, daily fact, badges
│   ├── Onboarding/          # 5-step setup flow
│   ├── Craving/             # SOS sheet + 4-7-8 breathing exercise
│   ├── Journal/             # Usage chart, history, slip logging
│   ├── Wishlist/            # Savings-funded wishlist
│   ├── Learn/               # Fact library, recovery timeline, quiz
│   ├── Settings/            # Profile, themes, notifications, Health
│   └── Support/             # HealthKit, notifications, watch sync
├── Shared/                  # Compiled into all 4 targets
│   ├── Models.swift         # SmokingType, UserProfile, AppState…
│   ├── Stats.swift          # Streak / money / units engine
│   ├── Persistence.swift    # App-group JSON storage + widget reload
│   ├── Theme.swift          # The three 3-color palettes
│   ├── HealthMilestones.swift, DailyFacts.swift, Achievements.swift
│   └── WidgetShared.swift   # Shared TimelineProvider + entry
├── SmokeLessWidgets/        # iOS home/lock screen widgets
├── SmokeLessWatch/          # watchOS app
├── SmokeLessWatchWidgets/   # watch-face complications
└── Config/                  # Entitlements + widget Info.plists
```

## How the numbers work

- **Baseline** = units/day × price/unit, from onboarding (editable in Settings).
- **Money saved** = (baseline units for the elapsed time − logged slips) × price/unit. Slips honestly reduce savings.
- **Streak** — quit mode: whole days since the last slip (or start). Reduce mode: whole days since the last day you exceeded your allowance.
- **Wishlist pool** = money saved − prices of items marked purchased.
- **Recovery timeline** anchors to your last logged smoke.

## Feature brainstorm (future ideas)

- Craving-time predictions from logged slip times (e.g. "your risky hour is 9 PM")
- Buddy mode: share your streak with a friend for accountability
- Nicotine-strength taper planner for vapers (mg/ml step-down)
- Location triggers: geofenced nudges near places you used to smoke
- StoreKit tip jar funded by one day of your old habit
- Siri Shortcuts / App Intents: "Hey Siri, I'm craving"
- Live Activity during a craving: countdown on the lock screen / Dynamic Island
- CSV export and yearly report
- Local leaderboard of best streaks across your devices' family sharing

## Disclaimer

SmokeLess is a motivational tracker, not a medical device. Health-timeline content is based on widely published WHO/CDC guidance and is educational only. For help quitting, talk to a healthcare professional or a local quitline.

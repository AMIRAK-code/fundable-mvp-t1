# Pet Monitor (iOS)

A calm, native SwiftUI app for keeping gentle, daily awareness of a pet's
wellbeing — for **dogs, cats, rabbits, hamsters, and parrots**.

> Pet Monitor never diagnoses. It helps you notice changes early and always
> points you to your veterinarian.

## Features

- **Pet profiles** — choose your species, name, birth date, weight, and a
  muted avatar color. Multiple pets supported, with a quick switcher.
- **Periodic check-in cycle** — log mood, energy, appetite, water intake,
  weight, unusual signs, and notes on the rhythm you choose (morning &
  evening, daily, every other day, or weekly), with gentle local
  notification reminders and a check-in streak.
- **Wellness score** — a 0–100 rolling score from the last 7 days of
  check-ins, reduced by logged symptoms, shown as a calm progress ring.
- **Health check (pre-diagnosis)** — a species-specific, rule-based symptom
  checker. Pick observed signs and get possible causes, self-care guidance,
  and an urgency level (*keep an eye on it / see a vet soon / contact a vet
  now*). Every screen refers you to your vet; species red-flag lists are
  always visible.
- **Vet alerts on Apple Watch** — urgent signs trigger a local notification
  which iOS automatically mirrors to a paired Apple Watch (when the iPhone
  is locked). One-tap "call your vet" when you've saved a number.
- **Daily tips** — 60 species-specific care tips that rotate one per day,
  optionally delivered as a morning notification.
- **Trends** — Swift Charts of mood, energy, appetite, and weight over the
  last 30 days, plus a 7-day summary. Weight jumps produce a gentle alert.
- **Home screen widgets** — a *Daily Pet Tip* widget and a *Pet Status*
  widget (wellness ring, streak, next check-in) in small and medium sizes.
- **Local-only data** with JSON export you can share with your vet.

## Design

A deliberately **non-stimulant** look: desaturated sage / sand / mist /
lavender palette, rounded typography, soft blurred background fields, and
**Liquid Glass** cards. On iOS 26 the app uses the real `glassEffect` API;
on earlier systems (or when built with Xcode 16) it falls back to an
equivalent frosted material automatically. Light and dark mode are both
supported. Even the "urgent" tone is a muted terracotta, not an alarm red.

## Requirements

- **Xcode 16 or newer** (Xcode 26 recommended — that's where Liquid Glass
  renders natively). The project uses Xcode 16's folder-synchronized groups.
- **iOS 17.0+** deployment target.

## Getting started

1. Open `PetMonitor/PetMonitor.xcodeproj` in Xcode.
2. Select the **PetMonitor** scheme and an iPhone simulator, then Run.
   No signing team is needed for the simulator.
3. For a device: select your development team on both the **PetMonitor**
   and **PetMonitorWidgetsExtension** targets and change the bundle
   identifier prefix (`com.example.petmonitor`) to something unique.

### Widgets with live data (optional)

Widgets work out of the box: the tip widget is fully functional, and the
status widget shows a setup hint until data is shared. For **live** pet data
in widgets, the app and extension need a shared App Group:

1. Add the **App Groups** capability to both targets.
2. Use the group id `group.com.example.petmonitor` — or pick your own and
   update `SharedStorage.appGroupID` in `Shared/SharedStorage.swift`.

### Apple Watch alerts

Reminders and urgent vet alerts are local notifications. iOS mirrors them
to a paired Apple Watch automatically when the iPhone is locked and the
watch is on your wrist — no watch app or extra setup is required.

## Project layout

```
PetMonitor.xcodeproj        Xcode project (app + widget extension targets)
PetMonitor/                 App target
  PetMonitorApp.swift       Entry point
  Store/                    PetStore (state + persistence), notifications
  Views/                    Home, check-in, journal, health check, trends,
                            tips, settings, onboarding + glass components
  Assets.xcassets           App icon placeholder, accent color
PetMonitorWidgets/          Widget extension (daily tip + pet status)
Shared/                     Code compiled into both targets:
                            models, storage, theme, tips & symptom libraries
```

## Disclaimer

Pet Monitor offers general guidance to help you notice changes early. It is
not a medical device and never replaces professional veterinary care. If you
are worried about your pet — even a little — contact your veterinarian.

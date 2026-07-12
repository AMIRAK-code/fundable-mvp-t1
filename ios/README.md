# MANE — Engineered Hair Care for Men (iOS)

A native SwiftUI app for men's hair care: a personalized routine built from a
productive onboarding flow, product recommendations aggregated from multiple
data sources, and a **hairline scanner** that analyzes 3–4 photos on device to
estimate whether your hairline is receding, stable or restoring — plus a hair
density index — and tracks both over time.

## Open in Xcode

```bash
git clone <this-repo>
open ios/Mane.xcodeproj
```

- **Requirements:** Xcode 16 or newer, iOS 17.0+ deployment target.
- No dependencies, no package resolution, no signing team required for the
  simulator — clone, open, press ⌘R.
- The project uses Xcode 16 buildable folders (filesystem-synchronized
  groups), so any file you drop into `ios/Mane/` is picked up automatically.

On a real device, select your development team under
*Signing & Capabilities* first. The camera only works on device; in the
simulator use **Choose from library** in the scan flow.

## Features

### Productive onboarding
Nine focused steps — name/age, hair type & length, scalp condition, concerns,
lifestyle (training, swimming, hard water, heat styling, hats), current wash
habits and a single primary goal. The rule-based `RoutineEngine` turns the
profile into:

- a **wash-frequency plan** (scalp type ± exercise/swimming adjustments),
- a **weekly step schedule** (AM/PM, per-weekday) with a "why" behind every
  step,
- **starter product picks** scored against the profile.

### Today dashboard
Daily AM/PM checklist with per-day completion persistence, a streak counter
(≥75% of steps for consecutive days), completion ring, tip of the day, and a
re-scan nudge every 3 weeks.

### Hairline scanner
Guided capture of **front hairline, left temple, right temple and (optional)
crown**. Everything runs on device (`Vision` + custom pixel analysis, no
network):

1. **Face geometry** — `VNDetectFaceLandmarksRequest` finds the face box and
   eyebrow line.
2. **Skin reference** — the lower forehead is sampled to learn *your* skin
   tone in *this* photo's lighting.
3. **Hairline detection** — each pixel column is walked upward from the
   eyebrows until the color departs from the skin reference for several
   consecutive pixels; the median transition across columns is the hairline.
   `hairlineRatio = forehead height ÷ face height` (higher over time suggests
   recession) → displayed as a 0–100 **Hairline index** (higher is better).
4. **Density index** — Otsu thresholding separates hair from scalp in the
   hair region (with a uniform-region fallback) and is blended with a
   horizontal-gradient texture measure (strand edges) → 0–100.
5. **Trends** — the latest session is compared with the average of up to
   three prior sessions; ±4% (hairline) / ±6% (density) bands map to
   **Restoring / Stable / Receding** and **Improving / Stable / Thinning**
   verdicts, with a history chart (Swift Charts).

Every angle result carries a confidence score (column agreement × coverage),
and low-confidence scans are flagged with retake guidance.

> **Disclaimer:** MANE is a grooming companion, not a medical device. The
> estimates are heuristics, sensitive to lighting, angle and hair color. What
> makes them useful is *consistency between sessions*, not absolute accuracy.
> For medical concerns about hair loss, consult a dermatologist.

### Multi-source product data
`DataHub` aggregates the catalog from three sources, merged by product id and
labeled with provenance in the UI:

1. **Curated catalog** — bundled `products.json` (26 products across shampoo,
   conditioner, treatment, serum, styling, oil, supplement, tools).
2. **Grooming tips library** — bundled `tips.json`.
3. **Community feed (remote)** — any URL serving the same JSON shape
   (`{"products": [...], "tips": [...]}`), configurable in Settings, fetched
   with `URLSession`, cached on disk for offline use, and overriding bundled
   entries by id. Host `ios/sample-remote-catalog.json` anywhere (gist, raw
   GitHub, S3) to try it.

Settings shows the live status of every source (loaded / live / cached /
unreachable, item counts, last update).

### Themes — all selectable in Settings
| Theme | Vibe |
|---|---|
| **Arctic** (default) | Deep clinical navy + ice blue — skincare-counter calm |
| **Steel** | Near-black chrome + safety orange — razor-aisle edge |
| **Classic Light** | Clean white + charcoal + blue — bright and minimal |

Theming is a first-class `Palette` (backgrounds, surfaces, text, accents,
gradients, semantic colors) injected via a `ThemeManager` environment object;
every screen, chip, ring and chart follows it.

## Architecture

```
ios/Mane/
├── ManeApp.swift            App entry; injects ThemeManager + AppModel
├── RootView.swift           Onboarding ↔ main tabs switch
├── Theme/AppTheme.swift     3 themes, Palette, ThemeManager
├── Models/                  HairProfile, Product/Tip, Routine, Scan models & trends
├── Services/
│   ├── AppModel.swift       Single source of truth (ObservableObject)
│   ├── RoutineEngine.swift  Rules: profile → routine; product scoring & reasons
│   ├── DataHub.swift        Multi-source catalog aggregation + caching
│   ├── HairlineAnalyzer.swift  Vision + pixel-level hairline/density analysis
│   └── ScanStore.swift      On-device persistence for sessions & photos
├── Views/
│   ├── Onboarding/          9-step flow → results preview
│   ├── Today/               Checklist dashboard
│   ├── Scanner/             Hub + guided capture flow + session detail
│   ├── Products/            "For you" shelf, catalog, product detail
│   ├── Settings/            Themes, profile, data sources, scan data, about
│   └── Components/          Cards, chips, rings, badges, camera picker
└── Resources/               products.json, tips.json
```

- Pure SwiftUI, MVVM-ish with one `AppModel` hub; no third-party code.
- All persistence is local: `UserDefaults` (profile, routine, completions,
  theme) and `Documents/ManeScans` (scan JSON + JPEGs).
- Privacy: photos and analysis never leave the device; the only network call
  is the optional community feed you configure yourself.

## Roadmap ideas

- Norwood-stage estimation and side-by-side photo overlay comparisons
- ARKit-guided capture for repeatable head pose
- HealthKit sleep/stress correlation with shedding
- Reminders/notifications for wash days and re-scans
- CoreML segmentation model to replace the heuristic hairline detector

# Carl — iOS app

Native SwiftUI implementation of the Claude Design handoff (`docs/Carl.dc.html`),
all 18 screens, matching the brand: navy `#1B2A4A` + royal blue `#2563EB`,
Plus Jakarta Sans, and the briefcase-in-magnifier Carl mark.

## Run it

1. Open `ios/Carl.xcodeproj` in **Xcode 16+** (the project uses filesystem-
   synchronized groups, so new files added to `Carl/` are picked up automatically).
2. Select an iPhone simulator and hit **Run**.
3. The app launches into a **Screen Gallery** — every screen grouped by section,
   plus a swipeable **Hero Flow** (Welcome → Interview → Searching → Reveal →
   Paywall → Queue → Dashboard).

Requires iOS 17+. No third-party dependencies.

## Project layout

```
Carl/
  CarlApp.swift            App entry → ScreenGallery
  Models.swift             JobMatch + sample data
  ScreenGallery.swift      Browsable index of all screens + Hero Flow
  DesignSystem/
    Theme.swift            Brand colors + typography helpers
    CarlMark.swift         The Carl mascot (Canvas), + CarlAvatar (animated)
    Components.swift       PhoneFrame, status bar, buttons, chips, etc.
  Screens/
    Screens_Onboarding.swift   01–05  Meet Carl → Confirm
    Screens_MagicMoment.swift  06–09  Searching A/B → Reveal A/B
    Screens_Paywall.swift      10–12  Paywall A/B + Buy-more sheet
    Screens_Core.swift         13–16  Queue, Dashboard, Detail, Settings
    Screens_Supporting.swift   17–18  All caught up, Push notification
```

Each screen is rendered inside a fixed 402×872 `PhoneFrame` (notch, status bar,
home indicator) and scaled to fit the device by `ScaledPhone`, so it looks right
on any simulator.

## Fonts

The design uses **Plus Jakarta Sans**. Out of the box the app falls back to the
system rounded font (the closest friendly-geometric match) so it builds with zero
setup. To use the real typeface:

1. Add the Plus Jakarta Sans `.ttf` files to the `Carl/` folder.
2. Register them under `UIAppFonts` in the target's Info settings.
3. Set `CarlFont.usePlusJakarta = true` in `DesignSystem/Theme.swift`.

## Status

This is the **UI layer** — faithful, navigable screens with sample data and
animation (searching counters, scanning rings, shimmer, celebration). It is not
yet wired to a backend. Next up (see `/docs`): resume parsing, the Adzuna/USAJOBS
discovery adapters, the Greenhouse/Lever apply adapters, StoreKit credit packs,
and real application tracking.

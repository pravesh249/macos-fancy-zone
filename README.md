# FancyZones for macOS

A macOS window management utility inspired by [Windows PowerToys FancyZones](https://github.com/microsoft/PowerToys/tree/main/src/modules/fancyzones).

Snap windows into predefined zones by dragging them while holding **Shift** or **Option**.

![Menu Bar](docs/menubar.png)

## Features

- 🪟 **Zone snapping** — hold Shift or Option while dragging any window
- 📐 **Multiple layouts** — Wide Center (30/40/30), Priority Grid (25/50/25), 3-Column, 2×2 Grid
- 🔄 **Cycle layouts** from the menu bar icon
- 🚫 **No Dock icon** — lives quietly in the menu bar
- ⚡ **Lightweight** — ~150KB binary, no dependencies

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac
- **Accessibility permission** (required to move/resize other apps' windows)

## Quick Start

### Run the pre-built app

1. Download `FancyZones.app` from [Releases](../../releases)
2. Right-click → **Open** (to bypass Gatekeeper on first launch)
3. Grant **Accessibility** permission when prompted:
   System Settings → Privacy & Security → Accessibility → enable FancyZones
4. The grid icon (⊞) appears in your menu bar — you're ready

### Build from source

Requires Swift 6 / Xcode Command Line Tools.

```bash
git clone https://github.com/YOUR_USERNAME/FancyZones.git
cd FancyZones
bash build_app.sh        # builds FancyZones.app in the project root
open FancyZones.app
```

Or run directly without bundling:

```bash
swift run FancyZones
```

## Usage

| Action | Result |
|---|---|
| Hold **Shift** or **Option** + drag a window | Zone overlay appears |
| Move mouse over a zone | Zone highlights in blue |
| Release mouse button | Window snaps to that zone |
| Click menu bar icon → **Switch Layout** | Cycles through layouts |

## Layouts

| Layout | Zones | Description |
|---|---|---|
| Wide Center | 30% \| 40% \| 30% | Default — equal side columns, wide center |
| Priority Grid | 25% \| 50% \| 25% | Narrow sides, large center |
| 3-Column | 33% \| 33% \| 33% | Equal thirds |
| 2×2 Grid | 4 quadrants | Full grid |

## Adding a Custom Layout

Edit [`Sources/FancyZonesCore/ZoneEngine.swift`](Sources/FancyZonesCore/ZoneEngine.swift) and add a new `static let` to `ZoneLayout`:

```swift
public static let myLayout = ZoneLayout(
    name: "My Layout",
    spacing: 0,          // gap in points between zones (0 = no gap)
    zones: [
        Zone(rect: CGRect(x: 0.0, y: 0.0, width: 0.5, height: 1.0)),  // left half
        Zone(rect: CGRect(x: 0.5, y: 0.0, width: 0.5, height: 1.0)),  // right half
    ]
)
```

Coordinates are normalized (0.0–1.0), top-left origin. Then add it to `cycleLayout()` in `OverlayManager.swift`.

## Running Tests

```bash
swift run FancyZonesCoreTests
```

32 tests covering zone layout definitions, hit-testing, coordinate conversion, and AX frame calculation.

## Architecture

```
Sources/
├── FancyZonesCore/          # Pure logic library (no AppKit, fully testable)
│   └── ZoneEngine.swift     # Zone models, layouts, hit-testing, coordinate math
└── FancyZones/              # Main app (AppKit + SwiftUI)
    ├── main.swift            # Entry point
    ├── AppDelegate.swift     # Menu bar setup, permissions check
    ├── InputMonitor.swift    # Global mouse event monitoring
    ├── OverlayManager.swift  # Orchestrates overlay + snapping
    ├── OverlayPanel.swift    # Transparent NSPanel + SwiftUI zone view
    ├── WindowManager.swift   # AXUIElement window move/resize
    └── AccessibilityManager.swift
Tests/
└── FancyZonesCoreTests/     # Standalone test runner (no XCTest needed)
```

## License

MIT

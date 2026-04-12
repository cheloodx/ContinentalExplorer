# Continental Explorer

Premium, high-performance navigation ecosystem designed for cross-European travel. Built with SwiftUI for iOS 17+.

## Features
- **Master Pilot Dashboard** — AR-enhanced navigation HUD with glassmorphic overlays
- **Offline Maps** — Tile pre-fetching with CoreData storage and delta updates
- **Speed/Radar Alerts** — Geo-fencing with CLCircularRegion and community reports
- **Eco-Voyager Mode** — OLED-optimized dark theme with reduced animations
- **Live Alert System** — Real-time community safety reports via WebSocket

## Tech Stack
- **Platform:** iOS 17.0+
- **Framework:** SwiftUI + Combine / Swift Concurrency
- **Maps:** Apple MapKit (with Mapbox SDK option)
- **Storage:** CoreData for offline map tile management
- **AI:** CoreML for Road Health Scan and Aura AI
- **AR:** ARKit + RealityKit

## Design System
| Token | Value |
|---|---|
| Primary Accent | `#4CD6FF` (Cyan Neon) |
| Secondary Accent | `#FFB68D` (Amber Alert) |
| Background (Dark) | `#101223` |
| Background (OLED) | `#000000` |
| Headlines | Space Grotesk |
| Body | Inter / Plus Jakarta Sans |

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for project generation)

### Setup
```bash
# Install XcodeGen if needed
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Open in Xcode
open ContinentalExplorer.xcodeproj
```

## Project Structure
```
ContinentalExplorer/
├── Theme/          # Design tokens, colors, typography
├── Models/         # Data models (alerts, tiles, regions)
├── ViewModels/     # MVVM view models with Combine
├── Views/          # SwiftUI views organized by feature
│   ├── Dashboard/  # Master Pilot HUD
│   ├── Alerts/     # Speed, radar, community alerts
│   ├── Map/        # Map container and annotations
│   ├── EcoMode/    # Eco-Voyager dark mode
│   └── Settings/   # App settings
├── Services/       # Location, alerts, offline, WebSocket
└── CoreData/       # Persistence layer
```

## Development Milestones
1. **Sprint 1:** Core Map Integration & Offline Tile Manager ← *Current*
2. **Sprint 2:** Real-time Socket integration for Community Alerts
3. **Sprint 3:** AR Overlay & HUD Projection logic
4. **Sprint 4:** Aura AI & Gamification (Road XP)

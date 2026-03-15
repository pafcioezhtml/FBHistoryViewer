# My Social History

macOS app for importing and visualizing Facebook data exports.

## Build

```bash
xcodebuild -project MySocialHistory.xcodeproj -scheme MySocialHistory -configuration Debug -derivedDataPath build/derived -destination 'platform=macOS' build
open build/derived/Build/Products/Debug/MySocialHistory.app
```

## Project Structure

- **Package.swift** + **MySocialHistory.xcodeproj** — dual SPM/Xcode setup
- `Sources/MySocialHistory/` — all source code
  - `App/` — MySocialHistoryApp entry point, AppState
  - `Database/` — DatabaseManager, Migrations, Schema
  - `Feed/` — FeedRepository, FeedViewModel, FeedItem
  - `Import/` — ImportPipeline, all importers (actor-based), ImportProgress
  - `Models/` — Record types (GRDB): Message, Post, Comment, Like, Thread, Reaction, Visit, etc.
  - `Parsing/` — File decoders for JSON formats
  - `Profile/` — ProfileRepository, ProfileViewModel
  - `Statistics/` — StatisticsRepository, StatisticsViewModel, StatisticsModels
  - `Views/` — All SwiftUI views organized by feature
  - `Resources/Assets.xcassets/` — App icon asset catalog

## Adding New Files

New `.swift` files MUST be added to BOTH:
1. `Package.swift` (automatically via directory)
2. `MySocialHistory.xcodeproj/project.pbxproj` — requires PBXBuildFile, PBXFileReference, PBXGroup, and PBXSourcesBuildPhase entries

New resources must also be added to PBXResourcesBuildPhase.

## Key Conventions

- Swift 6.0 tools version, Swift 5 language mode (`.swiftLanguageMode(.v5)`)
- `@Observable` ViewModels with `@MainActor`
- `actor` importers for thread safety
- GRDB 7.x for database (SQLite)
- macOS 14+ deployment target
- Facebook text encoding: always apply `String.fixedFacebookEncoding` to user-generated content from JSON
- Bundle ID: `com.mysocialhistory.app`
- Database location: `~/Library/Application Support/MySocialHistory/history.sqlite`

## UI Patterns

- **Copyable overlay**: `.copyable()` modifier on all GroupBoxes/stat cards in Statistics views. Uses `CopyableOverlay` ViewModifier with `CGWindowListCreateImage` to capture the window region. Button hides before screenshot to avoid appearing in the image.
- **Help sidebar**: `HelpSidebar.swift` displays contextual help per `SidebarItem`. Toggled by `?` button in the detail toolbar. Implemented as a manual `HStack` column in the detail area (not `.inspector()` — that adds an unwanted `>>` toggle button).
- **Toolbar layout**: Re-import and help buttons are in a single `ToolbarItem(placement: .primaryAction)` with `HStack` in `ContentView`. The sidebar has no toolbar items (avoids conflict with the sidebar toggle button on collapse/expand).
- **SidebarItem extensions**: `icon`, `iconColor`, and `helpSections` are defined in `HelpSidebar.swift`.

## App Icon

Source SVG: `../icons/2_history_book.svg`
Regenerate PNGs: `for size in 16 32 64 128 256 512 1024; do rsvg-convert -w $size -h $size ../icons/2_history_book.svg -o Sources/MySocialHistory/Resources/Assets.xcassets/AppIcon.appiconset/icon_${size}x${size}.png; done`

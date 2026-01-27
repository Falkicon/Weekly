# Changelog
## [1.3.2] - 2026-01-27

### Added
- Twilight Ascension: Added "Twilight's Dawn" quest (87308) for pre-patch event


## [1.3.1] - 2026-01-20

### Fixed
- Fix crash when saved debug config was boolean instead of table (WoW 12.0 compatibility)


All notable changes to Weekly will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-01-17

### Added
- **Time-Gated Sections**: Content can now appear/disappear based on date ranges (`showAfter`/`hideAfter`)
- **Debug Toggle**: "Show All Gated Content" setting to reveal time-gated sections for testing
- **Item Tracking**: New `item` type for tracking bag items (used for Housing lumber)
- **Pre-Patch Content**: Twilight Ascension event and Housing sections with proper time gates
- **Right-click Settings**: Right-clicking "Weekly" in the addon compartment now opens settings
- **Visibility Persistence**: Weekly tracker remembers its visibility state across reload/restart
- **Collapsible Sections**: Click section headers `[-]/[+]` to expand/collapse sections
- **Section Memory**: Collapsed state persists per-section across reloads
- **Expand/Collapse All**: Button at top-left to toggle all sections at once
- **Title Header**: Added `[-] WEEKLY` title row at top-left for consistent anchoring
- **Bridge/Core Architecture**: New layered architecture with Bridge (context) and Core (actions) layers
- **Mechanic Integration**: Full dashboard integration with the Mechanic development addon

### Changed
- **Settings Cleanup**: Removed obsolete "Show on Login" and "Anchor Point" settings
- **Background Opacity**: Moved from General to Appearance settings section
- **Section Order**: Reordered to Twilight → Ongoing → Housing → Weekly → Currencies
- **Loader Simplification**: TOC 12.0.0 now routes to Season 3 (time-gating handles phased content)
- **Default Behavior**: Weekly now respects last visibility state instead of always showing
- **Frame Anchoring**: Frame anchored from top-left for stable positioning when resizing

### Fixed
- **ID=0 Collision**: Fixed settings showing only one ID=0 quest (label-based keys now used)
- **Lua 5.1 Compatibility**: Removed `goto` statements not supported by WoW's Lua
- **Luacheck Cleanup**: Reduced warnings from 1724 to 0 by prefixing unused variables
- **Pool Row Cleanup**: Fixed rows not hiding when sections collapse
- **Label Color Bleeding**: Fixed header gold color bleeding into item rows after toggle

### Removed
- **MidnightPrePatch.lua**: Consolidated into Season3.lua with time gates


## [0.4.0] - 2025-12-23

### Changed
- ### Added
- **System Upgrade**: Modernized the Weekly tracker with StyLua formatting.
- **Localization**: Integrated AceLocale-3.0 for full localization support (114 strings extracted).
- **Automated Testing**: Added unit tests for seasonal data loader and weekly journal reset logic.

### Fixed
- **Localization**: Fixed missing localization entries that caused AceLocale errors during initialization.

## [0.3.0] - 2025-12-20

### Added
- **Midnight Pre-patch Support**: Added a new database for Season 3.5 (Midnight Pre-patch) with automatic transition logic.
- **Auto-Detection**: The addon now automatically selects the correct expansion and season data based on the game client version (supports TWW S3, Midnight Pre-patch, and future Midnight launch).
- **Waypoint Navigation**: Clickable quest icons in the tracker now set map waypoints for quests you don't have yet (when coordinates are available in the database).
- **Discovery Tool V2**: (Dev only) Enhanced data collection to capture player coordinates, client version, and build info for easier database maintenance.

### Changed
- **Default Settings**: New installations now default to "Automatic" expansion and season selection.

## [0.2.3] - 2025-12-20

### Fixed
- **Midnight Compatibility**: Replaced deprecated `EasyMenu` with modern `MenuUtil` API in `JournalBroker.lua` for WoW 11.2.8/12.0. Removed legacy `UIDropDownMenu` fallback to reduce technical debt and potential taints.
- **Settings API**: Fixed `bad argument #1 to OpenSettingsPanel` error and corrected navigation issues in WoW 11.2.8/12.0. The addon now properly retrieves and uses the numeric category ID for the Blizzard Settings panel.
- **Broker Menu**: Refactored the context menu for better organization.
  - Renamed title to "Weekly".
  - Grouped Weekly Tracker options (Show Weekly, Lock Weekly).
  - Grouped Journal options (Show Journal, Jump to Category).
  - Converted "Show Weekly", "Lock Weekly", "Show Journal", and "Show Minimap Icon" into checkboxes for easier toggling and better state visibility.
  - Fixed issue where the minimap icon could not be easily re-enabled from the menu.

## [0.2.2] - 2025-12-19

### Added
- **CurseForge Metadata**: Added `## X-License: GPL-3.0` to .toc file
- **CurseForge Integration**: Added project ID and webhook info to AGENTS.md
- **Cursor Ignore**: Added `.cursorignore` to reduce indexing overhead
- **Deep-Dive Docs**: Moved Discovery Tool documentation to `Docs/` folder

### Changed
- **Documentation**: Consolidated shared documentation to central `ADDON_DEV/AGENTS.md`; trimmed addon-specific AGENTS.md
- **FenUI**: Updated embedded FenUI library with Layout, Image widgets and NineSlice fixes

### Fixed
- **JournalUI**: Minor UI adjustments

## [0.2.1] - 2025-12-19

### Added

- **Gathering Tab**: Track gathered materials in the Journal
  - Automatically tracks looted Trade Goods (herbs, ore, leather, cloth, fish, etc.)
  - Grouped by expansion with running totals
  - Great for farming old-world mats for Decor crafting
  - Shows item tooltips on hover

## [0.2.0] - 2024-12-19

### Added

- **Weekly Journal**: New collectibles tracker that logs what you earn each week
  - Tracks Achievements, Mounts, Pets, Toys, and Housing Decor
  - Dashboard tab shows at-a-glance metrics and category breakdown
  - Category tabs show individual items with timestamps
  - Click any item to open the official Collection UI
  - Auto-resets on weekly reset (Tuesday)
  - Manual clear per-category for farming sessions
- Journal minimap icon via LibDataBroker
- Journal settings tab in configuration panel
- New slash commands:
  - `/weekly journal` - Toggle journal window
  - `/weekly settings` - Open settings panel
  - `/weekly help` - Show available commands
- TrackerCore.lua moved to production (was dev-only)

### Changed

- Addon compartment tooltip now shows left/right-click hints
- Version bumped to 0.2.0

## [0.1.0] - Initial Release

### Added

- Weekly tracker window with auto-sizing layout
- Great Vault progress tracking (Raid, Dungeon, World)
- Currency tracking with weekly caps
- Quest tracking with progress display
- AceDB profile support
- LibDataBroker minimap integration
- Discovery Tool (dev mode only)

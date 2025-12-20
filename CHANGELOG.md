# Changelog

All notable changes to Weekly will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

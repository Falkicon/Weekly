# Weekly

A lightweight, modular World of Warcraft addon designed to track your weekly progress in *The War Within* and beyond. Provides a clean, auto-sizing interface to monitor your **Great Vault** progress, **Weekly Events**, **Currencies**, and **Quests** at a glance.

![WoW Version](https://img.shields.io/badge/WoW-11.0%2B-blue)
![Interface](https://img.shields.io/badge/Interface-120001-green)
[![GitHub](https://img.shields.io/badge/GitHub-Falkicon%2FWeekly-181717?logo=github)](https://github.com/Falkicon/Weekly)
[![Sponsor](https://img.shields.io/badge/Sponsor-pink?logo=githubsponsors)](https://github.com/sponsors/Falkicon)

> **The War Within Ready**: Pre-loaded with Season 3 and TWW expansion data. Data-driven design allows easy updates for new seasons.

## Features

- **📊 Visual Vault Tracking** – Distinct visual rows for Raid, Dungeon, and World Vault slots. Instantly see your progress (Green = Unlocked) and hover for detailed level info
- **📅 Weekly Events** – Track Theater Troupe, Awakening Machine, Spreading Light, and more
- **💰 Currency Tracking** – Monitor Valorstones, Crests, Resonance Crystals, and seasonal currencies
- **📔 Weekly Journal** – Track collectibles earned this week: Achievements, Mounts, Pets, Toys, Decor, and gathered materials. Auto-resets on weekly reset
- **⛏️ Gathering Tracker** – Automatically tracks looted herbs, ore, leather, cloth, and more. Grouped by expansion for easy old-world mat farming
- **🔄 Smart Sorting** – Automatically moves completed items and capped currencies to the bottom (configurable)
- **📐 Auto-Sizing UI** – Window dynamically adjusts height and width based on visible items
- **🗂️ Modular Data System** – Easily switch between Expansions and Seasons via settings
- **📍 Data Broker Support** – Includes Minimap icons and LDB support for TitanPanel/Bazooka
- **👤 Profile Support** – Share settings across characters or set up specific profiles for alts

## Installation

1. Download or clone this repository
2. Place the `Weekly` folder in your WoW addons directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
3. Restart WoW or type `/reload` if already running

## Usage

### Slash Commands

| Command | Description |
|---------|-------------|
| `/weekly` | Toggle the main tracker window |
| `/weekly journal` | Toggle the Journal window |
| `/weekly settings` | Open the configuration panel |
| `/weekly help` | Show available commands |
| `/weekly debug` | Toggle debug mode (prints Quest IDs to chat) |

### Interface

- **Drag** – Click and drag the window to position it anywhere
- **Tooltips**:
  - **Currencies** – Hover over the icon to see total counts (Weekly vs Total Max)
  - **Quests** – Hover to see the Quest ID
  - **Vault** – Hover to see the level of *each* slot (e.g., "Slot 1: Mythic 10")

## Configuration

Right-click the Minimap icon or use `/weekly config` to access options.

### Settings Sections

- **General** – Unlock window, adjust opacity
- **Data Source** – Switch the active Expansion and Season
- **Appearance** – Customize fonts, sizes, spacing, and indents
- **Tracked Items** – Individually toggle specific items on or off
- **Journal** – Enable/disable journal, notification settings, minimap icon
- **Profiles** – Standard AceDB profile management

| Setting | Description |
|---------|-------------|
| Lock Window | Toggle to drag/position the window |
| Opacity | Visibility of window background (0-100%) |
| Font Size | Size of text labels |
| Move Completed to Bottom | Auto-sort completed items to the end |

## Requirements

- World of Warcraft Retail 11.0+ or Midnight Beta

## Files

| File | Purpose |
|------|---------|
| `Weekly.toc` | Addon manifest |
| `Core.lua` | Initialization, slash commands |
| `Config.lua` | Default configuration values |
| `ConfigUI.lua` | AceConfig settings panel |
| `UI.lua` | Tracker window rendering |
| `TrackerCore.lua` | Shared tracking infrastructure |
| `Journal/Journal.lua` | Journal tracking logic |
| `Journal/JournalUI.lua` | Journal window UI |
| `Journal/JournalBroker.lua` | Journal minimap integration |
| `Data/Loader.lua` | Data registry and loader |
| `Data/*/Season*.lua` | Per-expansion season data |

## Technical Notes

- **Ace3 Framework** – Uses AceAddon, AceDB, AceConfig for robust infrastructure
- **Data-Driven** – Centralized `Data/` folder allows easy seasonal updates
- **Auto-Detection** – Automatically selects the correct Expansion/Season data based on game client version
- **Auto-Sizing Layout** – Window calculates height/width based on content
- **LibDataBroker** – Minimap and panel integration

## Development

### Adding New Data

Data is stored in `Data.lua` organized by Expansion and Season. To add a new season:

1. Add a new season block to the appropriate expansion in `Data.lua`
2. Define your sections (Vault, Events, Currencies, Quests)
3. Test with `/weekly debug` to verify Quest IDs

## Support

If you find Weekly useful, consider [sponsoring on GitHub](https://github.com/sponsors/Falkicon) to support continued development and new addons. Every contribution helps!

## License

GPL-3.0 License – see [LICENSE](LICENSE) for details.

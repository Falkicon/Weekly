# Weekly

A lightweight World of Warcraft Retail addon for tracking **Great Vault** progress, **weekly quests**, **currencies**, **bag items**, and **Prey hunts**. Its customizable tracker and Weekly Journal keep weekly objectives and newly earned collectibles in view.

![WoW Version](https://img.shields.io/badge/WoW-Retail-blue)
![Interface](https://img.shields.io/badge/Interface-120100-green)
[![GitHub](https://img.shields.io/badge/GitHub-Falkicon%2FWeekly-181717?logo=github)](https://github.com/Falkicon/Weekly)
[![Sponsor](https://img.shields.io/badge/Sponsor-pink?logo=githubsponsors)](https://github.com/sponsors/Falkicon)

The manifest targets **Interface 120100**. Bundled datasets cover The War Within Season 3 and Midnight Seasons 1 and 2. New Season 2 quest IDs are marked as PTR candidates in the data file and still need in-game confirmation.

## Features

- **Visual Vault Tracking** – Distinct visual rows for Raid, Dungeon, and World Vault slots. Instantly see your progress (Green = Unlocked) and hover for detailed level info
- **Seasonal Objectives** – Track quests, events, currencies, caps, and bag materials from the selected dataset
- **Prey Hunts** – Track observed weekly completions per character; a `+` marks a lower bound when tracking started during the week
- **Weekly Journal** – Record achievements, mounts, pets, toys, decor, and gathered materials while tracking is enabled. Resets at the regional weekly reset
- **Collapsible Sections** – Click section headers to expand/collapse, with state persisted across reloads
- **Time-Gated Content** – Sections appear/disappear based on dates configured in the dataset
- **Smart Sorting** – Automatically moves completed items and capped currencies to the bottom (configurable)
- **Auto-Sizing UI** – Window dynamically adjusts height and width based on visible items
- **Modular Data System** – Easily switch between Expansions and Seasons via settings
- **Data Broker Support** – Journal launcher with a minimap icon and LibDataBroker display support
- **Profile Support** – Share settings and Journal history across characters or choose separate profiles; the Prey ledger remains character-specific

## Installation

1. Download a packaged release from [CurseForge](https://www.curseforge.com/wow/addons/weekly)
2. Extract the `Weekly` folder into your WoW addons directory, with `Weekly.toc` directly inside it:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
3. Restart WoW after a new installation and enable Weekly in the AddOns list. Use `/reload` after updating an already loaded copy

For a source checkout and development tools, see [Contributing](CONTRIBUTING.md).

## Usage

### Slash Commands

| Command | Description |
|---------|-------------|
| `/weekly` | Toggle the main tracker window |
| `/weekly journal` or `/weekly j` | Toggle the Journal window |
| `/weekly settings`, `/weekly config`, or `/weekly options` | Open the configuration panel |
| `/weekly help` or `/weekly ?` | Show available commands |
| `/weekly debug` | Toggle quest-event debug logging and print Vault/lockout diagnostics |
| `/weekly discovery` or `/weekly disc` | Toggle Discovery in source/development builds |

### Interface

- **Drag** – Move the tracker while Lock Window is disabled
- **Icons** – Hover for currency, item, Prey, or Vault details. Quest icons show available actions; click to open an active quest or set a map marker when coordinates are supplied
- **Section headers** – Click to collapse or expand a section
- **Journal minimap icon** – Left-click to toggle the Journal; right-click for tracker, Journal, and settings options
- **Addon compartment** – Left-click Weekly to toggle the tracker; right-click to open settings

## Configuration

Use `/weekly settings`, or choose settings from the Journal minimap icon's context menu.

### Settings Sections

- **General** – Data Source (Expansion and Season), Lock Window, Sort Completed to Bottom, and Show All Gated Content
- **Appearance** – Customize fonts, sizes, spacing, indents, and background opacity
- **Tracked Items** – Individually toggle specific items on or off
- **Journal** – Enable/disable journal, notification settings, minimap icon
- **Profiles** – Standard AceDB profile management

| Setting | Description |
|---------|-------------|
| Lock Window | Disable to drag/position the tracker |
| Background Opacity | Visibility of window background (0-100%) |
| Header Font Size / Item Font Size | Text sizes for sections and rows |
| Sort Completed to Bottom | Move completed rows to the bottom of their section |

## Requirements

- A Retail client compatible with the manifest's Interface 120100 target
- Required libraries are included; FenCore and Mechanic are optional integrations

Older season datasets remain selectable; their inclusion does not establish support for older clients.

## Files

| File | Purpose |
|------|---------|
| `Weekly.toc` | Addon manifest |
| `Core.lua` | Lifecycle, module activation, slash commands |
| `Core/` | Migrations, regional resets, actions, schemas, FenCore compatibility |
| `Bridge/` | Action execution and runtime context adapters |
| `Config.lua` | AceDB defaults and profile transitions |
| `ConfigUI.lua` | AceConfig settings panel |
| `UI.lua` | Tracker window rendering |
| `TrackerCore.lua` | Shared tracking infrastructure |
| `PreyTracker.lua` | Character-specific weekly hunt ledger |
| `Journal/Journal.lua` | Journal tracking logic |
| `Journal/JournalUI.lua` | Journal window UI |
| `Journal/JournalBroker.lua` | Journal minimap integration |
| `Data/Loader.lua` | Data registry and loader |
| `Data/Factories.lua`, `Data/Validation.lua` | Row constructors and dataset validation |
| `Data/*/Season*.lua` | Per-expansion season data |
| `Tests/`, `Tools/` | Regression tests and the shared local/CI validation command |
| `Dev/Discovery.lua` | Discovery tool, excluded from release packages |

## Technical Notes

- **Ace3 Framework** – Uses AceAddon, AceDB, AceConfig for robust infrastructure
- **Data-Driven** – Centralized `Data/` folder allows easy seasonal updates
- **Auto-Selection** – Uses client Interface build thresholds, including PTR builds, rather than a live season calendar. Choose a season explicitly in settings to override it
- **Auto-Sizing Layout** – Window calculates height/width based on content
- **LibDataBroker** – Minimap and panel integration

## Development

### Adding New Data

Data is stored in `Data/<Expansion>/Season<N>.lua`. To add a new season:

1. Create a file containing sections with `title` and `items`, using the helpers in `Data/Factories.lua`
2. Register it with `ns.Data:Register(expansionID, seasonID, data, "Data/<Expansion>/Season<N>.lua")` and add it to `Weekly.toc`
3. Update automatic selection in `Data/Loader.lua` and test its client build boundary
4. Verify quest and currency IDs in-game with the development Discovery tool
5. Run `python Tools/validate.py` to check all registered datasets and the rest of the repository

See [Data Management](Data/AGENTS.md) for the schema and [Contributing](CONTRIBUTING.md) for validation commands.

[Lifecycle and Migrations](Docs/development.md) describes module activation, profile transitions, and versioned saved data.

## Support

If you find Weekly useful, consider [sponsoring on GitHub](https://github.com/sponsors/Falkicon) to support continued development and new addons. Every contribution helps!

## License

GPL-3.0 License – see [LICENSE](LICENSE) for details.

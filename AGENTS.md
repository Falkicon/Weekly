# Weekly – Agent Documentation

Technical reference for AI agents modifying this addon.

For shared patterns, library references, and development guides, see **[ADDON_DEV/AGENTS.md](../ADDON_DEV/AGENTS.md)**.

---

## CurseForge

| Item | Value |
|------|-------|
| **Project ID** | 1405635 |
| **Project URL** | https://www.curseforge.com/wow/addons/weekly |
| **Files** | https://authors.curseforge.com/#/projects/1405635/files |

---

## Project Intent

A lightweight, customizable HUD for tracking weekly objectives in World of Warcraft.

- **Goal**: Provide a clean, always-visible checklist of weekly currencies, quests, and caps
- **Style**: Flat, modern, dark aesthetic with customizable size and opacity
- **Philosophy**: "Set it and forget it" – automatically tracks what matters for the current season

---

## File Structure

| File | Purpose |
|------|---------|
| `Weekly.toc` | Manifest |
| `Core.lua` | Initialization, Slash commands |
| `Config.lua` | Default configuration values & storage logic |
| `ConfigUI.lua` | AceConfig settings panel definition |
| `UI.lua` | Frame creation, rendering, and update logic |
| `TrackerCore.lua` | Shared tracking infrastructure |
| `Data/Loader.lua` | Data registry and season loader |
| `Data/*/Season*.lua` | Per-expansion, per-season data files |

### Weekly Journal

| File | Purpose |
|------|---------|
| `Journal/Journal.lua` | Core tracking logic, weekly reset detection |
| `Journal/JournalUI.lua` | Tabbed window with Dashboard and category views |
| `Journal/JournalBroker.lua` | LibDataBroker integration |

### Dev Tools (Excluded from CurseForge)

| File | Purpose |
|------|---------|
| `DevMarker.lua` | Sets `ns.IS_DEV_MODE = true` when present |
| `Dev/Discovery.lua` | Currency/quest discovery tool |

---

## Architecture

### Data Structure

```lua
ns.Data = {
    [ExpansionID] = {
        [SeasonID] = {
            { type = "header", text = "..." },
            { type = "currency", id = 123, ... },
        }
    }
}
```

### UI Layout

- **Auto-Sizing**: Window calculates height/width based on content
- **Columns**: Icon | Label | Value | Checkmark
- **Profiles**: Full AceDB profile support

---

## Adding New Quests

```lua
-- Single-ID (most common)
Quest(91175, "Weekly Cache", "Interface\\Icons\\INV_Box_02")

-- Multi-ID (rotating quests with different IDs each week)
Quest({83363, 83365, 83359}, "Timewalking Event", "Interface\\Icons\\spell_holy_borrowedtime")

-- With Coordinates (Enables map marker navigation)
Quest(82483, "Worldsoul Weekly", nil, { mapID = 2274, x = 0.45, y = 0.50 })
```

For detailed quest/currency IDs, see `Data/AGENTS.md`.

---

## SavedVariables

- **Root**: `WeeklyDB`
- **Key patterns**:
  - `hiddenItems`: Table `[id] = true` for hidden items
  - `minimized`: Boolean for UI state
  - `locked`: Boolean for interaction state

---

## Slash Commands

- `/weekly` – Toggle the weekly tracker window
- `/weekly journal` – Toggle the Journal window
- `/weekly settings` – Open settings panel
- `/weekly debug` – Output diagnostic info
- `/weekly discovery` – (Dev only) Toggle Discovery Tool

---

## Weekly Journal

Tracks collectibles and materials earned during the week (reset to reset).

### Collectibles Tracked

| Category | Event |
|----------|-------|
| Achievements | `ACHIEVEMENT_EARNED` |
| Mounts | `NEW_MOUNT_ADDED` |
| Pets | `NEW_PET_ADDED` |
| Toys | `NEW_TOY_ADDED` |
| Decor | `HOUSE_DECOR_ADDED_TO_CHEST` |

### Gathering Tracked

Herbs, Ore, Leather, Cloth, Fish, Elemental, Enchanting Mats via `CHAT_MSG_LOOT`.

### Storage Schema

```lua
WeeklyDB.profile.journal = {
    enabled = true,
    weekStart = 1734566400,  -- Unix timestamp for reset detection
    categories = { achievement = {}, mount = {}, pet = {}, toy = {}, decor = {} },
    gathering = { [itemID] = { name, icon, count, expansion } },
}
```

---

## Deep-Dive Documentation

For detailed implementation docs, see the `Docs/` folder:
- [Data Management](Data/AGENTS.md) – Currency/quest IDs, seasonal updates

---

## Development & Tooling

### Tooling Commands
This addon is integrated with the `ADDON_DEV` workspace tools:
- **Linting**: `lint_addon("Weekly")`
- **Formatting**: `format_addon("Weekly")`
- **Testing**: `run_tests("Weekly")`
- **Localization**: `extract_locale_strings("Weekly")`

### Localization
Uses **AceLocale-3.0**.
- Base locale: `Locales/enUS.lua`
- All user-facing UI strings must be wrapped in `L["KEY"]`.
- Data files in `Data/` (quest/currency names) are NOT localized as they come from the WoW API.

### Unit Tests
Tests are located in the `Tests/` directory and use the **Busted** framework with `wow_api` mocks.
- `Tests/test_data_loader.lua`: Tests the seasonal data registration and recommended season detection.
- `Tests/test_journal.lua`: Tests the weekly journal logic, including reset detection and category counts.

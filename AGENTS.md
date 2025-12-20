# Weekly – Agent Documentation

Technical reference for AI agents modifying this addon.

## External References

### Development Documentation
For comprehensive addon development guidance, consult these resources:

- **[ADDON_DEV/AGENTS.md](../../ADDON_DEV/AGENTS.md)** – Library index, automation scripts, dependency chains
- **[Addon Development Guide](../../ADDON_DEV/Addon_Dev_Guide/)** – Full documentation covering:
  - Core principles, project structure, TOC best practices
  - UI engineering, configuration UI, combat lockdown
  - Performance optimization, API resilience
  - Debugging, packaging/release workflow
  - Midnight (12.0) compatibility and secret values

### Blizzard UI Source Code
For reverse-engineering, hijacking, or modifying official Blizzard UI frames:

- **[wow-ui-source-live](../../wow-ui-source-live/)** – Official Blizzard UI addon code
  - Use this to understand frame hierarchies, event patterns, and protected frame behavior
  - Reference for currency and quest tracking UI implementations
  - Helpful for understanding weekly reset and cap display patterns

---

## Project Intent

A lightweight, customizable HUD for tracking weekly objectives in World of Warcraft.

- **Goal**: Provide a clean, always-visible (or minimizable) checklist of weekly currencies, quests, and caps
- **Style**: Flat, modern, dark aesthetic with customizable size and opacity
- **Philosophy**: "Set it and forget it" – automatically tracks what matters for the current season

## Constraints

- Must work on Retail 11.0+
- **Interface Version**: Currently targeting **120001** (Midnight expansion, due January 20th, 2026)
- Uses Ace3 framework (AceAddon, AceDB, AceConfig)
- Data-driven design – centralized `Data.lua` allows easy seasonal updates

## File Structure

| File | Purpose |
|------|---------|
| `Weekly.toc` | Manifest |
| `Core.lua` | Initialization, Slash commands |
| `Config.lua` | Default configuration values & storage logic |
| `ConfigUI.lua` | AceConfig settings panel definition |
| `UI.lua` | Frame creation, rendering, and update logic |
| `TrackerCore.lua` | Shared tracking infrastructure (events, dedup, UI) |
| `Data/Loader.lua` | Data registry and season loader |
| `Data/*/Season*.lua` | Per-expansion, per-season data files |

### Weekly Journal

| File | Purpose |
|------|---------|
| `Journal/Journal.lua` | Core tracking logic, event handlers, weekly reset detection |
| `Journal/JournalUI.lua` | Tabbed window with Dashboard and category views |
| `Journal/JournalBroker.lua` | LibDataBroker integration for minimap/panel access |

### Dev Tools (Excluded from CurseForge)

| File | Purpose |
|------|---------|
| `DevMarker.lua` | Sets `ns.IS_DEV_MODE = true` when present |
| `Dev/TrackerCore.lua` | Dev copy of TrackerCore (for Discovery only) |
| `Dev/Discovery.lua` | Currency/quest discovery tool for database population |

## Architecture

### Data Structure (`Data.lua`)

The addon uses a nested table structure to organize data by Expansion and Season:

```lua
ns.Data = {
    [ExpansionID] = {
        [SeasonID] = {
            { type = "header", text = "..." },
            { type = "currency", id = 123, ... },
            ...
        }
    }
}
```

### UI Layout

- **Auto-Sizing Layout**: Window calculates height/width based on content
- **Columns**: Icon | Label | Value | Checkmark
- **Settings**: Sections for General, Appearance (Fonts), Tracking
- **Profiles**: Full AceDB profile support (per-character or shared)

### Identifiers (The War Within)

**Currencies** (confirmed IDs for TWW):

| Currency | ID | Type | Notes |
|----------|------|------|-------|
| Kej | 3056 | Currency | Azj-Kahet currency |
| Resonance Crystals | 2815 | Currency | General TWW currency |
| Nerub-ar Finery | 3093 | Currency | Raid drop, weekly cap |
| Undercoin | 2803 | Currency | Delve currency |
| Restored Coffer Key | 3028 | Currency | Delve keys |
| Valorstones | 3008 | Cap | Upgrade currency |
| Weathered Crest | 2915 | Cap | Season 1 Crest |
| Carved Crest | 2916 | Cap | Season 1 Crest |
| Runed Crest | 2917 | Cap | Season 1 Crest |
| Gilded Crest | 2918 | Cap | Season 1 Crest |

**Quests** (confirmed IDs for TWW Season 3):

| Quest | ID | Notes |
|-------|------|-------|
| Weekly Cache | 91175 | TWW Season 3 Weekly |
| Theater Troupe | 83240 | Isle of Dorn event |
| Awakening Machine | 83333 | Gearing Up for Trouble (Gundargaz) |
| Spreading Light | 82483 | Worldsoul: Spreading the Light (Hallowfall) |
| Eco Succession | 85460 | Ecological Succession (K'aresh) |

*Note: Quest IDs are tracked in `Data.lua`. Use `/weekly debug` for dynamic checking.*

## Adding New Quests

### Quest Helper Function

```lua
Quest(id, label, icon)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | `number` or `table` | Quest ID(s) - see patterns below |
| `label` | `string` | Display name in UI |
| `icon` | `string` (optional) | Texture path (defaults to book icon) |

### Single-ID Quests (Most Common)

For quests with a consistent ID every week:

```lua
Quest(91175, "Weekly Cache", "Interface\\Icons\\INV_Box_02")
Quest(82706, "Delves: Worldwide Research")  -- icon is optional
```

### Multi-ID Quests (Rotating/Variant)

Some quests have **different IDs each week** depending on active content. Use a **table of IDs**:

```lua
-- Timewalking: Different quest ID based on which expansion's TW is active
Quest({83363, 83365, 83359, 83362, 83364, 83360, 86731, 88805}, "Timewalking Event", "Interface\\Icons\\spell_holy_borrowedtime")

-- Sparks of War: Different quest ID based on which PvP brawl is active  
Quest({81793, 81794, 81795, 81796, 86853}, "Sparks of War", "Interface\\Icons\\spell_fire_felfire")
```

**How multi-ID works:**
1. `Utils.GetQuest()` iterates through the ID table
2. Returns the first ID that the player has active OR completed
3. UI stores the resolved ID for click-to-open-quest-log
4. If no variant is active, shows as unavailable

### When to Use Multi-ID

| Scenario | Use |
|----------|-----|
| Same quest every week | Single ID |
| Quest rotates weekly (same reward, different ID) | Multi-ID table |
| Multiple separate quests (different rewards) | Separate entries |

### Finding Quest IDs

1. **Discovery Tool** (dev mode): `/weekly discovery` - auto-captures quests you pick up
2. **In-game**: `/dump C_QuestLog.GetQuestIDForLogIndex(1)` when quest is in log
3. **Wowhead**: Check the quest page URL (e.g., `wowhead.com/quest=91175`)

## SavedVariables

- **Root**: `WeeklyDB`
- **Namespace**: `ns.Config` (Runtime copy)
- **Key patterns**:
  - `hiddenItems`: Table `[id] = true` for hidden items
  - `minimized`: Boolean for UI state
  - `locked`: Boolean for interaction state

## Slash Commands

- `/weekly` – Toggle the weekly tracker window
- `/weekly journal` – Toggle the Journal window
- `/weekly settings` – Open settings panel
- `/weekly help` – Show available commands
- `/weekly debug` – Output diagnostic info for quest/currency IDs
- `/weekly discovery` – (Dev only) Toggle the Discovery Tool window

## Debugging

- `/weekly debug` outputs diagnostic info
- Quest IDs can be dynamically checked in-game

## Discovery Tool (Dev Only)

The Discovery Tool helps developers find new currencies and quests to add to Weekly's database.

### How It Works

1. **Automatic Tracking**: When `DevMarker.lua` is present (dev mode), the tool automatically tracks **in the background** from login:
   - `CURRENCY_DISPLAY_UPDATE` – Any currency you receive or spend
   - `QUEST_ACCEPTED` / `QUEST_TURNED_IN` – Quests you pick up or complete
   - **No need to open the window** - tracking happens automatically

2. **Deduplication**: Each item is logged only once (persists across sessions)

3. **Persistence**: Data is saved to `WeeklyDB.dev.discovery` and survives reloads/logouts
   - Auto-saves every 5 seconds when new items are logged
   - Saves on logout
   - **Storage cap**: 500 items maximum (oldest items auto-pruned)

3. **Filtering**: 
   - "Only New" checkbox hides items already in Weekly's database
   - Filter by currencies/quests
   - Shows expansion info for each item

4. **Export**: Click "Export" to get copyable Lua code formatted for `Data/*.lua` files

### Accessing the Discovery Tool

| Method | How |
|--------|-----|
| Slash Command | `/weekly discovery` or `/weekly disc` |
| Settings UI | Settings → Weekly → Dev Tools → "Open Discovery Window" |

### Dev Tools Settings Tab

The Dev Tools tab in Weekly's settings shows:
- **Dev Mode Status**: Whether dev mode is active
- **Session Stats**: Count of currencies/quests logged this session
- **Open Discovery Window**: Button to open the Discovery UI
- **Clear Logged Items**: Reset all tracked items

### UI Features

| Element | Description |
|---------|-------------|
| Filter Checkboxes | Toggle "Only New", Currencies, Quests |
| Item List | Scrollable list with icon, type tag, name, ID, expansion |
| Export Button | Opens popup with formatted Lua code |
| Clear Button | Resets all logged items |

### Export Format

```lua
-- === CURRENCY ===
Cap(2912, "Renascent Awakening"),  -- icon: 12345, The War Within
Currency(3056, "Kej"),  -- icon: 67890, The War Within

-- === QUEST ===
Quest(91175, "Weekly Cache"),  -- Weekly, The War Within
```

### TrackerCore Architecture

The Discovery Tool is built on `TrackerCore.lua`, a shared infrastructure that provides:
- Event registration/unregistration
- Item logging with deduplication and timestamps
- Filtering and export formatting
- Reusable UI components (window, scrollable list, buttons)

This architecture is designed to be reused for the future **Weekly Journal** feature.

## Documentation Requirements

**Always update documentation when making changes:**

### CHANGELOG.md
Update the changelog for any change that:
- Adds new features or functionality
- Fixes bugs or issues
- Changes existing behavior
- Modifies settings or configuration options
- Updates currency/quest IDs for new seasons

**Format** (Keep a Changelog style):
```markdown
## [Version] - YYYY-MM-DD
### Added
- New features

### Changed
- Changes to existing functionality

### Fixed
- Bug fixes

### Removed
- Removed features
```

### README.md
Update the README when:
- Adding new features that users should know about
- Changing slash commands or settings
- Updating for new seasons/expansions
- Modifying installation or usage instructions

**Key sections to review**: Features, Slash Commands, Configuration

## Weekly Journal

The Weekly Journal tracks collectibles and materials earned during the week (reset to reset). Unlike the main Weekly tracker which shows "what to do," the Journal shows "what you got done."

### Collectibles Tracked

| Category | Event | Info API | Link to UI |
|----------|-------|----------|------------|
| Achievements | `ACHIEVEMENT_EARNED` | `GetAchievementInfo(id)` | `OpenAchievementFrameToAchievement(id)` |
| Mounts | `NEW_MOUNT_ADDED` | `C_MountJournal.GetMountInfoByID(id)` | Collections Journal (Mounts tab) |
| Pets | `NEW_PET_ADDED` | `C_PetJournal.GetPetInfoBySpeciesID(id)` | Collections Journal (Pets tab) |
| Toys | `NEW_TOY_ADDED` | `C_ToyBox.GetToyInfo(id)` | Collections Journal (Toys tab) |
| Decor | `HOUSE_DECOR_ADDED_TO_CHEST` | `C_HousingDecor.GetDecorName/Icon(id)` | Housing Dashboard |

**Not tracked (Phase 1):** Transmog (requires complex diffing; may integrate with AllTheThings later)

### Gathering Tracked

The Gathering tab tracks looted Trade Goods materials via `CHAT_MSG_LOOT`:

- **Herbs** (Herbalism)
- **Ore & Stone** (Mining)
- **Leather** (Skinning)
- **Cloth** (World drops)
- **Fish & Cooking Mats** (Fishing)
- **Elemental** (Various)
- **Enchanting Mats**

Items are grouped by expansion (newest first), making it easy to track old-world mat farming for Decor crafting.

### Storage Schema

```lua
WeeklyDB.profile.journal = {
    enabled = true,              -- Enable journal tracking
    showNotifications = false,   -- Show chat message when item logged
    weekStart = 1734566400,      -- Unix timestamp for reset detection
    categories = {               -- Collectibles: { [category] = { [id] = itemData, ... } }
        achievement = { [12345] = { name, icon, points, timestamp } },
        mount = { ... },
        pet = { ... },
        toy = { ... },
        decor = { ... },
    },
    gathering = {                -- Materials: { [itemID] = { name, icon, count, expansion } }
        [12345] = { name = "Mycobloom", icon = "...", count = 247, expansion = 10 },
    },
}
```

### Weekly Reset Detection

On login, the Journal compares `C_DateAndTime.GetServerTimeLocal()` against the stored `weekStart` timestamp. If a new week has started (Tuesday reset), all categories and gathering are cleared automatically.

### Access Points

1. **Slash Command**: `/weekly journal`
2. **Settings Tab**: Weekly → Journal → "Open Journal Window"
3. **LibDataBroker**: Separate minimap icon (left-click toggles, right-click shows menu)
4. **Addon Compartment**: Right-click "Weekly" entry

## Future Considerations

### Potential Tracked Items to Add

| Item | Currency ID | Notes |
|------|-------------|-------|
| Catalyst Charges | 2912 | Renascent Awakening (TWW) |
| PvP Conquest | 1602 | Weekly cap |
| Sparks | Various | Crafting, may change in Midnight |

## Library Management

This addon manages its libraries using `update_libs.ps1` located in `Interface\ADDON_DEV`.
**DO NOT** manually update libraries in `Libs`.
Instead, if you need to update libraries, run:
`powershell -File "c:\Program Files (x86)\World of Warcraft\_retail_\Interface\ADDON_DEV\update_libs.ps1"`

# Weekly – Agent Documentation

Technical reference for AI agents modifying this addon.

Start with this guide and [Lifecycle, Migrations, and Validation](Docs/development.md). These instructions are self-contained; a sibling `ADDON_DEV` checkout is not required.

---

## CurseForge

| Item | Value |
|------|-------|
| **Project ID** | 1405635 |
| **Project URL** | https://www.curseforge.com/wow/addons/weekly-to-do-tracker |
| **Files** | https://authors.curseforge.com/#/projects/1405635/files |

---

## Project Intent

A lightweight, customizable HUD for tracking weekly objectives in World of Warcraft.

- **Goal**: Provide a clean checklist of weekly currencies, quests, items, and caps with persistent visibility preferences
- **Style**: Flat, modern, dark aesthetic with customizable size and opacity
- **Philosophy**: "Set it and forget it" – select seasonal data by client build, with manual expansion/season overrides

`Weekly.toc` is authoritative for version, target Interface, and load order. It currently targets Interface 120100 and loads The War Within Season 3 and Midnight Seasons 1 and 2. Season 2 includes PTR candidate IDs that need in-game confirmation; dataset validation establishes structure, not live ID correctness.

---

## File Structure

| File | Purpose |
|------|---------|
| `Weekly.toc` | Manifest |
| `Core.lua` | AceAddon lifecycle, ordered activation, slash commands, debug subscriptions |
| `Core/ConfigMigrations.lua` | Versioned profile and character migrations |
| `Core/WeeklyReset.lua` | Shared regional weekly reset handling |
| `Core/FenCoreCompat.lua` | Optional FenCore domains with local fallbacks |
| `Core/Actions/`, `Core/Schemas/` | Action implementations and data contracts |
| `Bridge/Context.lua`, `Bridge/Executor.lua` | Runtime context and action execution adapters |
| `Config.lua` | AceDB defaults, aliases, and profile transition callbacks |
| `ConfigUI.lua` | AceConfig settings panel definition |
| `UI.lua` | Frame creation, rendering, and update logic |
| `TrackerCore.lua` | Shared tracking infrastructure |
| `PreyTracker.lua` | Character-specific observed hunt ledger |
| `Data/Loader.lua` | Data registry and season loader |
| `Data/Factories.lua` | Shared row constructors and explicit placeholders |
| `Data/Validation.lua` | Dataset checks used by tests/tooling |
| `Data/*/Season*.lua` | Per-expansion, per-season data files |
| `MechanicIntegration.lua` | Optional Mechanic diagnostics, tools, and performance sampling |
| `Tests/`, `Tools/` | Lua/Python tests, pinned tooling, and validation command |

### Weekly Journal

| File | Purpose |
|------|---------|
| `Journal/Journal.lua` | Core tracking logic, weekly reset detection |
| `Journal/JournalUI.lua` | Tabbed window with Dashboard and category views |
| `Journal/JournalBroker.lua` | LibDataBroker integration |

### Dev Tools (Excluded from CurseForge)

| File | Purpose |
|------|---------|
| `Dev/Discovery.lua` | Currency/quest discovery tool loaded by the TOC debug block |

Discovery initializes when its module is present in a source checkout. `.pkgmeta` excludes `Dev/`, and release packaging strips the TOC debug block. `Tests/`, `Tools/`, and developer documentation are also excluded from release packages.

---

## Architecture

`Weekly:OnInitialize()` binds AceDB, migrates saved data, and creates settings and tracker frames. `OnEnable()` activates modules through `Weekly:ApplyConfig(reason)`; `OnDisable()` shuts them down. Route profile and settings transitions through this path, keep initialization idempotent, and unregister events during shutdown. Use `Weekly:SetDebugEnabled()` to preserve the debug table and synchronize event subscriptions.

Profile copy/reset requires discarding old runtime Journal data before rebinding. Do not save stale Journal records into a profile AceDB has just replaced. See [Lifecycle and Migrations](Docs/development.md) before changing these paths.

### Data Structure

```lua
ns.Data = {
    Registry = {
        [ExpansionID] = {
            [SeasonID] = {
                { title = "...", items = { { type = "currency", id = 123 } } },
            },
        },
    },
}
```

### UI Layout

- **Auto-Sizing**: Window calculates height/width based on content
- **Columns**: Icon | Label | Value | Checkmark
- **Profiles**: Full AceDB profile support

---

## Adding New Quests

```lua
local _, ns = ...
local Quest = ns.DataFactory.Quest

-- Single-ID (most common)
Quest(91175, "Weekly Cache", "Interface\\Icons\\INV_Box_02")

-- Multi-ID (rotating quests with different IDs each week)
Quest({83363, 83365, 83359}, "Timewalking Event", "Interface\\Icons\\spell_holy_borrowedtime")

-- With Coordinates (Enables map marker navigation)
Quest(82483, "Worldsoul Weekly", nil, { mapID = 2274, x = 0.45, y = 0.50 })
```

These examples illustrate row construction; verify IDs for the target dataset. Use `ns.DataFactory.PlaceholderQuest(...)` for unconfirmed quests, not a bare `Quest(0, ...)`. Register datasets through `ns.Data:Register(...)`, include the source path for diagnostics, and add each season file to `Weekly.toc`. See [Data Management](Data/AGENTS.md) for validation rules and seasonal updates.

---

## SavedVariables

The TOC declares `WeeklyDB`. AceDB's runtime aliases and raw saved layout differ:

| Runtime access | Raw storage | Contents |
|----------------|-------------|----------|
| `ns.Config` / `ns.db.profile` | `WeeklyDB.profiles[profileName]` | Settings and Journal history |
| `ns.CharConfig` / `ns.db.char` | `WeeklyDB.char[characterKey]` | Prey ledger, independent of selected profile |
| `WeeklyDB.journalMinimapIcon` | Same | Shared minimap visibility/position |
| `WeeklyDB.dev.discovery` | Same | Development Discovery records |

- `hiddenItems[ns.Data:GetItemConfigKey(row)] = true` hides a row. Keys include type prefixes or an explicit row key; legacy numeric keys are still read for compatibility
- `collapsedSections[sectionTitle] = true` persists collapsed sections; `locked` controls dragging
- `visible` stores tracker visibility; `autoShow` overrides it on first enable in a session
- Profile and character records each store their own `schemaVersion`. Never put this field in `ConfigDefaults`, because AceDB defaults can conceal old records. Append ordered, idempotent migrations in `Core/ConfigMigrations.lua`

Journal history follows the selected profile. Characters sharing a profile share that history; Prey progress remains per character.

---

## Slash Commands

- `/weekly` – Toggle the weekly tracker window
- `/weekly journal` or `/weekly j` – Toggle the Journal window
- `/weekly settings`, `/weekly config`, or `/weekly options` – Open settings panel
- `/weekly help` or `/weekly ?` – Show command help
- `/weekly debug` – Toggle quest-event debug logging and print Vault/lockout diagnostics
- `/weekly discovery` or `/weekly disc` – Toggle Discovery when its development module is loaded

---

## Weekly Journal

Records collectibles and materials observed while Journal tracking is enabled, from reset to reset. It does not reconstruct earlier gains. Journal and Prey use the shared regional reset helper; avoid hard-coded weekday assumptions.

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
-- Runtime profile view; abbreviated fields, not a replacement for ConfigDefaults.
ns.Config.journal = {
    enabled = true,
    weekStart = 0,  -- Unix timestamp once initialized
    nextReset = 0,  -- Saved weekly reset boundary
    categories = { achievement = {}, mount = {}, pet = {}, toy = {}, decor = {} },
    gathering = {
        [itemID] = {
            name = "...", icon = 123, count = 1, expansion = 11, -- Item API expansion ID
            subclass = 0, firstSeen = 0, lastSeen = 0,
        },
    },
}
```

---

## Deep-Dive Documentation

For detailed implementation docs, see the `Docs/` folder:

- [Lifecycle and Migrations](Docs/development.md) – Module activation, saved-data versions, and the validation gate
- [Data Management](Data/AGENTS.md) – Currency/quest IDs, seasonal updates

---

## Libraries

### FenCore Integration

Weekly uses FenCore for pure logic domains with graceful fallbacks:

- **ActionResult**: Structured success/error returns in `Core/Actions/`
- All FenCore usage is wrapped via `Core/FenCoreCompat.lua` for optional dependency

The FenCoreCompat module provides fallback implementations when FenCore is not available, ensuring Weekly works standalone or with FenCore.

Run the repository validation command below to exercise the pure logic and bridge tests. When changing compatibility behavior, cover both the optional library and fallback paths.

### FenUI Integration

FenUI is bundled and loaded by `embeds.xml`. JournalUI uses its widgets with graceful fallbacks:

- `FenUI:CreatePanel` – Window frame
- `FenUI:CreateTabGroup` – Tab navigation
- `FenUI:CreateGrid` – Item lists
- `FenUI:CreateScrollInset` – Scrollable content
- `FenUI:CreateEmptyState` – Empty state display
- `FenUI:CreateLayout` – Footer layout

All FenUI usage includes fallback to plain WoW API when FenUI is unavailable.

---

## Development & Tooling

### Tooling Commands

Run `python Tools/validate.py` from the repository root for the full local/CI gate. Tool versions are pinned in `Tools/toolchain.json`; `python Tools/install_lua_tools.py` installs the Lua tools through LuaRocks. See [Contributing](CONTRIBUTING.md) for executable overrides and setup.

The gate checks tool versions, Python tooling tests, literal localization keys, TOC/XML dependencies, release exclusions, omitted season files, Luacheck, both Busted suites, and diff whitespace. It does not verify live quest IDs or fetch remote packaging externals. Optional Mechanic tooling supplements this gate; it is not required to run it.

### Localization

Uses **AceLocale-3.0**.

- Base locale: `Locales/enUS.lua`
- All user-facing UI strings must be wrapped in `L["KEY"]`.
- Keep seasonal data labels in `Data/` unlocalized; the UI uses WoW API names where available and dataset labels as needed.

### Unit Tests

`Tests/test_*.lua` and `Tests/Core/*_spec.lua` use **Busted** with WoW API mocks; migration tests also load the bundled AceDB implementation. `Tests/test_validation.py` uses Python's unittest framework. Representative coverage:

- `Tests/test_data_loader.lua`, `Tests/test_data_validation.lua`: Build selection and all datasets loaded from the TOC
- `Tests/test_lifecycle.lua`, `Tests/test_config_migrations.lua`: Activation, shutdown, profile transitions, and versioned saved data
- `Tests/test_journal.lua`, `Tests/test_journal_ui.lua`: Reset boundaries, loot retries, FenUI callbacks, and fallback rendering
- `Tests/test_ui.lua`, `Tests/test_mechanic_integration.lua`: Coalesced rendering, diagnostics, and performance sampling

Use the validation gate for automated checks and in-game testing for visual behavior, client event timing, and combat restrictions. Follow `.gitattributes` when editing; avoid unrelated formatting of bundled libraries.

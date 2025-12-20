# Weekly Discovery Tool – Deep Dive

Detailed documentation for the dev-only Discovery Tool.

---

## Overview

The Discovery Tool helps developers find new currencies and quests to add to Weekly's database.

---

## How It Works

1. **Automatic Tracking**: When `DevMarker.lua` is present (dev mode), the tool automatically tracks **in the background** from login:
   - `CURRENCY_DISPLAY_UPDATE` – Any currency you receive or spend
   - `QUEST_ACCEPTED` / `QUEST_TURNED_IN` – Quests you pick up or complete
   - **No need to open the window** - tracking happens automatically

2. **Deduplication**: Each item is logged only once (persists across sessions)

3. **Persistence**: Data is saved to `WeeklyDB.dev.discovery` and survives reloads/logouts
   - Auto-saves every 5 seconds when new items are logged
   - Saves on logout
   - **Storage cap**: 500 items maximum (oldest items auto-pruned)

4. **Filtering**: 
   - "Only New" checkbox hides items already in Weekly's database
   - Filter by currencies/quests
   - Shows expansion info for each item

5. **Export**: Click "Export" to get copyable Lua code formatted for `Data/*.lua` files

---

## Accessing the Discovery Tool

| Method | How |
|--------|-----|
| Slash Command | `/weekly discovery` or `/weekly disc` |
| Settings UI | Settings → Weekly → Dev Tools → "Open Discovery Window" |

---

## Dev Tools Settings Tab

The Dev Tools tab in Weekly's settings shows:
- **Dev Mode Status**: Whether dev mode is active
- **Session Stats**: Count of currencies/quests logged this session
- **Open Discovery Window**: Button to open the Discovery UI
- **Clear Logged Items**: Reset all tracked items

---

## UI Features

| Element | Description |
|---------|-------------|
| Filter Checkboxes | Toggle "Only New", Currencies, Quests |
| Item List | Scrollable list with icon, type tag, name, ID, expansion |
| Export Button | Opens popup with formatted Lua code |
| Clear Button | Resets all logged items |

---

## Export Format

```lua
-- === CURRENCY ===
Cap(2912, "Renascent Awakening"),  -- icon: 12345, The War Within
Currency(3056, "Kej"),  -- icon: 67890, The War Within

-- === QUEST ===
Quest(91175, "Weekly Cache"),  -- Weekly, The War Within
```

---

## TrackerCore Architecture

The Discovery Tool is built on `TrackerCore.lua`, a shared infrastructure that provides:
- Event registration/unregistration
- Item logging with deduplication and timestamps
- Filtering and export formatting
- Reusable UI components (window, scrollable list, buttons)

This architecture is designed to be reused for the future **Weekly Journal** feature.

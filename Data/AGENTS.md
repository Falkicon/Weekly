# Data Management

This folder contains the data definitions for the Weekly addon.
We use a **Registration System** to load data based on Expansion and Season.

## Adding a New Season

1.  Create a new file in `Data/[ExpansionName]/Season[X].lua`.
2.  Follow the template below:

```lua
local _, ns = ...

local data = {
    -- Headers
    { type = "header", text = "My New Season" },
    
    -- Currencies
    { type = "currency", id = 1234, label = "My New Coin", style = "value" },
    
    -- Quests
    { type = "quest", id = 5678, label = "Weekly Event", style = "checkbox" },
}

-- Register(ExpansionID, SeasonID, Data)
ns.Data:Register(11, 4, data) -- Example: Exp 11, Season 4
```

3.  Add the new file to your `.toc` file (after `Loader.lua`).

## Data Types

### `currency`
Displays a simple "Current Amount".
- `id`: Currency ID (from `C_CurrencyInfo`).
- `label`: Optional override name.

### `currency_cap`
Displays "Current / Max" and a checkmark if capped.
- `id`: Currency ID (from `C_CurrencyInfo`).

### `quest`
Displays a checkbox status (Green check if done).
- `id`: Quest ID (from `C_QuestLog`).

### `header`
Displays a section header.
- `text`: The title text.

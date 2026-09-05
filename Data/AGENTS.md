# Data Management

This folder contains the data definitions for the Weekly addon.
We use a **Registration System** to load data based on Expansion and Season.

## Adding a New Season

1.  Create a new file in `Data/[ExpansionName]/Season[X].lua`.
2.  Follow the template below:

```lua
local _, ns = ...

local Factory = ns.DataFactory
local data = {
    {
        title = "My New Season",
        items = {
            Factory.Currency(1234, "My New Coin"),
            Factory.Quest(5678, "Weekly Event"),
        },
    },
}

-- Register(ExpansionID, SeasonID, Data)
ns.Data:Register(11, 4, data, "Data/ExpansionName/Season4.lua") -- Example: Exp 11, Season 4
```

3.  Add the new file to `Weekly.toc` after `Data/Loader.lua` and `Data/Factories.lua`.
4.  Update `Data:GetRecommendedSeason()` in `Loader.lua` if the new season should be selected automatically, and cover its build boundary in `Tests/test_data_loader.lua`.

## Sections and Settings

Each dataset is an ordered array of sections with a `title` and an `items` array. A flat list of rows or `type = "header"` entries is not supported by the renderer.

- `noSort = true` preserves the order of a section's items.
- `showAfter` and `hideAfter` optionally gate a section using `YYYY-MM-DD` dates at local midnight. Use `Data:IsSectionVisible()` so settings and rendering agree.
- Use `Data:GetItemConfigKey(item)` for visibility settings. Keys are namespaced by type; placeholder IDs (`0`) use the label. An explicit `key` provides a stable identity for composite trackers.
- Unknown quest IDs must use `Factory.PlaceholderQuest(label, icon, coords)`. A bare `Quest(0, ...)` fails dataset validation, keeping placeholders explicit and searchable.
- Expansion IDs in this registry use addon numbering (11 = The War Within, 12 = Midnight), not the zero-based IDs returned by item APIs.

`Data/Validation.lua` provides pure-Lua schema checks for tooling and tests. It validates every registered season, including array shape, tracker requirements, time gates, coordinates, and settings-key collisions. Keep it out of refresh paths; call `ns.Data:ValidateRegistry()` after all season files have loaded.

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
- `icon`: Optional texture path or positive numeric file ID.
- `coords`: Optional `{ mapID, x, y }`, with normalized `x` and `y` values from 0 through 1.

### `item`
Displays the item count, including bank storage through the bridge adapter.
- `id`: Item ID.

### `vault_visual`
Displays Great Vault reward slots.
- `id`: Vault category (1 = Dungeons, 3 = Raid, 6 = World).

### `prey`
Displays the character's observed weekly hunt count using `PreyTracker.lua`.
- `maxCount`: Target count for the selected season.
- `ids`: Optional list of known hunt quest IDs.
- `questId`: Related cache quest, separate from the hunt counter.
- Create these rows with `Factory.Prey()` to preserve their shared settings key.

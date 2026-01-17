# Midnight Pre-Patch Research (12.0.0)

> Research compiled for Weekly addon - tracking weeklies and repetitive content

## Timeline

| Date | Event | Content Type |
|------|-------|--------------|
| **Jan 20** | Patch 12.0.0 | Systems update, Housing (Early Access) |
| **Jan 27** | Twilight Ascension | Pre-patch event, main grind loop |

---

## 1. Twilight Ascension Event (Jan 27)

The primary pre-patch grind loop, similar to *Radiant Echoes*.

### Currency
- **Twilight's Blade Insignia** - Warband-transferable
- Track via `C_CurrencyInfo.GetCurrencyInfo(id).quantity`

### Weekly Quests
| Quest | Reward |
|-------|--------|
| Twilight's Call | 40 Insignias + Champion Gear |
| Disrupt the Call | 40 Insignias + Champion Gear |

*Check `IsWeekly()` flag in QuestUtils*

### Rare Rotation
- **18 Rares** on 10-minute fixed loop
- Achievement: *Two Minutes to Midnight* (Feat of Strength)
- Scan achievement criteria to track player progress

### World Quests
- 4-5 active in Twilight Highlands
- Reward: 10 Insignias each

---

## 2. Player Housing (Jan 20 - Early Access)

### Currencies
| Currency | Purpose |
|----------|---------|
| Lumber | Core crafting (variants: Ironwood, Bamboo) |
| Neighborhood Favor | Unlock rooms/floors |

*Check `C_CurrencyInfo` for weekly cap on Favor*

### Weekly: Neighborhood Endeavors
- Wrapper quest: "Complete 3 Neighborhood tasks"
- API: `C_NeighborhoodInitiative.GetActiveNeighborhood()`

### Dailies
- Small "Favor" quests from neighbors

---

## 3. One-Time Campaign: The Light's Summons

> Campaign tab - one-time story, not tracked by Weekly

| # | Quest | ID |
|---|-------|----|
| 1 | Midnight | 91281 |
| 2 | A Voice from the Light | 88719 |
| 3 | Last Bastion of the Light | 86769 |
| 4 | Champions of Quel'Danas | 86770 |
| 4b | My Son | 89271 |
| 4c | Where Heroes Hold | 86780 |
| 5 | The Hour of Need | 86805 |
| 5b | A Safe Path | 89012 |
| 6 | Luminous Wings | 86806 |
| 7 | The Gate | 86807 |
| 8 | Severing the Void | 91274 |
| 8b | Voidborn Banishing | 86834 |
| 9 | Ethereal Eradication | 86811 |
| 9b | Light's Arsenal | 86848 |
| 10 | Wrath Unleashed | 86849 |
| 11 | Broken Sun | 86850 |
| 12 | Light's Last Stand | 86852 |

[Storyline on Wowhead](https://www.wowhead.com/beta/storyline/the-lights-summons-5811)

---

## API Notes for 12.0

### Quest Tracking
- New: `C_ContentTracking` API
- Enum: `Enum.ContentTrackingTargetType.QuestObjective` (ID 4)

### Achievement Scanning
> ⚠️ **Breaking Change**: Querying hidden/invalid achievement criteria now throws Lua error instead of returning nil
```lua
-- Wrap in pcall or verify existence first
local success, result = pcall(function()
    return C_AchievementInfo.GetAchievementCriteriaInfo(id)
end)
```

### Secret Value Restrictions
- `UnitName` and `UnitClass` restricted in Mythic+ combat
- World tracking unaffected

---

## Action Items for Launch Day (Jan 20)

- [ ] Run `C_CurrencyInfo` dump for final integer IDs
- [ ] Get **Twilight's Blade Insignia** currency ID
- [ ] Get **Neighborhood Favor** currency ID
- [ ] Verify weekly quest IDs for tracking

---

## Resources

- [Warcraft Wiki - Midnight (quest)](https://warcraft.wiki.gg/wiki/Midnight_(quest))
- [Warcraft Wiki - Patch 12.0.0](https://warcraft.wiki.gg/wiki/Patch_12.0.0)
- [Wowhead - The Light's Summons Storyline](https://www.wowhead.com/beta/storyline/the-lights-summons-5811)

# Midnight Season 2 update proposal

Research date: 2026-08-10

Target client: World of Warcraft 12.1.0, *Curse of Ula'tek*

Status: initial Season 2 dataset and tracker support implemented; PTR-derived IDs still require launch validation.

## Recommendation

Use the new `Data/Midnight/Season2.lua` dataset on client builds `>= 120100`, and use the August 11–18 launch window to validate all PTR-derived IDs with the addon's Discovery tool before publishing.

Do not clone `Season1.lua` wholesale. It contains launch-era placeholders (`id = 0`), one-time campaign quests, and it predates the 12.0.5/12.0.7 weekly systems that remain relevant in Season 2. Season 2 should be rebuilt from an audited evergreen baseline plus the new 12.1 content.

The data-only work is small, but three tracker changes should be included because Season 2 exposes existing assumptions:

1. Derive Prey progress and its target from the live wrapper quest objective instead of the hard-coded value `4`.
2. Correct item counting so Warband-bank items such as Corrosive Souls are included.
3. Make live-ID validation and Warband completion semantics explicit rather than silently accepting invalid or character-only results.

## Release facts

- Patch 12.1 launches in North America on **August 11, 2026** (August 12 in Europe).
- Midnight Season 2 begins in North America on **August 18, 2026** (August 19 in Europe).
- The patch adds the Coiled Isle, Vaults of Atal'Utek, Curse Surges, the Nymrissa Lair, Altar of Fangs, three Delves, new Prey content, and the Venomous Abyss raid.
- The content patch is the right activation boundary for the dataset: most new outdoor objectives arrive with 12.1, even though the raid, Bountiful Delves, Mythic+, and Season 2 rewards open one week later.

Sources: [Blizzard's Curse of Ula'tek overview](https://worldofwarcraft.blizzard.com/en-us/news/24294370), [official PTR development notes](https://us.forums.blizzard.com/en/wow/t/midnight-curse-of-ulatek-ptr-development-notes/2317811), [official Season 2 announcement](https://us.forums.blizzard.com/en/wow/t/the-shadows-deepen-midnight-season-2-begins-august-18/2330820), and [official raid schedule](https://news.blizzard.com/en-us/article/24294062/curse-of-ulatek-the-venomous-abyss-raid-goes-live-august-18).

## Proposed Season 2 HUD

### 1. Great Vault

Keep the existing three dynamic rows:

- Raid (`C_WeeklyRewards` category 3)
- Dungeons (`C_WeeklyRewards` category 1)
- World (`C_WeeklyRewards` category 6)

No Season 2-specific Vault IDs are needed.

### 2. Weekly priorities

These are the initial high-value rows. IDs marked "candidate" come from the current PTR database and must be verified on live.

| Row | Candidate ID | Recommendation | Confidence |
|---|---:|---|---|
| Midnight: Delves | 93909 | Carry forward if the same wrapper is offered in Season 2 | Medium; live verification required |
| Midnight: Prey | 93910 | Carry forward as the authoritative progress wrapper; derive its required count dynamically | Medium; live verification required |
| Midnight: World Boss | 93913 | Add; this generic Midnight wrapper already exists and the Nymrissa Lair is the new world-boss path | High for quest ID; validate Lair interaction |
| A Nightmarish Task | 94446 | Carry forward only if still offered in Season 2 | Medium |
| Midnight: Void Assaults | 95842 | Add as evergreen 12.0.5 weekly content | High |
| Purging the Vaults | 95520 | Add as the main Vaults of Atal'Utek weekly meta quest | High PTR candidate |
| Lair: Nymrissa Wavecaller | 97128 | Add if it is a distinct weekly rather than only the generic world-boss wrapper | Medium PTR candidate |

`Purging the Vaults` currently rewards Corrosive Souls, Corrosive Coins, Coffer Key Shards, Zul'jarra's Forces reputation, and a Trovehunter's Bounty on PTR. This makes it the clearest new headline weekly. [Quest database entry](https://www.wowhead.com/ptr/quest=95520/purging-the-vaults).

Exclude these from the default weekly HUD:

- The one-time Season 2 campaign and Prey introduction chain.
- `Prey: Anguish from Beyond` (96528), which the PTR notes describe as daily repeatable.
- `Counter-Curse Bounty`, which is a Renown unlock/reward quest rather than a recurring core weekly.
- Individual Curse Surges unless live testing finds a weekly wrapper; the activity itself is repeatable.
- Placeholder rows with `id = 0`.

The Naigtal/Val weeklies, Ritual Sites, Arcantina rotation, Neighborhood Endeavors, and any rotating weekly-event quests should be captured during the live discovery pass. They should be added as multi-ID quest rows only after their frequency and reset behavior are confirmed.

### 3. Prey

Season 2 adds new targets, affixes, and Coiled Isle hunts, including Kursak the Coiled and the Ral'kala sequence. PTR reporting disagrees on the final weekly hunt limit, which is exactly why the limit should not live in data.

Proposed behavior:

- Treat quest 93910's objective `numFulfilled` and `numRequired` as authoritative while it is active.
- Use a data `maxCount` only as an offline/fallback display value.
- Use `C_QuestLog.GetActivePreyQuest()` only to indicate an active hunt, not to infer weekly completion.
- Retain a list of individual hunt IDs only as a fallback for clients where the wrapper is absent.
- Populate the fallback ID list from Discovery output on live, rather than copying the Season 1 list and guessing.

The 12.1 PTR API still documents `C_QuestLog.GetActivePreyQuest`, `GetQuestObjectives`, and `IsQuestFlaggedCompleted`: [12.1 QuestLog API source](https://raw.githubusercontent.com/Gethe/wow-ui-source/ptr/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua).

### 4. Upgrade and seasonal currencies

The latest PTR database uses a new five-currency Mistcrest series. Earlier PTR builds exposed different IDs for at least the first tiers, so all five must be checked in-game before release.

| Type | Candidate ID | Notes |
|---|---:|---|
| Adventurer Mistcrest | 3442 | Replaces Adventurer Dawncrest for Season 2 |
| Veteran Mistcrest | 3443 | Earlier PTR data also exposed 3438 |
| Champion Mistcrest | 3444 | Season 2 Champion upgrades |
| Hero Mistcrest | 3445 | Season 2 Hero upgrades |
| Myth Mistcrest | 3446 | Season 2 Myth upgrades |
| Corrosive Coin | 3448 | Vaults of Atal'Utek spendable currency |
| Nebulous Voidcore | 3513 | Season 2 bonus-roll currency; current live Season 1 ID differs |

Useful database checks: [Adventurer](https://www.wowhead.com/ptr/currency=3442/adventurer-mistcrest), [Veteran](https://www.wowhead.com/ptr/currency=3443/veteran-mistcrest), [Champion](https://www.wowhead.com/ptr/currency=3444/champion-mistcrest), [Hero](https://www.wowhead.com/ptr/currency=3445/hero-mistcrest), [Myth](https://www.wowhead.com/ptr/currency=3446/myth-mistcrest), [Corrosive Coin](https://www.wowhead.com/ptr/currency=3448/corrosive-coin), and [Nebulous Voidcore](https://www.wowhead.com/ptr/currency=3513/nebulous-voidcore).

Track the five Mistcrests as `currency_cap` and the others as ordinary `currency` unless the live API reports a meaningful weekly cap. The existing `GetCurrencyStatus` implementation already prefers `quantityEarnedThisWeek/maxWeeklyQuantity` when Blizzard provides it.

### 5. Seasonal items

| Item | Candidate ID | Recommendation |
|---|---:|---|
| Corrosive Soul | 273000 | Add as `item`; this is a Warband-bound consumable, not a currency |
| Spark of Tides | 274476 | Add as `item` if the HUD is intended to show crafting-spark inventory |
| Ascendant Venomstone | TBD | Defer; Blizzard says it arrives later in the season |

Sources: [Corrosive Soul](https://www.wowhead.com/ptr/item=273000/corrosive-soul), [Spark of Tides](https://www.wowhead.com/ptr/item=274476/spark-of-tides), and [Blizzard's Season 2 reward changes](https://us.forums.blizzard.com/en/wow/t/curse-of-ulatek-endgame-reward-changes/2317450).

### 6. Persistent Midnight rows

Carry forward stable, still-useful non-seasonal rows rather than making Season 2 feel empty outside the new zone:

- Voidlight Marl (3316)
- Field Accolade (3405)
- Community Coupons (3363)
- Housing lumber items
- Profession Moxie currencies, if preserving the current broad-currency scope

Do not carry Season 1 Dawncrests into the default Season 2 view. Other Season 1 currencies should be retained only when their vendor/system remains useful in 12.1.

## Required tracker changes

### Dynamic Prey target

`UI.lua` currently reads the wrapper quest objective but compares it to `item.maxCount`, which is hard-coded to 4 in `Season1.lua`. Change the active-wrapper path to use `obj.numRequired` when it is greater than zero. Preserve `maxCount` only as a fallback.

Add tests for target changes (4, 12, 15), completion, an absent wrapper, and individual-ID fallback.

### Correct account-bank item counting

`Bridge/Context.lua` says it counts bags, bank, reagent bank, and Warband bank, but currently calls:

```lua
C_Item.GetItemCount(itemId, true, true)
```

In the 12.1 API, the arguments are `itemInfo, includeBank, includeUses, includeReagentBank, includeAccountBank`. The current third argument enables `includeUses`; it does not include either additional bank.

Use the equivalent of:

```lua
C_Item.GetItemCount(itemId, true, false, true, true)
```

This matters immediately for the Warband-bound Corrosive Soul. Source: [12.1 Item API source](https://raw.githubusercontent.com/Gethe/wow-ui-source/ptr/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua).

### Warband-aware quest completion

Validate the new weekly wrappers on a second character. If Blizzard marks a quest account-wide, use `C_QuestLog.IsAccountQuest` plus `IsQuestFlaggedCompletedOnAccount` to avoid showing a completed Warband weekly as unfinished on alts. Do not globally replace character completion checks; many weeklies remain character-specific.

### Discovery improvements

The dev Discovery tool attempts to call `C_QuestLog.IsWeekly`, but that function is not present in the generated 12.1 QuestLog documentation. For accepted quests, classify frequency from `C_QuestLog.GetInfo(logIndex).frequency == Enum.QuestFrequency.Weekly`. Record these fields in exports:

- quest ID and title
- frequency
- account-quest flag
- objective fulfilled/required counts
- map ID and coordinates
- reward currency IDs

This turns the launch-day pass into repeatable evidence instead of a manual name/ID transcription exercise.

## 12.1 API impact assessment

### Direct impact: low

The current 12.1 PTR-generated API documentation still contains the APIs Weekly relies on for its primary HUD:

- `C_CurrencyInfo.GetCurrencyInfo`
- `C_QuestLog.GetActivePreyQuest`, `GetLogIndexForQuestID`, `GetQuestObjectives`, `IsOnQuest`, and `IsQuestFlaggedCompleted`
- `C_Item.GetItemCount` and `GetItemInfo`
- `C_WeeklyRewards.GetActivities` and `GetActivityEncounterInfo`

Sources: [Currency API](https://raw.githubusercontent.com/Gethe/wow-ui-source/ptr/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurrencyInfoDocumentation.lua), [Quest API](https://raw.githubusercontent.com/Gethe/wow-ui-source/ptr/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua), [Item API](https://raw.githubusercontent.com/Gethe/wow-ui-source/ptr/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua), and [Weekly Rewards API](https://raw.githubusercontent.com/Gethe/wow-ui-source/ptr/Interface/AddOns/Blizzard_APIDocumentationGenerated/WeeklyRewardsDocumentation.lua).

### Aura restrictions: no current feature impact

12.1 substantially restricts index/slot/instance-based aura reads while auras are secret and introduces managed aura containers. Weekly does not display or inspect combat auras. Embedded FenUI defines spell-ID-based aura helpers, but Weekly does not call them. This should still receive an in-combat smoke test because the library is loaded.

Source: [12.1 API change summary](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes) and [Blizzard's addon/aura announcement](https://us.forums.blizzard.com/en/wow/t/addons-and-auras-in-curse-of-ula%E2%80%99tek/2317456).

### Texture filename publication: minor workflow impact

Blizzard will no longer publish new UI texture filenames to `ManifestInterfaceData`; existing filenames continue to work. Prefer runtime-provided `iconFileID` values from currency/item/quest APIs for new rows. Avoid adding guessed 12.1 texture paths. Existing icon paths in the dataset are not invalidated.

### TOC version

`Weekly.toc` already targets `## Interface: 120100`; no additional TOC bump is required for 12.1.0.

## Implementation plan

### Phase 1 — Correct the baseline

1. Update stale Data Loader tests so their expectations match the current 12.0/12.0.1 behavior.
2. Add a 12.1.0 test expecting expansion 12, season 2.
3. Correct account-bank item counting and add unit coverage.
4. Make Prey objective targets dynamic and add regression tests.
5. Improve Discovery frequency/account/reward capture.

### Phase 2 — Live reconnaissance (August 11–18)

1. Run Discovery while accepting and completing every new Coiled Isle, Vaults, Lair, Prey, Arcantina, and Endeavor wrapper.
2. Dump the five Mistcrest currencies, Corrosive Coin, Nebulous Voidcore, Corrosive Soul, and Spark of Tides.
3. Confirm whether 93909, 93910, 93913, 94446, and 95842 persist.
4. Confirm whether 97128 and 93913 represent separate weekly completions.
5. Test all Warband-wide rows on a second character.
6. Record any time-gated quest variants as multi-ID rows.

### Phase 3 — Season 2 dataset

1. Add `Data/Midnight/Season2.lua` and register it with `ns.Data:Register(12, 2, data)`.
2. Add it after Season 1 in `Weekly.toc`.
3. Return `(12, 2)` from `GetRecommendedSeason()` for TOC `>= 120100`.
4. Build sections from the verified list above; exclude placeholders and one-time campaign rows.
5. Preserve Season 1 as a manually selectable historical dataset.

### Phase 4 — Verification and release

1. Run formatter, linter, sandbox tests, and locale validation.
2. Smoke-test the HUD out of combat and in combat on 12.1.
3. Test an empty/new character, a main with completed weeklies, and an alt after Warband completion.
4. Verify every row has a real icon/name and that no row renders `---`, `Unknown`, or a permanently incomplete placeholder.
5. Recheck IDs after the August 18 Season 2 reset, because seasonal currencies and wrapper availability may differ from the pre-season week.

## Acceptance criteria

- Automatic selection chooses Midnight Season 2 on 12.1 clients.
- The default dataset contains no `id = 0` rows and no one-time campaign checklist.
- Mistcrest caps display current weekly progress correctly.
- Corrosive Souls include the account bank in their displayed count.
- Prey displays the server-provided target, not a hard-coded Season 1 target.
- New weeklies show correct active, progress, and completed states on main and alt characters.
- All PTR-derived IDs have been confirmed on live or are explicitly omitted until confirmed.
- No Lua errors occur when opening or updating the tracker in or out of combat.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| PTR IDs change at launch | Treat all new IDs as candidates and validate with runtime APIs/Discovery |
| Patch week and season week differ | Activate outdoor dataset at build 120100, then perform a second validation at the August 18 reset |
| Prey target changes again | Read `numRequired` from the active wrapper objective |
| Warband quests look incomplete on alts | Detect account quests and use account completion only for those rows |
| Item counts omit Warband bank | Pass the explicit `includeAccountBank` argument |
| New texture names are unavailable | Use API-provided file IDs and existing texture paths |
| Aura API restrictions affect embedded code | In-combat smoke test; no new aura-dependent behavior |

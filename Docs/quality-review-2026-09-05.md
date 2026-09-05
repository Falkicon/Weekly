# Repository quality review — September 5, 2026

## Assessment

The existing separation between pure actions, WoW API adapters, configuration, seasonal data, and rendering is workable. The strongest findings concern state transitions and integration contracts: weekly resets, profile changes, delayed item data, optional widgets, and diagnostic sampling.

The review covered first-party Lua modules, tests, data definitions, localization references, manifests, packaging, and contributor guidance. Bundled libraries were inspected where needed to verify integration contracts; their internals were not comprehensively audited. Seasonal quest/currency IDs were not revalidated against live gameplay.

## Fixed findings

| Priority | Finding and consequence | Change |
| --- | --- | --- |
| P1 | A Journal event within 60 seconds of the previous check could cross the reset boundary without clearing the old week. New-week loot could later be erased with the old records. | Bypass the throttle when the saved reset boundary has arrived. Regression covers the first loot event at that boundary. |
| P1 | Uncached loot queued before a reset could be credited to the following week when its item data arrived. | Check resets in the item-data callback and discard pending quantities during reset. |
| P2 | Clearing Journal gathering data could be undone by an outstanding item-data callback. | Clear pending gathering quantities on manual category/full clears. |
| P2 | Fresh profiles were not marked as migrated until auto-show became true. Enabling auto-show could therefore be undone on the next reload. | Mark all visited profiles, and run migrations when profiles are changed, copied, or reset. |
| P2 | Profile changes applied appearance and position but ignored the profile's saved tracker visibility. | Restore saved visibility when refreshing the profile. Login auto-show remains a separate preference. |
| P2 | Item tracker values stayed stale after bag changes or newly available item data. | Route bag and item-data events through the existing coalesced refresh queue. Item rows also receive item tooltips. |
| P2 | Journal collectible rows assigned callbacks that FenUI's grid never invoked. Without FenUI, nonempty category tabs had no rendering path. | Connect the grid's supported interaction hooks and implement the category view using pooled fallback rows, sharing item interaction binding. |
| P2 | Mechanic's debug toggle overwrote the debug table with a boolean, losing other settings. Its window tools bypassed public methods and persistence. | Preserve `debug.enabled` and sibling fields, update debug event subscriptions, delegate window toggles, and save reset positions. |
| P2 | Ordinary Vault status refreshes loaded full dungeon history and scanned raid lockouts. | Request those details only for the detailed tooltip action. |
| P2 | Mechanic reported a mixture of last-refresh durations and cumulative Journal time as milliseconds per second. | Accumulate counters and report sampled rates over a common elapsed interval. |
| P3 | Export windows were hidden without releasing their AceGUI widgets. | Release each export window on close so the library can reuse it. |
| P3 | Tracker exports could reorder categories and equal-timestamp items between equivalent runs. | Sort category names and add deterministic item tie-breakers. |
| P3 | Rendering created unused per-row wrapper/context tables and repeatedly resolved the same font. Gathering views regrouped and sorted the whole collection for each expansion. | Reuse source rows and the resolved font within a render; reuse the gathering groups from the first pass. |
| P3 | The minimap setting could appear unchecked before default saved settings existed. | Read the broker's state, with the correct visible default as fallback. |
| P3 | Data-authoring docs referenced a nonexistent `Data.lua` and an unsupported flat header/row schema. Development files were included in release packaging. | Document the actual section registry and factories, align interface metadata in docs, document both test commands, and exclude tests/development documentation from packages. |

## Validation

Combined validation passed:

- **117 tests:** 69 addon module tests and 48 pure action tests; no failures, errors, or pending tests.
- **Luacheck:** zero warnings and zero errors across all 25 first-party production Lua files.
- **Localization:** all literal `L["..."]` references resolve in the 161-key base locale.
- **Manifest:** every runtime file listed in `Weekly.toc` exists.
- **Whitespace:** `git diff --check` passes.

New regression files cover profile behavior, tracker refresh events, export widget lifecycle/order, minimap settings, Journal UI interaction, and Mechanic integration. Existing bridge and Journal tests cover the Vault query split and reset/clear boundaries. Timing improvements are supported by eliminated queries/allocations and counter tests; no live-game performance benchmark was run.

The repository's two Busted commands are both required:

```sh
luacheck .
busted --pattern='test_.*%.lua' Tests
busted Tests/Core
git diff --check
```

## In-game verification still needed

The automated tests run against Lua 5.1 with mocked WoW APIs. Verify profile switching and saved visibility, bag-driven item counts, Journal category clicks/tooltips with and without FenUI, reset/clear behavior, and Mechanic's performance display in WoW. Combat restrictions and visual layout require the live client; no in-game validation was performed during this review.

For future work, preserve the existing action/adapter boundary and test state transitions as well as happy-path calculations. Profile switches, weekly boundaries, delayed callbacks, and optional-library paths now have more direct regression coverage and remain the most valuable places to extend it.

## Follow-up implementation

The subsequent improvement pass added centralized module activation/shutdown, versioned profile and character migrations, automatic validation of all TOC-listed season data, lifecycle integration tests, and a shared local/CI validation command with pinned Lua tools and explicit line-ending rules. See [Lifecycle, migrations, and validation](development.md) for the development contract.

The follow-up local validation gate passes **150 tests** (93 addon, 48 pure action, 9 tooling), Luacheck 1.2.0 across 27 first-party Lua files, localization, checkout/release dependencies, orphan-season checks, and diff whitespace. GitHub Actions is wired to the same gate; it was not run remotely during this session. Live WoW verification is still required.

# Lifecycle, migrations, and validation

## Module lifecycle

`Weekly:OnInitialize()` loads the database, applies migrations, and creates configuration and tracker UI. AceAddon's `OnEnable()` then calls the single ordered activation path, `Weekly:ApplyConfig(reason)`. Journal, its broker, Discovery, and Prey no longer rely on separate delayed `PLAYER_LOGIN` callbacks.

The reason describes the state transition:

| Reason | Meaning |
| --- | --- |
| `login` | First enable this session; tracker `autoShow` may override saved visibility. |
| `enable` | Subsequent enable; restore saved visibility. |
| `profile` | Profile changed, copied, or reset; apply the new profile's settings and Journal records. |
| `settings` | Apply a change to module settings, such as enabling Journal tracking. |

Initialization methods must tolerate repeated calls. Activation owns event subscriptions; shutdown unregisters them, saves current data when appropriate, and hides windows. The tracker invalidates queued refresh callbacks when it shuts down, so callbacks from a previous activation cannot interfere with new work.

Use `Weekly:SetDebugEnabled(enabled)` for debug changes. It preserves other debug settings and keeps quest subscriptions in sync with both the preference and addon activation. Slash commands and Mechanic use this same method.

Profile handling has an important distinction: `PrepareProfileChange()` saves and shuts down the old Journal before a normal switch. Copy/reset callbacks can arrive after AceDB has already overwritten the current table. `RefreshConfig()` therefore discards the old runtime Journal without saving, updates database aliases, migrates the new records, and calls `ApplyConfig("profile")`. Do not replace that discard with `Shutdown()` after a copy/reset; it could write old history into the new profile.

While the addon is disabled, profile aliases and migrations can update, but `ApplyConfig` does not activate modules. Re-enabling applies the current profile.

## Saved-data versions

`Core/ConfigMigrations.lua` maintains separate ordered migrations for profile and character records. `schemaVersion` is stored on each saved record and must never appear in `ConfigDefaults`: AceDB defaults could otherwise make old records look current.

Profile version 1 imports the legacy auto-show/anchor migration flags. Version 2 converts legacy boolean debug settings and repairs missing or malformed setting containers/types. Character version 1 repairs the character settings structure. Journal history and unknown fields are preserved when their surrounding containers are valid.

When adding a migration:

1. Append an idempotent step to the appropriate scope and update its version constant.
2. Preserve explicit choices and data belonging to the other scope.
3. Test the previous version, an incomplete record, repeated application, and profile copy/reset when relevant.
4. Keep version stamping after successful completion of each step. An interrupted step must remain retryable.

The migration helper returns false without running steps for unknown or future schema versions. This prevents a downgrade from applying older migration steps to a newer record; it is not a general promise that an older addon can understand every future setting.

## Seasonal data and release validation

The dataset tests read ordered `Data/*.lua` entries from `Weekly.toc`, then validate the entire registry. Adding a new season to the TOC automatically includes it in these tests. The static validator also rejects a `Data/*/Season*.lua` file omitted from the TOC.

Use `Factory.PlaceholderQuest` for unconfirmed IDs rather than `Quest(0, ...)`. The validator checks data structure, required tracker fields, dates, coordinates, and conflicting settings keys without querying the game API. It reports source and row paths and rejects malformed arrays without scanning arbitrary numeric ranges. Validation is invoked by tooling/tests, not by the UI refresh loop. See [Data Management](../Data/AGENTS.md) for the full format.

Run `python Tools/validate.py` before submitting changes. CI uses the same command and the tool versions from `Tools/toolchain.json`. It includes both Lua suites, validation-tool tests, localization references, TOC/XML dependencies, release exclusions, orphan seasons, lint, and whitespace checks. See [Contributing](../CONTRIBUTING.md) for installation and executable overrides.

The tests cover real-module lifecycle sequences and exercise migrations against bundled AceDB. Optional broker libraries are tested both present and absent, while Journal UI tests cover FenUI hooks and fallback rendering. WoW still needs to be used to verify visual layout, client event timing, and combat restrictions.

# Contributing to Weekly

Thanks for your interest in contributing! Weekly is a lightweight HUD for tracking weekly objectives in World of Warcraft, and we welcome bug reports, feature suggestions, and code contributions.

## Getting Started

1. **Fork and clone** the repository
2. **Place the addon** in your WoW addons directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\Weekly\
   ```
3. **Install validation tools** using the setup below and run `python Tools/validate.py` from the repository root
4. **Restart WoW** for the first installation, then use `/reload` after source edits. Check that the loaded copy is the checkout you are editing

Source checkouts load `Dev/Discovery.lua` through the TOC debug block, making `/weekly discovery` available. Release packaging removes that block and excludes development files through `.pkgmeta`.

## Development Guidelines

### Read the Docs First

- [AGENTS.md](AGENTS.md) – Technical reference for development
- [README.md](README.md) – General overview and usage instructions
- [Lifecycle and Migrations](Docs/development.md) – Activation, profile transitions, saved-data versions, and validation
- [Data Management](Data/AGENTS.md) – Seasonal data structure, placeholders, and ID verification

### Code Style

- **Lua 5.1-compatible syntax** for the pinned validation toolchain; game APIs are supplied by the WoW client
- **Local variables** – Prefer `local` for performance and scope control
- **Ace3 Framework** – Use AceAddon, AceDB, and AceConfig patterns
- **Data-Driven** – Add currencies and quests to `Data/<Expansion>/Season<N>.lua` using `Data/Factories.lua`. Register new files in `Weekly.toc`; use explicit placeholder quests for unconfirmed IDs
- **Localization** – Wrap user-facing UI strings in `L["KEY"]` and define keys in `Locales/enUS.lua`. Seasonal data labels follow the data guide
- **Lifecycle and storage** – Route activation through `Weekly:ApplyConfig(reason)` and add saved-data changes to the ordered migrations. Preserve the distinction between profile settings/Journal history and the character-specific Prey ledger

### Performance Expectations

This addon prioritizes a clean, performant experience:

- Avoid per-frame table allocations
- Use event-driven updates where possible
- Reuse row frames and scratch tables; keep retained data bounded
- Coalesce bursts of events and keep expensive history queries out of ordinary rendering

### Midnight Compatibility

The addon targets Interface 120100 (Midnight expansion). When adding features:

- Assume APIs may be restricted in combat
- Fail gracefully – avoid throwing Lua errors during combat lockdown

## Submitting Changes

### Bug Reports

Open an issue with:

- Addon version, WoW build, client channel (Retail/PTR/Beta), and selected expansion/season
- Steps to reproduce
- Output from `/weekly debug` if relevant; this command also toggles quest-event logging, so run it again to turn logging off after reproducing
- Any Lua errors from BugSack/BugGrabber

### Feature Requests

Open an issue describing:

- What you want to accomplish
- Why it fits the addon's scope (lightweight weekly tracker)

### Pull Requests

1. **Create a branch** from `main`
2. **Keep changes focused** – one feature or fix per PR
3. **Run validation and test in-game** on the affected client build; include PTR/Beta checks when the change depends on those APIs or datasets
4. **Update docs** if adding settings or slash commands
5. **Describe your changes** in the PR description

## File Structure

See [AGENTS.md](AGENTS.md#file-structure) for the module map. `Weekly.toc` defines runtime load order, `embeds.xml` loads bundled libraries, and `.pkgmeta` controls release exclusions and external libraries.

## Testing Checklist

Run the same validation command locally and in CI from the repository root:

```sh
python Tools/validate.py
```

It checks tool versions, validation-tool tests, literal localization keys, the TOC/XML dependency tree, release exclusions, season files omitted from the TOC, Lua lint, both Busted suites (including dataset and lifecycle tests), and diff whitespace. A failed check returns a nonzero exit code.

Install Python 3.10+, Git, Lua 5.1 and LuaRocks, then install the pinned Busted and Luacheck versions with `python Tools/install_lua_tools.py`. This uses your configured LuaRocks tree; use `sudo` only if installing to a system tree that requires it. Version pins live in `Tools/toolchain.json` and are shared by installation, validation, and CI.

When Lua executables are not on `PATH`, pass `--lua`, `--busted`, or `--luacheck`. The `--busted-script` and `--luacheck-script` alternatives invoke Lua entrypoints directly, which also avoids stale Windows launchers. Configure `LUA_PATH` and `LUA_CPATH` for your LuaRocks installation when using these alternatives. Run `python Tools/validate.py --help` for the full options.

The release check follows the checked-out files using `.pkgmeta` exclusions and TOC debug blocks. It catches missing or excluded runtime dependencies, including nested XML includes, and development files accidentally left in the package. It does not fetch or verify remote CurseForge externals. Tests use mocks and do not replace the in-game checks below.

`.gitattributes` specifies LF for source files and CRLF for Windows batch files. Apply that policy to files you edit; avoid unrelated repository-wide formatting changes.

Before submitting:

- [ ] `python Tools/validate.py` passes
- [ ] Addon loads without errors on the target client build
- [ ] Affected tracker/Journal views and interactions display correctly
- [ ] Settings and visibility persist across reloads; profile switch/copy/reset behaves correctly when affected
- [ ] No Lua errors during affected combat or event paths
- [ ] Seasonal ID changes are verified in-game, or clearly marked as candidates/placeholders

Report which checks you ran and any in-game checks you could not perform. For release work, also inspect the actual packaged artifact with its resolved external libraries; the local release check alone does not cover that step.

## Questions?

Open an issue or check the existing documentation. Thanks for helping make Weekly better!

# Contributing to Weekly

Thanks for your interest in contributing! Weekly is a lightweight HUD for tracking weekly objectives in World of Warcraft, and we welcome bug reports, feature suggestions, and code contributions.

## Getting Started

1. **Fork and clone** the repository
2. **Place the addon** in your WoW addons directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\Weekly\
   ```
3. **Test in-game** with `/reload` after making changes

## Development Guidelines

### Read the Docs First

- [AGENTS.md](AGENTS.md) – Technical reference for development
- [README.md](README.md) – General overview and usage instructions

### Code Style

- **Lua 5.1** syntax (WoW's embedded Lua version)
- **Local variables** – Prefer `local` for performance and scope control
- **Ace3 Framework** – Use AceAddon, AceDB, and AceConfig patterns
- **Data-Driven** – New currencies or quests should be added to `Data/*.lua` files

### Performance Expectations

This addon prioritizes a clean, performant experience:

- Avoid per-frame table allocations
- Use event-driven updates where possible
- Memory should remain stable between GC cycles

### Midnight Compatibility

The addon targets Interface 120001 (Midnight expansion). When adding features:

- Assume APIs may be restricted in combat
- Fail gracefully – avoid throwing Lua errors during combat lockdown

## Submitting Changes

### Bug Reports

Open an issue with:

- WoW version and client (Retail/Beta)
- Steps to reproduce
- Output from `/weekly debug` if relevant
- Any Lua errors from BugSack/BugGrabber

### Feature Requests

Open an issue describing:

- What you want to accomplish
- Why it fits the addon's scope (lightweight weekly tracker)

### Pull Requests

1. **Create a branch** from `main`
2. **Keep changes focused** – one feature or fix per PR
3. **Test in-game** on both Retail and Beta if possible
4. **Update docs** if adding settings or slash commands
5. **Describe your changes** in the PR description

## File Structure

| File | Purpose |
|------|---------|
| `Weekly.toc` | Manifest |
| `Core.lua` | Initialization, Slash commands |
| `Config.lua` | Default configuration & storage logic |
| `ConfigUI.lua` | AceConfig settings panel |
| `UI.lua` | Frame creation and rendering |
| `TrackerCore.lua` | Shared tracking infrastructure |
| `Data/Loader.lua` | Data registry and season loader |
| `Journal/` | Weekly Journal logic and UI |

## Testing Checklist

Before submitting:

- [ ] Addon loads without errors (`/reload`)
- [ ] UI displays correctly
- [ ] Settings persist across sessions
- [ ] `/weekly debug` shows correct info
- [ ] No Lua errors in combat

## Questions?

Open an issue or check the existing documentation. Thanks for helping make Weekly better!

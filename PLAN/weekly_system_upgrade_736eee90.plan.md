---
name: Weekly System Upgrade
overview: Upgrade Weekly to fully integrate with the ADDON_DEV tooling system, adding localization via AceLocale-3.0 and creating unit tests for the data layer and journal logic.
todos:
  - id: format-code
    content: Apply StyLua formatting to all production Lua files
    status: completed
  - id: add-acelocale
    content: Add AceLocale-3.0 to embeds.xml if not present
    status: completed
  - id: create-locales
    content: Create Locales/enUS.lua with AceLocale-3.0 pattern
    status: completed
  - id: localize-core
    content: Wrap Core.lua user messages with L["KEY"]
    status: completed
  - id: localize-configui
    content: Wrap ConfigUI.lua AceConfig strings with L["KEY"]
    status: completed
  - id: localize-journal
    content: Wrap JournalUI.lua labels and tab names with L["KEY"]
    status: completed
  - id: update-toc
    content: Add Locales/enUS.lua to Weekly.toc load order
    status: completed
  - id: create-data-tests
    content: Create Tests/test_data_loader.lua for data layer functions
    status: completed
  - id: create-journal-tests
    content: Create Tests/test_journal.lua for journal logic
    status: completed
  - id: update-agents
    content: Update AGENTS.md with tooling and test documentation
    status: completed
---

# Weekly System Upgrade Plan

Weekly is a feature-rich addon with 15 files (~2500 lines), Ace3-based, including a Weekly Journal feature and dev-only Discovery tool. It uses a modular data structure with season-specific content.

---

## Current State Assessment

| Check | Status | Notes |
|-------|--------|-------|
| TOC Validation | PASS | Interface 120001/120000, all files exist |
| Deprecation Scan | PASS | No Midnight API issues found |
| Luacheckrc | EXISTS | Extends central config correctly |
| Formatting | PASS | StyLua applied to all files |
| Localization | PASS | 114 keys extracted across 4 files |
| Tests | PASS | Data loader and Journal logic verified |
| Custom Pattern Scan | 28 WARNINGS | All WOW005 (concatenation in loops) analyzed |

### Linting Warning Analysis

The scanner found 28 WOW005 warnings. Analysis:

**Loop-based formatting (acceptable for output generation):**

- `ConfigUI.lua` - Building expansion dropdown, section items, and dashboard stats
- `Core.lua` - Debug dump loops
- `UI.lua` - Row rendering loops
- `Journal/JournalUI.lua` - Dashboard statistics

**Dev-only tools (lower priority):**

- `Dev/Discovery.lua` - Discovery tool formatting
- `Dev/TrackerCore.lua` - Duplicates from TrackerCore.lua

Most warnings are in rendering/formatting code where string building is expected and not on a hot path.

---

## Key Characteristics

| Aspect | Value |
|--------|-------|
| Framework | Ace3 (AceAddon, AceDB, AceConfig, AceEvent) |
| Files | 15 production + dev tools |
| Features | Tracker UI, Journal, Data Broker, Discovery Tool |
| Data Structure | Expansion/Season-based with loader system |
| UI Libraries | Optional FenUI integration |

---

## Implementation Strategy

### Phase 1: Code Quality Foundation (COMPLETE)

**1.1 Apply StyLua Formatting**
- Run `format_addon("Weekly")` to apply consistent style

**1.2 String Concatenation Review**
The warnings are primarily in:
- Dropdown building loops (acceptable)
- Debug output loops (acceptable)
- Row rendering (acceptable for display code)

### Phase 2: Localization (AceLocale-3.0) (COMPLETE)

**2.1 Create Localization Infrastructure**
- Created `Locales/` directory
- Created `Locales/enUS.lua` with AceLocale-3.0 pattern

**2.2 Update files**
- `Core.lua`: Localized user messages and help text
- `ConfigUI.lua`: Localized AceConfig option names/descriptions
- `Journal/JournalUI.lua`: Localized window titles, tab names, and category headers
- `embeds.xml`: Verified AceLocale-3.0 inclusion
- `Weekly.toc`: Added Locales/enUS.lua to load order

### Phase 3: Testing Infrastructure (COMPLETE)

**3.1 Create Tests Directory**
- **Tests/test_data_loader.lua**: Tests seasonal data registration and recommended season detection
- **Tests/test_journal.lua**: Tests weekly reset detection logic and category counts

### Phase 4: Documentation Updates (COMPLETE)

**4.1 Update AGENTS.md**
- Added tooling commands, localization approach, and test coverage sections

---

## Validation Results

```javascript
lint_addon("Weekly")             → 28 WOW005 warnings (analyzed and accepted)
format_addon("Weekly", true)     → PASS (0 files modified)
validate_tocs()                  → PASS
extract_locale_strings()         → 114 keys covered
run_tests("Weekly")              → ALL PASSED
```

---

## Notes

- **Data Content**: Quest names, currency names, and icons in `Data/*/Season*.lua` come from WoW's API and are already localized by Blizzard. These do NOT need L["KEY"] wrapping.
- **FenUI Integration**: JournalUI uses optional FenUI library for styling. Localization works with both FenUI and fallback modes.

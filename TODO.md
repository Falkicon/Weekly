# Follow-up Work

Pending checks and data work after the repository quality review. Automated coverage and completed changes are documented in [the review report](Docs/quality-review-2026-09-05.md) and [CHANGELOG.md](CHANGELOG.md).

## In-game Verification

- [ ] Exercise startup, disable/re-enable, and profile switch/copy/reset on the target client. Check tracker visibility, debug subscriptions, and Journal history isolation between profiles.
- [ ] Check tracker and Journal layout, tabs, category lists, tooltips, and broker controls with the bundled FenUI widgets and the fallback UI path.
- [ ] Verify loot callbacks and Journal/Prey reset behavior at a regional weekly boundary, including uncached items and reloads.
- [ ] Check affected quest, bag, and UI interactions during combat and record the client build used.

## Seasonal Data

- [ ] Confirm the PTR candidate quest IDs in `Data/Midnight/Season2.lua` using the source-build Discovery tool.
- [ ] Resolve intentional `Factory.PlaceholderQuest` entries as IDs become available. Verify objectives and coordinates before replacing placeholders.
- [ ] Recheck automatic build thresholds and dataset time gates when adopting a new season. Structural validation alone cannot confirm live content availability.

## Release Verification

- [ ] Run `python Tools/validate.py` before release.
- [ ] Inspect the actual packaged artifact after external libraries resolve. Confirm runtime dependencies are present and development files/debug TOC entries are excluded.
- [ ] Smoke-test that artifact in WoW with optional integrations present and absent. Record the package version and client build.

See [Contributing](CONTRIBUTING.md) for setup and validation instructions. These items remain pending until their results are recorded; mocked tests do not establish in-game verification.

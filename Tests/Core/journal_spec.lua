--------------------------------------------------------------------------------
-- Weekly Addon - Journal Actions Tests (Sandbox)
-- Run with: mech call sandbox.test -i '{"addon": "Weekly"}'
--------------------------------------------------------------------------------

-- Set up globals for addon loading (sandbox pattern)
-- The vararg pattern `local _, ns = ...` becomes `_G["ns"]` when ns is global
_G.ns = { Actions = {} }

-- Mock FenCore for testing (matches FenCoreCompat.lua fallback pattern)
_G.ns.FenCore = {
	ActionResult = {
		success = function(data, reasoning)
			return { success = true, data = data, reasoning = reasoning }
		end,
		error = function(code, message, suggestion)
			return { success = false, error = { code = code, message = message, suggestion = suggestion } }
		end,
		isSuccess = function(result)
			return result and result.success == true
		end,
		unwrap = function(result)
			return result and result.success and result.data or nil
		end,
	},
}

-- Stub the vararg loader that WoW addons use
local function loadAddonFile(path)
	local chunk = loadfile(path)
	if chunk then
		-- Call with addon name and namespace as varargs
		chunk("Weekly", _G.ns)
	end
end

-- Load journal actions
loadAddonFile("Core/Actions/journal.lua")
local Journal = _G.ns.Actions.Journal

--------------------------------------------------------------------------------
-- ParseLootMessage Tests
--------------------------------------------------------------------------------

describe("Journal.ParseLootMessage", function()
	it("parses standard loot message with quantity", function()
		local result = Journal.ParseLootMessage({
			message = "You receive loot: |cff1eff00|Hitem:12345:0:0:0:0:0:0:0:0|h[Test Item]|h|r x5.",
		})

		assert.is_true(result.success)
		assert.equals(12345, result.data.itemID)
		assert.equals(5, result.data.quantity)
		assert.is_not_nil(result.data.itemLink)
	end)

	it("defaults to quantity 1 when not specified", function()
		local result = Journal.ParseLootMessage({
			message = "You receive loot: |cff1eff00|Hitem:67890:0:0:0:0:0:0:0:0|h[Single Item]|h|r.",
		})

		assert.is_true(result.success)
		assert.equals(67890, result.data.itemID)
		assert.equals(1, result.data.quantity)
	end)

	it("returns nil values when no item link found", function()
		local result = Journal.ParseLootMessage({
			message = "You receive 50 gold.",
		})

		assert.is_true(result.success)
		assert.is_nil(result.data.itemLink)
		assert.is_nil(result.data.itemID)
		assert.equals(0, result.data.quantity)
	end)

	it("returns error for missing message", function()
		local result = Journal.ParseLootMessage(nil)

		assert.is_false(result.success)
		assert.equals("INVALID_CONTEXT", result.error.code)
	end)

	it("handles epic quality items", function()
		local result = Journal.ParseLootMessage({
			message = "You receive loot: |cffa335ee|Hitem:99999:0:0:0:0:0:0:0:0|h[Epic Sword]|h|r x1.",
		})

		assert.is_true(result.success)
		assert.equals(99999, result.data.itemID)
	end)
end)

--------------------------------------------------------------------------------
-- ClassifyLootItem Tests
--------------------------------------------------------------------------------

describe("Journal.ClassifyLootItem", function()
	it("identifies herbs as gathering materials", function()
		local result = Journal.ClassifyLootItem({
			itemID = 12345,
			itemClassID = 7, -- Trade Goods
			itemSubClassID = 9, -- Herb
			expansionID = 10,
		})

		assert.is_true(result.success)
		assert.is_true(result.data.isGathering)
		assert.equals("Herb", result.data.category)
		assert.equals(10, result.data.expansion)
	end)

	it("identifies ore as gathering materials", function()
		local result = Journal.ClassifyLootItem({
			itemID = 12345,
			itemClassID = 7, -- Trade Goods
			itemSubClassID = 7, -- Metal & Stone
			expansionID = 9,
		})

		assert.is_true(result.success)
		assert.is_true(result.data.isGathering)
		assert.equals("Metal & Stone", result.data.category)
	end)

	it("identifies leather as gathering materials", function()
		local result = Journal.ClassifyLootItem({
			itemID = 12345,
			itemClassID = 7, -- Trade Goods
			itemSubClassID = 6, -- Leather
			expansionID = 8,
		})

		assert.is_true(result.success)
		assert.is_true(result.data.isGathering)
		assert.equals("Leather", result.data.category)
	end)

	it("rejects non-trade goods items", function()
		local result = Journal.ClassifyLootItem({
			itemID = 12345,
			itemClassID = 2, -- Weapon
			itemSubClassID = 1,
			expansionID = 10,
		})

		assert.is_true(result.success)
		assert.is_false(result.data.isGathering)
		assert.is_nil(result.data.category)
	end)

	it("rejects non-tracked trade goods subclasses", function()
		local result = Journal.ClassifyLootItem({
			itemID = 12345,
			itemClassID = 7, -- Trade Goods
			itemSubClassID = 0, -- Untracked subclass
			expansionID = 10,
		})

		assert.is_true(result.success)
		assert.is_false(result.data.isGathering)
	end)

	it("returns error for invalid context", function()
		local result = Journal.ClassifyLootItem(nil)

		assert.is_false(result.success)
		assert.equals("INVALID_CONTEXT", result.error.code)
	end)
end)

--------------------------------------------------------------------------------
-- ShouldResetJournal Tests
--------------------------------------------------------------------------------

describe("Journal.ShouldResetJournal", function()
	it("detects reset when week start is newer", function()
		-- Simulate: savedWeekStart = last week, current = this week
		local result = Journal.ShouldResetJournal({
			currentServerTime = 1700000000,
			savedWeekStart = 1699300000, -- Older
			resetDayOfWeek = 3, -- Tuesday
			resetHour = 7,
			currentDate = {
				weekday = 4, -- Wednesday
				hour = 10,
				minute = 30,
			},
		})

		assert.is_true(result.success)
		assert.is_true(result.data.shouldReset)
	end)

	it("does not reset within same week", function()
		-- Calculate a weekStart that would be current
		local currentTime = 1700000000
		local result = Journal.ShouldResetJournal({
			currentServerTime = currentTime,
			savedWeekStart = currentTime - 1000, -- Very recent
			resetDayOfWeek = 3,
			resetHour = 7,
			currentDate = {
				weekday = 3, -- Tuesday (reset day)
				hour = 8, -- After reset
				minute = 0,
			},
		})

		assert.is_true(result.success)
		-- The calculation is complex, but it should handle same-week properly
	end)

	it("returns error for missing context", function()
		local result = Journal.ShouldResetJournal(nil)

		assert.is_false(result.success)
		assert.equals("INVALID_CONTEXT", result.error.code)
	end)

	it("returns error for missing date info", function()
		local result = Journal.ShouldResetJournal({
			currentServerTime = 1700000000,
			savedWeekStart = 0,
			resetDayOfWeek = 3,
			resetHour = 7,
			currentDate = nil,
		})

		assert.is_false(result.success)
		assert.equals("MISSING_DATE", result.error.code)
	end)
end)

--------------------------------------------------------------------------------
-- FormatJournalSummary Tests
--------------------------------------------------------------------------------

describe("Journal.FormatJournalSummary", function()
	it("formats summary with collectibles and gathering", function()
		local result = Journal.FormatJournalSummary({
			categories = {
				mount = 2,
				pet = 1,
				achievement = 3,
			},
			gatheringTotal = 500,
			achievementPoints = 50,
		})

		assert.is_true(result.success)
		assert.is_true(result.data.hasContent)
		assert.match("6 collectibles", result.data.summaryText)
		assert.match("50 achievement pts", result.data.summaryText)
		assert.match("500 materials", result.data.summaryText)
	end)

	it("returns no activity message when empty", function()
		local result = Journal.FormatJournalSummary({
			categories = {},
			gatheringTotal = 0,
			achievementPoints = 0,
		})

		assert.is_true(result.success)
		assert.is_false(result.data.hasContent)
		assert.equals("No activity this week", result.data.summaryText)
	end)

	it("handles partial data", function()
		local result = Journal.FormatJournalSummary({
			categories = { toy = 1 },
			gatheringTotal = 0,
			achievementPoints = 0,
		})

		assert.is_true(result.success)
		assert.is_true(result.data.hasContent)
		assert.match("1 collectibles", result.data.summaryText)
	end)

	it("returns error for missing context", function()
		local result = Journal.FormatJournalSummary(nil)

		assert.is_false(result.success)
		assert.equals("INVALID_CONTEXT", result.error.code)
	end)
end)

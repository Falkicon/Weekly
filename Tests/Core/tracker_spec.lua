--------------------------------------------------------------------------------
-- Weekly Addon - Tracker Actions Tests (Sandbox)
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

-- Load tracker actions
loadAddonFile("Core/Actions/tracker.lua")
local Tracker = _G.ns.Actions.Tracker

--------------------------------------------------------------------------------
-- GetCurrencyStatus Tests
--------------------------------------------------------------------------------

describe("Tracker.GetCurrencyStatus", function()
	it("returns success with valid context", function()
		local result = Tracker.GetCurrencyStatus({
			quantity = 100,
			maxQuantity = 500,
			maxWeeklyQuantity = 0,
			quantityEarnedThisWeek = 0,
		})

		assert.is_true(result.success)
		assert.is_not_nil(result.data)
	end)

	it("returns isCapped=true when at weekly max", function()
		local result = Tracker.GetCurrencyStatus({
			quantity = 500,
			maxQuantity = 1000,
			maxWeeklyQuantity = 500,
			quantityEarnedThisWeek = 500,
		})

		assert.is_true(result.success)
		assert.is_true(result.data.isCapped)
		assert.equals(500, result.data.amount)
		assert.equals(500, result.data.max)
	end)

	it("returns isCapped=false when below weekly max", function()
		local result = Tracker.GetCurrencyStatus({
			quantity = 300,
			maxQuantity = 1000,
			maxWeeklyQuantity = 500,
			quantityEarnedThisWeek = 300,
		})

		assert.is_true(result.success)
		assert.is_false(result.data.isCapped)
		assert.equals(300, result.data.amount)
	end)

	it("handles uncapped currencies (max = 0)", function()
		local result = Tracker.GetCurrencyStatus({
			quantity = 12345,
			maxQuantity = 0,
			maxWeeklyQuantity = 0,
			quantityEarnedThisWeek = 0,
		})

		assert.is_true(result.success)
		assert.is_false(result.data.isCapped)
		assert.equals(12345, result.data.amount)
		assert.equals(0, result.data.max)
	end)

	it("uses total max when no weekly max exists", function()
		local result = Tracker.GetCurrencyStatus({
			quantity = 400,
			maxQuantity = 500,
			maxWeeklyQuantity = 0,
			quantityEarnedThisWeek = 0,
		})

		assert.is_true(result.success)
		assert.equals(400, result.data.amount)
		assert.equals(500, result.data.max)
	end)

	it("returns error for invalid context", function()
		local result = Tracker.GetCurrencyStatus(nil)

		assert.is_false(result.success)
		assert.equals("INVALID_CONTEXT", result.error.code)
	end)

	it("formats displayText correctly for capped currency", function()
		local result = Tracker.GetCurrencyStatus({
			quantity = 500,
			maxQuantity = 1000,
			maxWeeklyQuantity = 500,
			quantityEarnedThisWeek = 500,
		})

		assert.equals("500 / 500", result.data.displayText)
	end)
end)

--------------------------------------------------------------------------------
-- GetQuestStatus Tests
--------------------------------------------------------------------------------

describe("Tracker.GetQuestStatus", function()
	it("detects completed quests", function()
		local result = Tracker.GetQuestStatus({
			ids = { 12345 },
			isCompleted = function(id)
				return true
			end,
			isOnQuest = function(id)
				return false
			end,
			getObjectives = function(id)
				return {}
			end,
		})

		assert.is_true(result.success)
		assert.is_true(result.data.isCompleted)
		assert.is_false(result.data.isOnQuest)
		assert.equals(12345, result.data.resolvedId)
	end)

	it("detects active quests with progress", function()
		local result = Tracker.GetQuestStatus({
			ids = { 12345 },
			isCompleted = function(id)
				return false
			end,
			isOnQuest = function(id)
				return true
			end,
			getObjectives = function(id)
				return { { numFulfilled = 3, numRequired = 5, finished = false } }
			end,
		})

		assert.is_true(result.success)
		assert.is_false(result.data.isCompleted)
		assert.is_true(result.data.isOnQuest)
		assert.equals(3, result.data.progress)
		assert.equals(5, result.data.max)
	end)

	it("resolves multi-ID quests to active variant", function()
		local result = Tracker.GetQuestStatus({
			ids = { 111, 222, 333 },
			isCompleted = function(id)
				return false
			end,
			isOnQuest = function(id)
				return id == 222
			end,
			getObjectives = function(id)
				return { { numFulfilled = 3, numRequired = 5 } }
			end,
		})

		assert.is_true(result.success)
		assert.equals(222, result.data.resolvedId)
		assert.equals(3, result.data.progress)
	end)

	it("returns nil resolvedId when no multi-ID variant is active", function()
		local result = Tracker.GetQuestStatus({
			ids = { 111, 222, 333 },
			isCompleted = function(id)
				return false
			end,
			isOnQuest = function(id)
				return false
			end,
			getObjectives = function(id)
				return {}
			end,
		})

		assert.is_true(result.success)
		assert.is_nil(result.data.resolvedId)
		assert.is_false(result.data.isOnQuest)
	end)

	it("detects percentage-based objectives from text", function()
		local result = Tracker.GetQuestStatus({
			ids = { 12345 },
			isCompleted = function(id)
				return false
			end,
			isOnQuest = function(id)
				return true
			end,
			getObjectives = function(id)
				return { { text = "Progress: (75%)", numFulfilled = 0, numRequired = 0 } }
			end,
		})

		assert.is_true(result.success)
		assert.is_true(result.data.isPercent)
		assert.equals(75, result.data.progress)
		assert.equals(100, result.data.max)
	end)

	it("handles multi-objective quests", function()
		local result = Tracker.GetQuestStatus({
			ids = { 12345 },
			isCompleted = function(id)
				return false
			end,
			isOnQuest = function(id)
				return true
			end,
			getObjectives = function(id)
				return {
					{ numFulfilled = 1, numRequired = 1, finished = true },
					{ numFulfilled = 0, numRequired = 1, finished = false },
					{ numFulfilled = 1, numRequired = 1, finished = true },
				}
			end,
		})

		assert.is_true(result.success)
		assert.equals(2, result.data.progress) -- 2 completed
		assert.equals(3, result.data.max) -- 3 total objectives
	end)
end)

--------------------------------------------------------------------------------
-- GetVaultStatus Tests
--------------------------------------------------------------------------------

describe("Tracker.GetVaultStatus", function()
	it("counts completed vault slots", function()
		local result = Tracker.GetVaultStatus({
			activities = {
				{ index = 1, threshold = 1, progress = 1, level = 450 },
				{ index = 2, threshold = 4, progress = 4, level = 460 },
				{ index = 3, threshold = 8, progress = 3, level = 0 },
			},
		})

		assert.is_true(result.success)
		assert.equals(2, result.data.completed)
		assert.equals(3, result.data.max)
	end)

	it("returns slot details", function()
		local result = Tracker.GetVaultStatus({
			activities = {
				{ index = 1, threshold = 1, progress = 1, level = 450 },
				{ index = 2, threshold = 4, progress = 2, level = 0 },
			},
		})

		assert.is_true(result.success)
		assert.equals(2, #result.data.slots)
		assert.is_true(result.data.slots[1].completed)
		assert.is_false(result.data.slots[2].completed)
	end)

	it("handles empty activities", function()
		local result = Tracker.GetVaultStatus({
			activities = {},
		})

		assert.is_true(result.success)
		assert.equals(0, result.data.completed)
		assert.equals(0, result.data.max)
	end)

	it("returns error for invalid context", function()
		local result = Tracker.GetVaultStatus(nil)

		assert.is_false(result.success)
		assert.equals("INVALID_CONTEXT", result.error.code)
	end)
end)

--------------------------------------------------------------------------------
-- GetVaultDetails Tests
--------------------------------------------------------------------------------

describe("Tracker.GetVaultDetails", function()
	it("includes M+ run history for dungeons", function()
		local result = Tracker.GetVaultDetails({
			categoryID = 1,
			activities = {
				{ index = 1, threshold = 1, progress = 1, level = 450 },
			},
			runHistory = {
				{ mapChallengeModeID = 123, mapName = "Test Dungeon", level = 15, completed = true },
				{ mapChallengeModeID = 456, mapName = "Another Dungeon", level = 12, completed = false },
			},
		})

		assert.is_true(result.success)
		assert.equals(2, #result.data.history)
		assert.equals("Test Dungeon", result.data.history[1].name)
		assert.equals(15, result.data.history[1].level)
	end)

	it("includes raid boss kills for raids", function()
		local result = Tracker.GetVaultDetails({
			categoryID = 3,
			activities = {
				{ index = 1, threshold = 2, progress = 2, level = 480 },
			},
			savedInstances = {
				{ bossName = "Boss One", diffName = "Heroic", isKilled = true },
				{ bossName = "Boss Two", diffName = "Heroic", isKilled = true },
			},
		})

		assert.is_true(result.success)
		assert.equals(2, #result.data.history)
		assert.equals("Boss One", result.data.history[1].name)
		assert.equals("Heroic", result.data.history[1].level)
	end)

	it("returns empty history for world category", function()
		local result = Tracker.GetVaultDetails({
			categoryID = 6,
			activities = {
				{ index = 1, threshold = 3, progress = 3, level = 450 },
			},
		})

		assert.is_true(result.success)
		assert.equals(0, #result.data.history)
	end)
end)

--------------------------------------------------------------------------------
-- SortTrackerItems Tests
--------------------------------------------------------------------------------

describe("Tracker.SortTrackerItems", function()
	it("sorts vault items in custom order (Raid -> Dungeon -> World)", function()
		local result = Tracker.SortTrackerItems({
			items = {
				{ type = "vault_visual", id = 6, label = "World" },
				{ type = "vault_visual", id = 1, label = "Dungeon" },
				{ type = "vault_visual", id = 3, label = "Raid" },
			},
			sortCompletedBottom = false,
		})

		assert.is_true(result.success)
		assert.equals("Raid", result.data.items[1].label)
		assert.equals("Dungeon", result.data.items[2].label)
		assert.equals("World", result.data.items[3].label)
	end)

	it("sorts completed items to bottom when enabled", function()
		local result = Tracker.SortTrackerItems({
			items = {
				{ type = "quest", id = 1, label = "Quest A" },
				{ type = "quest", id = 2, label = "Quest B" },
			},
			sortCompletedBottom = true,
			getQuestStatus = function(id)
				return { isCompleted = id == 1 }
			end,
			getCurrencyStatus = function(id)
				return { isCapped = false }
			end,
		})

		assert.is_true(result.success)
		assert.equals("Quest B", result.data.items[1].label) -- Active first
		assert.equals("Quest A", result.data.items[2].label) -- Completed last
	end)

	it("sorts alphabetically as fallback", function()
		local result = Tracker.SortTrackerItems({
			items = {
				{ type = "quest", id = 1, label = "Zebra Quest" },
				{ type = "quest", id = 2, label = "Apple Quest" },
				{ type = "quest", id = 3, label = "Middle Quest" },
			},
			sortCompletedBottom = false,
		})

		assert.is_true(result.success)
		assert.equals("Apple Quest", result.data.items[1].label)
		assert.equals("Middle Quest", result.data.items[2].label)
		assert.equals("Zebra Quest", result.data.items[3].label)
	end)
end)

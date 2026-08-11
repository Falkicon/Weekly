-- test_bridge_context.lua
-- Unit tests for the WoW API adapter behavior used by tracker actions

local addonName = "Weekly"
local ns = {}

local function LoadFile(path)
	local func, err = loadfile(path)
	if not func then
		error("Failed to load " .. path .. ": " .. err)
	end
	setfenv(func, getfenv(1))
	func(addonName, ns)
end

describe("Weekly Bridge Context", function()
	before_each(function()
		ns = {}
		_G.C_QuestLog = {
			IsAccountQuest = function(id)
				return id == 100
			end,
			IsQuestFlaggedCompletedOnAccount = function(id)
				return id == 100
			end,
			IsQuestFlaggedCompleted = function(id)
				return id == 200
			end,
		}
		_G.C_Item = {
			GetItemCount = function()
				return 0
			end,
			GetItemInfo = function()
				return nil
			end,
		}
		_G.GetServerTime = function()
			return 1000
		end
		_G.C_DateAndTime = {
			GetSecondsUntilWeeklyReset = function()
				return 5000
			end,
		}
		LoadFile("Bridge/Context.lua")
	end)

	it("uses account-wide completion only for account quests", function()
		assert.is_true(ns.Context:IsQuestCompleted(100))
		assert.is_true(ns.Context:IsQuestCompleted(200))
		assert.is_false(ns.Context:IsQuestCompleted(300))
	end)

	it("keeps character-specific completion available for trackers like Prey", function()
		assert.is_false(ns.Context:IsCharacterQuestCompleted(100))
		assert.is_true(ns.Context:IsCharacterQuestCompleted(200))
	end)

	it("includes bank, reagent bank, and account bank in item counts", function()
		local captured = {}
		_G.C_Item.GetItemCount = function(...)
			captured = { ... }
			return 42
		end

		local context = ns.Context:BuildItemContext(273000)

		assert.are.equal(42, context.count)
		assert.are.equal(273000, captured[1])
		assert.is_true(captured[2])
		assert.is_false(captured[3])
		assert.is_true(captured[4])
		assert.is_true(captured[5])
	end)

	it("builds journal reset context from Blizzard's live boundary", function()
		ns.Config = { journal = { nextReset = 5500 } }
		local context = ns.Context:BuildJournalResetContext()

		assert.are.equal(1000, context.currentServerTime)
		assert.are.equal(5500, context.savedNextReset)
		assert.are.equal(6000, context.observedNextReset)
	end)
end)

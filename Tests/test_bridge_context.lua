-- test_bridge_context.lua
-- Unit tests for the WoW API adapter behavior used by tracker actions

local addonName = "Weekly"
local ns = {}

local function LoadFile(path)
	local func, err = loadfile(path)
	if not func then
		error("Failed to load " .. path .. ": " .. err)
	end
	func(addonName, ns)
end

describe("Weekly Bridge Context", function()
	before_each(function()
		ns = {}
		C_QuestLog = {
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
		C_Item = {
			GetItemCount = function()
				return 0
			end,
			GetItemInfo = function()
				return nil
			end,
		}
		LoadFile("_dev_/Weekly/Bridge/Context.lua")
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
		C_Item.GetItemCount = function(...)
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
end)

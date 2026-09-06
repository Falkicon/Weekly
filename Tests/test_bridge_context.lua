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

	it("does not query tooltip history when fetching vault status", function()
		_G.C_WeeklyRewards = {
			GetActivities = function()
				return {}
			end,
		}
		_G.C_MythicPlus = {
			GetRunHistory = function()
				error("Unexpected run history query")
			end,
		}
		_G.GetNumSavedInstances = function()
			error("Unexpected lockout query")
		end
		local dungeon = ns.Context:BuildVaultContext(1)
		local raid = ns.Context:BuildVaultContext(3)
		assert.is_nil(dungeon.runHistory)
		assert.is_nil(raid.savedInstances)
	end)

	it("still loads history and lockouts when vault details are requested", function()
		_G.C_WeeklyRewards = {
			GetActivities = function()
				return {}
			end,
		}
		_G.C_MythicPlus = {
			GetRunHistory = function()
				return { { mapChallengeModeID = 123, level = 10 } }
			end,
		}
		_G.C_ChallengeMode = {
			GetMapUIInfo = function()
				return "Test Dungeon"
			end,
		}
		local lockoutQueries = 0
		ns.Context.GetRaidLockouts = function()
			lockoutQueries = lockoutQueries + 1
			return { { bossName = "Test Boss" } }
		end
		local dungeon = ns.Context:BuildVaultContext(1, true)
		local raid = ns.Context:BuildVaultContext(3, true)
		assert.are.equal("Test Dungeon", dungeon.runHistory[1].mapName)
		assert.are.equal("Test Boss", raid.savedInstances[1].bossName)
		assert.are.equal(1, lockoutQueries)
	end)

	it("requests vault history only for the details bridge action", function()
		local requests = {}
		ns.Context.BuildVaultContext = function(_, categoryID, includeDetails)
			requests[#requests + 1] = { categoryID, includeDetails == true }
			return {}
		end
		ns.Actions = {
			Tracker = {
				GetVaultStatus = function()
					return { success = true, data = {} }
				end,
				GetVaultDetails = function()
					return { success = true, data = {} }
				end,
			},
		}
		LoadFile("Bridge/Executor.lua")
		ns.Bridge:GetVaultStatus(1)
		ns.Bridge:GetVaultDetails(3)
		assert.are.same({ { 1, false }, { 3, true } }, requests)
	end)
end)

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

describe("Weekly Prey Tracker", function()
	before_each(function()
		ns = {
			CharConfig = { prey = {} },
			Context = {
				IsCharacterQuestCompleted = function()
					return false
				end,
			},
		}
		_G.C_QuestLog = {
			IsOnQuest = function()
				return false
			end,
			GetLogIndexForQuestID = function()
				return nil
			end,
			GetQuestObjectives = function()
				return nil
			end,
			GetActivePreyQuest = function()
				return nil
			end,
		}
		LoadFile("PreyTracker.lua")
	end)

	it("starts with an explicitly partial weekly count", function()
		local state = ns.PreyTracker:GetState()
		assert.are.equal(0, state.count)
		assert.is_true(state.partial)
	end)

	it("clears uncertainty after witnessing a weekly reset", function()
		local state = ns.PreyTracker:GetState()
		state.count = 4
		state.nextReset = 1000
		assert.is_true(ns.PreyTracker:CheckReset(state, 1001, 700000))
		assert.are.equal(0, state.count)
		assert.is_false(state.partial)
	end)

	it("does not reset again within the same reset window", function()
		local state = ns.PreyTracker:GetState()
		state.count = 4
		state.partial = false
		state.nextReset = 700000
		assert.is_false(ns.PreyTracker:CheckReset(state, 2000, 700000))
		assert.are.equal(4, state.count)
	end)

	it("records a target turn-in once and suppresses duplicate events", function()
		local state = ns.PreyTracker:GetState()
		assert.is_true(ns.PreyTracker:RecordCompletion(state, 91210, 100, 15))
		assert.is_false(ns.PreyTracker:RecordCompletion(state, 91210, 105, 15))
		assert.are.equal(1, state.count)
	end)

	it("accepts repeat completions of the same target after the event window", function()
		local state = ns.PreyTracker:GetState()
		assert.is_true(ns.PreyTracker:RecordCompletion(state, 91210, 100, 15))
		assert.is_true(ns.PreyTracker:RecordCompletion(state, 91210, 111, 15))
		assert.are.equal(2, state.count)
	end)

	it("uses the cache quest as a lower bound without treating it as the weekly cap", function()
		_G.C_QuestLog.IsOnQuest = function(id)
			return id == 93910
		end
		_G.C_QuestLog.GetLogIndexForQuestID = function()
			return 1
		end
		_G.C_QuestLog.GetQuestObjectives = function()
			return { { numFulfilled = 2, numRequired = 3 } }
		end

		local state = ns.PreyTracker:GetState()
		ns.PreyTracker:ReconcileCacheProgress(state, 93910, 3)
		assert.are.equal(2, state.count)
		assert.is_true(state.partial)
	end)

	it("recognizes verified target quest IDs and rejects helper quests", function()
		assert.is_true(ns.PreyTracker:IsKnownHuntQuest(91095))
		assert.is_true(ns.PreyTracker:IsKnownHuntQuest(91269))
		assert.is_true(ns.PreyTracker:IsKnownHuntQuest(95023))
		assert.is_false(ns.PreyTracker:IsKnownHuntQuest(93910))
		assert.is_false(ns.PreyTracker:IsKnownHuntQuest(96503))
	end)

	it("counts the live active hunt but not the cache quest turn-in", function()
		local state = ns.PreyTracker:GetState()
		state.activeQuestID = 95100
		ns.PreyTracker:OnQuestTurnedIn(95100)
		assert.are.equal(1, state.count)

		ns.PreyTracker:OnQuestTurnedIn(93910)
		assert.are.equal(1, state.count)
	end)

	it("clears the active indicator while retaining the last hunt for turn-in matching", function()
		local state = ns.PreyTracker:GetState()
		state.activeQuestID = 95100
		state.lastActiveQuestID = 95100
		ns.PreyTracker:RefreshActiveQuest()
		assert.are.equal(0, state.activeQuestID)
		assert.are.equal(95100, state.lastActiveQuestID)
	end)

	it("does not truncate persisted progress when viewing a lower historical cap", function()
		local state = ns.PreyTracker:GetState()
		state.count = 10
		local complete, displayCount, max = ns.PreyTracker:GetStatus(4, 93910, 3)
		assert.is_true(complete)
		assert.are.equal(4, displayCount)
		assert.are.equal(4, max)
		assert.are.equal(10, state.count)
	end)
end)

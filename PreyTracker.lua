local _, ns = ...

local PreyTracker = {}
ns.PreyTracker = PreyTracker

local CACHE_QUEST_ID = 93910
local DEFAULT_CACHE_MAX = 3
local DEFAULT_WEEKLY_MAX = 15
local DUPLICATE_EVENT_WINDOW = 10

local function Clamp(value, minimum, maximum)
	return math.max(minimum, math.min(value, maximum))
end

local function GetNow()
	if GetServerTime then
		return GetServerTime()
	end
	if time then
		return time()
	end
	return os.time()
end

-- These are the target quests, not the helper/objective quests used during a
-- hunt. The live active-Prey API remains the primary match for new targets.
function PreyTracker:IsKnownHuntQuest(questID)
	return (questID >= 91095 and questID <= 91124)
		or (questID >= 91210 and questID <= 91269)
		or questID == 95022
		or questID == 95023
end

function PreyTracker:GetState()
	if not ns.CharConfig then
		return nil
	end

	ns.CharConfig.prey = ns.CharConfig.prey or {}
	local state = ns.CharConfig.prey
	state.count = tonumber(state.count) or 0
	if state.partial == nil then
		state.partial = true
	end
	state.nextReset = tonumber(state.nextReset) or 0
	state.activeQuestID = tonumber(state.activeQuestID) or 0
	state.lastActiveQuestID = tonumber(state.lastActiveQuestID) or 0
	state.lastTurnInQuestID = tonumber(state.lastTurnInQuestID) or 0
	state.lastTurnInAt = tonumber(state.lastTurnInAt) or 0
	return state
end

function PreyTracker:GetNextReset(now)
	if ns.WeeklyReset then
		return ns.WeeklyReset:GetObservedNextReset(now)
	end
	if not C_DateAndTime or not C_DateAndTime.GetSecondsUntilWeeklyReset then
		return nil
	end

	local ok, seconds = pcall(C_DateAndTime.GetSecondsUntilWeeklyReset)
	if not ok or type(seconds) ~= "number" or seconds <= 0 then
		return nil
	end
	return now + seconds
end

-- Public and deterministic so the reset behavior can be covered by unit tests.
function PreyTracker:CheckReset(state, now, observedNextReset)
	if not state then
		return false
	end

	local firstObservation = state.nextReset <= 0
	local resetOccurred
	if ns.WeeklyReset then
		resetOccurred = ns.WeeklyReset:Check(state, now, observedNextReset)
	else
		-- Test/dev fallback when this module is loaded in isolation.
		if firstObservation then
			state.nextReset = observedNextReset or 0
			resetOccurred = false
		else
			local resetPassed = now >= state.nextReset
			local apiRolledForward = observedNextReset and observedNextReset > state.nextReset + (6 * 60 * 60)
			resetOccurred = resetPassed or apiRolledForward
			if resetOccurred then
				state.nextReset = observedNextReset or 0
			end
		end
	end

	if firstObservation then
		state.partial = true
		return false
	end
	if not resetOccurred then
		return false
	end

	state.count = 0
	state.partial = false
	state.activeQuestID = 0
	state.lastActiveQuestID = 0
	state.lastTurnInQuestID = 0
	state.lastTurnInAt = 0
	return true
end

function PreyTracker:RefreshReset()
	local state = self:GetState()
	if not state then
		return false
	end
	local now = GetNow()
	return self:CheckReset(state, now, self:GetNextReset(now))
end

function PreyTracker:RefreshActiveQuest()
	local state = self:GetState()
	if not state or not C_QuestLog or not C_QuestLog.GetActivePreyQuest then
		return 0
	end

	local ok, questID = pcall(C_QuestLog.GetActivePreyQuest)
	if ok and type(questID) == "number" and questID > 0 then
		state.activeQuestID = questID
		state.lastActiveQuestID = questID
		return questID
	end
	state.activeQuestID = 0
	return 0
end

function PreyTracker:GetCacheStatus(questID, cacheMax)
	questID = questID or CACHE_QUEST_ID
	cacheMax = cacheMax or DEFAULT_CACHE_MAX
	if not C_QuestLog then
		return false, 0, cacheMax, false
	end

	local completed = ns.Context and ns.Context:IsCharacterQuestCompleted(questID) or false
	if completed then
		return true, cacheMax, cacheMax, false
	end

	local active = C_QuestLog.IsOnQuest
		and C_QuestLog.IsOnQuest(questID)
		and (not C_QuestLog.GetLogIndexForQuestID or C_QuestLog.GetLogIndexForQuestID(questID) ~= nil)
	if not active or not C_QuestLog.GetQuestObjectives then
		return false, 0, cacheMax, false
	end

	local objectives = C_QuestLog.GetQuestObjectives(questID)
	local bestProgress, bestMax = 0, cacheMax
	for _, objective in ipairs(objectives or {}) do
		local required = tonumber(objective.numRequired) or 0
		if required > 0 and (required > bestMax or required == cacheMax) then
			bestProgress = tonumber(objective.numFulfilled) or 0
			bestMax = required
		end
	end

	bestMax = bestMax > 0 and bestMax or cacheMax
	return bestProgress >= bestMax, Clamp(bestProgress, 0, bestMax), bestMax, true
end

function PreyTracker:ReconcileCacheProgress(state, questID, cacheMax)
	local completed, progress = self:GetCacheStatus(questID, cacheMax)
	if completed then
		progress = cacheMax or DEFAULT_CACHE_MAX
	end
	if progress > state.count then
		state.count = progress
	end
end

function PreyTracker:RecordCompletion(state, questID, now, weeklyMax)
	if not state or type(questID) ~= "number" then
		return false
	end
	now = now or GetNow()
	weeklyMax = weeklyMax or DEFAULT_WEEKLY_MAX

	if state.lastTurnInQuestID == questID and now - state.lastTurnInAt <= DUPLICATE_EVENT_WINDOW then
		return false
	end

	state.count = Clamp((state.count or 0) + 1, 0, weeklyMax)
	state.lastTurnInQuestID = questID
	state.lastTurnInAt = now
	state.activeQuestID = 0
	state.lastActiveQuestID = 0
	return true
end

function PreyTracker:OnQuestTurnedIn(questID)
	local state = self:GetState()
	if not state then
		return
	end

	self:RefreshReset()
	local isTrackedHunt = questID == state.activeQuestID
		or questID == state.lastActiveQuestID
		or self:IsKnownHuntQuest(questID)
	if not isTrackedHunt or not self:RecordCompletion(state, questID) then
		return
	end

	if ns.UI and ns.UI.QueueRefresh then
		ns.UI:QueueRefresh()
	elseif ns.UI and ns.UI.RenderRows then
		ns.UI:RenderRows()
	end
end

function PreyTracker:GetStatus(weeklyMax, cacheQuestID, cacheMax)
	weeklyMax = weeklyMax or DEFAULT_WEEKLY_MAX
	local state = self:GetState()
	if not state then
		return false, 0, weeklyMax, false, 0
	end

	self:RefreshReset()
	self:RefreshActiveQuest()
	self:ReconcileCacheProgress(state, cacheQuestID or CACHE_QUEST_ID, cacheMax or DEFAULT_CACHE_MAX)
	local displayCount = Clamp(state.count, 0, weeklyMax)
	local activeCount = state.activeQuestID > 0 and 1 or 0
	return displayCount >= weeklyMax, displayCount, weeklyMax, state.partial, activeCount
end

function PreyTracker:Initialize()
	if self.initialized then
		return
	end
	self.initialized = true
	self:RefreshReset()
	self:RefreshActiveQuest()

	if not CreateFrame then
		return
	end
	self.eventFrame = self.eventFrame or CreateFrame("Frame")
	self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.eventFrame:RegisterEvent("QUEST_ACCEPTED")
	self.eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
	self.eventFrame:RegisterEvent("QUEST_TURNED_IN")
	self.eventFrame:SetScript("OnEvent", function(_, event, arg1)
		if event == "QUEST_TURNED_IN" then
			self:OnQuestTurnedIn(arg1)
		else
			self:RefreshReset()
			self:RefreshActiveQuest()
		end
	end)
end

function PreyTracker:Shutdown()
	if self.eventFrame then
		self.eventFrame:UnregisterAllEvents()
		self.eventFrame:SetScript("OnEvent", nil)
	end
	self.initialized = false
end

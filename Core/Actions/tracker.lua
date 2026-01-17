--------------------------------------------------------------------------------
-- Weekly Addon - Tracker Actions (Pure Lua)
-- Business logic for currency, quest, and vault tracking
-- All functions take context parameters and return ActionResult
--------------------------------------------------------------------------------

local _, ns = ...

-- FenCore ActionResult (with graceful fallback)
local Result = ns.FenCore and ns.FenCore.ActionResult

---@class TrackerActions
local Tracker = {}
ns.Actions.Tracker = Tracker

--------------------------------------------------------------------------------
-- GetCurrencyStatus
-- Returns the display status of a currency (amount, max, capped state)
--------------------------------------------------------------------------------

---@param context CurrencyContext
---@return ActionResult<CurrencyStatusResult>
function Tracker.GetCurrencyStatus(context)
	if not context or not context.quantity then
		return Result.error("INVALID_CONTEXT", "Currency context is missing or invalid")
	end

	local quantity = context.quantity or 0
	local maxQuantity = context.maxQuantity or 0
	local maxWeeklyQuantity = context.maxWeeklyQuantity or 0
	local earnedThisWeek = context.quantityEarnedThisWeek or 0

	-- Determine display values
	-- Prefer weekly max if available, otherwise total max
	local displayAmount = quantity
	local displayMax = maxQuantity

	if maxWeeklyQuantity > 0 then
		-- For weekly capped currencies, show earned vs weekly max
		displayAmount = earnedThisWeek
		displayMax = maxWeeklyQuantity
	end

	local isCapped = displayMax > 0 and displayAmount >= displayMax

	-- Format display text
	local displayText
	if displayMax > 0 then
		displayText = displayAmount .. " / " .. displayMax
	else
		displayText = tostring(displayAmount)
	end

	local reasoning = isCapped and string.format("Currency capped at %d/%d", displayAmount, displayMax)
		or string.format("Currency at %d/%d", displayAmount, displayMax)

	return Result.success({
		amount = displayAmount,
		max = displayMax,
		isCapped = isCapped,
		displayText = displayText,
		name = context.name,
		iconFileID = context.iconFileID,
	}, reasoning)
end

--------------------------------------------------------------------------------
-- GetQuestStatus
-- Returns the completion and progress status of a quest
-- Handles both single-ID and multi-ID (rotating) quests
--------------------------------------------------------------------------------

---@param context QuestContext
---@return ActionResult<QuestStatusResult>
function Tracker.GetQuestStatus(context)
	if not context or not context.ids then
		return Result.error("INVALID_CONTEXT", "Quest context is missing or invalid")
	end

	local ids = context.ids
	local isOnQuest = context.isOnQuest
	local isCompleted = context.isCompleted
	local getObjectives = context.getObjectives

	-- Find the active or completed quest ID from the list
	local resolvedId = nil
	for _, qid in ipairs(ids) do
		if qid ~= 0 and (isOnQuest(qid) or isCompleted(qid)) then
			resolvedId = qid
			break
		end
	end

	-- No active quest found for multi-ID quests
	if not resolvedId then
		return Result.success({
			isCompleted = false,
			isOnQuest = false,
			progress = 0,
			max = 0,
			isPercent = false,
			resolvedId = nil,
		}, "No active variant found for rotating quest")
	end

	local questCompleted = isCompleted(resolvedId)
	local questActive = isOnQuest(resolvedId)
	local progress = 0
	local max = 0
	local isPercent = false

	if questActive then
		local objectives = getObjectives(resolvedId)
		if objectives and #objectives > 0 then
			if #objectives > 1 then
				-- Multi-objective: count completed objectives vs total
				local completedCount = 0
				for _, obj in ipairs(objectives) do
					if obj.finished then
						completedCount = completedCount + 1
					end
				end
				progress = completedCount
				max = #objectives
			else
				-- Single objective
				local obj = objectives[1]
				progress = obj.numFulfilled or 0
				max = obj.numRequired or 0

				-- Check for percentage-based objectives
				if obj.text then
					local pct = obj.text:match("%((%d+)%%%)") -- Match "(X%)"
					if not pct then
						pct = obj.text:match("(%d+)%%") -- Match "X%" anywhere
					end
					if pct then
						progress = tonumber(pct) or 0
						max = 100
						isPercent = true
					end
				end

				-- Fallback: 0-100 range likely means percentage
				if not isPercent and max == 100 and progress <= 100 then
					isPercent = true
				end
			end
		end
	elseif questCompleted then
		progress = 1
		max = 1
	end

	local reasoning
	if questCompleted then
		reasoning = "Quest completed"
	elseif questActive then
		if isPercent then
			reasoning = string.format("Quest in progress: %d%%", progress)
		elseif max > 0 then
			reasoning = string.format("Quest in progress: %d/%d", progress, max)
		else
			reasoning = "Quest active, no objectives"
		end
	else
		reasoning = "Quest not active"
	end

	return Result.success({
		isCompleted = questCompleted,
		isOnQuest = questActive,
		progress = progress,
		max = max,
		isPercent = isPercent,
		resolvedId = resolvedId,
	}, reasoning)
end

--------------------------------------------------------------------------------
-- GetVaultStatus
-- Returns the vault slot completion status (slots unlocked / total)
--------------------------------------------------------------------------------

---@param context VaultContext
---@return ActionResult<VaultStatusResult>
function Tracker.GetVaultStatus(context)
	if not context or not context.activities then
		return Result.error("INVALID_CONTEXT", "Vault context is missing or invalid")
	end

	local activities = context.activities
	local completed = 0
	local max = #activities
	local slots = {}

	for _, activity in ipairs(activities) do
		local slotCompleted = activity.progress >= activity.threshold
		if slotCompleted then
			completed = completed + 1
		end
		table.insert(slots, {
			threshold = activity.threshold,
			progress = activity.progress,
			level = activity.level or 0,
			completed = slotCompleted,
		})
	end

	-- Sort slots by index
	table.sort(slots, function(a, b)
		return (a.index or 0) < (b.index or 0)
	end)

	return Result.success({
		completed = completed,
		max = max,
		slots = slots,
	}, string.format("Vault: %d/%d slots unlocked", completed, max))
end

--------------------------------------------------------------------------------
-- GetVaultDetails
-- Returns detailed vault information including M+ runs or raid kills
--------------------------------------------------------------------------------

---@param context VaultContext
---@return ActionResult<VaultDetailsResult>
function Tracker.GetVaultDetails(context)
	-- Get base vault status first
	local statusResult = Tracker.GetVaultStatus(context)
	if not statusResult.success then
		return statusResult
	end

	local history = {}
	local categoryID = context.categoryID

	-- Dungeons (M+ runs)
	if categoryID == 1 and context.runHistory then
		local runs = context.runHistory
		-- Sort by key level descending
		table.sort(runs, function(a, b)
			return (a.level or 0) > (b.level or 0)
		end)

		for _, run in ipairs(runs) do
			table.insert(history, {
				name = run.mapName or ("Dungeon " .. (run.mapChallengeModeID or "?")),
				level = run.level or 0,
				completed = run.completed ~= false, -- Default to true if not specified
			})
		end
	end

	-- Raids (boss kills)
	if categoryID == 3 and context.savedInstances then
		for _, lockout in ipairs(context.savedInstances) do
			if lockout.isKilled then
				table.insert(history, {
					name = lockout.bossName,
					level = lockout.diffName or "Unknown",
					completed = true,
				})
			end
		end
	end

	return Result.success({
		completed = statusResult.data.completed,
		max = statusResult.data.max,
		slots = statusResult.data.slots,
		history = history,
	}, statusResult.reasoning)
end

--------------------------------------------------------------------------------
-- SortTrackerItems
-- Sorts tracker items based on configuration (completion status, alphabetical)
--------------------------------------------------------------------------------

---@param context SortContext
---@return ActionResult<{items: TrackerItem[]}>
function Tracker.SortTrackerItems(context)
	if not context or not context.items then
		return Result.error("INVALID_CONTEXT", "Sort context is missing or invalid")
	end

	local items = {}
	for i, item in ipairs(context.items) do
		items[i] = item
	end

	local sortCompletedBottom = context.sortCompletedBottom
	local getQuestStatus = context.getQuestStatus
	local getCurrencyStatus = context.getCurrencyStatus

	table.sort(items, function(a, b)
		-- Vault items have custom sort order
		if a.type == "vault_visual" and b.type == "vault_visual" then
			local order = { [3] = 1, [1] = 2, [6] = 3 } -- Raid -> Dungeon -> World
			local orderA = order[a.id] or 99
			local orderB = order[b.id] or 99
			return orderA < orderB
		end

		-- Completion sorting (if enabled)
		if sortCompletedBottom then
			local aDone = false
			local bDone = false

			if a.type == "quest" and getQuestStatus then
				local result = getQuestStatus(a.id)
				aDone = result and result.isCompleted
			elseif (a.type == "currency_cap" or a.type == "currency") and getCurrencyStatus then
				local result = getCurrencyStatus(a.id)
				aDone = result and result.isCapped
			end

			if b.type == "quest" and getQuestStatus then
				local result = getQuestStatus(b.id)
				bDone = result and result.isCompleted
			elseif (b.type == "currency_cap" or b.type == "currency") and getCurrencyStatus then
				local result = getCurrencyStatus(b.id)
				bDone = result and result.isCapped
			end

			if aDone ~= bDone then
				return not aDone -- Active (not done) comes first
			end
		end

		-- Alphabetical fallback
		return (a.label or "") < (b.label or "")
	end)

	return Result.success({
		items = items,
	}, string.format("Sorted %d items", #items))
end

return Tracker

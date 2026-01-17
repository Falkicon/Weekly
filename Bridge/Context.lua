--------------------------------------------------------------------------------
-- Weekly Addon - Bridge Context (WoW API Adapter)
-- Builds context tables from WoW APIs for Core actions
--------------------------------------------------------------------------------

local _, ns = ...

---@class WeeklyContext
local Context = {}
ns.Context = Context

--------------------------------------------------------------------------------
-- Currency Context Builder
--------------------------------------------------------------------------------

---@param currencyId number
---@return CurrencyContext
function Context:BuildCurrencyContext(currencyId)
	local info = C_CurrencyInfo.GetCurrencyInfo(currencyId)

	return {
		id = currencyId,
		quantity = info and info.quantity or 0,
		maxQuantity = info and info.maxQuantity or 0,
		maxWeeklyQuantity = info and info.maxWeeklyQuantity or 0,
		quantityEarnedThisWeek = info and info.quantityEarnedThisWeek or 0,
		name = info and info.name,
		iconFileID = info and info.iconFileID,
	}
end

--------------------------------------------------------------------------------
-- Quest Context Builder
--------------------------------------------------------------------------------

---@param questId number|number[] Single ID or table of IDs for rotating quests
---@return QuestContext
function Context:BuildQuestContext(questId)
	-- Normalize to table of IDs
	local ids = type(questId) == "table" and questId or { questId }

	return {
		ids = ids,
		isOnQuest = function(id)
			return C_QuestLog.IsOnQuest(id)
		end,
		isCompleted = function(id)
			return C_QuestLog.IsQuestFlaggedCompleted(id)
		end,
		getObjectives = function(id)
			return C_QuestLog.GetQuestObjectives(id)
		end,
	}
end

--------------------------------------------------------------------------------
-- Item Context Builder (for pseudo-currency items like Lumber)
--------------------------------------------------------------------------------

---@param itemId number
---@return ItemContext
function Context:BuildItemContext(itemId)
	-- Get item count from bags, bank, reagent bank, and warband bank
	local count = C_Item.GetItemCount(itemId, true, true) or 0

	-- Get item info for name/icon
	local itemName, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(itemId)

	return {
		itemId = itemId,
		count = count,
		name = itemName or ("Item " .. itemId),
		iconFileID = itemIcon,
	}
end

--------------------------------------------------------------------------------
-- Vault Context Builder
--------------------------------------------------------------------------------

---@param categoryID number Vault category (1=Dungeon, 3=Raid, 6=World)
---@return VaultContext
function Context:BuildVaultContext(categoryID)
	local activities = C_WeeklyRewards.GetActivities(categoryID) or {}

	-- Sort by index for consistent ordering
	table.sort(activities, function(a, b)
		return (a.index or 0) < (b.index or 0)
	end)

	local context = {
		categoryID = categoryID,
		activities = activities,
		runHistory = nil,
		savedInstances = nil,
	}

	-- Get M+ run history for dungeons
	if categoryID == 1 then
		local runs = C_MythicPlus.GetRunHistory(false, false)
		if runs then
			-- Add map names
			for _, run in ipairs(runs) do
				run.mapName = C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID)
			end
			context.runHistory = runs
		end
	end

	-- Get raid lockouts for raids
	if categoryID == 3 then
		context.savedInstances = self:GetRaidLockouts()
	end

	return context
end

---@return RaidLockout[]
function Context:GetRaidLockouts()
	local lockouts = {}
	local numSaved = GetNumSavedInstances()

	for i = 1, numSaved do
		local _name, _id, _reset, _diff, locked, _extended, _instanceIDMostSig, isRaid, _maxPlayers, diffName, numEncounters, _encounterProgress =
			GetSavedInstanceInfo(i)

		if isRaid and locked then
			for j = 1, numEncounters do
				local bossName, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
				if isKilled then
					table.insert(lockouts, {
						bossName = bossName,
						diffName = diffName,
						isKilled = true,
					})
				end
			end
		end
	end

	return lockouts
end

--------------------------------------------------------------------------------
-- Sort Context Builder
--------------------------------------------------------------------------------

---@param items TrackerItem[]
---@return SortContext
function Context:BuildSortContext(items)
	local Actions = ns.Actions.Tracker

	return {
		items = items,
		sortCompletedBottom = ns.Config and ns.Config.sortCompletedBottom or false,
		getQuestStatus = function(id)
			local questContext = self:BuildQuestContext(id)
			local result = Actions.GetQuestStatus(questContext)
			return result.success and result.data or nil
		end,
		getCurrencyStatus = function(id)
			local currencyContext = self:BuildCurrencyContext(id)
			local result = Actions.GetCurrencyStatus(currencyContext)
			return result.success and result.data or nil
		end,
	}
end

--------------------------------------------------------------------------------
-- Journal Reset Context Builder
--------------------------------------------------------------------------------

---@return JournalResetContext
function Context:BuildJournalResetContext()
	local serverTime = C_DateAndTime.GetServerTimeLocal()
	local date = C_DateAndTime.GetCurrentCalendarTime()

	return {
		currentServerTime = serverTime,
		savedWeekStart = ns.Config and ns.Config.journal and ns.Config.journal.weekStart or 0,
		resetDayOfWeek = 3, -- Tuesday
		resetHour = 7, -- 7 AM (varies by region, but close enough)
		currentDate = {
			weekday = date.weekday,
			hour = date.hour,
			minute = date.minute,
		},
	}
end

--------------------------------------------------------------------------------
-- Loot Classify Context Builder
--------------------------------------------------------------------------------

---@param itemID number
---@return LootClassifyContext|nil
function Context:BuildLootClassifyContext(itemID)
	local _itemName, _itemLink, _itemQuality, _itemLevel, _itemMinLevel, _itemType, _itemSubType, _itemStackCount, _itemEquipLoc, _itemTexture, _sellPrice, classID, subclassID, _bindType, expansionID =
		C_Item.GetItemInfo(itemID)

	if not classID then
		return nil -- Item info not cached yet
	end

	return {
		itemID = itemID,
		itemClassID = classID,
		itemSubClassID = subclassID,
		expansionID = expansionID,
	}
end

return Context

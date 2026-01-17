--------------------------------------------------------------------------------
-- Weekly Addon - Bridge Executor
-- Routes commands to Core actions and handles results
--------------------------------------------------------------------------------

local _, ns = ...

---@class WeeklyBridge
local Bridge = {}
ns.Bridge = Bridge

--------------------------------------------------------------------------------
-- Action Registry
--------------------------------------------------------------------------------

local actionRegistry = {
	["tracker.getCurrencyStatus"] = function(params)
		local context = ns.Context:BuildCurrencyContext(params.id)
		return ns.Actions.Tracker.GetCurrencyStatus(context)
	end,

	["tracker.getQuestStatus"] = function(params)
		local context = ns.Context:BuildQuestContext(params.id)
		return ns.Actions.Tracker.GetQuestStatus(context)
	end,

	["tracker.getVaultStatus"] = function(params)
		local context = ns.Context:BuildVaultContext(params.categoryID)
		return ns.Actions.Tracker.GetVaultStatus(context)
	end,

	["tracker.getVaultDetails"] = function(params)
		local context = ns.Context:BuildVaultContext(params.categoryID)
		return ns.Actions.Tracker.GetVaultDetails(context)
	end,

	["tracker.sortItems"] = function(params)
		local context = ns.Context:BuildSortContext(params.items)
		return ns.Actions.Tracker.SortTrackerItems(context)
	end,

	["journal.shouldReset"] = function(_params)
		local context = ns.Context:BuildJournalResetContext()
		return ns.Actions.Journal.ShouldResetJournal(context)
	end,

	["journal.classifyLoot"] = function(params)
		local context = ns.Context:BuildLootClassifyContext(params.itemID)
		if not context then
			return {
				success = false,
				error = {
					code = "ITEM_NOT_CACHED",
					message = "Item info not yet available",
					retryable = true,
				},
			}
		end
		return ns.Actions.Journal.ClassifyLootItem(context)
	end,

	["journal.parseLoot"] = function(params)
		return ns.Actions.Journal.ParseLootMessage({ message = params.message })
	end,
}

--------------------------------------------------------------------------------
-- Execute Action
--------------------------------------------------------------------------------

---@param actionName string Name of the action to execute
---@param params table Action parameters
---@return ActionResult
function Bridge:Execute(actionName, params)
	local handler = actionRegistry[actionName]

	if not handler then
		return {
			success = false,
			error = {
				code = "UNKNOWN_ACTION",
				message = string.format("Action '%s' not found", actionName),
				retryable = false,
			},
		}
	end

	-- Execute the action
	local ok, result = pcall(handler, params or {})

	if not ok then
		return {
			success = false,
			error = {
				code = "EXECUTION_ERROR",
				message = tostring(result),
				retryable = false,
			},
		}
	end

	return result
end

--------------------------------------------------------------------------------
-- Convenience Methods (Typed wrappers for common actions)
--------------------------------------------------------------------------------

---@param currencyId number
---@return CurrencyStatusResult|nil, string|nil
function Bridge:GetCurrencyStatus(currencyId)
	local result = self:Execute("tracker.getCurrencyStatus", { id = currencyId })
	if result.success then
		return result.data, nil
	else
		return nil, result.error and result.error.message or "Unknown error"
	end
end

---@param questId number|number[]
---@return QuestStatusResult|nil, string|nil
function Bridge:GetQuestStatus(questId)
	local result = self:Execute("tracker.getQuestStatus", { id = questId })
	if result.success then
		return result.data, nil
	else
		return nil, result.error and result.error.message or "Unknown error"
	end
end

---@param categoryID number
---@return VaultStatusResult|nil, string|nil
function Bridge:GetVaultStatus(categoryID)
	local result = self:Execute("tracker.getVaultStatus", { categoryID = categoryID })
	if result.success then
		return result.data, nil
	else
		return nil, result.error and result.error.message or "Unknown error"
	end
end

---@param categoryID number
---@return VaultDetailsResult|nil, string|nil
function Bridge:GetVaultDetails(categoryID)
	local result = self:Execute("tracker.getVaultDetails", { categoryID = categoryID })
	if result.success then
		return result.data, nil
	else
		return nil, result.error and result.error.message or "Unknown error"
	end
end

---@param items TrackerItem[]
---@return TrackerItem[]|nil, string|nil
function Bridge:SortItems(items)
	local result = self:Execute("tracker.sortItems", { items = items })
	if result.success then
		return result.data.items, nil
	else
		return nil, result.error and result.error.message or "Unknown error"
	end
end

return Bridge

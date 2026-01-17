--------------------------------------------------------------------------------
-- Weekly Addon - Journal Actions (Pure Lua)
-- Business logic for weekly journal tracking
-- All functions take context parameters and return ActionResult
--------------------------------------------------------------------------------

local _, ns = ...

-- FenCore ActionResult (with graceful fallback)
local Result = ns.FenCore and ns.FenCore.ActionResult

---@class JournalActions
local Journal = {}
ns.Actions.Journal = Journal

-- Trade Goods class ID
local ITEM_CLASS_TRADEGOODS = 7

-- Trade Goods subclasses we want to track (gathering materials)
local TRACKED_SUBCLASSES = {
	[5] = "Cloth",
	[6] = "Leather",
	[7] = "Metal & Stone", -- Ore
	[8] = "Cooking", -- Meat, Fish
	[9] = "Herb",
	[10] = "Elemental",
	[11] = "Other", -- Some reagents
	[12] = "Enchanting",
	[16] = "Inscription", -- Pigments
	[18] = "Optional Reagents",
}

--------------------------------------------------------------------------------
-- ShouldResetJournal
-- Determines if the journal should be reset for a new week
-- Weekly reset is Tuesday at server reset time
--------------------------------------------------------------------------------

---@param context JournalResetContext
---@return ActionResult<JournalResetResult>
function Journal.ShouldResetJournal(context)
	if not context then
		return Result.error("INVALID_CONTEXT", "Journal reset context is missing")
	end

	local currentServerTime = context.currentServerTime or 0
	local savedWeekStart = context.savedWeekStart or 0
	local resetDayOfWeek = context.resetDayOfWeek or 3 -- Tuesday
	local resetHour = context.resetHour or 7 -- 7 AM (varies by region)

	-- Calculate the timestamp for the start of the current reset week
	-- This is a pure calculation based on the provided server time and date info
	local date = context.currentDate
	if not date then
		return Result.error("MISSING_DATE", "Current date info is required")
	end

	-- Get current day of week (1=Sunday, 2=Monday, 3=Tuesday, etc.)
	local weekday = date.weekday or 1

	-- Calculate days since last Tuesday
	local daysSinceReset
	if weekday >= resetDayOfWeek then
		daysSinceReset = weekday - resetDayOfWeek
	else
		daysSinceReset = weekday + (7 - resetDayOfWeek) -- Wrap around
	end

	-- Account for reset time (if we're before reset hour on reset day, go back a week)
	local currentHour = date.hour or 0
	if weekday == resetDayOfWeek and currentHour < resetHour then
		daysSinceReset = 7
	end

	-- Calculate midnight of today
	local secondsIntoDay = ((date.hour or 0) * 3600) + ((date.minute or 0) * 60)
	local midnightToday = currentServerTime - secondsIntoDay

	-- Go back to reset day midnight (plus reset hour offset)
	local currentWeekStart = midnightToday - (daysSinceReset * 86400) + (resetHour * 3600)

	-- Compare with saved week start
	local shouldReset = currentWeekStart > savedWeekStart

	local reasoning = shouldReset and "Weekly reset occurred, journal should be cleared" or "Within same reset week"

	return Result.success({
		shouldReset = shouldReset,
		newWeekStart = currentWeekStart,
		reasoning = shouldReset
				and string.format("New week detected (saved: %d, current: %d)", savedWeekStart, currentWeekStart)
			or "Same week as previous session",
	}, reasoning)
end

--------------------------------------------------------------------------------
-- ClassifyLootItem
-- Determines if a looted item is a trackable gathering material
--------------------------------------------------------------------------------

---@param context LootClassifyContext
---@return ActionResult<LootClassifyResult>
function Journal.ClassifyLootItem(context)
	if not context or not context.itemClassID then
		return Result.error("INVALID_CONTEXT", "Loot classify context is missing or invalid")
	end

	local itemClassID = context.itemClassID
	local itemSubClassID = context.itemSubClassID

	-- Must be Trade Goods class
	if itemClassID ~= ITEM_CLASS_TRADEGOODS then
		return Result.success({
			isGathering = false,
			category = nil,
			expansion = nil,
		}, "Not a trade goods item")
	end

	-- Check if it's a tracked subclass
	local categoryName = TRACKED_SUBCLASSES[itemSubClassID]
	if not categoryName then
		return Result.success({
			isGathering = false,
			category = nil,
			expansion = nil,
		}, string.format("Trade goods subclass %d is not tracked", itemSubClassID))
	end

	return Result.success({
		isGathering = true,
		category = categoryName,
		expansion = context.expansionID,
	}, string.format("Gathering material: %s", categoryName))
end

--------------------------------------------------------------------------------
-- ParseLootMessage
-- Extracts item link and quantity from a loot chat message
-- This is pure string parsing with no WoW API dependencies
--------------------------------------------------------------------------------

---@param context {message: string}
---@return ActionResult<{itemLink: string|nil, quantity: number, itemID: number|nil}>
function Journal.ParseLootMessage(context)
	if not context or not context.message then
		return Result.error("INVALID_CONTEXT", "Message is required")
	end

	local message = context.message

	-- Match item link pattern |cxxxxxxxx|Hitem:itemID:...|h[Name]|h|r
	local itemLink = message:match("|c%x+|Hitem:[^|]+|h%[.-%]|h|r")
	if not itemLink then
		return Result.success({
			itemLink = nil,
			quantity = 0,
			itemID = nil,
		}, "No item link found in message")
	end

	-- Extract quantity (defaults to 1)
	local quantity = message:match("x(%d+)") or 1
	quantity = tonumber(quantity) or 1

	-- Extract item ID from link
	local itemID = tonumber(itemLink:match("item:(%d+)"))

	return Result.success({
		itemLink = itemLink,
		quantity = quantity,
		itemID = itemID,
	}, string.format("Parsed loot: item %s x%d", tostring(itemID), quantity))
end

--------------------------------------------------------------------------------
-- FormatJournalSummary
-- Creates a formatted summary of journal contents for display
--------------------------------------------------------------------------------

---@param context {categories: table<string, number>, gatheringTotal: number, achievementPoints: number}
---@return ActionResult<{summaryText: string, hasContent: boolean}>
function Journal.FormatJournalSummary(context)
	if not context then
		return Result.error("INVALID_CONTEXT", "Summary context is missing")
	end

	local categories = context.categories or {}
	local gatheringTotal = context.gatheringTotal or 0
	local achievementPoints = context.achievementPoints or 0

	local parts = {}
	local totalCollectibles = 0

	-- Count collectibles
	for _category, count in pairs(categories) do
		if count > 0 then
			totalCollectibles = totalCollectibles + count
		end
	end

	-- Build summary
	if totalCollectibles > 0 then
		table.insert(parts, string.format("%d collectibles", totalCollectibles))
	end

	if achievementPoints > 0 then
		table.insert(parts, string.format("%d achievement pts", achievementPoints))
	end

	if gatheringTotal > 0 then
		table.insert(parts, string.format("%d materials", gatheringTotal))
	end

	local hasContent = #parts > 0
	local summaryText = hasContent and table.concat(parts, ", ") or "No activity this week"

	return Result.success({
		summaryText = summaryText,
		hasContent = hasContent,
	}, summaryText)
end

return Journal

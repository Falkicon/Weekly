-- Discovery.lua
-- Dev-only tool for discovering currencies and quests to add to Weekly's database
-- Excluded from CurseForge builds via .pkgmeta

local _, ns = ...

-- Only run in dev mode
if not ns.IS_DEV_MODE then
	return
end

local Discovery = {}
ns.Discovery = Discovery

-- Current expansion for filtering
local CURRENT_EXPANSION = GetExpansionLevel()

-- Persistence settings
local MAX_STORED_ITEMS = 500 -- Cap to prevent unbounded growth
local SAVED_DATA_KEY = "discovery" -- Key in WeeklyDB.dev

--------------------------------------------------------------------------------
-- Zone to Expansion Mapping
--------------------------------------------------------------------------------

-- Parent map IDs for each expansion's continent
-- Note: Expansion IDs are 0-indexed (Classic=0, TBC=1, etc.)
local EXPANSION_PARENT_MAPS = {
	[2274] = 10, -- Khaz Algar (The War Within)
	[1978] = 9, -- Dragon Isles (Dragonflight)
	[1550] = 8, -- Shadowlands
	[1643] = 7, -- Kul Tiras (BfA Alliance)
	[1642] = 7, -- Zandalar (BfA Horde)
	[619] = 6, -- Broken Isles (Legion)
	[572] = 5, -- Draenor (WoD)
	[424] = 4, -- Pandaria (MoP)
	[948] = 3, -- The Maelstrom (Cata) - Note: Cata also uses Eastern Kingdoms/Kalimdor
	[113] = 2, -- Northrend (WotLK)
	[101] = 1, -- Outland (TBC)
	[1] = 0, -- Kalimdor (Classic) - but also used by later expacs
	[2] = 0, -- Eastern Kingdoms (Classic) - but also used by later expacs
}

-- Get expansion from current zone by traversing map hierarchy
local function GetExpansionFromCurrentZone()
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then
		return nil
	end

	-- Traverse up the map hierarchy looking for a known expansion parent
	local visited = {}
	local currentMap = mapID

	while currentMap and not visited[currentMap] do
		visited[currentMap] = true

		-- Check if this map is a known expansion parent
		if EXPANSION_PARENT_MAPS[currentMap] then
			return EXPANSION_PARENT_MAPS[currentMap]
		end

		-- Get parent map
		local mapInfo = C_Map.GetMapInfo(currentMap)
		if mapInfo and mapInfo.parentMapID and mapInfo.parentMapID > 0 then
			currentMap = mapInfo.parentMapID
		else
			break
		end
	end

	return nil
end

-- Get zone info for logging
local function GetCurrentZoneInfo()
	local mapID = C_Map.GetBestMapForUnit("player")
	local zoneName = GetRealZoneText() or "Unknown"
	local subZone = GetSubZoneText() or ""

	-- Get player position
	local x, y = 0, 0
	if mapID then
		local pos = C_Map.GetPlayerMapPosition(mapID, "player")
		if pos then
			x, y = pos:GetXY()
		end
	end

	-- Get client build info
	local _, build, _, tocversion = GetBuildInfo()

	return {
		mapID = mapID,
		zoneName = zoneName,
		subZone = subZone,
		x = x,
		y = y,
		build = build,
		tocversion = tocversion,
		expansion = GetExpansionFromCurrentZone(),
	}
end

--------------------------------------------------------------------------------
-- Persistence: Save/Load discovered items
--------------------------------------------------------------------------------

local function GetSavedData()
	if not WeeklyDB then
		return nil
	end
	if not WeeklyDB.dev then
		WeeklyDB.dev = {}
	end
	return WeeklyDB.dev[SAVED_DATA_KEY]
end

local function SetSavedData(data)
	if not WeeklyDB then
		return
	end
	if not WeeklyDB.dev then
		WeeklyDB.dev = {}
	end
	WeeklyDB.dev[SAVED_DATA_KEY] = data
end

local function SaveDiscoveryData(tracker)
	if not tracker then
		return
	end

	local data = {
		items = tracker.items,
		itemCount = tracker.itemCount,
		lastSaved = time(),
		lastSavedFormatted = date("%Y-%m-%d %H:%M:%S"),
	}

	SetSavedData(data)
end

local function LoadDiscoveryData(tracker)
	local saved = GetSavedData()
	if not saved or not saved.items then
		return false
	end

	tracker.items = saved.items
	tracker.itemCount = saved.itemCount or 0

	-- Recount to be safe
	local count = 0
	for category, items in pairs(tracker.items) do
		for _ in pairs(items) do
			count = count + 1
		end
	end
	tracker.itemCount = count

	return true, saved.lastSavedFormatted
end

local function PruneOldestItems(tracker, maxItems)
	if tracker.itemCount <= maxItems then
		return 0
	end

	-- Collect all items with timestamps
	local allItems = {}
	for category, items in pairs(tracker.items) do
		for id, data in pairs(items) do
			table.insert(allItems, {
				category = category,
				id = id,
				firstSeen = data.firstSeen or 0,
			})
		end
	end

	-- Sort by timestamp (oldest first)
	table.sort(allItems, function(a, b)
		return a.firstSeen < b.firstSeen
	end)

	-- Remove oldest items until we're under the cap
	local toRemove = tracker.itemCount - maxItems
	local removed = 0

	for i = 1, toRemove do
		local item = allItems[i]
		if item and tracker.items[item.category] then
			tracker.items[item.category][item.id] = nil
			removed = removed + 1
		end
	end

	tracker.itemCount = tracker.itemCount - removed
	return removed
end

--------------------------------------------------------------------------------
-- Helper: Check if item is already tracked in Weekly's database
--------------------------------------------------------------------------------

local function IsAlreadyTracked(itemType, id)
	local data = ns:GetCurrentSeasonData()
	if not data then
		return false
	end

	for _, section in ipairs(data) do
		if section.items then
			for _, item in ipairs(section.items) do
				-- Map Weekly types to our categories
				local checkType = item.type
				if checkType == "currency" or checkType == "currency_cap" then
					checkType = "currency"
				end

				if checkType == itemType then
					-- Handle both single IDs and tables of IDs
					local checkIds = type(item.id) == "table" and item.id or { item.id }
					for _, trackedId in ipairs(checkIds) do
						if trackedId == id then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- Initialize Discovery Tracker
--------------------------------------------------------------------------------

function Discovery:Initialize()
	if self.tracker then
		return
	end

	-- Create tracker using TrackerCore
	self.tracker = ns.TrackerCore:CreateTracker("Discovery", {
		persistent = true,
		onItemLogged = function(tracker, category, id, data)
			self:OnItemLogged(category, id, data)
		end,
	})

	-- Load saved data
	local loaded, lastSaved = LoadDiscoveryData(self.tracker)
	if loaded then
		-- Prune if over cap
		local pruned = PruneOldestItems(self.tracker, MAX_STORED_ITEMS)
		if pruned > 0 then
			print(
				string.format("|cffff8800[Weekly Discovery]|r Pruned %d old items (cap: %d)", pruned, MAX_STORED_ITEMS)
			)
		end
		print(
			string.format(
				"|cff00ff00[Weekly Discovery]|r Loaded %d saved items (last saved: %s)",
				self.tracker.itemCount,
				lastSaved or "unknown"
			)
		)
	end

	-- Filter settings
	self.filters = {
		showOnlyNew = true, -- Hide already-tracked items
		showCurrencies = true,
		showQuests = true,
		expansionFilter = nil, -- nil = all, number = specific expansion
	}

	-- Register events
	self.tracker:RegisterEvents({
		-- Currency events
		CURRENCY_DISPLAY_UPDATE = function(
			t,
			event,
			currencyType,
			quantity,
			quantityChange,
			quantityGainSource,
			quantityLostSource
		)
			self:OnCurrencyUpdate(currencyType, quantity, quantityChange)
		end,

		-- Quest events
		QUEST_ACCEPTED = function(t, event, questID)
			self:OnQuestEvent(questID, "accepted")
		end,
		QUEST_TURNED_IN = function(t, event, questID, xpReward, moneyReward)
			self:OnQuestEvent(questID, "completed")
		end,

		-- Save on logout
		PLAYER_LOGOUT = function(t, event)
			self:Save()
		end,
	})

	-- Create UI
	self:CreateUI()

	print("|cff00ff00[Weekly Discovery]|r Active - automatically tracking currencies and quests")
	print("|cff00ff00[Weekly Discovery]|r Use /weekly disc or Settings > Dev Tools to view")
end

function Discovery:Save()
	if self.tracker then
		SaveDiscoveryData(self.tracker)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

function Discovery:OnCurrencyUpdate(currencyID, quantity, quantityChange)
	if not currencyID then
		return
	end

	-- Get currency info
	local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
	if not info then
		return
	end

	-- Skip if already tracked (optional filter)
	if self.filters.showOnlyNew and IsAlreadyTracked("currency", currencyID) then
		return
	end

	-- Get expansion (if available)
	local expansion = info.expansionID

	-- Determine if it has a weekly cap
	local hasCap = info.maxWeeklyQuantity and info.maxWeeklyQuantity > 0
	local hasMax = info.maxQuantity and info.maxQuantity > 0

	-- Get extended info (coords, build)
	local extended = GetCurrentZoneInfo()

	-- Log it
	self.tracker:LogItem("currency", currencyID, {
		name = info.name,
		icon = info.iconFileID,
		expansion = expansion,
		expansionName = ns.TrackerCore.GetExpansionName(expansion),
		hasCap = hasCap,
		hasMax = hasMax,
		maxWeekly = info.maxWeeklyQuantity,
		maxTotal = info.maxQuantity,
		quality = info.quality,
		-- Extended metadata
		mapID = extended.mapID,
		x = extended.x,
		y = extended.y,
		build = extended.build,
		tocversion = extended.tocversion,
	})
end

function Discovery:OnQuestEvent(questID, eventType)
	if not questID then
		return
	end

	-- Skip if already tracked
	if self.filters.showOnlyNew and IsAlreadyTracked("quest", questID) then
		return
	end

	-- Get quest info
	local questName = C_QuestLog.GetTitleForQuestID(questID) or ("Quest " .. questID)

	-- Get expansion (try API first, then zone-based detection)
	local expansion = C_QuestLog.GetQuestExpansion and C_QuestLog.GetQuestExpansion(questID)

	-- Get current zone info (useful even if API returns expansion)
	local zoneInfo = GetCurrentZoneInfo()

	-- If API didn't give us expansion, use zone-based detection
	if not expansion and zoneInfo.expansion then
		expansion = zoneInfo.expansion
	end

	-- Check if it's a weekly quest
	local isWeekly = C_QuestLog.IsWeekly and C_QuestLog.IsWeekly(questID)
	local isDaily = C_QuestLog.IsDaily and C_QuestLog.IsDaily(questID)

	-- Log it
	self.tracker:LogItem("quest", questID, {
		name = questName,
		expansion = expansion,
		expansionName = ns.TrackerCore.GetExpansionName(expansion),
		eventType = eventType,
		isWeekly = isWeekly,
		isDaily = isDaily,
		-- Zone info for additional context
		zoneName = zoneInfo.zoneName,
		zoneMapID = zoneInfo.mapID,
		-- Extended metadata (coords at time of event)
		x = zoneInfo.x,
		y = zoneInfo.y,
		build = zoneInfo.build,
		tocversion = zoneInfo.tocversion,
	})
end

-- Throttled save (don't save more than once per 5 seconds)
local lastSaveTime = 0
local SAVE_THROTTLE = 5

local function ThrottledSave(self)
	local now = GetTime()
	if now - lastSaveTime >= SAVE_THROTTLE then
		lastSaveTime = now
		self:Save()
	end
end

function Discovery:OnItemLogged(category, id, data)
	-- Update UI if visible
	if self.tracker.frame and self.tracker.frame:IsShown() then
		self:RefreshUI()
	end

	-- Auto-save (throttled)
	ThrottledSave(self)

	-- Prune if over cap
	if self.tracker.itemCount > MAX_STORED_ITEMS then
		local pruned = PruneOldestItems(self.tracker, MAX_STORED_ITEMS)
		if pruned > 0 then
			print(string.format("|cffff8800[Discovery]|r Auto-pruned %d oldest items", pruned))
		end
	end

	-- Debug output
	local expansionTag = data.expansionName and (" [" .. data.expansionName .. "]") or ""
	local capTag = data.hasCap and " (WEEKLY CAP)" or ""
	local zoneTag = ""
	if data.zoneName and not data.expansionName then
		-- Show zone if we couldn't determine expansion
		zoneTag = " @ " .. data.zoneName
	end
	print(
		string.format(
			"|cff00ff00[Discovery]|r %s: %s (%d)%s%s%s",
			category,
			data.name or "Unknown",
			id,
			expansionTag,
			zoneTag,
			capTag
		)
	)
end

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------

function Discovery:CreateUI()
	local frame = self.tracker:CreateWindow({
		name = "WeeklyDiscoveryFrame",
		title = "Weekly Discovery Tool",
		width = 450,
		height = 550,
	})

	-- Filter checkboxes
	local filterFrame = CreateFrame("Frame", nil, frame)
	filterFrame:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -5)
	filterFrame:SetSize(400, 25)

	-- "Only New" checkbox
	local onlyNewCB = CreateFrame("CheckButton", nil, filterFrame, "UICheckButtonTemplate")
	onlyNewCB:SetPoint("LEFT", 0, 0)
	onlyNewCB:SetSize(24, 24)
	onlyNewCB:SetChecked(self.filters.showOnlyNew)
	onlyNewCB:SetScript("OnClick", function(cb)
		self.filters.showOnlyNew = cb:GetChecked()
		self:RefreshUI()
	end)

	local onlyNewLabel = filterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	onlyNewLabel:SetPoint("LEFT", onlyNewCB, "RIGHT", 2, 0)
	onlyNewLabel:SetText("Only New")

	-- "Currencies" checkbox
	local currencyCB = CreateFrame("CheckButton", nil, filterFrame, "UICheckButtonTemplate")
	currencyCB:SetPoint("LEFT", onlyNewLabel, "RIGHT", 15, 0)
	currencyCB:SetSize(24, 24)
	currencyCB:SetChecked(self.filters.showCurrencies)
	currencyCB:SetScript("OnClick", function(cb)
		self.filters.showCurrencies = cb:GetChecked()
		self:RefreshUI()
	end)

	local currencyLabel = filterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	currencyLabel:SetPoint("LEFT", currencyCB, "RIGHT", 2, 0)
	currencyLabel:SetText("Currencies")

	-- "Quests" checkbox
	local questCB = CreateFrame("CheckButton", nil, filterFrame, "UICheckButtonTemplate")
	questCB:SetPoint("LEFT", currencyLabel, "RIGHT", 15, 0)
	questCB:SetSize(24, 24)
	questCB:SetChecked(self.filters.showQuests)
	questCB:SetScript("OnClick", function(cb)
		self.filters.showQuests = cb:GetChecked()
		self:RefreshUI()
	end)

	local questLabel = filterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	questLabel:SetPoint("LEFT", questCB, "RIGHT", 2, 0)
	questLabel:SetText("Quests")

	-- Adjust scroll frame position to account for filters
	frame.scrollFrame:SetPoint("TOPLEFT", 10, -70)

	-- Count label
	frame.countLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.countLabel:SetPoint("TOPRIGHT", -35, -10)
	frame.countLabel:SetTextColor(0.7, 0.7, 0.7)

	-- Buttons
	self.tracker:AddButton("Export", function()
		self:ExportData()
	end)

	self.tracker:AddButton("Clear", function()
		self.tracker:Clear()
		self:Save() -- Save the cleared state
		self:RefreshUI()
		print("|cff00ff00[Discovery]|r Cleared all logged items")
	end)

	self.tracker:AddButton("Refresh", function()
		self:RefreshUI()
	end)

	-- Row pool for content
	frame.rows = {}
end

function Discovery:RefreshUI()
	local frame = self.tracker.frame
	if not frame then
		return
	end

	-- Build filter function
	local function filterFunc(category, id, data)
		-- Category filter
		if category == "currency" and not self.filters.showCurrencies then
			return false
		end
		if category == "quest" and not self.filters.showQuests then
			return false
		end

		-- Expansion filter
		if self.filters.expansionFilter and data.expansion ~= self.filters.expansionFilter then
			return false
		end

		-- "Only new" filter (already tracked check)
		if self.filters.showOnlyNew and IsAlreadyTracked(category, id) then
			return false
		end

		return true
	end

	local items = self.tracker:GetItems(filterFunc)

	-- Update count
	frame.countLabel:SetText(string.format("%d items", #items))

	-- Clear existing rows
	for _, row in ipairs(frame.rows) do
		row:Hide()
	end

	-- Create/update rows
	local yOffset = 0
	local ROW_HEIGHT = 22
	local content = frame.content

	for i, item in ipairs(items) do
		local row = frame.rows[i]
		if not row then
			row = self:CreateRow(content)
			frame.rows[i] = row
		end

		row:Show()
		row:SetPoint("TOPLEFT", 0, -yOffset)
		row:SetPoint("RIGHT", 0, 0)

		self:UpdateRow(row, item)
		yOffset = yOffset + ROW_HEIGHT
	end

	-- Update content height
	content:SetHeight(math.max(1, yOffset))
end

function Discovery:CreateRow(parent)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(20)

	-- Icon
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(18, 18)
	row.icon:SetPoint("LEFT", 2, 0)

	-- Category tag
	row.tag = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.tag:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
	row.tag:SetWidth(50)
	row.tag:SetJustifyH("LEFT")

	-- Name
	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.name:SetPoint("LEFT", row.tag, "RIGHT", 4, 0)
	row.name:SetWidth(180)
	row.name:SetJustifyH("LEFT")

	-- ID
	row.idText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.idText:SetPoint("LEFT", row.name, "RIGHT", 4, 0)
	row.idText:SetWidth(60)
	row.idText:SetJustifyH("LEFT")
	row.idText:SetTextColor(0.5, 0.5, 0.5)

	-- Expansion
	row.expansion = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.expansion:SetPoint("LEFT", row.idText, "RIGHT", 4, 0)
	row.expansion:SetWidth(80)
	row.expansion:SetJustifyH("LEFT")
	row.expansion:SetTextColor(0.6, 0.6, 0.8)

	-- Highlight on hover
	row:EnableMouse(true)
	row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
	row.highlight:SetAllPoints()
	row.highlight:SetColorTexture(1, 1, 1, 0.1)

	return row
end

function Discovery:UpdateRow(row, item)
	local data = item.data
	local category = item.category

	-- Icon
	if data.icon then
		row.icon:SetTexture(data.icon)
		row.icon:Show()
	else
		row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		if category == "quest" then
			row.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
		end
	end

	-- Tag (category + cap indicator)
	local tagText = category:upper()
	if data.hasCap then
		tagText = "CAP"
		row.tag:SetTextColor(0.8, 0.6, 0.2) -- Gold for capped
	elseif category == "currency" then
		row.tag:SetTextColor(0.2, 0.8, 0.2) -- Green for currency
	elseif category == "quest" then
		row.tag:SetTextColor(0.4, 0.6, 1.0) -- Blue for quest
		if data.isWeekly then
			tagText = "WEEKLY"
			row.tag:SetTextColor(1, 0.8, 0)
		elseif data.isDaily then
			tagText = "DAILY"
		end
	else
		row.tag:SetTextColor(0.7, 0.7, 0.7)
	end
	row.tag:SetText(tagText)

	-- Name
	row.name:SetText(data.name or "Unknown")

	-- ID
	row.idText:SetText(tostring(item.id))

	-- Expansion (or zone as fallback)
	if data.expansionName then
		-- Abbreviate expansion names
		local abbrev = data.expansionName
		if abbrev == "The War Within" then
			abbrev = "TWW"
		elseif abbrev == "Dragonflight" then
			abbrev = "DF"
		elseif abbrev == "Shadowlands" then
			abbrev = "SL"
		elseif abbrev == "Battle for Azeroth" then
			abbrev = "BfA"
		elseif abbrev == "Midnight" then
			abbrev = "MN"
		end
		row.expansion:SetText(abbrev)
		row.expansion:SetTextColor(0.6, 0.6, 0.8)
	elseif data.zoneName then
		-- Show zone name if expansion unknown (truncate if too long)
		local zoneName = data.zoneName
		if #zoneName > 12 then
			zoneName = zoneName:sub(1, 11) .. "…"
		end
		row.expansion:SetText(zoneName)
		row.expansion:SetTextColor(0.5, 0.5, 0.5) -- Dimmer to indicate it's zone, not expansion
	else
		row.expansion:SetText("")
	end
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

function Discovery:ExportData()
	local function formatter(category, id, data)
		local metadata = {}
		if data.tocversion then
			table.insert(metadata, "v" .. data.tocversion)
		end
		if data.build then
			table.insert(metadata, "build " .. data.build)
		end
		if data.zoneName then
			table.insert(metadata, data.zoneName)
		end
		if data.x and data.y and data.x > 0 then
			table.insert(
				metadata,
				string.format("coords: %d, %.2f, %.2f", data.zoneMapID or data.mapID or 0, data.x * 100, data.y * 100)
			)
		end
		local metaStr = #metadata > 0 and ("  -- " .. table.concat(metadata, ", ")) or ""

		if category == "currency" then
			local funcName = data.hasCap and "Cap" or "Currency"
			local expansionInfo = data.expansionName and ("  -- " .. data.expansionName) or ""
			-- If we have metadata, use it, otherwise use expansion info
			local comment = metaStr ~= "" and metaStr or expansionInfo
			return string.format('%s(%d, "%s"),%s', funcName, id, data.name or "Unknown", comment)
		elseif category == "quest" then
			local types = {}
			if data.isWeekly then
				table.insert(types, "Weekly")
			end
			if data.isDaily then
				table.insert(types, "Daily")
			end
			if data.expansionName then
				table.insert(types, data.expansionName)
			end

			local typeStr = #types > 0 and (table.concat(types, ", ") .. " | ") or ""
			local comment = "  -- " .. typeStr .. metaStr:gsub("^%s*%-%-%s*", "")

			-- Prepare coords table if available for the function call
			local coordArg = ""
			if data.zoneMapID and data.x and data.x > 0 then
				coordArg = string.format(", { mapID = %d, x = %.4f, y = %.4f }", data.zoneMapID, data.x, data.y)
			end

			return string.format('Quest(%d, "%s", nil%s),%s', id, data.name or "Unknown", coordArg, comment)
		end

		return nil
	end

	-- Build filter based on current settings
	local function filterFunc(category, id, data)
		if category == "currency" and not self.filters.showCurrencies then
			return false
		end
		if category == "quest" and not self.filters.showQuests then
			return false
		end
		return true
	end

	local text = self.tracker:ExportToString(formatter, filterFunc)

	if text == "" or text:match("^%s*$") then
		print("|cffff8800[Discovery]|r No items to export")
		return
	end

	self.tracker:ShowExportPopup(text)
end

--------------------------------------------------------------------------------
-- Slash Command & Toggle
--------------------------------------------------------------------------------

function Discovery:Toggle()
	if not self.tracker then
		self:Initialize()
	end

	if self.tracker.frame:IsShown() then
		self.tracker.frame:Hide()
	else
		self:RefreshUI()
		self.tracker.frame:Show()
	end
end

--------------------------------------------------------------------------------
-- Auto-Initialize on Load
--------------------------------------------------------------------------------

-- Initialize when Weekly loads (in dev mode)
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
	-- Delay slightly to ensure Weekly is fully loaded
	C_Timer.After(1, function()
		if ns.IS_DEV_MODE and ns.TrackerCore then
			Discovery:Initialize()
		end
	end)
	self:UnregisterAllEvents()
end)

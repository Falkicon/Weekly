-- Journal.lua
-- Weekly Journal - Tracks collectibles earned during the week
-- Categories: Achievements, Mounts, Pets, Toys, Decor, Gathering

local _, ns = ...

local Journal = {}
ns.Journal = Journal
local L = LibStub("AceLocale-3.0"):GetLocale("Weekly")

-- Category definitions (collectibles - tracked via TrackerCore)
Journal.CATEGORIES = {
	achievement = {
		name = L["Achievements"],
		icon = "Interface\\Icons\\Achievement_Level_10",
		order = 1,
	},
	mount = {
		name = L["Mounts"],
		icon = "Interface\\Icons\\Ability_Mount_RidingHorse",
		order = 2,
	},
	pet = {
		name = L["Pets"],
		icon = "Interface\\Icons\\INV_Pet_BabyBlizzardBear",
		order = 3,
	},
	toy = {
		name = L["Toys"],
		icon = "Interface\\Icons\\INV_Misc_Toy_07",
		order = 4,
	},
	decor = {
		name = L["Decor"],
		icon = "Interface\\Icons\\INV_Misc_Furniture_Chair_01",
		order = 5,
	},
}

-- Gathering is tracked separately (running totals, not unique items)
Journal.GATHERING_CATEGORY = {
	name = L["Gathering"],
	icon = "Interface\\Icons\\INV_Misc_Herb_MountainSilversage",
	order = 6,
}

-- Expansion names for grouping
Journal.EXPANSION_NAMES = {
	[0] = L["Classic"],
	[1] = L["Burning Crusade"],
	[2] = L["Wrath of the Lich King"],
	[3] = L["Cataclysm"],
	[4] = L["Mists of Pandaria"],
	[5] = L["Warlords of Draenor"],
	[6] = L["Legion"],
	[7] = L["Battle for Azeroth"],
	[8] = L["Shadowlands"],
	[9] = L["Dragonflight"],
	[10] = L["The War Within"],
	[11] = L["Midnight"],
}

-- Trade Goods class ID
local ITEM_CLASS_TRADEGOODS = 7

-- Trade Goods subclasses we want to track (gathering materials)
-- These are the subclasses that represent raw gathered materials
local TRACKED_SUBCLASSES = {
	[5] = true, -- Cloth
	[6] = true, -- Leather
	[7] = true, -- Metal & Stone (Ore)
	[8] = true, -- Cooking (Meat, Fish ingredients)
	[9] = true, -- Herb
	[10] = true, -- Elemental
	[11] = true, -- Other (some reagents)
	[12] = true, -- Enchanting
	[16] = true, -- Inscription (Pigments)
	[18] = true, -- Optional Reagents (crafting mats)
}

-- Collections Journal tab indices (for opening official UI)
local COLLECTIONS_TAB_MOUNTS = 1
local COLLECTIONS_TAB_PETS = 2
local COLLECTIONS_TAB_TOYS = 3
-- local COLLECTIONS_TAB_HEIRLOOMS = 4
-- local COLLECTIONS_TAB_APPEARANCES = 5

--------------------------------------------------------------------------------
-- Weekly Reset Detection
--------------------------------------------------------------------------------

-- Get the timestamp for the start of the current week (Tuesday 00:00 server time)
-- WoW weekly reset is Tuesday at different times per region, but we use midnight
-- server time as a reasonable approximation
local function GetWeekStartTimestamp()
	local serverTime = C_DateAndTime.GetServerTimeLocal()
	local date = C_DateAndTime.GetCurrentCalendarTime()

	-- Get current day of week (1=Sunday, 2=Monday, 3=Tuesday, etc.)
	local weekday = date.weekday

	-- Calculate days since last Tuesday
	-- Tuesday is weekday 3 in WoW's calendar
	local daysSinceTuesday
	if weekday >= 3 then
		daysSinceTuesday = weekday - 3
	else
		daysSinceTuesday = weekday + 4 -- Wrap around (Sun=1 -> 5, Mon=2 -> 6)
	end

	-- Get midnight of today
	local hour = date.hour
	local minute = date.minute
	local secondsIntoDay = (hour * 3600) + (minute * 60)
	local midnightToday = serverTime - secondsIntoDay

	-- Go back to Tuesday midnight
	local tuesdayMidnight = midnightToday - (daysSinceTuesday * 86400)

	return tuesdayMidnight
end

-- Check if we need to reset for a new week
local function CheckWeeklyReset()
	local currentWeekStart = GetWeekStartTimestamp()
	local savedWeekStart = ns.Config.journal and ns.Config.journal.weekStart or 0

	if currentWeekStart > savedWeekStart then
		-- New week! Clear journal data
		if Journal.tracker then
			Journal.tracker:Clear()
		end

		-- Update the week start timestamp
		if ns.Config.journal then
			ns.Config.journal.weekStart = currentWeekStart
			ns.Config.journal.categories = {}
		end

		return true -- Reset occurred
	end

	return false -- No reset needed
end

--------------------------------------------------------------------------------
-- Persistence
--------------------------------------------------------------------------------

local function SaveJournalData()
	if not Journal.tracker then
		return
	end
	if not ns.Config.journal then
		return
	end

	ns.Config.journal.categories = Journal.tracker.items
	ns.Config.journal.itemCount = Journal.tracker.itemCount
	ns.Config.journal.lastSaved = time()

	-- Save gathering data separately
	ns.Config.journal.gathering = Journal.gathering or {}
end

local function LoadJournalData()
	if not Journal.tracker then
		return false
	end
	if not ns.Config.journal then
		return false
	end
	if not ns.Config.journal.categories then
		return false
	end

	Journal.tracker.items = ns.Config.journal.categories

	-- Recount items
	local count = 0
	for _category, items in pairs(Journal.tracker.items) do
		for _ in pairs(items) do
			count = count + 1
		end
	end
	Journal.tracker.itemCount = count

	-- Load gathering data
	Journal.gathering = ns.Config.journal.gathering or {}

	return true
end

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

local function OnAchievementEarned(tracker, _event, achievementID, alreadyEarned)
	if alreadyEarned then
		return
	end -- Skip if this was already earned before

	-- 12.0.1: GetAchievementInfo can throw hard errors for invalid IDs
	local ok, _id, name, points, _completed, _month, _day, _year, description, _flags, icon, _rewardText, _isGuild, _wasEarnedByMe, _earnedBy, _isStatistic =
		pcall(GetAchievementInfo, achievementID)

	if not ok or not name then
		return
	end

	-- Get current zone for source info
	local zoneName = GetRealZoneText() or "Unknown"

	local logged = tracker:LogItem("achievement", achievementID, {
		name = name,
		icon = icon,
		points = points,
		description = description,
		zoneName = zoneName,
	})

	if logged then
		SaveJournalData()
	end
end

local function OnNewMountAdded(tracker, _event, mountID)
	if not mountID then
		return
	end

	local name, spellID, icon, _isActive, _isUsable, sourceType, _isFavorite, _isFactionSpecific, _faction, _shouldHideOnChar, _isCollected, _mountID2, _isForDragonriding =
		C_MountJournal.GetMountInfoByID(mountID)

	if not name then
		return
	end

	-- Get current zone for source info
	local zoneName = GetRealZoneText() or "Unknown"

	local logged = tracker:LogItem("mount", mountID, {
		name = name,
		icon = icon,
		spellID = spellID,
		sourceType = sourceType,
		zoneName = zoneName,
	})

	if logged then
		SaveJournalData()
	end
end

local function OnNewPetAdded(tracker, _event, battlePetGUID)
	if not battlePetGUID then
		return
	end

	-- Get species ID from the GUID
	local speciesID = C_PetJournal.GetPetInfoByPetID(battlePetGUID)
	if not speciesID then
		return
	end

	local speciesName, speciesIcon, petType, _companionID, tooltipSource, _tooltipDescription, _isWild, _canBattle, _isTradeable, _isUnique, _obtainable, _creatureDisplayID =
		C_PetJournal.GetPetInfoBySpeciesID(speciesID)

	if not speciesName then
		return
	end

	-- Get current zone for source info
	local zoneName = GetRealZoneText() or "Unknown"

	local logged = tracker:LogItem("pet", speciesID, {
		name = speciesName,
		icon = speciesIcon,
		petType = petType,
		tooltipSource = tooltipSource,
		zoneName = zoneName,
		petGUID = battlePetGUID,
	})

	if logged then
		SaveJournalData()
	end
end

local function OnNewToyAdded(tracker, _event, itemID, isNew)
	if not itemID then
		return
	end
	if not isNew then
		return
	end -- Only track newly added toys

	local _itemID2, toyName, icon, _isFavorite, _hasFanfare, itemQuality = C_ToyBox.GetToyInfo(itemID)

	if not toyName then
		-- Fallback to item info if toy info isn't available yet
		toyName = C_Item.GetItemNameByID(itemID) or ("Toy " .. itemID)
		icon = C_Item.GetItemIconByID(itemID)
	end

	-- Get current zone for source info
	local zoneName = GetRealZoneText() or "Unknown"

	local logged = tracker:LogItem("toy", itemID, {
		name = toyName,
		icon = icon,
		quality = itemQuality,
		zoneName = zoneName,
	})

	if logged then
		SaveJournalData()
	end
end

local function OnDecorAddedToChest(tracker, _event, decorGUID, decorID)
	if not decorID then
		return
	end

	local name = C_HousingDecor.GetDecorName(decorID)
	local icon = C_HousingDecor.GetDecorIcon(decorID)

	if not name then
		name = "Decor " .. decorID
	end

	-- Get current zone for source info
	local zoneName = GetRealZoneText() or "Unknown"

	local logged = tracker:LogItem("decor", decorID, {
		name = name,
		icon = icon,
		decorGUID = decorGUID,
		zoneName = zoneName,
	})

	if logged then
		SaveJournalData()
	end
end

--------------------------------------------------------------------------------
-- Gathering Event Handler
--------------------------------------------------------------------------------

-- Parse item link from loot message
-- Format: "You receive loot: [Item Name] x5" or "You receive loot: [Item Name]"
local function ParseLootMessage(message)
	-- Match item link pattern |cxxxxxxxx|Hitem:itemID:...|h[Name]|h|r
	local itemLink = message:match("|c%x+|Hitem:[^|]+|h%[.-%]|h|r")
	if not itemLink then
		return nil, nil
	end

	-- Extract quantity (defaults to 1)
	local quantity = message:match("x(%d+)") or 1
	quantity = tonumber(quantity)

	return itemLink, quantity
end

-- Check if an item is a trackable gathering material
local function IsGatheringMaterial(itemID)
	local _itemName, _itemLink, _itemQuality, _itemLevel, _itemMinLevel, _itemType, _itemSubType, _itemStackCount, _itemEquipLoc, _itemTexture, _sellPrice, classID, subclassID, _bindType, expansionID =
		C_Item.GetItemInfo(itemID)

	-- Must be Trade Goods class
	if classID ~= ITEM_CLASS_TRADEGOODS then
		return false, nil, nil
	end

	-- Check if it's a tracked subclass
	if not TRACKED_SUBCLASSES[subclassID] then
		return false, nil, nil
	end

	return true, expansionID, subclassID
end

local function OnChatMsgLoot(_tracker, _event, message, ...)
	local blockStart = debugprofilestop()

	local function recordPerf()
		if ns.PerfBlocks then
			ns.PerfBlocks.journalTrack = ns.PerfBlocks.journalTrack + (debugprofilestop() - blockStart)
		end
	end

	-- Only track our own loot
	local itemLink, quantity = ParseLootMessage(message)
	if not itemLink or not quantity then
		recordPerf()
		return
	end

	-- Extract item ID from link
	local itemID = tonumber(itemLink:match("item:(%d+)"))
	if not itemID then
		recordPerf()
		return
	end

	-- Check if it's a gathering material
	local isGathering, expansionID, subclassID = IsGatheringMaterial(itemID)
	if not isGathering then
		recordPerf()
		return
	end

	-- Initialize gathering storage if needed
	if not Journal.gathering then
		Journal.gathering = {}
	end

	-- Get item info for display
	local itemName = C_Item.GetItemNameByID(itemID)
	local itemIcon = C_Item.GetItemIconByID(itemID)

	-- Item info might not be cached yet, request it
	if not itemName then
		-- Queue the item for later (it will be tracked next time)
		C_Item.RequestLoadItemDataByID(itemID)
		recordPerf()
		return
	end

	-- Add to running total
	if not Journal.gathering[itemID] then
		Journal.gathering[itemID] = {
			name = itemName,
			icon = itemIcon,
			count = 0,
			expansion = expansionID or 0,
			subclass = subclassID,
			firstSeen = time(),
		}
	end

	Journal.gathering[itemID].count = Journal.gathering[itemID].count + quantity
	Journal.gathering[itemID].lastSeen = time()

	-- Update name/icon if we didn't have it before
	if itemName and not Journal.gathering[itemID].name then
		Journal.gathering[itemID].name = itemName
	end
	if itemIcon and not Journal.gathering[itemID].icon then
		Journal.gathering[itemID].icon = itemIcon
	end

	-- Notify
	Journal:OnGatheringLogged(itemID, quantity, Journal.gathering[itemID])

	-- Save periodically (not every single loot to avoid spam)
	-- The logout handler will ensure final save

	recordPerf()
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

function Journal:Initialize()
	if self.tracker then
		return
	end -- Already initialized

	-- Check if Journal is enabled
	if not ns.Config.journal or not ns.Config.journal.enabled then
		return
	end

	-- Initialize gathering storage
	self.gathering = {}

	-- Create tracker using TrackerCore
	self.tracker = ns.TrackerCore:CreateTracker("WeeklyJournal", {
		persistent = true,
		onItemLogged = function(_tracker, category, id, data)
			self:OnItemLogged(category, id, data)
		end,
	})

	-- Check for weekly reset before loading data
	local wasReset = CheckWeeklyReset()

	-- If reset, also clear gathering
	if wasReset then
		self.gathering = {}
		if ns.Config.journal then
			ns.Config.journal.gathering = {}
		end
	else
		-- Load saved data
		LoadJournalData()
	end

	-- Register events
	self.tracker:RegisterEvents({
		ACHIEVEMENT_EARNED = OnAchievementEarned,
		NEW_MOUNT_ADDED = OnNewMountAdded,
		NEW_PET_ADDED = OnNewPetAdded,
		NEW_TOY_ADDED = OnNewToyAdded,
		HOUSE_DECOR_ADDED_TO_CHEST = OnDecorAddedToChest,
		CHAT_MSG_LOOT = OnChatMsgLoot,

		-- Save on logout
		PLAYER_LOGOUT = function(_tracker, _event)
			SaveJournalData()
		end,
	})

	-- Print status
	local itemCount = self.tracker.itemCount or 0
	local gatheringCount = self:GetGatheringTotalCount()
	if itemCount > 0 or gatheringCount > 0 then
		ns.Weekly:Printf(L["Journal loaded: %d collectibles, %d materials gathered"], itemCount, gatheringCount)
	end
end

function Journal:Shutdown()
	if not self.tracker then
		return
	end

	SaveJournalData()
	self.tracker:UnregisterEvents()
	self.tracker = nil
end

function Journal:OnItemLogged(category, _id, data)
	-- Optional: Show notification
	if ns.Config.journal and ns.Config.journal.showNotifications then
		local categoryInfo = self.CATEGORIES[category]
		local categoryName = categoryInfo and categoryInfo.name or category
		ns.Weekly:Printf(L["New %s: %s"], categoryName, data.name or "Unknown")
	end

	-- Update UI if visible
	if ns.JournalUI and ns.JournalUI.frame and ns.JournalUI.frame:IsShown() then
		ns.JournalUI:RefreshCurrentTab()
	end
end

function Journal:OnGatheringLogged(_itemID, quantity, data)
	-- Optional: Show notification (less spammy for gathering)
	-- Only notify for first-time items
	if ns.Config.journal and ns.Config.journal.showNotifications and data.count == quantity then
		ns.Weekly:Printf(L["Started gathering: %s"], data.name or "Unknown")
	end

	-- Update UI if visible on gathering tab
	if ns.JournalUI and ns.JournalUI.frame and ns.JournalUI.frame:IsShown() then
		if ns.JournalUI.currentTab == "gathering" then
			ns.JournalUI:RefreshCurrentTab()
		end
	end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- Get total count of items this week
function Journal:GetTotalCount()
	if not self.tracker then
		return 0
	end
	return self.tracker.itemCount
end

-- Get count for a specific category
function Journal:GetCategoryCount(category)
	if not self.tracker then
		return 0
	end
	return self.tracker:GetCount(category)
end

-- Get all items for a category
function Journal:GetCategoryItems(category)
	if not self.tracker then
		return {}
	end
	return self.tracker:GetItems(function(cat, _id, _data)
		return cat == category
	end)
end

-- Get total achievement points earned this week
function Journal:GetAchievementPointsThisWeek()
	if not self.tracker then
		return 0
	end

	local total = 0
	local achievements = self.tracker.items.achievement
	if achievements then
		for _id, data in pairs(achievements) do
			total = total + (data.points or 0)
		end
	end
	return total
end

-- Clear a specific category (for manual reset)
function Journal:ClearCategory(category)
	if category == "gathering" then
		self.gathering = {}
		SaveJournalData()
		return
	end

	if not self.tracker then
		return
	end
	self.tracker:Clear(category)
	SaveJournalData()
end

-- Clear all categories (full manual reset)
function Journal:ClearAll()
	if not self.tracker then
		return
	end
	self.tracker:Clear()
	self.gathering = {}
	SaveJournalData()
end

-- Open the official UI for a specific item
function Journal:OpenOfficialUI(category, id, data)
	if category == "achievement" then
		-- Open Achievement UI to this achievement
		if OpenAchievementFrameToAchievement then
			OpenAchievementFrameToAchievement(id)
		end
	elseif category == "mount" then
		-- Open Collections Journal to Mounts tab
		SetCollectionsJournalShown(true, COLLECTIONS_TAB_MOUNTS)
	elseif category == "pet" then
		-- Open Collections Journal to Pets tab and set search filter
		SetCollectionsJournalShown(true, COLLECTIONS_TAB_PETS)
		-- Set search filter to pet name so it's easy to find
		if data and data.name and C_PetJournal and C_PetJournal.SetSearchFilter then
			C_Timer.After(0.1, function()
				C_PetJournal.SetSearchFilter(data.name)
			end)
		end
	elseif category == "toy" then
		-- Open Collections Journal to Toys tab
		SetCollectionsJournalShown(true, COLLECTIONS_TAB_TOYS)
	elseif category == "decor" then
		-- Open Housing Dashboard to Catalog tab with search
		local function SetupCatalogSearch()
			if not HousingDashboardFrame or not HousingDashboardFrame:IsShown() then
				return
			end

			-- Switch to Catalog tab
			if HousingDashboardFrame.catalogTab then
				HousingDashboardFrame:SetTab(HousingDashboardFrame.catalogTab)
			end

			-- Set search text if we have a name
			if data and data.name then
				C_Timer.After(0.1, function()
					local catalog = HousingDashboardFrame.CatalogContent
					if catalog then
						-- Hide the preview so UpdateCatalogData will auto-select first result
						if catalog.PreviewFrame then
							catalog.PreviewFrame:Hide()
						end

						-- Set the text in the search box
						if catalog.SearchBox then
							catalog.SearchBox:SetText(data.name)
						end

						-- Trigger the actual search
						if catalog.OnSearchTextUpdated then
							catalog:OnSearchTextUpdated(data.name)
						end
					end
				end)
			end
		end

		-- Check if dashboard is already open
		if HousingDashboardFrame and HousingDashboardFrame:IsShown() then
			-- Already open, just setup the search
			SetupCatalogSearch()
		elseif HousingFramesUtil and HousingFramesUtil.ToggleHousingDashboard then
			-- Need to open it first
			HousingFramesUtil.ToggleHousingDashboard()
			-- Wait for it to be ready
			C_Timer.After(0.2, SetupCatalogSearch)
		else
			-- Fallback if HousingFramesUtil isn't loaded yet
			ns.Weekly:Printf("Decor: %s (ID: %d)", data and data.name or "Unknown", id)
		end
	end
end

-- Get ordered list of categories for display
function Journal:GetOrderedCategories()
	local categories = {}
	for key, info in pairs(self.CATEGORIES) do
		table.insert(categories, {
			key = key,
			name = info.name,
			icon = info.icon,
			order = info.order,
		})
	end
	table.sort(categories, function(a, b)
		return a.order < b.order
	end)
	return categories
end

--------------------------------------------------------------------------------
-- Gathering API
--------------------------------------------------------------------------------

-- Get total count of gathered items (sum of all quantities)
function Journal:GetGatheringTotalCount()
	if not self.gathering then
		return 0
	end

	local total = 0
	for _itemID, data in pairs(self.gathering) do
		total = total + (data.count or 0)
	end
	return total
end

-- Get count of unique gathering item types
function Journal:GetGatheringUniqueCount()
	if not self.gathering then
		return 0
	end

	local count = 0
	for _ in pairs(self.gathering) do
		count = count + 1
	end
	return count
end

-- Get all gathering items, grouped by expansion
function Journal:GetGatheringByExpansion()
	if not self.gathering then
		return {}
	end

	local byExpansion = {}

	for itemID, data in pairs(self.gathering) do
		local expID = data.expansion or 0
		if not byExpansion[expID] then
			byExpansion[expID] = {}
		end
		table.insert(byExpansion[expID], {
			itemID = itemID,
			name = data.name,
			icon = data.icon,
			count = data.count,
			subclass = data.subclass,
			firstSeen = data.firstSeen,
			lastSeen = data.lastSeen,
		})
	end

	-- Sort items within each expansion by count (highest first)
	for _expID, items in pairs(byExpansion) do
		table.sort(items, function(a, b)
			return (a.count or 0) > (b.count or 0)
		end)
	end

	return byExpansion
end

-- Get ordered list of expansions that have gathering data (newest first)
function Journal:GetGatheringExpansions()
	local byExpansion = self:GetGatheringByExpansion()
	local expansions = {}

	for expID, items in pairs(byExpansion) do
		if #items > 0 then
			table.insert(expansions, {
				id = expID,
				name = self.EXPANSION_NAMES[expID] or ("Expansion " .. expID),
				itemCount = #items,
				totalCount = 0,
			})
			-- Sum total count for this expansion
			for _, item in ipairs(items) do
				expansions[#expansions].totalCount = expansions[#expansions].totalCount + (item.count or 0)
			end
		end
	end

	-- Sort by expansion ID (newest first)
	table.sort(expansions, function(a, b)
		return a.id > b.id
	end)

	return expansions
end

-- Get gathering items for a specific expansion
function Journal:GetGatheringForExpansion(expansionID)
	local byExpansion = self:GetGatheringByExpansion()
	return byExpansion[expansionID] or {}
end

--------------------------------------------------------------------------------
-- Auto-Initialize
--------------------------------------------------------------------------------

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, _event)
	-- Delay slightly to ensure Weekly is fully loaded
	C_Timer.After(0.5, function()
		if ns.Config and ns.Config.journal and ns.Config.journal.enabled then
			Journal:Initialize()
		end
	end)
	self:UnregisterAllEvents()
end)

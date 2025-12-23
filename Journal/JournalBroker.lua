-- JournalBroker.lua
-- LibDataBroker integration for Weekly Journal
-- Provides minimap button and broker display support

local _, ns = ...

local JournalBroker = {}
ns.JournalBroker = JournalBroker

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

-- Broker data object
local brokerObj = nil

--------------------------------------------------------------------------------
-- Broker Object
--------------------------------------------------------------------------------

function JournalBroker:Initialize()
	if not LDB then
		return
	end

	-- Create the broker data object
	brokerObj = LDB:NewDataObject("WeeklyJournal", {
		type = "launcher",
		icon = "Interface\\Icons\\INV_Misc_Book_09",
		label = "Weekly Journal",
		text = "Journal",

		OnClick = function(_, button)
			if button == "LeftButton" then
				-- Left click: Toggle journal window
				if ns.JournalUI then
					ns.JournalUI:Toggle()
				end
			elseif button == "RightButton" then
				-- Right click: Show context menu
				self:ShowContextMenu()
			end
		end,

		OnTooltipShow = function(tooltip)
			self:UpdateTooltip(tooltip)
		end,
	})

	-- Register with LibDBIcon for minimap button
	if LDBIcon then
		-- Use a separate saved variable key for the journal minimap icon
		if not WeeklyDB then
			WeeklyDB = {}
		end
		if not WeeklyDB.journalMinimapIcon then
			WeeklyDB.journalMinimapIcon = { hide = false }
		end

		LDBIcon:Register("WeeklyJournal", brokerObj, WeeklyDB.journalMinimapIcon)
	end
end

--------------------------------------------------------------------------------
-- Tooltip
--------------------------------------------------------------------------------

function JournalBroker:UpdateTooltip(tooltip)
	tooltip:AddLine("Weekly Journal", 1, 0.82, 0)
	tooltip:AddLine(" ")

	-- Show stats if journal is initialized
	if ns.Journal and ns.Journal.tracker then
		local totalCount = ns.Journal:GetTotalCount()
		local achievePoints = ns.Journal:GetAchievementPointsThisWeek()

		tooltip:AddDoubleLine("Items this week:", tostring(totalCount), 1, 1, 1, 0.2, 0.8, 0.2)

		if achievePoints > 0 then
			tooltip:AddDoubleLine("Achievement points:", tostring(achievePoints), 1, 1, 1, 1, 0.82, 0)
		end

		tooltip:AddLine(" ")

		-- Category breakdown (only non-zero)
		local categories = ns.Journal:GetOrderedCategories()
		local hasItems = false
		for _, cat in ipairs(categories) do
			local count = ns.Journal:GetCategoryCount(cat.key)
			if count > 0 then
				tooltip:AddDoubleLine(cat.name .. ":", tostring(count), 0.7, 0.7, 0.7, 0.2, 0.8, 0.2)
				hasItems = true
			end
		end

		if hasItems then
			tooltip:AddLine(" ")
		end
	else
		tooltip:AddLine("Journal not initialized", 0.5, 0.5, 0.5)
		tooltip:AddLine(" ")
	end

	tooltip:AddLine("|cff00ff00Left-click|r to toggle journal", 0.7, 0.7, 0.7)
	tooltip:AddLine("|cff00ff00Right-click|r for options", 0.7, 0.7, 0.7)
end

--------------------------------------------------------------------------------
-- Context Menu
--------------------------------------------------------------------------------

function JournalBroker:ShowContextMenu()
	-- Modern Menu API (Retail 11.0+)
	MenuUtil.CreateContextMenu(UIParent, function(owner, rootDescription)
		rootDescription:CreateTitle("Weekly")

		-- Weekly Tracker Section
		rootDescription:CreateCheckbox("Show Weekly", function()
			return ns.UI.frame and ns.UI.frame:IsShown()
		end, function()
			if ns.UI then
				ns.UI:Toggle()
			end
		end)

		rootDescription:CreateCheckbox("Lock Weekly", function()
			return ns.Config.locked
		end, function()
			ns.Config.locked = not ns.Config.locked
			if ns.UI then
				ns.UI:ApplyFrameStyle()
			end
		end)

		rootDescription:CreateDivider()

		-- Journal Section
		rootDescription:CreateCheckbox("Show Journal", function()
			return ns.JournalUI and ns.JournalUI:IsShown()
		end, function()
			if ns.JournalUI then
				ns.JournalUI:Toggle()
			end
		end)

		-- Add category quick-access submenu
		if ns.Journal and ns.Journal.tracker then
			local categories = ns.Journal:GetOrderedCategories()
			local submenu = rootDescription:CreateButton("Jump to Journal Category")

			for _, cat in ipairs(categories) do
				local count = ns.Journal:GetCategoryCount(cat.key)
				local catKey = cat.key
				submenu:CreateButton(string.format("%s (%d)", cat.name, count), function()
					if ns.JournalUI then
						ns.JournalUI:Show()
						ns.JournalUI:SelectTab(catKey)
					end
				end)
			end
		end

		rootDescription:CreateDivider()

		-- Settings & Minimap Section
		rootDescription:CreateButton("Settings", function()
			-- Open Weekly settings
			if ns.ConfigUI and ns.ConfigUI.categoryID then
				Settings.OpenToCategory(ns.ConfigUI.categoryID)
			else
				-- Last resort fallback
				Settings.OpenToCategory(Settings.GetCategory("Weekly"))
			end
		end)

		-- Add minimap icon toggle
		if LDBIcon then
			rootDescription:CreateCheckbox("Show Minimap Icon", function()
				return self:IsMinimapIconShown()
			end, function()
				if self:IsMinimapIconShown() then
					self:HideMinimapIcon()
				else
					self:ShowMinimapIcon()
				end
			end)
		end
	end)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- Show/hide minimap icon
function JournalBroker:ShowMinimapIcon()
	if LDBIcon then
		WeeklyDB.journalMinimapIcon.hide = false
		LDBIcon:Show("WeeklyJournal")
	end
end

function JournalBroker:HideMinimapIcon()
	if LDBIcon then
		WeeklyDB.journalMinimapIcon.hide = true
		LDBIcon:Hide("WeeklyJournal")
	end
end

function JournalBroker:IsMinimapIconShown()
	if LDBIcon then
		return not WeeklyDB.journalMinimapIcon.hide
	end
	return false
end

-- Update the broker text (e.g., show count)
function JournalBroker:UpdateText()
	if brokerObj and ns.Journal then
		local count = ns.Journal:GetTotalCount()
		if count > 0 then
			brokerObj.text = string.format("Journal (%d)", count)
		else
			brokerObj.text = "Journal"
		end
	end
end

--------------------------------------------------------------------------------
-- Auto-Initialize
--------------------------------------------------------------------------------

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
	-- Delay to ensure libs are loaded
	C_Timer.After(1, function()
		JournalBroker:Initialize()
	end)
	self:UnregisterAllEvents()
end)

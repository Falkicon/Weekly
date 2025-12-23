-- JournalUI.lua
-- Weekly Journal UI - Tabbed window with Dashboard and category views

local _, ns = ...

local JournalUI = {}
ns.JournalUI = JournalUI
local L = LibStub("AceLocale-3.0"):GetLocale("Weekly")

-- UI Constants (use FenUI layout tokens if available)
local function GetLayout(name, fallback)
	if FenUI and FenUI.GetLayout then
		local value = FenUI:GetLayout(name)
		if value > 0 then
			return value
		end
	end
	return fallback
end

local WINDOW_WIDTH = 620 -- Wide enough to fit all tabs comfortably
local WINDOW_HEIGHT = 500
local TAB_HEIGHT = GetLayout("tabHeight", 28)
local ROW_HEIGHT = GetLayout("rowHeight", 24)
local HEADER_HEIGHT = GetLayout("headerHeight", 24)
local FOOTER_HEIGHT = GetLayout("footerHeight", 32)
local PANEL_PADDING = GetLayout("marginPanel", 24)

-- Colors (use FenUI v2 tokens if available, fallback to local)
-- Uses GetColorTableRGB which returns {r, g, b} for safe use with unpack()
local function GetColor(token, fallback)
	if FenUI and FenUI.GetColorTableRGB then
		return FenUI:GetColorTableRGB(token)
	end
	return fallback
end

local C_GOLD = GetColor("textHeading", { 1, 0.82, 0 })
local C_WHITE = GetColor("textDefault", { 1, 1, 1 })
local C_GRAY = GetColor("textMuted", { 0.6, 0.6, 0.6 })
local C_GREEN = GetColor("feedbackSuccess", { 0.2, 0.8, 0.2 })
local C_HIGHLIGHT = { 0.3, 0.3, 0.4, 0.5 }

--------------------------------------------------------------------------------
-- Window Creation
--------------------------------------------------------------------------------

function JournalUI:CreateWindow()
	if self.frame then
		return self.frame
	end

	local frame

	-- Use FenUI v2 panel if available
	if FenUI and FenUI.CreatePanel then
		frame = FenUI:CreatePanel(UIParent, {
			name = "WeeklyJournalFrame",
			title = L["Weekly Journal"],
			width = WINDOW_WIDTH,
			height = WINDOW_HEIGHT,
			theme = FenUI:GetGlobalTheme(),
			movable = true,
			closable = true,
			-- Re-enable panel background with proper inset for chamfered corners
			background = "surfacePanel",
			onMoved = function()
				self:SavePosition()
			end,
		})
		frame:SetFrameStrata("HIGH")
		frame.useFenUI = true
	else
		-- Fallback to basic frame
		frame = CreateFrame("Frame", "WeeklyJournalFrame", UIParent, "BackdropTemplate")
		frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
		frame:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Buttons\\WHITE8X8",
			edgeSize = 1,
		})
		frame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
		frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", function()
			frame:StopMovingOrSizing()
			self:SavePosition()
		end)
		frame:SetClampedToScreen(true)
		frame:SetFrameStrata("HIGH")
	end

	frame:SetPoint("CENTER")

	-- Title (only if not using FenUI, which provides its own title)
	if not frame.useFenUI then
		frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		frame.title:SetPoint("TOPLEFT", 12, -10)
		frame.title:SetText(L["Weekly Journal"])
		frame.title:SetTextColor(unpack(C_GOLD))

		-- Close button (FenUI provides its own)
		frame.closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
		frame.closeBtn:SetPoint("TOPRIGHT", -2, -2)
	end

	-- Tab container (for internal tabs at top)
	frame.tabContainer = CreateFrame("Frame", nil, frame)
	if frame.safeZone then
		-- Anchor to systematic SafeZone
		frame.tabContainer:SetPoint("TOPLEFT", frame.safeZone, "TOPLEFT", 0, -HEADER_HEIGHT)
		frame.tabContainer:SetPoint("TOPRIGHT", frame.safeZone, "TOPRIGHT", 0, -HEADER_HEIGHT)
	else
		-- Fallback to manual padding
		frame.tabContainer:SetPoint("TOPLEFT", PANEL_PADDING, -HEADER_HEIGHT)
		frame.tabContainer:SetPoint("TOPRIGHT", -PANEL_PADDING, -HEADER_HEIGHT)
	end
	frame.tabContainer:SetHeight(TAB_HEIGHT)

	-- Content container with scroll (use FenUI if available)
	-- NOTE: Systematic Spacing Refactor
	-- We now anchor to the tabContainer or SafeZone to ensure consistency.
	local footerH = GetLayout("footerHeight", 32)

	if FenUI and FenUI.CreateScrollInset then
		-- Use FenUI's combined inset+scroll widget with background
		-- NOTE: Using solid color instead of gradient for reliability
		frame.contentContainer, frame.scrollChild = FenUI:CreateScrollInset(frame, {
			-- padding = 0 since we are anchoring to SafeZone/Tabs which already have margins
			padding = 0,
			alpha = 0.95,
			-- Let CreateInset use its default surfaceInset background
			-- (gradient was not rendering reliably)
		})

		-- Position the content inset relative to tabs and footer
		frame.contentContainer:ClearAllPoints()
		frame.contentContainer:SetPoint("TOPLEFT", frame.tabContainer, "BOTTOMLEFT", 0, -4)
		if frame.safeZone then
			frame.contentContainer:SetPoint("BOTTOMRIGHT", frame.safeZone, "BOTTOMRIGHT", 0, footerH)
		else
			frame.contentContainer:SetPoint("BOTTOMRIGHT", -PANEL_PADDING, footerH + 8)
		end

		frame.scrollFrame = frame.contentContainer.scrollPanel.scrollFrame
	else
		-- Fallback to manual creation
		frame.contentContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
		frame.contentContainer:SetPoint("TOPLEFT", frame.tabContainer, "BOTTOMLEFT", 0, -4)
		if frame.safeZone then
			frame.contentContainer:SetPoint("BOTTOMRIGHT", frame.safeZone, "BOTTOMRIGHT", 0, footerH)
		else
			frame.contentContainer:SetPoint("BOTTOMRIGHT", -PANEL_PADDING, footerH + 8)
		end

		frame.contentContainer:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Buttons\\WHITE8X8",
			edgeSize = 1,
			insets = { left = 1, right = 1, top = 1, bottom = 1 },
		})
		frame.contentContainer:SetBackdropColor(0.06, 0.06, 0.06, 0.95)
		frame.contentContainer:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

		frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame.contentContainer, "UIPanelScrollFrameTemplate")
		frame.scrollFrame:SetPoint("TOPLEFT", 5, -5)
		frame.scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

		frame.scrollChild = CreateFrame("Frame", nil, frame.scrollFrame)
		frame.scrollChild:SetSize(WINDOW_WIDTH - 60, 1)
		frame.scrollFrame:SetScrollChild(frame.scrollChild)
	end

	-- Footer Layout (refactored to use a systematic layout component)
	-- This handles the left-aligned buttons and right-aligned text in a single robust unit.
	if FenUI and FenUI.CreateLayout then
		local footerH = GetLayout("footerHeight", 32)

		-- Create a horizontal 2-column layout for the footer
		-- NOTE: We use 1fr/1fr to give both sides equal space, then justify content within.
		self.footerLayout = FenUI:CreateLayout(frame, {
			name = "WeeklyJournalFooter",
			cols = { "1fr", "1fr" },
			padding = "sm", -- 8px internal padding
			gap = 10,
		})

		-- Position the footer layout precisely within the frame's bottom area
		-- NOTE: We anchor via the systematic slot if available.
		if frame.SetSlot then
			frame:SetSlot("footer", self.footerLayout)
			self.footerLayout:SetHeight(footerH)
		else
			local margin = GetLayout("marginPanel", 24)
			self.footerLayout:SetPoint("BOTTOMLEFT", margin, 8)
			self.footerLayout:SetPoint("BOTTOMRIGHT", -margin, 8)
			self.footerLayout:SetHeight(footerH)
		end

		-- LEFT CELL: Buttons
		local leftCell = self.footerLayout:GetCell(1)

		-- Clear Tab button
		frame.clearTabBtn = CreateFrame("Button", nil, leftCell, "UIPanelButtonTemplate")
		frame.clearTabBtn:SetSize(90, 22)
		frame.clearTabBtn:SetPoint("LEFT", 0, 0)
		frame.clearTabBtn:SetText(L["Clear Tab"])
		frame.clearTabBtn:SetScript("OnClick", function()
			self:OnClearTabClicked()
		end)

		-- Clear All button
		frame.clearAllBtn = CreateFrame("Button", nil, leftCell, "UIPanelButtonTemplate")
		frame.clearAllBtn:SetSize(90, 22)
		frame.clearAllBtn:SetPoint("LEFT", frame.clearTabBtn, "RIGHT", 10, 0)
		frame.clearAllBtn:SetText(L["Clear All"])
		frame.clearAllBtn:SetScript("OnClick", function()
			self:OnClearAllClicked()
		end)

		-- RIGHT CELL: Week Label
		local rightCell = self.footerLayout:GetCell(2)
		frame.weekLabel = rightCell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		frame.weekLabel:SetPoint("RIGHT", 0, 0) -- Right-justified in the right cell
		frame.weekLabel:SetTextColor(unpack(C_GRAY))
	elseif FenUI and FenUI.CreateToolbar then
		-- (Existing Toolbar fallback - kept just in case but we prefer the new layout)
		self.footerToolbar = FenUI:CreateToolbar(frame, {
			height = FOOTER_HEIGHT - 10,
			padding = { left = 4, right = 12 },
			gap = 8,
		})
		local footerX = PANEL_PADDING + 4
		local footerY = 22
		self.footerToolbar:SetPoint("BOTTOMLEFT", footerX, footerY)
		self.footerToolbar:SetPoint("BOTTOMRIGHT", -footerX, footerY)
		-- ... rest of toolbar code ...
	else
		-- Manual fallback
		local footerPadding = PANEL_PADDING + 4
		frame.footer = CreateFrame("Frame", nil, frame)
		frame.footer:SetPoint("BOTTOMLEFT", footerPadding, footerPadding)
		frame.footer:SetPoint("BOTTOMRIGHT", -footerPadding, footerPadding)
		frame.footer:SetHeight(FOOTER_HEIGHT - 10)
		-- ... rest of manual fallback ...
	end

	frame:Hide()
	self.frame = frame
	self.tabs = {}
	self.currentTab = nil

	-- Initialize Grid for items
	if FenUI and FenUI.CreateGrid then
		self.itemGrid = FenUI:CreateGrid(frame.scrollChild, {
			columns = { "auto", "1fr", "auto" }, -- icon | name | extra
			rowHeight = ROW_HEIGHT,
			onRowBind = function(row, item, index)
				-- Icon
				row:GetCell(1):SetIcon(item.data and item.data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

				-- Name
				local name = item.data and item.data.name or ("ID: " .. (item.id or "unknown"))
				row:GetCell(2):SetText(name)

				-- Extra (timestamp)
				local timeStr = self:FormatTimestamp(item.data and item.data.firstSeen)
				row:GetCell(3):SetText(timeStr, "fontSmall")
				row:GetCell(3).fontString:SetTextColor(unpack(C_GRAY))

				-- Tooltip and Click
				row.tooltipFunc = function()
					GameTooltip:SetText(name, unpack(C_GOLD))
					if item.category == "achievement" and item.data.points then
						GameTooltip:AddLine(item.data.points .. " points", unpack(C_GOLD))
					end
					if item.data.zoneName then
						GameTooltip:AddLine(L["Found in: %s"]:format(item.data.zoneName), unpack(C_GRAY))
					end
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine(L["Click to view in Collections"], 0.5, 0.5, 0.5)
					GameTooltip:Show()
				end

				row.clickFunc = function()
					ns.Journal:OpenOfficialUI(item.category, item.id, item.data)
				end
			end,
		})
		self.itemGrid:SetPoint("TOPLEFT")
		self.itemGrid:SetPoint("TOPRIGHT")
	end

	-- Initialize EmptyState (use FenUI if available)
	if FenUI and FenUI.CreateEmptyState then
		self.emptyState = FenUI:CreateEmptyState(frame.contentContainer, {
			-- Faction-conditional chest image
			image = {
				condition = "faction",
				variants = {
					Horde = "Interface\\AddOns\\Weekly\\assets\\weekly_empty_horde.png",
					Alliance = "Interface\\AddOns\\Weekly\\assets\\weekly_empty_alliance.png",
				},
				fallback = "Interface\\Icons\\INV_Misc_Book_09",
				width = 120,
				height = 120,
			},
			title = L["No items collected"],
			subtitle = L["Items will appear here as you collect them this week"],
			gap = 20,
		})
		self.emptyState:Hide()
	end

	-- Row pool for non-grid elements (Dashboard)
	self.rowPool = {}

	-- Create tabs
	self:CreateTabs()

	-- Restore position
	self:RestorePosition()

	return frame
end

--------------------------------------------------------------------------------
-- Tab Management
--------------------------------------------------------------------------------

function JournalUI:CreateTabs()
	local frame = self.frame
	if not frame then
		return
	end

	-- Build tab definitions
	local tabDefs = {
		{ key = "dashboard", text = L["Dashboard"], icon = "Interface\\Icons\\INV_Misc_Book_09" },
	}

	-- Add category tabs
	local categories = ns.Journal:GetOrderedCategories()
	for _, cat in ipairs(categories) do
		table.insert(tabDefs, {
			key = cat.key,
			text = cat.name,
			icon = cat.icon,
		})
	end

	-- Add Gathering tab last
	table.insert(tabDefs, {
		key = "gathering",
		text = L["Gathering"],
		icon = ns.Journal.GATHERING_CATEGORY.icon,
	})

	-- Use FenUI v2 tab group if available
	if FenUI and FenUI.CreateTabGroup then
		-- Convert tabDefs to FenUI v2 format
		local fenUITabs = {}
		for _, def in ipairs(tabDefs) do
			table.insert(fenUITabs, { key = def.key, text = def.text, icon = def.icon })
		end

		self.tabGroup = FenUI:CreateTabGroup(frame.tabContainer, {
			tabs = fenUITabs,
			onChange = function(key)
				self:OnTabSelected(key)
			end,
		})
		self.tabGroup:SetPoint("TOPLEFT")
		self.tabGroup:SetPoint("TOPRIGHT")

		-- Store references for badge updates
		local tabs = self.tabGroup:GetTabs()
		for key, tab in pairs(tabs) do
			self.tabs[key] = tab
		end
	else
		-- Fallback to basic tabs
		local xOffset = 0
		for i, tabInfo in ipairs(tabDefs) do
			local tab = self:CreateTab(tabInfo.key, tabInfo.text, tabInfo.icon)
			tab:SetPoint("LEFT", frame.tabContainer, "LEFT", xOffset, 0)
			xOffset = xOffset + tab:GetWidth() + 2
			self.tabs[tabInfo.key] = tab
		end
	end

	-- Select default tab
	local savedTab = ns.Config.journal and ns.Config.journal.selectedTab or "dashboard"
	self:SelectTab(savedTab)
end

-- Called when a FenUI tab is clicked
function JournalUI:OnTabSelected(key)
	self.currentTab = key

	-- Save selection
	if ns.Config.journal then
		ns.Config.journal.selectedTab = key
	end

	-- Update clear button state
	if key == "dashboard" then
		self.frame.clearTabBtn:Disable()
	else
		self.frame.clearTabBtn:Enable()
	end

	-- Render content
	self:RenderCurrentTab()
end

function JournalUI:CreateTab(key, name, icon)
	local tab = CreateFrame("Button", nil, self.frame.tabContainer, "BackdropTemplate")
	tab:SetSize(70, TAB_HEIGHT - 4)
	tab:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	tab:SetBackdropColor(0.15, 0.15, 0.15, 1)
	tab:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

	-- Icon
	tab.icon = tab:CreateTexture(nil, "ARTWORK")
	tab.icon:SetSize(16, 16)
	tab.icon:SetPoint("LEFT", 4, 0)
	tab.icon:SetTexture(icon)

	-- Text
	tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	tab.text:SetPoint("LEFT", tab.icon, "RIGHT", 3, 0)
	tab.text:SetPoint("RIGHT", -4, 0)
	tab.text:SetText(name)
	tab.text:SetJustifyH("LEFT")

	-- Count badge (for category tabs)
	tab.countBadge = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	tab.countBadge:SetPoint("RIGHT", -4, 0)
	tab.countBadge:SetTextColor(unpack(C_GREEN))
	tab.countBadge:Hide()

	tab.key = key

	-- Click handler
	tab:SetScript("OnClick", function()
		self:SelectTab(key)
	end)

	-- Hover highlight
	tab:SetScript("OnEnter", function()
		if self.currentTab ~= key then
			tab:SetBackdropColor(0.2, 0.2, 0.2, 1)
		end
	end)
	tab:SetScript("OnLeave", function()
		if self.currentTab ~= key then
			tab:SetBackdropColor(0.15, 0.15, 0.15, 1)
		end
	end)

	return tab
end

function JournalUI:SelectTab(key)
	-- Use FenUI v2 tab group if available
	if self.tabGroup and self.tabGroup.Select then
		self.tabGroup:Select(key)
		return
	end

	-- Fallback: Update visual state for basic tabs
	for tabKey, tab in pairs(self.tabs) do
		if tabKey == key then
			tab:SetBackdropColor(0.25, 0.25, 0.3, 1)
			tab:SetBackdropBorderColor(0.5, 0.5, 0.6, 1)
		else
			tab:SetBackdropColor(0.15, 0.15, 0.15, 1)
			tab:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
		end
	end

	self.currentTab = key

	-- Save selection
	if ns.Config.journal then
		ns.Config.journal.selectedTab = key
	end

	-- Update clear button state
	if key == "dashboard" then
		self.frame.clearTabBtn:Disable()
	else
		self.frame.clearTabBtn:Enable()
	end

	-- Render content
	self:RenderCurrentTab()
end

function JournalUI:RefreshCurrentTab()
	if self.frame and self.frame:IsShown() then
		self:UpdateTabBadges()
		self:RenderCurrentTab()
	end
end

function JournalUI:UpdateTabBadges()
	for key, tab in pairs(self.tabs) do
		if key ~= "dashboard" then
			local count
			if key == "gathering" then
				count = ns.Journal:GetGatheringUniqueCount()
			else
				count = ns.Journal:GetCategoryCount(key)
			end

			-- Use FenUI SetBadge if available
			if tab.SetBadge then
				tab:SetBadge(count > 0 and tostring(count) or nil)
			elseif tab.countBadge then
				-- Fallback for basic tabs
				if count > 0 then
					tab.countBadge:SetText(count)
					tab.countBadge:Show()
					tab.text:SetPoint("RIGHT", tab.countBadge, "LEFT", -2, 0)
				else
					tab.countBadge:Hide()
					tab.text:SetPoint("RIGHT", -4, 0)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Content Rendering
--------------------------------------------------------------------------------

function JournalUI:RenderCurrentTab()
	if not self.frame then
		return
	end

	-- Clear existing content
	self:ClearContent()

	-- Update week label
	self:UpdateWeekLabel()

	-- Render based on current tab
	if self.currentTab == "dashboard" then
		self:RenderDashboard()
	elseif self.currentTab == "gathering" then
		self:RenderGatheringTab()
	else
		self:RenderCategoryTab(self.currentTab)
	end
end

function JournalUI:ClearContent()
	-- Hide all rows in the manual pool
	for _, row in ipairs(self.rowPool) do
		row:Hide()
	end

	-- NOTE: Systematic Cleanup
	-- When switching tabs, we must hide all persistent widgets
	-- so they don't overlap with the new tab's content.
	if self.itemGrid then
		self.itemGrid:Hide()
	end
	if self.emptyState then
		self.emptyState:Hide()
	end
end

function JournalUI:GetRow(index)
	if self.rowPool[index] then
		return self.rowPool[index]
	end

	local row = CreateFrame("Frame", nil, self.frame.scrollChild)
	row:SetHeight(ROW_HEIGHT)
	row:EnableMouse(true)

	-- Highlight
	row.highlight = row:CreateTexture(nil, "BACKGROUND")
	row.highlight:SetAllPoints()
	row.highlight:SetColorTexture(unpack(C_HIGHLIGHT))
	row.highlight:Hide()

	-- Icon
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(20, 20)
	row.icon:SetPoint("LEFT", 4, 0)

	-- Name
	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
	row.name:SetPoint("RIGHT", -80, 0)
	row.name:SetJustifyH("LEFT")

	-- Extra info (timestamp, points, etc.)
	row.extra = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.extra:SetPoint("RIGHT", -4, 0)
	row.extra:SetTextColor(unpack(C_GRAY))

	-- Hover handlers
	row:SetScript("OnEnter", function()
		row.highlight:Show()
		GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
		if row.tooltipFunc then
			row.tooltipFunc(row)
		end
	end)
	row:SetScript("OnLeave", function()
		row.highlight:Hide()
		GameTooltip:Hide()
	end)

	-- Click handler
	row:SetScript("OnMouseUp", function(_, button)
		if button == "LeftButton" and row.clickFunc then
			row.clickFunc(row)
		end
	end)

	self.rowPool[index] = row
	return row
end

function JournalUI:UpdateWeekLabel()
	if not self.frame then
		return
	end

	-- Get current week number (approximate)
	local date = C_DateAndTime.GetCurrentCalendarTime()
	local weekNum = math.floor(date.monthDay / 7) + 1
	local monthName = CALENDAR_FULLDATE_MONTH_NAMES[date.month] or date.month

	self.frame.weekLabel:SetText(L["Week of %s %d"]:format(monthName, math.floor((date.monthDay - 1) / 7) * 7 + 1))
end

--------------------------------------------------------------------------------
-- Dashboard Tab
--------------------------------------------------------------------------------

function JournalUI:RenderDashboard()
	local scrollChild = self.frame.scrollChild
	local yOffset = 0
	local rowIndex = 1

	-- Header: "This Week's Collection"
	local headerRow = self:GetRow(rowIndex)
	headerRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
	headerRow:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
	headerRow.icon:Hide()
	headerRow.name:SetPoint("LEFT", 4, 0)
	headerRow.name:SetText(L["This Week's Collection"])
	headerRow.name:SetFontObject("GameFontNormalLarge")
	headerRow.name:SetTextColor(unpack(C_GOLD))
	headerRow.extra:SetText("")
	headerRow.tooltipFunc = nil
	headerRow.clickFunc = nil
	headerRow:Show()

	rowIndex = rowIndex + 1
	yOffset = yOffset + ROW_HEIGHT + 10

	-- Total count
	local totalCount = ns.Journal:GetTotalCount()
	local totalRow = self:GetRow(rowIndex)
	totalRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
	totalRow:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
	totalRow.icon:SetTexture("Interface\\Icons\\Achievement_GuildPerk_BountifulBags")
	totalRow.icon:Show()
	totalRow.name:SetPoint("LEFT", totalRow.icon, "RIGHT", 6, 0)
	totalRow.name:SetText(L["Total Items"])
	totalRow.name:SetFontObject("GameFontNormal")
	totalRow.name:SetTextColor(unpack(C_WHITE))
	totalRow.extra:SetText(tostring(totalCount))
	totalRow.extra:SetTextColor(unpack(C_GREEN))
	totalRow.tooltipFunc = nil
	totalRow.clickFunc = nil
	totalRow:Show()

	rowIndex = rowIndex + 1
	yOffset = yOffset + ROW_HEIGHT

	-- Achievement points
	local achievePoints = ns.Journal:GetAchievementPointsThisWeek()
	local pointsRow = self:GetRow(rowIndex)
	pointsRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
	pointsRow:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
	pointsRow.icon:SetTexture("Interface\\Icons\\Achievement_Level_10")
	pointsRow.icon:Show()
	pointsRow.name:SetPoint("LEFT", pointsRow.icon, "RIGHT", 6, 0)
	pointsRow.name:SetText(L["Achievement Points"])
	pointsRow.name:SetFontObject("GameFontNormal")
	pointsRow.name:SetTextColor(unpack(C_WHITE))
	pointsRow.extra:SetText(tostring(achievePoints))
	pointsRow.extra:SetTextColor(unpack(C_GOLD))
	pointsRow.tooltipFunc = nil
	pointsRow.clickFunc = nil
	pointsRow:Show()

	rowIndex = rowIndex + 1
	yOffset = yOffset + ROW_HEIGHT + 15

	-- Divider: "By Category"
	local dividerRow = self:GetRow(rowIndex)
	dividerRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
	dividerRow:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
	dividerRow.icon:Hide()
	dividerRow.name:SetPoint("LEFT", 4, 0)
	dividerRow.name:SetText(L["By Category"])
	dividerRow.name:SetFontObject("GameFontNormal")
	dividerRow.name:SetTextColor(unpack(C_GRAY))
	dividerRow.extra:SetText("")
	dividerRow.tooltipFunc = nil
	dividerRow.clickFunc = nil
	dividerRow:Show()

	rowIndex = rowIndex + 1
	yOffset = yOffset + ROW_HEIGHT + 5

	-- Category breakdown
	local categories = ns.Journal:GetOrderedCategories()
	for _, cat in ipairs(categories) do
		local count = ns.Journal:GetCategoryCount(cat.key)

		local catRow = self:GetRow(rowIndex)
		catRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
		catRow:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
		catRow.icon:SetTexture(cat.icon)
		catRow.icon:Show()
		catRow.name:SetPoint("LEFT", catRow.icon, "RIGHT", 6, 0)
		catRow.name:SetText(cat.name)
		catRow.name:SetFontObject("GameFontNormal")
		catRow.name:SetTextColor(unpack(C_WHITE))
		catRow.extra:SetText(tostring(count))
		catRow.extra:SetTextColor(unpack(count > 0 and C_GREEN or C_GRAY))

		-- Click to go to that tab
		local catKey = cat.key
		catRow.clickFunc = function()
			self:SelectTab(catKey)
		end
		catRow.tooltipFunc = function(row)
			GameTooltip:SetText(cat.name, unpack(C_GOLD))
			GameTooltip:AddLine(L["Click to view %s"]:format(cat.name), unpack(C_GRAY))
			GameTooltip:Show()
		end
		catRow:Show()

		rowIndex = rowIndex + 1
		yOffset = yOffset + ROW_HEIGHT
	end

	-- Gathering summary
	yOffset = yOffset + 10
	local gatheringDivider = self:GetRow(rowIndex)
	gatheringDivider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
	gatheringDivider:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
	gatheringDivider.icon:Hide()
	gatheringDivider.name:SetPoint("LEFT", 4, 0)
	gatheringDivider.name:SetText(L["Gathering"])
	gatheringDivider.name:SetFontObject("GameFontNormal")
	gatheringDivider.name:SetTextColor(unpack(C_GRAY))
	gatheringDivider.extra:SetText("")
	gatheringDivider.tooltipFunc = nil
	gatheringDivider.clickFunc = nil
	gatheringDivider:Show()

	rowIndex = rowIndex + 1
	yOffset = yOffset + ROW_HEIGHT + 5

	local gatheringTotal = ns.Journal:GetGatheringTotalCount()
	local gatheringUnique = ns.Journal:GetGatheringUniqueCount()

	local gatheringRow = self:GetRow(rowIndex)
	gatheringRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
	gatheringRow:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
	gatheringRow.icon:SetTexture(ns.Journal.GATHERING_CATEGORY.icon)
	gatheringRow.icon:Show()
	gatheringRow.name:SetPoint("LEFT", gatheringRow.icon, "RIGHT", 6, 0)
	gatheringRow.name:SetText(L["Materials Gathered"])
	gatheringRow.name:SetFontObject("GameFontNormal")
	gatheringRow.name:SetTextColor(unpack(C_WHITE))
	gatheringRow.extra:SetText(L["%d (%d types)"]:format(gatheringTotal, gatheringUnique))
	gatheringRow.extra:SetTextColor(unpack(gatheringTotal > 0 and C_GREEN or C_GRAY))

	gatheringRow.clickFunc = function()
		self:SelectTab("gathering")
	end
	gatheringRow.tooltipFunc = function(row)
		GameTooltip:SetText(L["Gathering"], unpack(C_GOLD))
		GameTooltip:AddLine(L["%d (%d types)"]:format(gatheringTotal, gatheringUnique), unpack(C_WHITE))
		GameTooltip:AddLine(L["Click to view %s"]:format(L["Gathering"]), unpack(C_GRAY))
		GameTooltip:Show()
	end
	gatheringRow:Show()

	rowIndex = rowIndex + 1
	yOffset = yOffset + ROW_HEIGHT

	-- Update scroll child height
	scrollChild:SetHeight(yOffset + 10)
end

--------------------------------------------------------------------------------
-- Category Tabs
--------------------------------------------------------------------------------

function JournalUI:RenderCategoryTab(category)
	local items = ns.Journal:GetCategoryItems(category)

	-- Hide both by default
	if self.itemGrid then
		self.itemGrid:Hide()
	end
	if self.emptyState then
		self.emptyState:Hide()
	end
	self:ClearContent()

	if #items == 0 then
		-- Use FenUI EmptyState if available
		if self.emptyState then
			-- Reset text in case it was changed by Gathering tab
			self.emptyState:SetTitle(L["No items collected"])
			self.emptyState:SetSubtitle(L["Items will appear here as you collect them this week"])
			self.emptyState:Show()
		else
			-- Fallback to row pool
			local emptyRow = self:GetRow(1)
			emptyRow:SetPoint("TOPLEFT", self.frame.scrollChild, "TOPLEFT", 0, -20)
			emptyRow:SetPoint("RIGHT", self.frame.scrollChild, "RIGHT", 0, 0)
			emptyRow.icon:Hide()
			emptyRow.name:SetPoint("LEFT", 4, 0)
			emptyRow.name:SetText(L["No items collected this week"])
			emptyRow.name:SetFontObject("GameFontNormal")
			emptyRow.name:SetTextColor(unpack(C_GRAY))
			emptyRow.extra:SetText("")
			emptyRow.tooltipFunc = nil
			emptyRow.clickFunc = nil
			emptyRow:Show()
		end

		self.frame.scrollChild:SetHeight(60)
		return
	end

	-- Update Grid
	if self.itemGrid then
		self.itemGrid:Show()
		self.itemGrid:SetData(items)
		self.frame.scrollChild:SetHeight(self.itemGrid:GetHeight() + 10)
	end
end

function JournalUI:FormatTimestamp(timestamp)
	if not timestamp then
		return ""
	end

	local now = time()
	local diff = now - timestamp

	-- Today
	if diff < 86400 then
		return date("Today %H:%M", timestamp)
	end
	-- Yesterday
	if diff < 172800 then
		return date("Yesterday %H:%M", timestamp)
	end
	-- This week
	if diff < 604800 then
		return date("%a %H:%M", timestamp)
	end
	-- Older
	return date("%m/%d %H:%M", timestamp)
end

--------------------------------------------------------------------------------
-- Gathering Tab
--------------------------------------------------------------------------------

function JournalUI:RenderGatheringTab()
	local scrollChild = self.frame.scrollChild
	local expansions = ns.Journal:GetGatheringExpansions()

	-- Hide persistent widgets
	if self.itemGrid then
		self.itemGrid:Hide()
	end
	if self.emptyState then
		self.emptyState:Hide()
	end
	self:ClearContent()

	if #expansions == 0 then
		-- Use FenUI EmptyState if available
		if self.emptyState then
			self.emptyState:SetTitle(L["No materials gathered"])
			self.emptyState:SetSubtitle(L["Items will appear here as you gather them this week"])
			self.emptyState:Show()
		else
			-- Fallback
			local emptyRow = self:GetRow(1)
			emptyRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -20)
			emptyRow:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
			emptyRow.icon:Hide()
			emptyRow.name:SetPoint("LEFT", 4, 0)
			emptyRow.name:SetText(L["No materials gathered this week"])
			emptyRow.name:SetFontObject("GameFontNormal")
			emptyRow.name:SetTextColor(unpack(C_GRAY))
			emptyRow.extra:SetText("")
			emptyRow.tooltipFunc = nil
			emptyRow.clickFunc = nil
			emptyRow:Show()
		end

		scrollChild:SetHeight(60)
		return
	end

	local yOffset = 5
	local rowIndex = 1

	for _, expData in ipairs(expansions) do
		-- Expansion header
		local headerRow = self:GetRow(rowIndex)
		headerRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
		headerRow:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
		headerRow.icon:Hide()
		headerRow.name:SetPoint("LEFT", 4, 0)
		headerRow.name:SetText(expData.name)
		headerRow.name:SetFontObject("GameFontNormalLarge")
		headerRow.name:SetTextColor(unpack(C_GOLD))
		headerRow.extra:SetText(L["%d items"]:format(expData.totalCount))
		headerRow.extra:SetTextColor(unpack(C_GRAY))
		headerRow.tooltipFunc = nil
		headerRow.clickFunc = nil
		headerRow:Show()

		rowIndex = rowIndex + 1
		yOffset = yOffset + ROW_HEIGHT + 2

		-- Items for this expansion
		local items = ns.Journal:GetGatheringForExpansion(expData.id)
		for _, item in ipairs(items) do
			local row = self:GetRow(rowIndex)
			row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
			row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

			-- Icon
			if item.icon then
				row.icon:SetTexture(item.icon)
				row.icon:Show()
			else
				row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				row.icon:Show()
			end

			-- Name (indented)
			row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
			row.name:SetText(item.name or (L["Item %s"]:format(item.itemID)))
			row.name:SetFontObject("GameFontNormal")
			row.name:SetTextColor(unpack(C_WHITE))

			-- Count
			row.extra:SetText(L["x %d"]:format(item.count))
			row.extra:SetTextColor(unpack(C_GREEN))

			-- Tooltip
			local itemID = item.itemID
			local itemData = item
			row.tooltipFunc = function(r)
				GameTooltip:SetItemByID(itemID)
			end

			-- No click action for gathering items (could add shift-click to link)
			row.clickFunc = nil

			row:Show()

			rowIndex = rowIndex + 1
			yOffset = yOffset + ROW_HEIGHT
		end

		-- Small gap after each expansion
		yOffset = yOffset + 8
	end

	scrollChild:SetHeight(yOffset + 10)
end

--------------------------------------------------------------------------------
-- Button Handlers
--------------------------------------------------------------------------------

function JournalUI:OnClearTabClicked()
	if self.currentTab == "dashboard" then
		return
	end

	-- Confirmation dialog
	StaticPopupDialogs["WEEKLY_JOURNAL_CLEAR_TAB"] = {
		text = L["Clear all %s from this week's journal?"],
		button1 = L["Clear"],
		button2 = CANCEL,
		OnAccept = function()
			ns.Journal:ClearCategory(self.currentTab)
			self:RefreshCurrentTab()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	local categoryName
	if self.currentTab == "gathering" then
		categoryName = ns.Journal.GATHERING_CATEGORY.name
	else
		local categoryInfo = ns.Journal.CATEGORIES[self.currentTab]
		categoryName = categoryInfo and categoryInfo.name or self.currentTab
	end
	StaticPopup_Show("WEEKLY_JOURNAL_CLEAR_TAB", categoryName)
end

function JournalUI:OnClearAllClicked()
	StaticPopupDialogs["WEEKLY_JOURNAL_CLEAR_ALL"] = {
		text = L["Clear ALL items from this week's journal?"],
		button1 = L["Clear All"],
		button2 = CANCEL,
		OnAccept = function()
			ns.Journal:ClearAll()
			self:RefreshCurrentTab()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopup_Show("WEEKLY_JOURNAL_CLEAR_ALL")
end

--------------------------------------------------------------------------------
-- Position Management
--------------------------------------------------------------------------------

function JournalUI:SavePosition()
	if not self.frame then
		return
	end
	if not ns.Config.journal then
		return
	end

	local point, _, relativePoint, xOfs, yOfs = self.frame:GetPoint()
	ns.Config.journal.windowPosition = {
		point = point,
		relativePoint = relativePoint,
		xOfs = xOfs,
		yOfs = yOfs,
	}
end

function JournalUI:RestorePosition()
	if not self.frame then
		return
	end
	if not ns.Config.journal then
		return
	end

	local pos = ns.Config.journal.windowPosition
	if pos then
		self.frame:ClearAllPoints()
		self.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
	end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function JournalUI:Toggle()
	if not self.frame then
		self:CreateWindow()
	end

	if self.frame:IsShown() then
		self.frame:Hide()
	else
		self:RefreshCurrentTab()
		self.frame:Show()
	end
end

function JournalUI:Show()
	if not self.frame then
		self:CreateWindow()
	end

	self:RefreshCurrentTab()
	self.frame:Show()
end

function JournalUI:Hide()
	if self.frame then
		self.frame:Hide()
	end
end

function JournalUI:IsShown()
	return self.frame and self.frame:IsShown()
end

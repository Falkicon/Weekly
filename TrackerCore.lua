-- TrackerCore.lua
-- Shared tracking infrastructure for Discovery Tool and Weekly Journal
-- Provides: event registration, deduplication, timestamping, UI base, export

local _, ns = ...

local TrackerCore = {}
ns.TrackerCore = TrackerCore

--------------------------------------------------------------------------------
-- Tracker Factory
--------------------------------------------------------------------------------

--- Create a new tracker instance
-- @param name string: Unique name for this tracker (e.g., "Discovery", "WeeklyJournal")
-- @param config table: Configuration options
-- @return table: Tracker instance
function TrackerCore:CreateTracker(name, config)
	config = config or {}

	local tracker = {
		name = name,
		items = {}, -- [category] = { [id] = itemData }
		itemCount = 0,
		events = {},
		frame = nil,
		config = {
			persistent = config.persistent or false, -- Save across sessions?
			onItemLogged = config.onItemLogged, -- Callback when item logged
		},
	}

	-- Methods
	setmetatable(tracker, { __index = self })

	return tracker
end

--------------------------------------------------------------------------------
-- Event Management
--------------------------------------------------------------------------------

--- Register events for this tracker
-- @param eventTable table: { EVENT_NAME = handlerFunction, ... }
function TrackerCore:RegisterEvents(eventTable)
	if not self.eventFrame then
		self.eventFrame = CreateFrame("Frame")
		self.eventFrame:SetScript("OnEvent", function(_, event, ...)
			if self.events[event] then
				self.events[event](self, event, ...)
			end
		end)
	end

	for event, handler in pairs(eventTable) do
		self.events[event] = handler
		self.eventFrame:RegisterEvent(event)
	end
end

--- Unregister all events
function TrackerCore:UnregisterEvents()
	if self.eventFrame then
		self.eventFrame:UnregisterAllEvents()
	end
	self.events = {}
end

--------------------------------------------------------------------------------
-- Item Logging
--------------------------------------------------------------------------------

--- Log an item (with deduplication)
-- @param category string: Category (e.g., "currency", "quest", "mount")
-- @param id number: Item ID
-- @param data table: Item data (name, icon, expansion, etc.)
-- @return boolean: true if newly logged, false if duplicate
function TrackerCore:LogItem(category, id, data)
	if not category or not id then
		return false
	end

	-- Initialize category
	if not self.items[category] then
		self.items[category] = {}
	end

	-- Check for duplicate
	if self.items[category][id] then
		return false
	end

	-- Add timestamp and store
	data = data or {}
	data.id = id
	data.category = category
	data.firstSeen = time()
	data.firstSeenFormatted = date("%Y-%m-%d %H:%M:%S")

	self.items[category][id] = data
	self.itemCount = self.itemCount + 1

	-- Callback
	if self.config.onItemLogged then
		self.config.onItemLogged(self, category, id, data)
	end

	return true
end

--- Check if an item is already logged
-- @param category string: Category
-- @param id number: Item ID
-- @return boolean
function TrackerCore:IsLogged(category, id)
	return self.items[category] and self.items[category][id] ~= nil
end

--- Get logged item data
-- @param category string: Category
-- @param id number: Item ID
-- @return table or nil
function TrackerCore:GetItem(category, id)
	if self.items[category] then
		return self.items[category][id]
	end
	return nil
end

--- Get all items, optionally filtered
-- @param filterFunc function: Optional filter(category, id, data) -> boolean
-- @return table: Array of { category, id, data }
function TrackerCore:GetItems(filterFunc)
	local results = {}

	for category, items in pairs(self.items) do
		for id, data in pairs(items) do
			if not filterFunc or filterFunc(category, id, data) then
				table.insert(results, {
					category = category,
					id = id,
					data = data,
				})
			end
		end
	end

	-- Sort by firstSeen (newest first)
	table.sort(results, function(a, b)
		return (a.data.firstSeen or 0) > (b.data.firstSeen or 0)
	end)

	return results
end

--- Get item count
-- @param category string: Optional category filter
-- @return number
function TrackerCore:GetCount(category)
	if category then
		local count = 0
		if self.items[category] then
			for _ in pairs(self.items[category]) do
				count = count + 1
			end
		end
		return count
	end
	return self.itemCount
end

--- Clear all logged items
-- @param category string: Optional category to clear (nil = clear all)
function TrackerCore:Clear(category)
	if category then
		if self.items[category] then
			for id in pairs(self.items[category]) do
				self.itemCount = self.itemCount - 1
			end
			self.items[category] = {}
		end
	else
		self.items = {}
		self.itemCount = 0
	end
end

--------------------------------------------------------------------------------
-- Export Formatting
--------------------------------------------------------------------------------

--- Export items to a formatted string
-- @param formatter function: formatter(category, id, data) -> string
-- @param filterFunc function: Optional filter
-- @return string
function TrackerCore:ExportToString(formatter, filterFunc)
	local items = self:GetItems(filterFunc)
	local lines = {}

	-- Group by category
	local byCategory = {}
	for _, item in ipairs(items) do
		if not byCategory[item.category] then
			byCategory[item.category] = {}
		end
		table.insert(byCategory[item.category], item)
	end

	-- Format each category
	for category, categoryItems in pairs(byCategory) do
		table.insert(lines, "-- === " .. category:upper() .. " ===")
		for _, item in ipairs(categoryItems) do
			local line = formatter(item.category, item.id, item.data)
			if line then
				table.insert(lines, line)
			end
		end
		table.insert(lines, "")
	end

	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- UI Helpers
--------------------------------------------------------------------------------

--- Create a basic tracker window
-- @param config table: UI configuration
-- @return Frame
function TrackerCore:CreateWindow(config)
	config = config or {}

	local frame = CreateFrame("Frame", config.name or (self.name .. "Window"), UIParent, "BackdropTemplate")
	frame:SetSize(config.width or 400, config.height or 500)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetClampedToScreen(true)

	-- Backdrop
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
	frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

	-- Title
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.title:SetPoint("TOPLEFT", 10, -10)
	frame.title:SetText(config.title or self.name)
	frame.title:SetTextColor(1, 0.8, 0)

	-- Close button
	frame.closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	frame.closeBtn:SetPoint("TOPRIGHT", -2, -2)

	-- Scroll frame for content
	frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	frame.scrollFrame:SetPoint("TOPLEFT", 10, -40)
	frame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)

	-- Scroll child (content container)
	frame.content = CreateFrame("Frame", nil, frame.scrollFrame)
	frame.content:SetSize(config.width and (config.width - 40) or 360, 1)
	frame.scrollFrame:SetScrollChild(frame.content)

	-- Button bar at bottom
	frame.buttonBar = CreateFrame("Frame", nil, frame)
	frame.buttonBar:SetPoint("BOTTOMLEFT", 10, 10)
	frame.buttonBar:SetPoint("BOTTOMRIGHT", -10, 10)
	frame.buttonBar:SetHeight(30)

	frame:Hide()
	self.frame = frame

	return frame
end

--- Create a button in the button bar
-- @param text string: Button text
-- @param onClick function: Click handler
-- @return Button
function TrackerCore:AddButton(text, onClick)
	if not self.frame or not self.frame.buttonBar then
		return nil
	end

	local btn = CreateFrame("Button", nil, self.frame.buttonBar, "UIPanelButtonTemplate")
	btn:SetSize(100, 24)
	btn:SetText(text)
	btn:SetScript("OnClick", onClick)

	-- Position based on existing buttons
	if not self.frame.buttons then
		self.frame.buttons = {}
	end

	local count = #self.frame.buttons
	if count == 0 then
		btn:SetPoint("LEFT", 0, 0)
	else
		btn:SetPoint("LEFT", self.frame.buttons[count], "RIGHT", 5, 0)
	end

	table.insert(self.frame.buttons, btn)
	return btn
end

--- Create an export popup with copyable text
-- @param text string: Text to display
function TrackerCore:ShowExportPopup(text)
	-- Use AceGUI if available, otherwise simple frame
	local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

	if AceGUI then
		local popup = AceGUI:Create("Frame")
		popup:SetTitle("Export - " .. self.name)
		popup:SetWidth(500)
		popup:SetHeight(400)
		popup:SetLayout("Fill")

		local editBox = AceGUI:Create("MultiLineEditBox")
		editBox:SetLabel("")
		editBox:SetText(text)
		editBox:DisableButton(true)
		editBox:SetFullWidth(true)
		editBox:SetFullHeight(true)
		popup:AddChild(editBox)

		-- Select all on focus
		editBox.editBox:SetScript("OnEditFocusGained", function(self)
			self:HighlightText()
		end)

		popup:Show()
	else
		-- Fallback: print to chat
		print("|cffff8800[" .. self.name .. "]|r Export copied to chat (install AceGUI for popup):")
		for line in text:gmatch("[^\n]+") do
			print(line)
		end
	end
end

--------------------------------------------------------------------------------
-- Expansion Helpers
--------------------------------------------------------------------------------

-- Expansion ID to Name mapping (0-indexed, matching GetExpansionLevel())
-- Classic=0, TBC=1, WotLK=2, Cata=3, MoP=4, WoD=5, Legion=6, BfA=7, SL=8, DF=9, TWW=10
local EXPANSION_NAMES = {
	[0] = "Classic",
	[1] = "Burning Crusade",
	[2] = "Wrath of the Lich King",
	[3] = "Cataclysm",
	[4] = "Mists of Pandaria",
	[5] = "Warlords of Draenor",
	[6] = "Legion",
	[7] = "Battle for Azeroth",
	[8] = "Shadowlands",
	[9] = "Dragonflight",
	[10] = "The War Within",
	[11] = "Midnight",
}

--- Get expansion name from ID
-- @param expansionID number
-- @return string
function TrackerCore.GetExpansionName(expansionID)
	return EXPANSION_NAMES[expansionID] or ("Expansion " .. tostring(expansionID))
end

--- Get current expansion ID
-- @return number
function TrackerCore.GetCurrentExpansion()
	return GetExpansionLevel()
end

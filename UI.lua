local _, ns = ...
local UI = {}
ns.UI = UI

-- Visual Constants
-- Visual Constants
local _C_BACKGROUND = { 0.1, 0.1, 0.1 }
local _C_BORDER = { 0.4, 0.4, 0.4, 1 }
local C_HEADER = { 1, 0.8, 0 } -- Gold
local _C_BAR_VALOR = { 0.8, 0.6, 0.2 } -- Earthy Gold
local _C_BAR_CREST = { 0.7, 0.4, 0.9 } -- Purple

--------------------------------------------------------------------------------
-- Time-Gating Utilities
--------------------------------------------------------------------------------

-- Parse "YYYY-MM-DD" date string to timestamp
local function ParseDate(dateStr)
	local y, m, d = dateStr:match("(%d+)-(%d+)-(%d+)")
	if y and m and d then
		return time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0 })
	end
	return nil
end

-- Check if section should be visible based on showAfter/hideAfter dates
local function IsSectionVisible(section, cfg)
	-- Debug override: show all gated content
	if cfg.debug and cfg.debug.ignoreTimeGates then
		return true
	end

	local now = time()

	if section.showAfter then
		local showTime = ParseDate(section.showAfter)
		if showTime and now < showTime then
			return false -- Not yet visible
		end
	end

	if section.hideAfter then
		local hideTime = ParseDate(section.hideAfter)
		if hideTime and now >= hideTime then
			return false -- Already hidden
		end
	end

	return true
end

function UI:Initialize()
	local _cfg = ns.Config

	-- Create Main Frame (Only once)
	if not self.frame then
		-- We use a plain frame (no default template) for maximum control
		self.frame = CreateFrame("Frame", "WeeklyFrame", UIParent)
		self.frame:SetFrameStrata("MEDIUM")
		self.frame:SetClampedToScreen(true)

		-- Default Position
		self.frame:SetPoint("CENTER")

		-- Draggable logic
		self.frame:RegisterForDrag("LeftButton")
		self.frame:SetScript("OnDragStart", self.frame.StartMoving)
		self.frame:SetScript("OnDragStop", function()
			self.frame:StopMovingOrSizing()
			self:SavePosition()
		end)

		-- Custom Background Texture (for reliable opacity)
		self.bg = self.frame:CreateTexture(nil, "BACKGROUND")
		self.bg:SetAllPoints()
		self.bg:SetColorTexture(0.1, 0.1, 0.1, 1)

		-- Content Frame (holds the rows)
		self.content = CreateFrame("Frame", nil, self.frame)

		-- Collapse/Expand All Toggle Button (top-left)
		self.collapseToggleBtn = CreateFrame("Button", nil, self.frame)
		self.collapseToggleBtn:SetSize(20, 16)
		self.collapseToggleBtn:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 4, -4)
		self.collapseToggleBtn.text = self.collapseToggleBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		self.collapseToggleBtn.text:SetPoint("LEFT")
		self.collapseToggleBtn.text:SetText("[-]")
		self.collapseToggleBtn.text:SetTextColor(0.7, 0.7, 0.7)
		self.collapseToggleBtn:SetScript("OnClick", function()
			if self:AreAllCollapsed() then
				self:ExpandAll()
			else
				self:CollapseAll()
			end
			self:UpdateCollapseToggleBtn()
		end)
		self.collapseToggleBtn:SetScript("OnEnter", function(btn)
			btn.text:SetTextColor(1, 0.82, 0) -- Gold on hover
			GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
			if self:AreAllCollapsed() then
				GameTooltip:SetText("Expand All", 1, 1, 1)
			else
				GameTooltip:SetText("Collapse All", 1, 1, 1)
			end
			GameTooltip:Show()
		end)
		self.collapseToggleBtn:SetScript("OnLeave", function(btn)
			btn.text:SetTextColor(0.7, 0.7, 0.7)
			GameTooltip:Hide()
		end)

		-- Title Text (after toggle button)
		self.titleText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		self.titleText:SetPoint("LEFT", self.collapseToggleBtn, "RIGHT", 2, 0)
		self.titleText:SetText("WEEKLY")
		self.titleText:SetTextColor(0.6, 0.6, 0.6)

		-- Events
		self.frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
		self.frame:RegisterEvent("QUEST_LOG_UPDATE")
		self.frame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
		self.frame:SetScript("OnEvent", function()
			self:RefreshRows()
		end)

		self.frame:Hide()

		-- Restore Position
		self:RestorePosition()
	end

	-- Initial Style Application
	self:ApplyFrameStyle()
	self:RenderRows()
end

-- Removed Manual Minimized Logic (LibDBIcon handles visibility/hiding window)
function UI:SetMinimized(_minimized)
	-- Deprecated by Broker, but kept for compatibility logic removal
end

function UI:SavePosition()
	if not self.frame then
		return
	end

	-- When saving, convert the current position to our desired anchor point
	local anchor = ns.Config.anchor or "TOP"
	local _scale = self.frame:GetEffectiveScale()
	local _uiScale = UIParent:GetEffectiveScale()

	local left = self.frame:GetLeft()
	local top = self.frame:GetTop()
	local bottom = self.frame:GetBottom()

	if not left or not top then
		return
	end

	-- Normalize to UIParent coords
	-- (Simplified mainly for standard usage)

	local point, rPoint, x, y

	if anchor == "BOTTOM" then
		point = "BOTTOMLEFT"
		rPoint = "BOTTOMLEFT"
		x = left
		y = bottom
	else
		point = "TOPLEFT"
		rPoint = "BOTTOMLEFT" -- Screen-relative logic
		x = left
		y = top
	end

	ns.Config.position = {
		point = point,
		relativePoint = rPoint,
		xOfs = x,
		yOfs = y,
	}
end

function UI:RestorePosition()
	if ns.Config.position then
		local pos = ns.Config.position
		self.frame:ClearAllPoints()
		-- Ensure we try to respect the current anchor setting if possible
		-- (or just trust the saved one, but the user wants to switch)

		-- If the saved point matches our desired anchor logic, use it.
		-- Otherwise we might need to recalculate?
		-- Actually, the best way is to re-force the anchor whenever the setting changes.

		self.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)

		-- If the saved point mismatches the config anchor (e.g. user switched setting),
		-- we should ideally re-anchor it right now.
		self:EnforceAnchor()
	else
		self.frame:ClearAllPoints()
		self.frame:SetPoint("CENTER")
	end
end

function UI:EnforceAnchor()
	if not self.frame then
		return
	end
	local anchor = ns.Config.anchor or "TOP"
	local left = self.frame:GetLeft()
	local top = self.frame:GetTop()
	local bottom = self.frame:GetBottom()

	if not left then
		return
	end -- Frame not valid yet

	self.frame:ClearAllPoints()
	if anchor == "BOTTOM" then
		self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
	else
		self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
	end
	-- Do not save here, just visual re-anchor
end

function UI:ApplyFrameStyle()
	if not self.frame then
		return
	end
	local cfg = ns.Config

	self:EnforceAnchor() -- Ensure anchor points are correct

	self.frame:SetScale(1)
	if cfg.backgroundAlpha then
		self.bg:SetAlpha(cfg.backgroundAlpha / 100)
	end

	-- 1. Locking / Click-through
	if cfg.locked then
		self.frame:SetMovable(false)
		self.frame:EnableMouse(false)
	else
		self.frame:SetMovable(true)
		self.frame:EnableMouse(true)
	end
	self.content:EnableMouse(false)

	-- Rows check
	if self.rows then
		for _, row in ipairs(self.rows) do
			row:EnableMouse(false)
		end
	end

	-- 2. Size (Handled by RenderRows Auto-Size)
	-- self.frame:SetSize(cfg.panelWidth, cfg.panelHeight)

	-- 3. Background Opacity
	local alpha = cfg.backgroundAlpha / 100
	self.bg:SetColorTexture(0.1, 0.1, 0.1, alpha)

	-- 4. Content Layout (starts below title row)
	self.content:ClearAllPoints()
	self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -24) -- Below [-] WEEKLY title
	self.content:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -10, 10)

	-- Refresh rows in case width changed
	self:RefreshRows()
end

-- Helpers (Bridge wrappers for backward compatibility)
-- Note: Core business logic is now in Core/Actions/tracker.lua
-- These Utils are thin wrappers that call the Bridge
local Utils = {}

function Utils.GetCurrency(id)
	local blockStart = debugprofilestop()

	-- Use Bridge for the action, but also need raw API data for icon
	local info = C_CurrencyInfo.GetCurrencyInfo(id)
	if not info then
		if ns.PerfBlocks then
			ns.PerfBlocks.dataQuery = ns.PerfBlocks.dataQuery + (debugprofilestop() - blockStart)
		end
		return "---", 0, 0, nil, nil
	end

	local status = ns.Bridge:GetCurrencyStatus(id)
	if ns.PerfBlocks then
		ns.PerfBlocks.dataQuery = ns.PerfBlocks.dataQuery + (debugprofilestop() - blockStart)
	end

	if not status then
		return "---", 0, 0, info.name, info.iconFileID
	end

	return FormatLargeNumber(info.quantity), status.amount, status.max, status.name, status.iconFileID
end

--------------------------------------------------------------------------------
-- Utils.GetQuest(id)
-- Gets quest completion status and progress.
-- Now delegates to Core/Actions/tracker.lua via Bridge
--
-- @param id: number or table - Single quest ID or table of variant IDs
-- @returns: isCompleted, progress, max, isOnQuest, isPercent, resolvedId
--------------------------------------------------------------------------------
function Utils.GetQuest(id)
	local blockStart = debugprofilestop()

	local status = ns.Bridge:GetQuestStatus(id)
	if ns.PerfBlocks then
		ns.PerfBlocks.dataQuery = ns.PerfBlocks.dataQuery + (debugprofilestop() - blockStart)
	end

	if not status then
		return false, 0, 0, false, false, nil
	end

	return status.isCompleted, status.progress, status.max, status.isOnQuest, status.isPercent, status.resolvedId
end

--------------------------------------------------------------------------------
-- Utils.GetItem(id)
-- Gets item count from bags/bank (for pseudo-currency items like Lumber)
-- Delegates to Core/Actions/tracker.lua via Bridge
--
-- @param id: number - Item ID
-- @returns: count, name, iconFileID
--------------------------------------------------------------------------------
function Utils.GetItem(id)
	local blockStart = debugprofilestop()

	local status = ns.Bridge:GetItemStatus(id)
	if ns.PerfBlocks then
		ns.PerfBlocks.dataQuery = ns.PerfBlocks.dataQuery + (debugprofilestop() - blockStart)
	end

	if not status then
		return 0, "Unknown", nil
	end

	return status.amount, status.name, status.iconFileID
end

function Utils.GetVault(categoryID)
	local blockStart = debugprofilestop()

	local status = ns.Bridge:GetVaultStatus(categoryID)
	if ns.PerfBlocks then
		ns.PerfBlocks.vaultLookup = ns.PerfBlocks.vaultLookup + (debugprofilestop() - blockStart)
	end

	if not status then
		return 0, 0
	end
	return status.completed, status.max
end

function Utils.GetVaultDetails(categoryID)
	local blockStart = debugprofilestop()

	local details = ns.Bridge:GetVaultDetails(categoryID)
	if ns.PerfBlocks then
		ns.PerfBlocks.vaultLookup = ns.PerfBlocks.vaultLookup + (debugprofilestop() - blockStart)
	end

	if not details then
		return { slots = {}, history = {} }
	end
	return details
end

function Utils.SortItems(items)
	local sorted = ns.Bridge:SortItems(items)
	if sorted then
		-- Replace items in-place to maintain reference
		for i = 1, #sorted do
			items[i] = sorted[i]
		end
		-- Clear any extra items if the sorted list is shorter
		for i = #sorted + 1, #items do
			items[i] = nil
		end
	end
	return items
end

ns.Utils = Utils

function UI:RefreshRows()
	local blockStart = debugprofilestop()

	-- Reset perf counters for this refresh cycle
	if ns.PerfBlocks then
		ns.PerfBlocks.uiRefresh = 0
		ns.PerfBlocks.dataQuery = 0
		ns.PerfBlocks.vaultLookup = 0
	end

	if self.rows then
		for _, row in ipairs(self.rows) do
			row:Hide()
		end
	end
	self:RenderRows()

	-- Record total UI refresh time
	if ns.PerfBlocks then
		ns.PerfBlocks.uiRefresh = debugprofilestop() - blockStart
	end
end

function UI:RenderRows()
	local sections = ns:GetCurrentSeasonData()
	local cfg = ns.Config
	self.rows = self.rows or {}
	local poolIndex = 1

	-- 1. Measurement & Processing Pass
	local visibleRows = {}
	local maxLabelWidth = 0
	local maxValueWidth = 0
	local totalHeight = 20 -- Padding

	if not self.measureFS then
		self.measureFS = self.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	end

	local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", cfg.font or "Friz Quadrata TT")

	for _, section in ipairs(sections) do
		-- Skip time-gated sections that shouldn't be visible yet
		if not IsSectionVisible(section, cfg) then
			-- Section is time-gated out - skip entirely
		else
			-- A. Process Items first to check if any are visible
			-- Create a copy for sorting so we don't mutate the data source
			local items = {}
			for _, item in ipairs(section.items) do
				-- Robust ID check: if table, use first ID as key
				local checkID = item.id
				if type(checkID) == "table" then
					checkID = checkID[1]
				end

				if not (item.id and cfg.hiddenItems[checkID]) then
					table.insert(items, item)
				end
			end

			-- Skip section entirely if all items are hidden
			if #items == 0 then
			-- Empty section - skip entirely
			else
				-- Check if this section is collapsed
				local isCollapsed = cfg.collapsedSections and cfg.collapsedSections[section.title]

				-- B. Header (only if there are visible items)
				table.insert(visibleRows, { type = "header", text = section.title, isCollapsed = isCollapsed })

				-- Measure Header (add space for collapse indicator)
				self.measureFS:SetFont(fontPath, cfg.headerFontSize, "OUTLINE")
				self.measureFS:SetText("[-] " .. section.title)

				-- Include header width in maxLabelWidth so collapsed sections set proper frame width
				local headerWidth = self.measureFS:GetStringWidth()
				if headerWidth > maxLabelWidth then
					maxLabelWidth = headerWidth
				end

				totalHeight = totalHeight + (cfg.headerFontSize + 6) + cfg.itemSpacing

				-- Only process/show items if section is NOT collapsed
				if not isCollapsed then
					-- Sort
					if not section.noSort then
						ns.Utils.SortItems(items)
					end

					-- Measure Items
					self.measureFS:SetFont(fontPath, cfg.itemFontSize)

					for _, item in ipairs(items) do
						local renderItem = setmetatable({ section = section.title }, { __index = item })
						table.insert(visibleRows, renderItem)

						local textWidth = 0
						local valueWidth = 0

						if item.type == "vault_row" then
							self.measureFS:SetText(item.label)
							textWidth = self.measureFS:GetStringWidth()

							local done, max = ns.Utils.GetVault(item.id)
							self.measureFS:SetText(done .. " / " .. max)
							valueWidth = self.measureFS:GetStringWidth()
						elseif item.type == "quest" then
							self.measureFS:SetText(item.label)
							textWidth = self.measureFS:GetStringWidth()

							local _, prog, max, _, isPercent = ns.Utils.GetQuest(item.id)
							if max >= 1 then
								if isPercent then
									self.measureFS:SetText(prog .. "%")
								else
									self.measureFS:SetText(prog .. " / " .. max)
								end
								valueWidth = self.measureFS:GetStringWidth()
							end
						elseif item.type == "currency" or item.type == "currency_cap" then
							local _, amt, max, name = ns.Utils.GetCurrency(item.id)
							self.measureFS:SetText(item.label or name)
							textWidth = self.measureFS:GetStringWidth()

							local valText = amt
							if max > 0 then
								valText = amt .. " / " .. max
							end
							self.measureFS:SetText(valText)
							valueWidth = self.measureFS:GetStringWidth()
						end

						if textWidth > maxLabelWidth then
							maxLabelWidth = textWidth
						end
						if valueWidth > maxValueWidth then
							maxValueWidth = valueWidth
						end

						totalHeight = totalHeight + (cfg.itemFontSize + 6) + cfg.itemSpacing
					end
				end
			end
		end -- Close time-gate else block
	end

	-- 2. Calculate Size
	local iconSize = cfg.itemFontSize + 4
	local checkSize = 16
	local gap = 16
	local inset = 10
	local titleHeight = 20 -- Space for [-] WEEKLY title row

	local contentWidth = cfg.itemIndent + iconSize + 4 + maxLabelWidth + gap + maxValueWidth + gap + checkSize
	local totalWidth = inset + contentWidth + inset

	-- Add title height to total
	totalHeight = totalHeight + titleHeight

	-- Ensure minimum height
	totalHeight = math.max(totalHeight, 40)

	self.frame:SetSize(totalWidth, totalHeight)

	-- Re-anchor from TOPLEFT so frame expands downward, not from center
	self:EnforceAnchor()

	-- 3. Render Pass
	local yOffset = 0

	for _i, rowData in ipairs(visibleRows) do
		local row = self.rows[poolIndex]
		if not row then
			row = self:CreateRowFrame()
			table.insert(self.rows, row)
		end
		poolIndex = poolIndex + 1

		row:Show()
		row:SetWidth(contentWidth)
		row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, yOffset)

		local context = { width = contentWidth }
		self:UpdateRow(row, rowData, context)

		yOffset = yOffset - (row:GetHeight() + cfg.itemSpacing)
	end

	-- 4. Hide unused pool rows (critical for collapse to work)
	for i = poolIndex, #self.rows do
		self.rows[i]:Hide()
	end
end

function UI:CreateRowFrame()
	local row = CreateFrame("Frame", nil, self.content)
	row:EnableMouse(false)
	row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

	-- Helper for "Done" checkmark (distinct from value)
	row.check = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.check:SetText("|A:common-icon-checkmark:16:16|a")
	row.check:Hide()

	-- Icon Button (for Tooltip)
	row.iconBtn = CreateFrame("Button", nil, row)
	row.iconBtn:SetNormalTexture("Interface\\Buttons\\UI-EmptySlot-Disabled") -- Placeholder, will be overwritten
	row.icon = row.iconBtn:GetNormalTexture()
	row.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	row.iconBtn:SetScript("OnEnter", function(self)
		-- Quests: No tooltip, click to open quest log
		if self.type == "quest" then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.label or "Quest", 1, 1, 1)

			-- Show hint tooltip only if player has the quest
			if self.isOnQuest then
				GameTooltip:AddLine("Left-click: Open Quest Log", 0.7, 0.7, 0.7)
			elseif self.coords and self.coords.mapID then
				GameTooltip:AddLine("Left-click: Set Map Marker", 0.7, 0.7, 0.7)

				-- Add zone name if available
				local mapInfo = C_Map.GetMapInfo(self.coords.mapID)
				if mapInfo and mapInfo.name then
					GameTooltip:AddLine("Location: " .. mapInfo.name, 0.5, 0.5, 0.8)
				end
			end
			GameTooltip:Show()
			return
		end

		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.type == "currency" and self.id then
			GameTooltip:SetCurrencyByID(self.id)
		elseif self.type == "vault" and self.details then
			GameTooltip:SetText(self.label or "Vault", 1, 1, 1)
			if self.details and self.details.slots then
				for i, info in ipairs(self.details.slots) do
					local color = info.completed and { 0, 1, 0 } or { 0.5, 0.5, 0.5 }
					local status = info.completed and ("Level " .. info.level) or "Incomplete"
					GameTooltip:AddDoubleLine("Slot " .. i, status, 1, 1, 1, color[1], color[2], color[3])
				end
			end

			if self.details and self.details.history and #self.details.history > 0 then
				GameTooltip:AddLine(" ")
				local header = "Runs this Week:"
				if self.id == 3 then
					header = "Bosses Defeated:"
				end -- Raid
				GameTooltip:AddLine(header, 1, 0.82, 0)
				for _, run in ipairs(self.details.history) do
					-- Format: [Name] - [Level]
					local _color = run.completed and { 0, 1, 0 } or { 0.5, 0.5, 0.5 }
					local rightText = run.level
					if not run.completed then
						rightText = rightText .. " (Failed)"
					end
					GameTooltip:AddDoubleLine(run.name, rightText, 1, 1, 1, 1, 1, 1)
				end
			end
		end
		GameTooltip:Show()
	end)
	row.iconBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Click handler for quests - opens quest log or sets waypoint
	row.iconBtn:SetScript("OnClick", function(self)
		if self.type == "quest" then
			if self.isOnQuest and self.id then
				-- Open quest log to this quest
				if QuestMapFrame_OpenToQuestDetails then
					QuestMapFrame_OpenToQuestDetails(self.id)
				else
					-- Fallback: just open the quest log
					ToggleQuestLog()
				end
			elseif not self.isOnQuest and self.coords and self.coords.mapID then
				-- Set Map Waypoint
				local point = UiMapPoint.CreateFromCoordinates(self.coords.mapID, self.coords.x, self.coords.y)
				C_Map.SetUserWaypoint(point)
				C_SuperTrack.SetSuperTrackedUserWaypoint(true)
				print(string.format("|cff00ff00[Weekly]|r Set map marker for: %s", self.label or "Quest"))
			end
		end
	end)
	row.iconBtn:RegisterForClicks("LeftButtonUp")

	-- Vault Slots (Visual Boxes)
	row.slots = {}
	for _i = 1, 3 do
		local slot = CreateFrame("Frame", nil, row, "BackdropTemplate")
		slot:SetSize(14, 14)
		slot:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = nil,
			tile = false,
			tileSize = 0,
			edgeSize = 0,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		slot:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
		slot:SetBackdropColor(0, 0, 0, 0.1)
		slot:Hide()

		slot.check = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		slot.check:SetPoint("CENTER")
		slot.check:SetText("|A:common-icon-checkmark:12:12|a")
		slot.check:Hide()

		table.insert(row.slots, slot)
	end

	return row
end

function UI:UpdateRow(row, data, _ctx)
	local cfg = ns.Config
	row.label:ClearAllPoints()
	row.value:ClearAllPoints()
	row.check:Hide()
	row:SetAlpha(1.0)

	-- Reset header click state (prevents pooled rows from capturing clicks)
	row:EnableMouse(false)
	row:SetScript("OnMouseDown", nil)
	row.headerTitle = nil

	-- Reset label color to default white (header rows will override to gold)
	row.label:SetTextColor(1, 1, 1)

	-- Alignments:
	-- Icon: LEFT, indent, 0
	-- Label: LEFT, Icon, RIGHT, 4, 0
	-- Check: RIGHT, 0, 0
	-- Value: RIGHT, Check, LEFT, -gap, 0

	if data.type == "header" then
		row:SetHeight(cfg.headerFontSize + 6)
		local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", cfg.font or "Friz Quadrata TT")
		row.label:SetFont(fontPath, cfg.headerFontSize, "OUTLINE")
		row.label:SetTextColor(unpack(C_HEADER))
		row.label:SetPoint("LEFT", 0, -2)

		-- Add collapse indicator (use ASCII that WoW fonts support)
		local indicator = data.isCollapsed and "[+] " or "[-] "
		row.label:SetText(indicator .. data.text)

		row.iconBtn:Hide()
		row.value:SetText("")

		-- Make header clickable for collapse toggle (set fresh each render)
		row:EnableMouse(true)
		local sectionTitle = data.text -- Capture for closure
		row:SetScript("OnMouseDown", function()
			UI:ToggleSection(sectionTitle)
		end)
	elseif data.type == "currency_cap" or data.type == "currency" then
		local height = cfg.itemFontSize + 6
		row:SetHeight(height)
		local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", cfg.font or "Friz Quadrata TT")
		row.label:SetFont(fontPath, cfg.itemFontSize)
		row.value:SetFont(fontPath, cfg.itemFontSize)

		local _textStr, amount, max, name, icon = ns.Utils.GetCurrency(data.id)

		-- Icon
		local iconSize = height - 2
		row.iconBtn:Show()
		row.iconBtn:SetSize(iconSize, iconSize)
		row.icon:SetTexture(icon)
		row.iconBtn:SetPoint("LEFT", cfg.itemIndent, 0)
		row.iconBtn.type = "currency"
		row.iconBtn.id = data.id

		-- Label
		row.label:SetPoint("LEFT", row.iconBtn, "RIGHT", 4, 0)
		row.label:SetText(data.label or name)

		-- Value
		row.value:Show()
		row.value:SetPoint("RIGHT", row.check, "LEFT", -4, 0) -- Check is anchor

		-- Check placement (Always visible as anchor, but texture hidden if not needed)
		row.check:SetPoint("RIGHT", 0, 0)

		if max > 0 then
			-- Capped
			local valText = amount .. " / " .. max
			row.value:SetText(valText)

			if amount >= max then
				row.check:Show() -- Green Check
				row.value:SetTextColor(0, 1, 0)
			else
				row.check:Hide()
				row.value:SetTextColor(1, 1, 1)
			end
		else
			-- Uncapped
			row.value:SetTextColor(1, 1, 1)
			row.value:SetText(amount)
			row.check:Hide()
		end

		-- Force Value to align to the "Value Column"
		-- The value string aligns to the right of the "Value Column Space"
		-- Column Width = ctx.maxValueWidth
		-- Check is fixed 16px.
		-- So Value Point should be: RIGHT, -20 (check+gap)
		row.value:ClearAllPoints()
		row.value:SetPoint("RIGHT", -24, 0) -- Fixed anchor to right side (Check space)
	elseif data.type == "item" then
		-- Item count (pseudo-currency like Lumber)
		local height = cfg.itemFontSize + 6
		row:SetHeight(height)
		local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", cfg.font or "Friz Quadrata TT")
		row.label:SetFont(fontPath, cfg.itemFontSize)
		row.value:SetFont(fontPath, cfg.itemFontSize)

		local count, name, icon = ns.Utils.GetItem(data.id)

		-- Icon
		local iconSize = height - 2
		row.iconBtn:Show()
		row.iconBtn:SetSize(iconSize, iconSize)
		row.icon:SetTexture(icon)
		row.iconBtn:SetPoint("LEFT", cfg.itemIndent, 0)
		row.iconBtn.type = "item"
		row.iconBtn.id = data.id

		-- Label
		row.label:SetPoint("LEFT", row.iconBtn, "RIGHT", 4, 0)
		row.label:SetText(data.label or name)

		-- Value (just the count, no max)
		row.value:Show()
		row.value:SetTextColor(1, 1, 1)
		row.value:SetText(count)
		row.check:Hide()

		row.value:ClearAllPoints()
		row.value:SetPoint("RIGHT", -24, 0)
	elseif data.type == "vault_visual" then
		local height = cfg.itemFontSize + 6
		row:SetHeight(height)
		local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", cfg.font or "Friz Quadrata TT")
		row.label:SetFont(fontPath, cfg.itemFontSize)

		-- Icon
		local iconSize = height - 2
		row.iconBtn:Show()
		row.iconBtn:SetSize(iconSize, iconSize)
		row.iconBtn:SetPoint("LEFT", cfg.itemIndent, 0)

		-- Distinct Icons per category (FileIDs)
		local iconTexture = 134400 -- Default Question Mark
		if data.id == 3 then
			iconTexture = "Interface\\Icons\\Achievement_Boss_Ragnaros"
		end -- Raid
		if data.id == 1 then
			iconTexture = 525134
		end -- Dungeon (ChallengeMode-Keystone-Empty)
		if data.id == 6 then
			iconTexture = "Interface\\Icons\\Achievement_WorldEvent_Lunar"
		end -- World

		row.icon:SetTexture(iconTexture)

		-- Tooltip Data
		row.iconBtn.type = "vault"
		row.iconBtn.id = data.id
		row.iconBtn.label = data.label

		-- Data
		local details = ns.Utils.GetVaultDetails(data.id)

		-- Label
		row.label:SetPoint("LEFT", row.iconBtn, "RIGHT", 4, 0)
		row.label:SetText(data.label)

		-- Render Slots (Replacing Value)
		row.value:Hide()
		row.check:Hide() -- Hide main check, we use individual slot checks

		local _prevSlot = nil
		-- Iterate backwards to align right? Or forward?
		-- Let's align them to the RIGHT of the row, like the Value would be.
		-- Slot 3 (Rightmost) -> Slot 2 -> Slot 1

		local _startX = -10
		local spacing = 2
		local size = 16

		for i = 3, 1, -1 do
			local slot = row.slots[i]
			local info = details.slots[i]

			if info then
				slot:Show()
				slot:SetSize(size, size)
				slot:ClearAllPoints()

				-- Anchor from Right
				if i == 3 then
					slot:SetPoint("RIGHT", 0, 0)
				else
					slot:SetPoint("RIGHT", row.slots[i + 1], "LEFT", -spacing, 0)
				end

				if info.completed then
					slot:SetBackdropBorderColor(0, 1, 0, 1) -- Green
					slot.check:Show()
				else
					slot:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) -- Gray
					slot.check:Hide()
				end
			else
				slot:Hide()
			end
		end

		-- Store for tooltip use
		row.iconBtn.details = details
	elseif data.type == "quest" then
		local height = cfg.itemFontSize + 6
		row:SetHeight(height)
		local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", cfg.font or "Friz Quadrata TT")
		row.label:SetFont(fontPath, cfg.itemFontSize)
		row.value:SetFont(fontPath, cfg.itemFontSize)

		local isComplete, prog, max, isOnQuest, isPercent, resolvedId = ns.Utils.GetQuest(data.id)

		if data.section == "Weekly Quests" and not isComplete and not isOnQuest then
			row:SetAlpha(0.5)
		end

		local iconSize = height - 2

		row.iconBtn:Show()
		row.iconBtn:SetSize(iconSize, iconSize)

		if data.icon then
			row.icon:SetTexture(data.icon)
		else
			row.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
		end

		row.iconBtn:SetPoint("LEFT", cfg.itemIndent, 0)
		row.iconBtn.type = "quest"
		row.iconBtn.id = resolvedId -- Use resolved ID for quest log navigation (nil for multi-ID with none active)
		row.iconBtn.label = data.label
		row.iconBtn.isOnQuest = isOnQuest -- For click-to-open-quest-log
		row.iconBtn.coords = data.coords -- For map marker navigation

		row.label:SetPoint("LEFT", row.iconBtn, "RIGHT", 4, 0)
		row.label:SetText(data.label)

		row.check:SetPoint("RIGHT", 0, 0)

		-- Logic: If max > 1 (progress quest), show "1/5" or "50%".
		-- If completed, show checkmark.

		if isComplete then
			row.check:Show()
			row.value:SetText("")
		else
			row.check:Hide()
			if max and max >= 1 then
				if isPercent then
					-- Show percentage format (e.g., "50%")
					row.value:SetText(prog .. "%")
				else
					-- Show count format (e.g., "0/1" or "3/5")
					row.value:SetText(prog .. " / " .. max)
				end
				row.value:SetPoint("RIGHT", -24, 0) -- Align same as currency
			else
				row.value:SetText("")
			end
		end
	else
		row:Hide()
	end
end

function UI:Toggle()
	if not self.frame then
		return
	end
	if self.frame:IsShown() then
		self.frame:Hide()
		ns.Config.visible = false
	else
		self.frame:Show()
		ns.Config.visible = true
	end
end

-- Section Collapse/Expand Functions
function UI:ToggleSection(sectionTitle)
	if not ns.Config.collapsedSections then
		ns.Config.collapsedSections = {}
	end

	-- Toggle the state
	ns.Config.collapsedSections[sectionTitle] = not ns.Config.collapsedSections[sectionTitle]

	-- Re-render and update button
	self:RenderRows()
	self:UpdateCollapseToggleBtn()
end

function UI:CollapseAll()
	if not ns.Config.collapsedSections then
		ns.Config.collapsedSections = {}
	end

	-- Collapse all sections
	local sections = ns:GetCurrentSeasonData()
	for _, section in ipairs(sections) do
		ns.Config.collapsedSections[section.title] = true
	end

	self:RenderRows()
end

function UI:ExpandAll()
	-- Clear all collapsed states
	ns.Config.collapsedSections = {}
	self:RenderRows()
end

function UI:AreAllCollapsed()
	local sections = ns:GetCurrentSeasonData()
	local cfg = ns.Config

	if not cfg.collapsedSections then
		return false
	end

	for _, section in ipairs(sections) do
		if not cfg.collapsedSections[section.title] then
			return false
		end
	end

	return true
end

function UI:UpdateCollapseToggleBtn()
	if not self.collapseToggleBtn then
		return
	end

	if self:AreAllCollapsed() then
		self.collapseToggleBtn.text:SetText("[+]") -- Can expand
	else
		self.collapseToggleBtn.text:SetText("[-]") -- Can collapse
	end
end

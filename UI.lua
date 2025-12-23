local _, ns = ...
local UI = {}
ns.UI = UI

-- Visual Constants
-- Visual Constants
local C_BACKGROUND = { 0.1, 0.1, 0.1 }
local C_BORDER = { 0.4, 0.4, 0.4, 1 }
local C_HEADER = { 1, 0.8, 0 } -- Gold
local C_BAR_VALOR = { 0.8, 0.6, 0.2 } -- Earthy Gold
local C_BAR_CREST = { 0.7, 0.4, 0.9 } -- Purple

function UI:Initialize()
	local cfg = ns.Config

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
function UI:SetMinimized(minimized)
	-- Deprecated by Broker, but kept for compatibility logic removal
end

function UI:SavePosition()
	if not self.frame then
		return
	end

	-- When saving, convert the current position to our desired anchor point
	local anchor = ns.Config.anchor or "TOP"
	local scale = self.frame:GetEffectiveScale()
	local uiScale = UIParent:GetEffectiveScale()

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

	-- 4. Content Layout (Heading gone)
	self.content:ClearAllPoints()
	self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -10)
	self.content:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -10, 10)

	-- Refresh rows in case width changed
	self:RefreshRows()
end

-- Helpers
local Utils = {}
function Utils.GetCurrency(id)
	local info = C_CurrencyInfo.GetCurrencyInfo(id)
	if not info then
		return "---", 0, 0
	end

	local amount = info.quantity
	-- Prefer weekly max if available, otherwise total max
	local max = (info.maxWeeklyQuantity > 0) and info.maxWeeklyQuantity or info.maxQuantity
	local earned = info.quantityEarnedThisWeek

	if info.maxWeeklyQuantity > 0 then
		-- For weekly capped currencies (e.g. Conquest), use earned vs weeklyMax
		amount = earned
	end

	-- Safety for 0 max (uncapped)
	-- if max == 0 then max = amount end -- REMOVED: Cause of fake caps

	return FormatLargeNumber(info.quantity), amount, max, info.name, info.iconFileID
end

--------------------------------------------------------------------------------
-- Utils.GetQuest(id)
-- Gets quest completion status and progress.
--
-- @param id: number or table - Single quest ID or table of variant IDs
--            (e.g., {83363, 83365, 83359} for rotating Timewalking quests)
--
-- @returns:
--   isCompleted (bool)  - Quest is flagged as completed
--   progress (number)   - Current progress value
--   max (number)        - Maximum progress value (for progress display)
--   isOnQuest (bool)    - Player currently has this quest
--   isPercent (bool)    - Progress should display as percentage (e.g., "50%")
--   resolvedId (number) - The actual quest ID (for multi-ID quests, returns the
--                         specific variant the player has; nil if none active)
--------------------------------------------------------------------------------
function Utils.GetQuest(id)
	local resolvedId = nil -- Track the actual quest ID (for multi-ID quests)

	-- Handle table of IDs (Find first active or completed)
	if type(id) == "table" then
		local foundId = nil
		for _, qid in ipairs(id) do
			if C_QuestLog.IsOnQuest(qid) or C_QuestLog.IsQuestFlaggedCompleted(qid) then
				foundId = qid
				break
			end
		end
		if foundId then
			id = foundId
			resolvedId = foundId -- Found the specific quest
		else
			-- If none valid found, return early (no quest active)
			-- Return nil for resolvedId so we know it's a multi-ID quest with none active
			return false, 0, 0, false, false, nil
		end
	else
		resolvedId = id -- Single ID quest
	end

	if id == 0 then
		return false, 0, 0, false, false, nil
	end

	local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(id)
	local isOnQuest = C_QuestLog.IsOnQuest(id)

	local progress = 0
	local max = 0
	local isPercent = false

	if isOnQuest then
		local objectives = C_QuestLog.GetQuestObjectives(id)
		if objectives and #objectives > 0 then
			-- Check if this is a multi-objective quest (multiple 0/1 or similar objectives)
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
				-- First, try to detect percentage from objective text (most reliable)
				if obj.text then
					local pct = obj.text:match("%((%d+)%%%)") -- Match "(X%)" format
					if not pct then
						pct = obj.text:match("(%d+)%%") -- Match "X%" format anywhere
					end
					if pct then
						progress = tonumber(pct) or 0
						max = 100
						isPercent = true
					end
				end

				-- Fallback: Some quests use numFulfilled/numRequired as 0-100 percentage
				if not isPercent and max == 100 and progress <= 100 then
					isPercent = true
				end
			end
		end
	elseif isCompleted then
		progress = 1
		max = 1 -- Treat as full
	end

	return isCompleted, progress, max, isOnQuest, isPercent, resolvedId
end

function Utils.GetVault(categoryID)
	local activities = C_WeeklyRewards.GetActivities(categoryID)
	local completed = 0
	local max = #activities
	for i, activity in ipairs(activities) do
		if activity.progress >= activity.threshold then
			completed = completed + 1
		end
	end
	return completed, max
end

function Utils.GetVaultDetails(categoryID)
	local activities = C_WeeklyRewards.GetActivities(categoryID)
	table.sort(activities, function(a, b)
		return a.index < b.index
	end)

	local results = { slots = {}, history = {} }

	for i, act in ipairs(activities) do
		table.insert(results.slots, {
			threshold = act.threshold,
			progress = act.progress,
			level = act.level or 0,
			completed = (act.progress >= act.threshold),
		})
	end
	-- Get M+ Runs for this week (Category 1 = Dungeons)
	if categoryID == 1 then
		local runs = C_MythicPlus.GetRunHistory(false, false)
		if runs then
			table.sort(runs, function(a, b)
				return a.level > b.level
			end)
			for _, run in ipairs(runs) do
				local mapName = C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID)
				table.insert(results.history, {
					name = mapName,
					level = run.level,
					completed = run.completed,
				})
			end
		end

	-- Raid History (Category 3 = Raid)
	elseif categoryID == 3 then
		-- Use SavedInstances (Lockouts) for accurate boss kill tracking
		local numSaved = GetNumSavedInstances()
		for i = 1, numSaved do
			local name, _, _, _, locked, _, _, isRaid, _, diffName, numEncounters = GetSavedInstanceInfo(i)
			if isRaid and locked then
				for j = 1, numEncounters do
					local bossName, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
					if isKilled then
						table.insert(results.history, {
							name = bossName,
							level = diffName, -- e.g. "Heroic"
							completed = true,
						})
					end
				end
			end
		end
	end

	return results
end

function Utils.SortItems(items)
	local cfg = ns.Config

	table.sort(items, function(a, b)
		if a.type == "vault_visual" and b.type == "vault_visual" then
			-- Custom Sort Order: Raid(3) -> Dungeons(1) -> World(6)
			local order = { [3] = 1, [1] = 2, [6] = 3 }
			local orderA = order[a.id] or 99
			local orderB = order[b.id] or 99
			return orderA < orderB
		end

		-- 1. Completion (Active First) - Optional
		if cfg.sortCompletedBottom then
			local aDone = false
			local bDone = false

			-- Determine completion status
			if a.type == "quest" then
				aDone = Utils.GetQuest(a.id)
			elseif a.type == "currency_cap" or a.type == "currency" then
				local _, amt, max = Utils.GetCurrency(a.id)
				aDone = (max > 0 and amt >= max)
			end

			if b.type == "quest" then
				bDone = Utils.GetQuest(b.id)
			elseif b.type == "currency_cap" or b.type == "currency" then
				local _, amt, max = Utils.GetCurrency(b.id)
				bDone = (max > 0 and amt >= max)
			end

			if aDone ~= bDone then
				return not aDone -- Active (not done) comes first
			end
		end

		-- 2. Alphabetical
		return (a.label or "") < (b.label or "")
	end)

	return items
end

ns.Utils = Utils

function UI:RefreshRows()
	if self.rows then
		for _, row in ipairs(self.rows) do
			row:Hide()
		end
	end
	self:RenderRows()
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
			-- Do nothing, skip this section
		else
			-- B. Header (only if there are visible items)
			table.insert(visibleRows, { type = "header", text = section.title })

			-- Measure Header
			self.measureFS:SetFont(fontPath, cfg.headerFontSize, "OUTLINE")
			self.measureFS:SetText(section.title)

			totalHeight = totalHeight + (cfg.headerFontSize + 6) + cfg.itemSpacing

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

	-- 2. Calculate Size
	local iconSize = cfg.itemFontSize + 4
	local checkSize = 16
	local gap = 16
	local inset = 10

	local contentWidth = cfg.itemIndent + iconSize + 4 + maxLabelWidth + gap + maxValueWidth + gap + checkSize
	local totalWidth = inset + contentWidth + inset

	self.frame:SetSize(totalWidth, totalHeight)

	-- 3. Render Pass
	local yOffset = 0

	for i, rowData in ipairs(visibleRows) do
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
					local color = run.completed and { 0, 1, 0 } or { 0.5, 0.5, 0.5 }
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
	for i = 1, 3 do
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

function UI:UpdateRow(row, data, ctx)
	local cfg = ns.Config
	row.label:ClearAllPoints()
	row.value:ClearAllPoints()
	row.check:Hide()
	row:SetAlpha(1.0)

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
		row.label:SetText(data.text)
		row.iconBtn:Hide()
		row.value:SetText("")
	elseif data.type == "currency_cap" or data.type == "currency" then
		local height = cfg.itemFontSize + 6
		row:SetHeight(height)
		local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", cfg.font or "Friz Quadrata TT")
		row.label:SetFont(fontPath, cfg.itemFontSize)
		row.value:SetFont(fontPath, cfg.itemFontSize)

		local textStr, amount, max, name, icon = ns.Utils.GetCurrency(data.id)

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

		local prevSlot = nil
		-- Iterate backwards to align right? Or forward?
		-- Let's align them to the RIGHT of the row, like the Value would be.
		-- Slot 3 (Rightmost) -> Slot 2 -> Slot 1

		local startX = -10
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

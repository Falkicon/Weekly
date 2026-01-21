local _, ns = ...
-- Libs
local AceDB = LibStub("AceDB-3.0")

ns.ConfigDefaults = {
	profile = {
		-- Data Selection
		selectedExpansion = "auto", -- Automatic detection
		selectedSeason = "auto", -- Automatic detection

		-- UI
		sortCompletedBottom = true,
		backgroundAlpha = 90,
		headerFontSize = 14,
		itemFontSize = 12,
		itemSpacing = 4,
		itemIndent = 10,
		locked = false,
		hiddenItems = {},
		collapsedSections = {}, -- { ["sectionTitle"] = true, ... } for collapsed sections
		anchor = "TOP", -- TOP or BOTTOM (controls growth direction)
		position = nil,

		-- Visibility
		autoShow = false, -- Always show on login (overrides saved visibility)
		visible = true, -- Remember last visibility state (default: shown on first load)

		-- Weekly Journal
		journal = {
			enabled = true, -- Enable journal tracking
			showNotifications = false, -- Show chat message when item logged
			weekStart = 0, -- Unix timestamp of current week start (for reset detection)
			categories = {}, -- { [category] = { [id] = itemData, ... }, ... }
			gathering = {}, -- { [itemID] = { name, icon, count, expansion, ... }, ... }
			itemCount = 0, -- Total collectibles logged this week
			lastSaved = 0, -- Last save timestamp

			-- UI Settings
			windowPosition = nil, -- Saved window position
			selectedTab = "dashboard", -- Last selected tab
		},

		-- Debug Options
		debug = {
			enabled = false, -- Debug mode (shows quest ID on accept/complete)
			ignoreTimeGates = false, -- Show all gated content regardless of date
		},
	},
}

function ns:LoadConfig()
	-- Initialize AceDB with defaults
	self.db = AceDB:New("WeeklyDB", self.ConfigDefaults, "Default")

	-- Set easy alias. Updates to ns.Config will now update the DB profile directly.
	self.Config = self.db.profile

	-- One-time migration: Fix old autoShow default (was true, now false)
	-- If autoShow was never explicitly set by user, update to new default
	if self.Config.autoShow == true and self.Config._autoShowMigrated == nil then
		self.Config.autoShow = false
		self.Config._autoShowMigrated = true
	end

	-- One-time migration: Reset anchor to TOP (setting was removed)
	if self.Config._anchorMigrated == nil then
		self.Config.anchor = "TOP"
		self.Config._anchorMigrated = true
	end

	-- Callbacks
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

function ns:RefreshConfig()
	self.Config = self.db.profile
	if self.UI then
		self.UI:ApplyFrameStyle()
		self.UI:RenderRows()
		-- Restore position if it exists in the new profile
		self.UI:RestorePosition()
	end
	-- Refresh Journal if active
	if self.Journal and self.Journal.tracker then
		-- Re-initialize with new profile settings
		if self.Config.journal and self.Config.journal.enabled then
			self.Journal:Initialize()
		else
			self.Journal:Shutdown()
		end
	end
end

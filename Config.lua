local _, ns = ...
-- Libs
local AceDB = LibStub("AceDB-3.0")

ns.ConfigDefaults = {
	char = {
		-- Prey has no API for the full weekly hunt count. Keep the observed
		-- ledger per character and mark it partial until we witness a reset.
		prey = {
			count = 0,
			partial = true,
			nextReset = 0,
			activeQuestID = 0,
			lastActiveQuestID = 0,
			lastTurnInQuestID = 0,
			lastTurnInAt = 0,
		},
	},
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
			nextReset = 0, -- Blizzard-provided weekly reset boundary
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

function ns:MigrateConfig()
	return self.ConfigMigrations:Migrate(self.Config, self.CharConfig, self.ConfigDefaults)
end

function ns:LoadConfig()
	-- Initialize AceDB with defaults
	self.db = AceDB:New("WeeklyDB", self.ConfigDefaults, "Default")

	-- Set easy alias. Updates to ns.Config will now update the DB profile directly.
	self.Config = self.db.profile
	self.CharConfig = self.db.char
	self:MigrateConfig()

	-- Callbacks
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileShutdown", "PrepareProfileChange")
end

function ns:PrepareProfileChange()
	if self.Journal then
		self.Journal:Shutdown()
	end
end

function ns:RefreshConfig()
	-- Copy/reset mutate the profile without OnProfileShutdown. Discard runtime
	-- records before rebinding; saving here could overwrite the copied data.
	if self.Journal then
		self.Journal:ReloadForProfile()
	end
	self.Config = self.db.profile
	self.CharConfig = self.db.char
	self:MigrateConfig()
	if self.Weekly then
		self.Weekly:ApplyConfig("profile")
	end
end

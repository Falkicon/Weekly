local _, ns = ...
-- Libs
local AceDB = LibStub("AceDB-3.0")

ns.ConfigDefaults = {
    profile = {
        -- Data Selection
        selectedExpansion = 11, -- The War Within
        selectedSeason = 3, -- Season 3
        
        -- UI
        sortCompletedBottom = true,
        backgroundAlpha = 90,
        headerFontSize = 14,
        itemFontSize = 12,
        itemSpacing = 4,
        itemIndent = 10,
        locked = false,
        hiddenItems = {},
        anchor = "TOP", -- TOP or BOTTOM (controls growth direction)
        position = nil,
        
        -- Visibility
        autoShow = true,  -- Show on login/reload
        visible = true,   -- Remember last visibility state
        
        -- Weekly Journal
        journal = {
            enabled = true,              -- Enable journal tracking
            showNotifications = false,   -- Show chat message when item logged
            weekStart = 0,               -- Unix timestamp of current week start (for reset detection)
            categories = {},             -- { [category] = { [id] = itemData, ... }, ... }
            gathering = {},              -- { [itemID] = { name, icon, count, expansion, ... }, ... }
            itemCount = 0,               -- Total collectibles logged this week
            lastSaved = 0,               -- Last save timestamp
            
            -- UI Settings
            windowPosition = nil,        -- Saved window position
            selectedTab = "dashboard",   -- Last selected tab
        },
    }
}

function ns:LoadConfig()
    -- Initialize AceDB with defaults
    self.db = AceDB:New("WeeklyDB", self.ConfigDefaults, "Default")
    
    -- Set easy alias. Updates to ns.Config will now update the DB profile directly.
    self.Config = self.db.profile
    
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

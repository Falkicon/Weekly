local addonName, ns = ...
local ConfigUI = {}
ns.ConfigUI = ConfigUI

-- Libs match what we put in embeds.xml
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

function ConfigUI:Initialize()
    -- 1. Main Options (General)
    local mainOptions = {
        name = "Weekly",
        type = "group",
        args = {
            general = {
                type = "group",
                name = "General",
                order = 1,
                inline = true,
                args = {
                    dataSelection = {
                        type = "group",
                        name = "Data Source",
                        inline = true,
                        order = 0,
                        args = {
                            expansion = {
                                type = "select",
                                name = "Expansion",
                                order = 1,
                                values = function()
                                    -- Convert list to key-value [11] = "11" for now, or map to names
                                    local exps = ns.Data:GetExpansions()
                                    local t = {}
                                    for _, id in ipairs(exps) do
                                        if id == 11 then t[id] = "The War Within"
                                        elseif id == 12 then t[id] = "Midnight"
                                        else t[id] = "Expansion " .. id end
                                    end
                                    return t
                                end,
                                get = function() return ns.Config.selectedExpansion end,
                                set = function(_, val)
                                    ns.Config.selectedExpansion = val
                                    -- Reset Season to first available
                                    local seasons = ns.Data:GetSeasons(val)
                                    if seasons and #seasons > 0 then
                                        ns.Config.selectedSeason = seasons[#seasons] -- Default to latest
                                    end
                                    ns.UI:RefreshRows()
                                end,
                            },
                            season = {
                                type = "select",
                                name = "Season",
                                order = 2,
                                values = function()
                                    local seasons = ns.Data:GetSeasons(ns.Config.selectedExpansion)
                                    local t = {}
                                    for _, id in ipairs(seasons) do
                                        t[id] = "Season " .. id
                                    end
                                    return t
                                end,
                                get = function() return ns.Config.selectedSeason end,
                                set = function(_, val)
                                    ns.Config.selectedSeason = val
                                    ns.UI:RefreshRows()
                                end,
                            },
                        },
                    },
                    sorting = {
                        type = "toggle",
                        name = "Sort Completed to Bottom",
                        desc = "Move completed quests and capped currencies to the bottom of their list.",
                        order = 3,
                        get = function() return ns.Config.sortCompletedBottom end,
                        set = function(_, val) 
                            ns.Config.sortCompletedBottom = val
                            ns.UI:RefreshRows() 
                        end,
                    },
                    locked = {
                        type = "toggle",
                        name = "Lock Window",
                        desc = "Lock the window in place and enable click-through",
                        order = 0,
                        get = function() return ns.Config.locked end,
                        set = function(_, val) 
                            ns.Config.locked = val 
                            ns.UI:ApplyFrameStyle()
                        end,
                    },
                    autoShow = {
                        type = "toggle",
                        name = "Show on Login",
                        desc = "Automatically show the Weekly window when you log in or reload the UI.",
                        order = 1,
                        get = function() return ns.Config.autoShow end,
                        set = function(_, val) 
                            ns.Config.autoShow = val
                        end,
                    },
                    anchor = {
                        type = "select",
                        name = "Anchor Point",
                        desc = "Determines which side the window grows from when resizing.",
                        order = 2,
                        values = {
                            ["TOP"] = "Top (Grows Down)",
                            ["BOTTOM"] = "Bottom (Grows Up)",
                        },
                        get = function() return ns.Config.anchor end,
                        set = function(_, val) 
                            ns.Config.anchor = val
                            ns.UI:ApplyFrameStyle() -- Updates the anchor immediately
                        end,
                    },
                    -- Minimized option removed (Broker handles standard visibility)
                    -- panelWidth/Height removed (Auto-Sizing)
                    backgroundAlpha = {
                        type = "range",
                        name = "Background Opacity",
                        min = 0, max = 100, step = 5,
                        order = 4,
                        get = function() return ns.Config.backgroundAlpha end,
                        set = function(_, val)
                            ns.Config.backgroundAlpha = val
                            ns.UI:ApplyFrameStyle()
                        end,
                    },
                },
            },
        },
    }

    -- 2. Appearance Sub-Table
    local appearanceOptions = {
        name = "Appearance",
        type = "group",
        args = {
            font = {
                type = "select",
                dialogControl = "LSM30_Font", -- Standard Font Picker
                name = "Font Face",
                desc = "Select the font used for the list.",
                values = LSM:HashTable("font"),
                order = 1,
                get = function() return ns.Config.font or "Friz Quadrata TT" end,
                set = function(_, val)
                    ns.Config.font = val
                    ns.UI:RefreshRows()
                end,
            },
            headerFontSize = {
                type = "range",
                name = "Header Font Size",
                min = 8, max = 32, step = 1,
                order = 3,
                get = function() return ns.Config.headerFontSize end,
                set = function(_, val)
                    ns.Config.headerFontSize = val
                    ns.UI:RefreshRows()
                end,
            },
            itemFontSize = {
                type = "range",
                name = "Item Font Size",
                min = 8, max = 24, step = 1,
                order = 4,
                get = function() return ns.Config.itemFontSize end,
                set = function(_, val)
                    ns.Config.itemFontSize = val
                    ns.UI:RefreshRows()
                end,
            },
            itemSpacing = {
                type = "range",
                name = "Item Spacing",
                min = 0, max = 20, step = 1,
                order = 5,
                get = function() return ns.Config.itemSpacing end,
                set = function(_, val)
                    ns.Config.itemSpacing = val
                    ns.UI:RefreshRows()
                end,
            },
            itemIndent = {
                type = "range",
                name = "Item Indent",
                min = 0, max = 50, step = 5,
                order = 6,
                get = function() return ns.Config.itemIndent end,
                set = function(_, val)
                    ns.Config.itemIndent = val
                    ns.UI:RefreshRows()
                end,
            },
        },
    }

    -- 3. Tracking Sub-Table
    local trackingOptions = {
        name = "Tracked Items",
        type = "group",
        args = {
            desc = {
                type = "description",
                name = "Uncheck items to hide them from the list.",
                order = 0,
            },
        },
    }
    
    -- Dynamically generate tracking toggles
    local data = ns:GetCurrentSeasonData()
    local order = 10
    
    for _, section in ipairs(data) do
        -- Add Section Header
        if section.title then
             trackingOptions.args["header_" .. order] = {
                 type = "header",
                 name = section.title,
                 order = order,
             }
             order = order + 1
        end
        
        if section.items then
            -- Create sorted copy of items (same logic as UI.lua)
            local sortedItems = {}
            for _, row in ipairs(section.items) do
                if row.id and (row.type == "currency" or row.type == "currency_cap" or row.type == "quest" or row.type == "vault_visual") then
                    table.insert(sortedItems, row)
                end
            end
            
            -- Sort alphabetically (except for noSort sections and vault which has custom order)
            if not section.noSort then
                table.sort(sortedItems, function(a, b)
                    -- Vault has custom order: Raid(3) -> Dungeons(1) -> World(6)
                    if a.type == "vault_visual" and b.type == "vault_visual" then
                        local vaultOrder = { [3] = 1, [1] = 2, [6] = 3 }
                        local orderA = vaultOrder[a.id] or 99
                        local orderB = vaultOrder[b.id] or 99
                        return orderA < orderB
                    end
                    -- Alphabetical for everything else
                    return (a.label or "") < (b.label or "")
                end)
            end
            
            for _, row in ipairs(sortedItems) do
                 local configID = row.id
                 if type(configID) == "table" then configID = configID[1] end
                 
                 trackingOptions.args["item_" .. configID] = {
                    type = "toggle",
                    name = row.label or ("Item " .. configID),
                    width = "full",
                    order = order,
                    get = function() 
                        return not ns.Config.hiddenItems[configID] 
                    end,
                    set = function(_, val)
                        if val then
                            ns.Config.hiddenItems[configID] = nil
                        else
                            ns.Config.hiddenItems[configID] = true
                        end
                        ns.UI:RefreshRows()
                    end,
                 }
                 order = order + 1
            end
        end
    end

    -- Register Main
    AceConfig:RegisterOptionsTable("Weekly", mainOptions)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("Weekly", "Weekly")
    
    -- Register Sub-Categories
    AceConfig:RegisterOptionsTable("Weekly_Appearance", appearanceOptions)
    AceConfigDialog:AddToBlizOptions("Weekly_Appearance", "Appearance", "Weekly")
    
    AceConfig:RegisterOptionsTable("Weekly_Tracking", trackingOptions)
    AceConfigDialog:AddToBlizOptions("Weekly_Tracking", "Tracked Items", "Weekly")
    
    -- Register Profiles
    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(ns.db)
    AceConfig:RegisterOptionsTable("Weekly_Profiles", profiles)
    AceConfigDialog:AddToBlizOptions("Weekly_Profiles", "Profiles", "Weekly")
    
    -- 4. Journal Tab
    local journalOptions = {
        name = "Journal",
        type = "group",
        args = {
            description = {
                type = "description",
                name = "The Weekly Journal tracks collectibles you earn each week: achievements, mounts, pets, toys, and housing decor. Data resets automatically on weekly reset (Tuesday).",
                fontSize = "medium",
                order = 1,
            },
            spacer1 = {
                type = "description",
                name = " ",
                order = 2,
            },
            enabled = {
                type = "toggle",
                name = "Enable Journal",
                desc = "Enable tracking of collectibles earned this week.",
                width = "full",
                order = 10,
                get = function() return ns.Config.journal and ns.Config.journal.enabled end,
                set = function(_, val)
                    if ns.Config.journal then
                        ns.Config.journal.enabled = val
                        if val then
                            ns.Journal:Initialize()
                        else
                            ns.Journal:Shutdown()
                        end
                    end
                end,
            },
            showNotifications = {
                type = "toggle",
                name = "Show Chat Notifications",
                desc = "Print a message to chat when a new item is logged to the journal.",
                width = "full",
                order = 11,
                disabled = function() return not ns.Config.journal or not ns.Config.journal.enabled end,
                get = function() return ns.Config.journal and ns.Config.journal.showNotifications end,
                set = function(_, val)
                    if ns.Config.journal then
                        ns.Config.journal.showNotifications = val
                    end
                end,
            },
            showMinimapIcon = {
                type = "toggle",
                name = "Show Minimap Icon",
                desc = "Show a separate minimap icon for the Journal. (Requires reload)",
                width = "full",
                order = 12,
                disabled = function() return not ns.Config.journal or not ns.Config.journal.enabled end,
                get = function()
                    return WeeklyDB and WeeklyDB.journalMinimapIcon and not WeeklyDB.journalMinimapIcon.hide
                end,
                set = function(_, val)
                    if ns.JournalBroker then
                        if val then
                            ns.JournalBroker:ShowMinimapIcon()
                        else
                            ns.JournalBroker:HideMinimapIcon()
                        end
                    end
                end,
            },
            spacer2 = {
                type = "description",
                name = " ",
                order = 19,
            },
            openJournal = {
                type = "execute",
                name = "Open Journal Window",
                desc = "Open the Weekly Journal window.",
                order = 20,
                disabled = function() return not ns.Config.journal or not ns.Config.journal.enabled end,
                func = function()
                    if ns.JournalUI then
                        ns.JournalUI:Show()
                    end
                end,
            },
            spacer3 = {
                type = "description",
                name = "\n\n",
                order = 29,
            },
            statsHeader = {
                type = "header",
                name = "This Week's Stats",
                order = 30,
            },
            stats = {
                type = "description",
                name = function()
                    if not ns.Journal or not ns.Journal.tracker then
                        return "|cff888888Journal not active|r"
                    end
                    
                    local total = ns.Journal:GetTotalCount()
                    local points = ns.Journal:GetAchievementPointsThisWeek()
                    
                    local lines = {
                        string.format("|cffffffffTotal items:|r  %d", total),
                        string.format("|cffffffffAchievement points:|r  %d", points),
                        " ",
                    }
                    
                    -- Category breakdown
                    local categories = ns.Journal:GetOrderedCategories()
                    for _, cat in ipairs(categories) do
                        local count = ns.Journal:GetCategoryCount(cat.key)
                        local color = count > 0 and "|cff00ff00" or "|cff888888"
                        table.insert(lines, string.format("%s%s:|r  %d", color, cat.name, count))
                    end
                    
                    return table.concat(lines, "\n")
                end,
                fontSize = "medium",
                order = 31,
            },
        },
    }
    
    AceConfig:RegisterOptionsTable("Weekly_Journal", journalOptions)
    AceConfigDialog:AddToBlizOptions("Weekly_Journal", "Journal", "Weekly")
    
    -- 5. Dev Tools Tab (only functional in dev mode)
    local devOptions = {
        name = "Dev Tools",
        type = "group",
        args = {
            devModeStatus = {
                type = "description",
                name = function()
                    if ns.IS_DEV_MODE then
                        return "|cff00ff00Dev Mode: ACTIVE|r\n\nThe Discovery Tool is automatically tracking currencies and quests in the background."
                    else
                        return "|cffff0000Dev Mode: INACTIVE|r\n\nDev tools are only available when running from a git clone (DevMarker.lua present)."
                    end
                end,
                fontSize = "medium",
                order = 1,
            },
            spacer1 = {
                type = "description",
                name = " ",
                order = 2,
            },
            discoveryHeader = {
                type = "header",
                name = "Discovery Tool",
                order = 10,
                hidden = function() return not ns.IS_DEV_MODE end,
            },
            discoveryDesc = {
                type = "description",
                name = "Discovers new currencies and quests to add to Weekly's database. Items are tracked automatically - the window just displays what's been found.",
                order = 11,
                hidden = function() return not ns.IS_DEV_MODE end,
            },
            discoveryStats = {
                type = "description",
                name = function()
                    if not ns.IS_DEV_MODE or not ns.Discovery or not ns.Discovery.tracker then
                        return ""
                    end
                    local currencyCount = ns.Discovery.tracker:GetCount("currency")
                    local questCount = ns.Discovery.tracker:GetCount("quest")
                    local total = ns.Discovery.tracker.itemCount or 0
                    
                    -- Get saved data info
                    local savedInfo = ""
                    if WeeklyDB and WeeklyDB.dev and WeeklyDB.dev.discovery then
                        local lastSaved = WeeklyDB.dev.discovery.lastSavedFormatted
                        if lastSaved then
                            savedInfo = string.format("\n|cff888888Last saved:|r  %s", lastSaved)
                        end
                    end
                    
                    return string.format("\n|cff888888Total logged:|r  %d items (%d currencies, %d quests)%s\n|cff888888Storage cap:|r  500 items (oldest auto-pruned)", 
                        total, currencyCount, questCount, savedInfo)
                end,
                fontSize = "medium",
                order = 12,
                hidden = function() return not ns.IS_DEV_MODE end,
            },
            openDiscovery = {
                type = "execute",
                name = "Open Discovery Window",
                desc = "Open the Discovery Tool window to view and export logged items.",
                order = 15,
                func = function()
                    if ns.Discovery then
                        ns.Discovery:Toggle()
                    end
                end,
                hidden = function() return not ns.IS_DEV_MODE end,
            },
            clearDiscovery = {
                type = "execute",
                name = "Clear Logged Items",
                desc = "Clear all items logged this session.",
                order = 16,
                func = function()
                    if ns.Discovery and ns.Discovery.tracker then
                        ns.Discovery.tracker:Clear()
                        print("|cff00ff00[Weekly Discovery]|r Cleared all logged items")
                    end
                end,
                confirm = true,
                confirmText = "Clear all discovered items?",
                hidden = function() return not ns.IS_DEV_MODE end,
            },
            spacer2 = {
                type = "description",
                name = "\n",
                order = 20,
                hidden = function() return not ns.IS_DEV_MODE end,
            },
        },
    }
    
    AceConfig:RegisterOptionsTable("Weekly_Dev", devOptions)
    AceConfigDialog:AddToBlizOptions("Weekly_Dev", "Dev Tools", "Weekly")
end

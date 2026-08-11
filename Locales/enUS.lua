local L = LibStub("AceLocale-3.0"):NewLocale("Weekly", "enUS", true)
if not L then
	return
end

-- Core Messages
L["Loaded. Type /weekly to open."] = true
L["Commands:"] = true
L["  /weekly - Toggle weekly tracker window"] = true
L["  /weekly journal - Toggle journal window"] = true
L["  /weekly settings - Open settings"] = true
L["  /weekly help - Show this help"] = true
L["Journal is not available. Check settings to enable it."] = true
L["Discovery tool requires Mechanic addon"] = true
L["Debug Mode: %s"] = true
L["Toggling UI..."] = true
L["Quest Completed: ID %s"] = true
L["Quest Accepted: ID %s"] = true
L["--- DEBUG VAULT (Raid) ---"] = true
L["Activities Found: %d"] = true
L["Slot %d: Tier %s, Level %s, Progress %s/%s"] = true
L["No Raid Activities found."] = true
L["Using Tier ID: %s"] = true
L["Index %d: nil (End)"] = true
L["Index %d: 0 (End?)"] = true
L["Index %d: EncID %d (%s)"] = true
L["--- END DEBUG VAULT ---"] = true
L["--- DEBUG LOCKOUTS ---"] = true
L["Saved Instances: %d"] = true
L["Raid %d: %s (%s) - Locked: %s"] = true
L["  - %s (Killed)"] = true
L["--- END DEBUG LOCKOUTS ---"] = true

-- ConfigUI - General
L["General"] = true
L["Data Source"] = true
L["Expansion"] = true
L["Automatic (Recommended)"] = true
L["The War Within"] = true
L["Midnight"] = true
L["Expansion %d"] = true
L["Season"] = true
L["Season 3 (Midnight Pre-Patch)"] = true
L["Season %s"] = true
L["Currently detecting: %s, %s"] = true
L["Sort Completed to Bottom"] = true
L["Move completed quests and capped currencies to the bottom of their list."] = true
L["Lock Window"] = true
L["Lock the window in place and enable click-through"] = true
L["Show on Login"] = true
L["Automatically show the Weekly window when you log in or reload the UI."] = true
L["Anchor Point"] = true
L["Determines which side the window grows from when resizing."] = true
L["Top (Grows Down)"] = true
L["Bottom (Grows Up)"] = true
L["Background Opacity"] = true
L["Show All Gated Content"] = true
L["Show all time-gated sections regardless of current date."] = true

-- ConfigUI - Appearance
L["Appearance"] = true
L["Font Face"] = true
L["Select the font used for the list."] = true
L["Header Font Size"] = true
L["Item Font Size"] = true
L["Item Spacing"] = true
L["Item Indent"] = true

-- ConfigUI - Tracking
L["Tracked Items"] = true
L["Uncheck items to hide them from the list."] = true
L["Item %s"] = true

-- ConfigUI - Journal
L["Journal"] = true
L["The Weekly Journal tracks collectibles you earn each week: achievements, mounts, pets, toys, and housing decor. Data resets automatically on weekly reset (Tuesday)."] =
	true
L["Enable Journal"] = true
L["Enable tracking of collectibles earned this week."] = true
L["Show Chat Notifications"] = true
L["Print a message to chat when a new item is logged to the journal."] = true
L["Show Minimap Icon"] = true
L["Show a separate minimap icon for the Journal."] = true
L["Open Journal Window"] = true
L["Open the Weekly Journal window."] = true
L["This Week's Stats"] = true
L["Journal not active"] = true
L["Total items:"] = true
L["Achievement points:"] = true

-- Discovery Tool (accessed via Mechanic Dashboard)
L["Discovery Tool"] = true

-- Journal Categories
L["Achievements"] = true
L["Mounts"] = true
L["Pets"] = true
L["Toys"] = true
L["Decor"] = true
L["Gathering"] = true

-- Expansion Names
L["Classic"] = true
L["Burning Crusade"] = true
L["Wrath of the Lich King"] = true
L["Cataclysm"] = true
L["Mists of Pandaria"] = true
L["Warlords of Draenor"] = true
L["Legion"] = true
L["Battle for Azeroth"] = true
L["Shadowlands"] = true
L["Dragonflight"] = true

-- Journal UI
L["Weekly Journal"] = true
L["Dashboard"] = true
L["Clear"] = true
L["Clear Tab"] = true
L["Clear All"] = true
L["Week of %s %d"] = true
L["This Week's Collection"] = true
L["Total Items"] = true
L["Achievement Points"] = true
L["By Category"] = true
L["Materials Gathered"] = true
L["%d (%d types)"] = true
L["No items collected"] = true
L["No items collected this week"] = true
L["Items will appear here as you collect them this week"] = true
L["Items will appear here as you gather them this week"] = true
L["No materials gathered"] = true
L["No materials gathered this week"] = true
L["%d items"] = true
L["x %d"] = true
L["Clear all %s from this week's journal?"] = true
L["Clear ALL items from this week's journal?"] = true
L["Today %H:%M"] = true
L["Yesterday %H:%M"] = true
L["%a %H:%M"] = true
L["%m/%d %H:%M"] = true

-- Tooltips
L["Left-click: Toggle tracker"] = true
L["Right-click: Open Journal"] = true
L["Right-click: Open settings"] = true
L["Click to view in Collections"] = true
L["Found in: %s"] = true
L["Click to view %s"] = true
L["Started gathering: %s"] = true
L["New %s: %s"] = true
L["Journal loaded: %d collectibles, %d materials gathered"] = true

-- Tracker and broker UI
L["WEEKLY"] = true
L["Expand All"] = true
L["Collapse All"] = true
L["Quest"] = true
L["Prey"] = true
L["Vault"] = true
L["Unknown"] = true
L["Profiles"] = true
L["%d points"] = true
L["Decor %d"] = true
L["ID: %s"] = true
L["Left-click: Open Quest Log"] = true
L["Left-click: Set Map Marker"] = true
L["Location: %s"] = true
L["Completed this week: %d / %d"] = true
L["Active hunts: %d"] = true
L["Lower bound: tracking began during this reset."] = true
L["Level %s"] = true
L["Incomplete"] = true
L["Slot %d"] = true
L["Runs this Week:"] = true
L["Bosses Defeated:"] = true
L[" (Failed)"] = true
L["|cff00ff00[Weekly]|r Set map marker for: %s"] = true
L["Items this week:"] = true
L["Journal not initialized"] = true
L["|cff00ff00Left-click|r to toggle journal"] = true
L["|cff00ff00Right-click|r for options"] = true
L["Show Weekly"] = true
L["Lock Weekly"] = true
L["Show Journal"] = true
L["Jump to Journal Category"] = true
L["Settings"] = true
L["Journal (%d)"] = true
L["Decor: %s (ID: %d)"] = true

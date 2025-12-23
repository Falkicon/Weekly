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
L["Discovery tool is only available in dev mode"] = true
L["Debug Mode: %s"] = true
L["Toggling UI..."] = true
L["Quest Completed: ID %s"] = true
L["Quest Accepted: ID %s"] = true

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
L["Show a separate minimap icon for the Journal. (Requires reload)"] = true
L["Open Journal Window"] = true
L["Open the Weekly Journal window."] = true
L["This Week's Stats"] = true
L["Journal not active"] = true
L["Total items:"] = true
L["Achievement points:"] = true

-- ConfigUI - Dev Tools
L["Dev Tools"] = true
L["Dev Mode: ACTIVE"] = true
L["Dev Mode: INACTIVE"] = true
L["The Discovery Tool is automatically tracking currencies and quests in the background."] = true
L["Dev tools are only available when running from a git clone (DevMarker.lua present)."] = true
L["Discovery Tool"] = true
L["Discovers new currencies and quests to add to Weekly's database. Items are tracked automatically - the window just displays what's been found."] =
	true
L["Total logged: %d items (%d currencies, %d quests)%s"] = true
L["Storage cap: 500 items (oldest auto-pruned)"] = true
L["Last saved: %s"] = true
L["Open Discovery Window"] = true
L["Open the Discovery Tool window to view and export logged items."] = true
L["Clear Logged Items"] = true
L["Clear all items logged this session."] = true
L["Clear all items logged this session?"] = true

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
L["Click to view in Collections"] = true
L["Found in: %s"] = true
L["Click to view %s"] = true
L["Started gathering: %s"] = true
L["New %s: %s"] = true
L["Journal loaded: %d collectibles, %d materials gathered"] = true

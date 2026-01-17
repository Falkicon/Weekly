-- Weekly Luacheck configuration
-- Comprehensive WoW API definitions to suppress false-positive warnings

std = "lua51"
max_line_length = false
codes = true
quiet = 1

-- Exclude patterns
exclude_files = {
    "**/Libs/**",       -- External libraries
    "**/Tests/**",      -- Test files
}

-- Globals that Weekly can write to
globals = {
    "_G",
    "Weekly",
    "WeeklyDB",
    "SlashCmdList",
    "SLASH_WEEKLY1",
    "SLASH_WEEKLY2",
    "StaticPopupDialogs",
}

-- Read-only WoW API globals
read_globals = {
    -- C_ Namespaced APIs (Modern)
    "C_AchievementInfo",
    "C_AddOns",
    "C_ChallengeMode",
    "C_Covenants",
    "C_CurrencyInfo",
    "C_DateAndTime",
    "C_HousingDecor",
    "C_Item",
    "C_Map",
    "C_MountJournal",
    "C_MythicPlus",
    "C_PetJournal",
    "C_QuestLog",
    "C_Reputation",
    "C_SuperTrack",
    "C_Timer",
    "C_TooltipInfo",
    "C_ToyBox",
    "C_TransmogCollection",
    "C_WeeklyRewards",
    "C_Secrets",
    
    -- Core Frame Functions
    "CreateFrame",
    "CreateFont",
    "CreateFromMixins",
    "Mixin",
    "BackdropTemplateMixin",
    "hooksecurefunc",
    "securecall",
    
    -- Fen Ecosystem
    "FenCore",
    "FenUI",
    
    -- Global UI Objects
    "UIParent",
    "WorldFrame",
    "GameTooltip",
    "GameFontNormal",
    "GameFontHighlight",
    "GameFontNormalSmall",
    "GameFontHighlightSmall",
    "GameFontNormalLarge",
    "GameFontHighlightLarge",
    "GameFontDisable",
    "GameFontDisableSmall",
    "DEFAULT_CHAT_FRAME",
    
    -- UI Systems
    "InterfaceOptionsFrame_OpenToCategory",
    "Settings",
    "QuestMapFrame_OpenToQuestDetails",
    "ToggleQuestLog",
    "SetCollectionsJournalShown",
    "OpenAchievementFrameToAchievement",
    "HousingDashboardFrame",
    "MenuUtil",
    "StaticPopup_Show",
    "StaticPopupDialogs",
    "CANCEL",
    "HousingFramesUtil",
    "GetMouseButtonClicked",
    "UiMapPoint",
    "AddonCompartmentFrame",
    "CreateColor",
    "ColorMixin",
    
    -- Encounter Journal
    "EJ_GetEncounterInfo",
    "EJ_GetCreatureInfo",
    "EJ_GetCurrentInstance",
    "EJ_SelectInstance",
    "UnitName",
    "UnitClass",
    "UnitFactionGroup",
    "UnitGUID",
    "UnitExists",
    "GetSpecialization",
    "GetSpecializationInfo",
    
    -- Combat & Instances
    "InCombatLockdown",
    "IsEncounterInProgress",
    "IsInInstance",
    "IsInGroup",
    "IsInRaid",
    "GetNumGroupMembers",
    "GetInstanceInfo",
    "GetDifficultyInfo",
    "GetNumSavedInstances",
    "GetSavedInstanceInfo",
    "GetSavedInstanceEncounterInfo",
    
    -- Achievements
    "GetAchievementInfo",
    "GetAchievementLink",
    
    -- Quests (Legacy)
    "IsQuestFlaggedCompleted",
    
    -- Currency (Legacy)
    "GetCurrencyInfo",
    
    -- Map (Legacy)
    "GetMapInfo",
    "GetPlayerMapPosition",
    "GetRealZoneText",
    "GetSubZoneText",
    
    -- Build & Server Info
    "GetBuildInfo",
    "GetRealmName",
    "GetServerTime",
    "GetTime",
    "GetExpansionLevel",
    "GetLocale",
    
    -- Addon Management
    "GetAddOnMetadata",
    "IsAddOnLoaded",
    
    -- Libraries
    "LibStub",
    
    -- Sound
    "PlaySound",
    "SOUNDKIT",
    
    -- Utility
    "print",
    "date",
    "time",
    "debugprofilestop",
    "debugstack",
    "geterrorhandler",
    "issecretvalue",
    "SecondsFormatter",
    "strtrim",
    "strsplit",
    "strjoin",
    "strfind",
    "strlen",
    "strsub",
    "strlower",
    "strupper",
    "strmatch",
    "gsub",
    "format",
    "wipe",
    "tinsert",
    "tremove",
    "tContains",
    "CopyTable",
    "FormatLargeNumber",
    "GetScreenWidth",
    "GetScreenHeight",
    "GetCVar",
    "ReloadUI",
    
    -- Constants
    "Enum",
    "LE_EXPANSION_WAR_WITHIN",
    "LE_EXPANSION_SHADOWLANDS",
    "LE_EXPANSION_DRAGONFLIGHT",
    "RAID_CLASS_COLORS",
    "ITEM_QUALITY_COLORS",
    
    -- Lua Standard
    "math",
    "string",
    "table",
    "bit",
    "ceil",
    "floor",
    "abs",
    "min",
    "max",
    "sqrt",
    "random",
    "pairs",
    "ipairs",
    "next",
    "select",
    "type",
    "tostring",
    "tonumber",
    "unpack",
    "pcall",
    "xpcall",
    "assert",
    "error",
    "rawget",
    "rawset",
    "setmetatable",
    "getmetatable",
    "CALENDAR_FULLDATE_MONTH_NAMES",
}

-- Ignore specific warning codes
ignore = {
    "211/_.*",      -- Unused variables starting with underscore
    "212/self",     -- Unused 'self' argument
    "212/_.*",      -- Unused arguments starting with underscore
    "212/%.%.%.",   -- Unused variable length argument (vararg)
    "213/_.*",      -- Unused loop variables starting with underscore
    "311",          -- Value assigned to variable is unused (common in loops)
    "421",          -- Variable shadowing (common in nested callbacks)
    "432",          -- Shadowing upvalue (common in OOP patterns)
    "542",          -- Empty if branch (used for intentional early-returns)
    "631",          -- Line too long
}

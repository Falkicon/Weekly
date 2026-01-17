---@class WeeklyActions
---@field Tracker TrackerActions
---@field Journal JournalActions

local _, ns = ...
local Actions = {}
ns.Actions = Actions

-- Action modules are registered here after loading
-- See tracker.lua and journal.lua for implementations

return Actions

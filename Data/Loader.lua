local _, ns = ...

-- Data Loader & Registry
ns.Data = ns.Data or {}
ns.Data.Registry = {}

--- Register a new season dataset
-- @param expansionID number: Expansion ID (e.g. 11 for TWW)
-- @param seasonID number: Season ID (e.g. 3)
-- @param data table: The data table for this season
function ns.Data:Register(expansionID, seasonID, data)
    if not self.Registry[expansionID] then
        self.Registry[expansionID] = {}
    end
    self.Registry[expansionID][seasonID] = data
end

--- Get a specific season dataset
function ns.Data:Get(expansionID, seasonID)
    if self.Registry[expansionID] and self.Registry[expansionID][seasonID] then
        return self.Registry[expansionID][seasonID]
    end
    return nil
end

--- Get all registered expansions (for Config)
function ns.Data:GetExpansions()
    local exps = {}
    for id, _ in pairs(self.Registry) do
        table.insert(exps, id)
    end
    table.sort(exps)
    return exps
end

--- Get all seasons for an expansion (for Config)
function ns.Data:GetSeasons(expansionID)
    local seasons = {}
    if self.Registry[expansionID] then
        for id, _ in pairs(self.Registry[expansionID]) do
            table.insert(seasons, id)
        end
    end
    table.sort(seasons)
    return seasons
end

-- Fallback / Helper to get current season based on Config
function ns:GetCurrentSeasonData()
    local cfg = ns.Config
    if not cfg then return {} end
    
    local exp = cfg.selectedExpansion or 11
    local sea = cfg.selectedSeason or 3
    
    return self.Data:Get(exp, sea) or {}
end

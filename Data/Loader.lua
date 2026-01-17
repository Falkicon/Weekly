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

--- Get the recommended expansion and season based on client version/date
function ns.Data:GetRecommendedSeason()
	local _, _, _, tocversion = GetBuildInfo()

	-- Expansion 12.0.1+ (Midnight Launch)
	if tocversion >= 120001 then
		return 12, 1
	end

	-- Expansion 12.0.0 (Midnight Pre-Patch) - Still TWW Season 3 with time-gated additions
	if tocversion >= 120000 then
		return 11, 3
	end

	-- Expansion 11 (TWW) - Season 3
	return 11, 3
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
	if not cfg then
		return {}
	end

	local exp = cfg.selectedExpansion
	local sea = cfg.selectedSeason

	-- Handle Automatic selection
	if exp == "auto" or sea == "auto" then
		local autoExp, autoSea = self.Data:GetRecommendedSeason()
		if exp == "auto" then
			exp = autoExp
		end
		if sea == "auto" then
			sea = autoSea
		end
	end

	-- Fallbacks
	exp = exp or 11
	sea = sea or 3

	return self.Data:Get(exp, sea) or {}
end

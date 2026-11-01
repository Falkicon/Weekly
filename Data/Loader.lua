local _, ns = ...

-- Data Loader & Registry
ns.Data = ns.Data or {}
ns.Data.Registry = {}
ns.Data.Sources = {}

-- Client flavors. World of Warcraft: Forever runs on the modern client with a
-- 1.60+ build line, so its datasets share this schema but must never be
-- auto-selected on Retail (and vice versa).
ns.Data.FLAVOR_MAINLINE = "mainline"
ns.Data.FLAVOR_FOREVER = "forever"
ns.Data.FOREVER_EXPANSION = 1

--- Detect which client flavor is running.
-- Prefers a project constant when the client exposes one, then falls back to
-- the build line: Forever builds are 1.60.x (16000+) while Classic Era stays
-- on 1.15.x, so the range is unambiguous.
-- @return string: ns.Data.FLAVOR_FOREVER or ns.Data.FLAVOR_MAINLINE
function ns.Data:GetClientFlavor()
	local foreverProject = WOW_PROJECT_FOREVER or WOW_PROJECT_CAMELOT
	if foreverProject and WOW_PROJECT_ID == foreverProject then
		return self.FLAVOR_FOREVER
	end
	local _, _, _, tocversion = GetBuildInfo()
	if type(tocversion) == "number" and tocversion >= 16000 and tocversion < 20000 then
		return self.FLAVOR_FOREVER
	end
	return self.FLAVOR_MAINLINE
end

--- Flavor that owns a registered expansion ID.
function ns.Data:GetExpansionFlavor(expansionID)
	if expansionID == self.FOREVER_EXPANSION then
		return self.FLAVOR_FOREVER
	end
	return self.FLAVOR_MAINLINE
end

local parsedDates = {}

local function ParseDate(dateStr)
	if not dateStr then
		return nil
	end
	if parsedDates[dateStr] ~= nil then
		return parsedDates[dateStr] or nil
	end

	local y, m, d = dateStr:match("(%d+)-(%d+)-(%d+)")
	if y and m and d then
		parsedDates[dateStr] = time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0 })
		return parsedDates[dateStr]
	end
	parsedDates[dateStr] = false
	return nil
end

function ns.Data:IsSectionVisible(section, cfg, now)
	if cfg and type(cfg.debug) == "table" and cfg.debug.ignoreTimeGates then
		return true
	end
	now = now or time()
	local showTime = ParseDate(section.showAfter)
	local hideTime = ParseDate(section.hideAfter)
	return not (showTime and now < showTime) and not (hideTime and now >= hideTime)
end

function ns.Data:GetItemConfigKey(item)
	if item.key then
		return tostring(item.key)
	end
	local id = item.id
	if type(id) == "table" then
		id = id[1]
	elseif id == nil and item.ids then
		id = item.ids[1]
	end
	if id ~= nil and id ~= 0 then
		return string.format("%s:%s", item.type or "item", tostring(id))
	end
	return string.format("%s:%s", item.type or "item", item.label or "unknown")
end

function ns.Data:GetLegacyItemConfigKey(item)
	local id = item.id
	if type(id) == "table" then
		id = id[1]
	elseif id == nil and item.ids then
		id = item.ids[1]
	end
	return id
end

--- Register a new season dataset
-- @param expansionID number: Expansion ID (e.g. 11 for TWW)
-- @param seasonID number: Season ID (e.g. 3)
-- @param data table: The data table for this season
-- @param source string|nil: Repository-relative source path for validation errors
function ns.Data:Register(expansionID, seasonID, data, source)
	if not self.Registry[expansionID] then
		self.Registry[expansionID] = {}
	end
	self.Registry[expansionID][seasonID] = data

	if source then
		if not self.Sources[expansionID] then
			self.Sources[expansionID] = {}
		end
		self.Sources[expansionID][seasonID] = source
	end
end

--- Get the recommended expansion and season based on client version
function ns.Data:GetRecommendedSeason()
	-- Forever ships content updates instead of seasons. Its build line (1.60.x)
	-- sits below every Retail threshold, so resolve the flavor first.
	if self:GetClientFlavor() == self.FLAVOR_FOREVER then
		return self.FOREVER_EXPANSION, 1
	end

	local _, _, _, tocversion = GetBuildInfo()

	-- Expansion 12.1.0+ (Curse of Ula'tek / Midnight Season 2)
	-- Build-gating also makes the dataset available on PTR before the live launch.
	if tocversion >= 120100 then
		return 12, 2
	end

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
-- @param flavor string|nil: Only expansions owned by this client flavor
function ns.Data:GetExpansions(flavor)
	local exps = {}
	for id, _ in pairs(self.Registry) do
		if flavor == nil or self:GetExpansionFlavor(id) == flavor then
			table.insert(exps, id)
		end
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
			if exp == autoExp then
				sea = autoSea
			else
				local seasons = self.Data:GetSeasons(exp)
				sea = seasons[#seasons]
			end
		end
	end

	-- Fallbacks
	exp = exp or 12
	sea = sea or 1

	return self.Data:Get(exp, sea) or {}
end

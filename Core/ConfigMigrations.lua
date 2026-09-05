local _, ns = ...

-- Versions belong to saved records, never AceDB defaults: a default version
-- would make an old profile appear migrated before its data is inspected.
local Migrations = { PROFILE_VERSION = 2, CHARACTER_VERSION = 1 }
ns.ConfigMigrations = Migrations

local function normalize(record, defaults)
	for key, default in pairs(defaults) do
		local value = record[key]
		if type(default) == "table" then
			if type(value) ~= "table" then
				value = {}
				record[key] = value
			end
			normalize(value, default)
		elseif
			type(value) ~= type(default)
			or (type(value) == "number" and (value ~= value or math.abs(value) == math.huge))
		then
			-- Expansion/season IDs accept either a number or the string "auto".
			if
				not (
					(key == "selectedExpansion" or key == "selectedSeason")
					and type(value) == "number"
					and value > 0
					and value < math.huge
				)
			then
				record[key] = default
			end
		end
	end
end

local profileSteps = {
	function(profile)
		-- Preserve the previous one-time migration semantics, including explicit
		-- choices made after those migrations ran in older releases.
		if profile._autoShowMigrated == nil and profile.autoShow == true then
			profile.autoShow = false
		end
		if profile._anchorMigrated == nil then
			profile.anchor = "TOP"
		end
		profile._autoShowMigrated = true
		profile._anchorMigrated = true
	end,
	function(profile, defaults)
		if type(profile.debug) == "boolean" then
			profile.debug = { enabled = profile.debug }
		end
		normalize(profile, defaults)
		for category, items in pairs(profile.journal.categories) do
			if type(items) ~= "table" then
				profile.journal.categories[category] = {}
			end
		end
		-- Journal contents are intentionally opaque. Do not rebuild collections
		-- or gathering records while repairing their surrounding settings.
	end,
}

local characterSteps = {
	function(character, defaults)
		normalize(character, defaults)
	end,
}

local function migrate(record, defaults, steps)
	assert(type(record) == "table", "Migration requires a saved-data table")
	local version = rawget(record, "schemaVersion")
	if version == nil then
		version = 0
	end
	-- An unknown/future schema must remain untouched on an addon downgrade.
	if type(version) ~= "number" or version < 0 or version % 1 ~= 0 or version > #steps then
		return false
	end
	for nextVersion = version + 1, #steps do
		steps[nextVersion](record, defaults)
		-- A failed stage remains retryable; never stamp the target in advance.
		record.schemaVersion = nextVersion
	end
	return true
end

function Migrations:MigrateProfile(profile, defaults)
	return migrate(profile, defaults, profileSteps)
end

function Migrations:MigrateCharacter(character, defaults)
	return migrate(character, defaults, characterSteps)
end

function Migrations:Migrate(profile, character, defaults)
	local profileSupported = self:MigrateProfile(profile, defaults.profile)
	local characterSupported = self:MigrateCharacter(character, defaults.char)
	return profileSupported and characterSupported
end

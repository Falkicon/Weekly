local ns

describe("Versioned saved-data migrations", function()
	before_each(function()
		ns = {}
		_G.LibStub = function()
			return {}
		end
		assert(loadfile("Config.lua"))("Weekly", ns)
		assert(loadfile("Core/ConfigMigrations.lua"))("Weekly", ns)
	end)

	it("upgrades old profiles and independently versions character data", function()
		local profile = { autoShow = true, anchor = "BOTTOM", selectedExpansion = 11, selectedSeason = 2 }
		local character = { prey = { count = 7, partial = false } }
		assert.is_true(ns.ConfigMigrations:Migrate(profile, character, ns.ConfigDefaults))
		assert.equals(2, profile.schemaVersion)
		assert.equals(1, character.schemaVersion)
		assert.is_false(profile.autoShow)
		assert.equals("TOP", profile.anchor)
		assert.equals(11, profile.selectedExpansion)
		assert.equals(2, profile.selectedSeason)
		assert.equals(7, character.prey.count)
		assert.is_false(character.prey.partial)
		assert.equals(0, character.prey.nextReset)
	end)

	it("preserves migrated choices when a profile is copied and on repeated loads", function()
		local profile = { autoShow = true, anchor = "BOTTOM", _autoShowMigrated = true, _anchorMigrated = true }
		ns.ConfigMigrations:MigrateProfile(profile, ns.ConfigDefaults.profile)
		local copied = {}
		for key, value in pairs(profile) do
			copied[key] = value
		end
		ns.ConfigMigrations:MigrateProfile(copied, ns.ConfigDefaults.profile)
		assert.is_true(copied.autoShow)
		assert.equals("BOTTOM", copied.anchor)
		assert.same(profile, copied)
	end)

	it("retains legacy boolean debug preferences", function()
		for _, enabled in ipairs({ true, false }) do
			local profile = { debug = enabled }
			ns.ConfigMigrations:MigrateProfile(profile, ns.ConfigDefaults.profile)
			assert.equals(enabled, profile.debug.enabled)
			assert.is_false(profile.debug.ignoreTimeGates)
		end
	end)

	it("repairs malformed settings without replacing journal history or unknown fields", function()
		local categories = { mount = { [42] = { name = "Mount", custom = true } }, pet = false }
		local gathering = { [99] = { count = 15, expansion = 11 } }
		local profile = {
			journal = { categories = categories, gathering = gathering, weekStart = "bad", enabled = false },
			hiddenItems = false,
			collapsedSections = 1,
			debug = { enabled = "bad" },
			backgroundAlpha = math.huge,
			custom = { keep = true },
		}
		ns.ConfigMigrations:MigrateProfile(profile, ns.ConfigDefaults.profile)
		assert.equals(categories, profile.journal.categories)
		assert.same({}, profile.journal.categories.pet)
		assert.equals(gathering, profile.journal.gathering)
		assert.equals(15, profile.journal.gathering[99].count)
		assert.equals(0, profile.journal.weekStart)
		assert.is_false(profile.journal.enabled)
		assert.same({}, profile.hiddenItems)
		assert.same({}, profile.collapsedSections)
		assert.is_false(profile.debug.enabled)
		assert.equals(90, profile.backgroundAlpha)
		assert.is_true(profile.custom.keep)
	end)

	it("creates independent defaults for missing or malformed containers", function()
		local first, second, character = { journal = 3 }, {}, { prey = false }
		ns.ConfigMigrations:Migrate(first, character, ns.ConfigDefaults)
		ns.ConfigMigrations:MigrateProfile(second, ns.ConfigDefaults.profile)
		first.journal.categories.mount = { [42] = {} }
		assert.is_nil(second.journal.categories.mount)
		assert.is_nil(ns.ConfigDefaults.profile.journal.categories.mount)
		assert.is_nil(ns.ConfigDefaults.profile.schemaVersion)
		assert.is_nil(ns.ConfigDefaults.char.schemaVersion)
		assert.equals(0, character.prey.count)
	end)

	it("leaves future and unknown schema records unchanged", function()
		for _, version in ipairs({ 999, "unknown", -1, 0.5, false }) do
			local profile = { schemaVersion = version, debug = true, autoShow = true }
			assert.is_false(ns.ConfigMigrations:MigrateProfile(profile, ns.ConfigDefaults.profile))
			assert.same({ schemaVersion = version, debug = true, autoShow = true }, profile)
		end
	end)

	it("records only successful stages and retries an interrupted upgrade", function()
		local profile = { autoShow = true }
		assert.has_error(function()
			ns.ConfigMigrations:MigrateProfile(profile, nil)
		end)
		assert.equals(1, profile.schemaVersion)
		profile.autoShow = true
		ns.ConfigMigrations:MigrateProfile(profile, ns.ConfigDefaults.profile)
		assert.equals(2, profile.schemaVersion)
		assert.is_true(profile.autoShow)
	end)

	it("migrates actual AceDB profiles across copy and reset without default version leakage", function()
		_G.LibStub = nil
		_G.strmatch = string.match
		assert(loadfile("Libs/LibStub/LibStub.lua"))()
		_G.CreateFrame = function()
			return { RegisterEvent = function() end, SetScript = function() end }
		end
		_G.GetRealmName = function()
			return "Test Realm"
		end
		_G.UnitName = function()
			return "Tester"
		end
		_G.UnitClass = function()
			return "Mage", "MAGE"
		end
		_G.UnitRace = function()
			return "Human", "Human"
		end
		_G.UnitFactionGroup = function()
			return "Alliance"
		end
		_G.GetLocale = function()
			return "enUS"
		end
		_G.GetCurrentRegion = function()
			return 1
		end
		assert(loadfile("Libs/AceDB-3.0/AceDB-3.0.lua"))()
		local db = LibStub("AceDB-3.0"):New({ profiles = { Old = { autoShow = true } } }, ns.ConfigDefaults, "Old")
		assert.is_nil(rawget(db.profile, "schemaVersion"))
		ns.ConfigMigrations:Migrate(db.profile, db.char, ns.ConfigDefaults)
		assert.is_false(db.profile.autoShow)
		db.profile.autoShow = true
		db:SetProfile("Copy")
		db:CopyProfile("Old")
		ns.ConfigMigrations:Migrate(db.profile, db.char, ns.ConfigDefaults)
		assert.is_true(db.profile.autoShow)
		db:ResetProfile()
		assert.is_nil(rawget(db.profile, "schemaVersion"))
		ns.ConfigMigrations:Migrate(db.profile, db.char, ns.ConfigDefaults)
		assert.equals(2, db.profile.schemaVersion)
		assert.is_false(db.profile.autoShow)
	end)
end)

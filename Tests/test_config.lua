local ns
local database

describe("Weekly profile migrations", function()
	before_each(function()
		ns = {}
		database = {
			profile = { autoShow = false },
			char = {},
			RegisterCallback = function() end,
		}
		_G.LibStub = function()
			return {
				New = function()
					return database
				end,
			}
		end
		local chunk = assert(loadfile("Config.lua"))
		assert(loadfile("Core/ConfigMigrations.lua"))("Weekly", ns)
		setfenv(chunk, getfenv(1))
		chunk("Weekly", ns)
	end)

	it("preserves an explicit auto-show choice across reloads", function()
		ns:LoadConfig()
		ns.Config.autoShow = true
		ns:LoadConfig()
		assert.is_true(ns.Config.autoShow)
	end)

	it("migrates the old auto-show default only once", function()
		database.profile.autoShow = true
		ns:LoadConfig()
		assert.is_false(ns.Config.autoShow)
		ns.Config.autoShow = true
		ns:LoadConfig()
		assert.is_true(ns.Config.autoShow)
	end)

	it("marks newly selected profiles before the user changes settings", function()
		ns:LoadConfig()
		database.profile = { autoShow = false }
		ns:RefreshConfig()
		ns.Config.autoShow = true
		ns:LoadConfig()
		assert.is_true(ns.Config.autoShow)
	end)

	it("applies the selected profile after rebinding and migrating its configuration", function()
		ns:LoadConfig()
		local applied = 0
		ns.Weekly = {
			ApplyConfig = function(_, reason)
				assert.equals("profile", reason)
				assert.equals(database.profile, ns.Config)
				assert.equals(ns.ConfigMigrations.PROFILE_VERSION, ns.Config.schemaVersion)
				applied = applied + 1
			end,
		}
		database.profile = { visible = false, autoShow = true, _autoShowMigrated = true }
		ns:RefreshConfig()
		assert.is_false(ns.Config.visible)
		assert.is_true(ns.Config.autoShow)
		database.profile = { visible = true }
		ns:RefreshConfig()
		assert.is_true(ns.Config.visible)
		assert.equals(2, applied)
	end)
end)

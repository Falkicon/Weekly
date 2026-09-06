local addonName = "Weekly"
local ns = {}

local function LoadFile(path)
	local func, err = loadfile(path)
	if not func then
		error("Failed to load " .. path .. ": " .. err)
	end
	setfenv(func, getfenv(1))
	func(addonName, ns)
end

describe("Weekly Config UI", function()
	local optionTables

	before_each(function()
		optionTables = {}
		ns = {
			Config = {
				selectedExpansion = "auto",
				selectedSeason = "auto",
				hiddenItems = {},
				journal = { enabled = true },
			},
			db = {},
			Data = {
				GetExpansions = function()
					return { 11, 12 }
				end,
				GetSeasons = function()
					return { 1, 2 }
				end,
				GetRecommendedSeason = function()
					return 12, 2
				end,
				IsSectionVisible = function()
					return true
				end,
			},
			GetCurrentSeasonData = function()
				return {}
			end,
		}
		_G.WeeklyDB = nil
		_G.time = function()
			return 1000
		end
		_G.Settings = {
			GetCategory = function()
				return {
					GetID = function()
						return 42
					end,
				}
			end,
		}
		local locale = setmetatable({}, {
			__index = function(_, key)
				return key
			end,
		})
		local AceConfig = {
			RegisterOptionsTable = function(_, name, options)
				optionTables[name] = options
			end,
		}
		local AceConfigDialog = {
			AddToBlizOptions = function()
				return { name = "Weekly" }
			end,
		}
		_G.LibStub = function(name)
			if name == "AceConfig-3.0" then
				return AceConfig
			elseif name == "AceConfigDialog-3.0" then
				return AceConfigDialog
			elseif name == "LibSharedMedia-3.0" then
				return {
					HashTable = function()
						return {}
					end,
				}
			elseif name == "AceLocale-3.0" then
				return {
					GetLocale = function()
						return locale
					end,
				}
			elseif name == "AceDBOptions-3.0" then
				return {
					GetOptionsTable = function()
						return { type = "group", args = {} }
					end,
				}
			end
		end
		LoadFile("ConfigUI.lua")
		ns.ConfigUI:Initialize()
	end)

	it("reports the minimap icon as visible before default settings are materialized", function()
		local option = optionTables.Weekly_Journal.args.showMinimapIcon
		assert.is_true(option.get())
	end)

	it("uses the broker as the source of truth for minimap visibility", function()
		ns.JournalBroker = {
			IsMinimapIconShown = function()
				return false
			end,
		}
		local option = optionTables.Weekly_Journal.args.showMinimapIcon
		assert.is_false(option.get())
	end)
end)

-- Unit tests for the season dataset schema validator.

local addonName = "Weekly"
local ns = {}

_G = _G or {}
_G.GetBuildInfo = function()
	return "12.1.0", "70000", "Aug 2026", 120100
end
_G.time = function(value)
	if value then
		return (value.year * 10000) + (value.month * 100) + value.day
	end
	return 20260905
end

local function LoadFile(path)
	local func, err = loadfile(path)
	if not func then
		error("Failed to load " .. path .. ": " .. err)
	end
	setfenv(func, getfenv(1))
	func(addonName, ns)
end

local function LoadShippedData()
	local loadedFiles = 0
	for line in io.lines("Weekly.toc") do
		local path = line:gsub("%s+$", ""):gsub("\\", "/")
		if path:match("^Data/.+%.lua$") then
			LoadFile(path)
			loadedFiles = loadedFiles + 1
		end
	end
	if loadedFiles == 0 then
		error("Weekly.toc does not contain any Data/*.lua entries")
	end
end

local function HasError(errors, text)
	for _, validationError in ipairs(errors) do
		if validationError:find(text, 1, true) then
			return true
		end
	end
	return false
end

describe("Weekly season data validation", function()
	before_each(function()
		ns = {}
		LoadShippedData()
	end)

	it("accepts every shipped season dataset", function()
		assert.is_not_nil(next(ns.Data.Registry), "Weekly.toc did not load any registered season datasets")
		local valid, errors = ns.Data:ValidateRegistry()
		assert.is_true(valid, table.concat(errors, "\n"))
		assert.are.same({}, errors)
	end)

	it("resolves registered data at every recommended-season build boundary", function()
		local boundaries = {
			{ build = 119999, expansion = 11, season = 3 },
			{ build = 120000, expansion = 11, season = 3 },
			{ build = 120001, expansion = 12, season = 1 },
			{ build = 120099, expansion = 12, season = 1 },
			{ build = 120100, expansion = 12, season = 2 },
		}

		for _, boundary in ipairs(boundaries) do
			_G.GetBuildInfo = function()
				return "test", "test", "test", boundary.build
			end
			local expansionID, seasonID = ns.Data:GetRecommendedSeason()
			assert.are.equal(boundary.expansion, expansionID)
			assert.are.equal(boundary.season, seasonID)
			assert.is_table(ns.Data:Get(expansionID, seasonID))
		end
	end)

	it("requires zero-ID quest placeholders to be explicit", function()
		local barePlaceholder = {
			{ title = "Events", items = { ns.DataFactory.Quest(0, "Unconfirmed Quest") } },
		}
		local valid, errors = ns.Data:ValidateDataset(barePlaceholder, "Data/Fixture.lua")
		assert.is_false(valid)
		assert.is_true(HasError(errors, "Data/Fixture.lua.sections[1].items[1].id: must be a positive integer ID"))

		local explicitPlaceholder = {
			{ title = "Events", items = { ns.DataFactory.PlaceholderQuest("Unconfirmed Quest") } },
		}
		valid, errors = ns.Data:ValidateDataset(explicitPlaceholder, "Data/Fixture.lua")
		assert.is_true(valid, table.concat(errors, "\n"))
	end)

	it("rejects impossible and reversed calendar gates with section paths", function()
		local dataset = {
			{
				title = "Bad dates",
				showAfter = "2026-2-28",
				hideAfter = "2025-02-28",
				items = {},
			},
		}
		local valid, errors = ns.Data:ValidateDataset(dataset, "Data/Fixture.lua")
		assert.is_false(valid)
		assert.is_true(HasError(errors, "Data/Fixture.lua.sections[1].showAfter: must use YYYY-MM-DD"))

		dataset[1].showAfter = "2025-02-29"
		valid, errors = ns.Data:ValidateDataset(dataset, "Data/Fixture.lua")
		assert.is_false(valid)
		assert.is_true(HasError(errors, "Data/Fixture.lua.sections[1].showAfter: must be a real calendar date"))

		dataset[1].showAfter = "2026-03-02"
		valid, errors = ns.Data:ValidateDataset(dataset, "Data/Fixture.lua")
		assert.is_false(valid)
		assert.is_true(HasError(errors, "Data/Fixture.lua.sections[1]: showAfter must be earlier than hideAfter"))
	end)

	it("validates tracker IDs, counts, types, and coordinates", function()
		local dataset = {
			{
				title = "Invalid trackers",
				items = {
					{ type = "currency", id = -1 },
					{ type = "quest", id = 10, coords = { mapID = 0, x = -0.1, y = 1.1 } },
					{ type = "prey", maxCount = 0 },
					{ type = "header", id = 10 },
				},
			},
		}
		local valid, errors = ns.Data:ValidateDataset(dataset, "Data/Fixture.lua")
		assert.is_false(valid)
		assert.is_true(HasError(errors, ".items[1].id: must be a positive integer ID"))
		assert.is_true(HasError(errors, ".items[2].coords.mapID: must be a positive integer ID"))
		assert.is_true(HasError(errors, ".items[2].coords.x: must be a number from 0 through 1"))
		assert.is_true(HasError(errors, ".items[3].maxCount: must be a positive integer"))
		assert.is_true(HasError(errors, ".items[3]: prey trackers require ids or questId"))
		assert.is_true(HasError(errors, '.items[4].type: unsupported tracker type "header"'))
	end)

	it("does not traverse malformed sparse arrays or throw on malformed ID lists", function()
		local sparseDataset = {}
		sparseDataset[1000000000] = { title = "Far away", items = {} }
		local valid, errors = ns.Data:ValidateDataset(sparseDataset, "Data/Sparse.lua")
		assert.is_false(valid)
		assert.is_true(HasError(errors, "Data/Sparse.lua.sections: must be a contiguous array"))

		local malformedIDs = {
			{ title = "Prey", items = { { type = "prey", ids = 42, maxCount = 4 } } },
		}
		valid, errors = ns.Data:ValidateDataset(malformedIDs, "Data/Malformed.lua")
		assert.is_false(valid)
		assert.is_true(HasError(errors, "Data/Malformed.lua.sections[1].items[1].ids: must be an array"))
	end)

	it("accepts numeric texture IDs and rejects non-finite coordinates", function()
		local dataset = {
			{
				title = "Map objective",
				items = {
					{ type = "quest", id = 10, icon = 134400, coords = { mapID = 1, x = 0, y = 1 } },
				},
			},
		}
		local valid, errors = ns.Data:ValidateDataset(dataset, "Data/Fixture.lua")
		assert.is_true(valid, table.concat(errors, "\n"))

		dataset[1].items[1].coords.x = 0 / 0
		dataset[1].items[1].coords.y = math.huge
		valid, errors = ns.Data:ValidateDataset(dataset, "Data/Fixture.lua")
		assert.is_false(valid)
		assert.is_true(HasError(errors, ".coords.x: must be a number from 0 through 1"))
		assert.is_true(HasError(errors, ".coords.y: must be a number from 0 through 1"))
	end)

	it("detects settings-key collisions within a season", function()
		local dataset = {
			{
				title = "First",
				items = { { type = "quest", id = 100, key = "shared-setting" } },
			},
			{
				title = "Second",
				items = { { type = "currency", id = 200, key = "shared-setting" } },
			},
		}
		local valid, errors = ns.Data:ValidateDataset(dataset, "Data/Fixture.lua")
		assert.is_false(valid)
		assert.is_true(
			HasError(errors, 'configuration key "shared-setting" conflicts with Data/Fixture.lua.sections[1].items[1]')
		)
	end)

	it("reports invalid registry IDs", function()
		ns.Data.Registry["midnight"] = { [0] = {} }
		local valid, errors = ns.Data:ValidateRegistry()
		assert.is_false(valid)
		assert.is_true(HasError(errors, "Registry[midnight]: expansion ID must be a positive integer"))
		assert.is_true(HasError(errors, "Registry[midnight][0]: season ID must be a positive integer"))
	end)
end)

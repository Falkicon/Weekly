-- test_data_loader.lua
-- Unit tests for Weekly data registration and loading

local addonName = "Weekly"
local ns = {}

-- Mock WoW APIs
_G = _G or {}
GetBuildInfo = function()
	return "11.2.7", "67748", "Dec 20 2025", 110207 -- TWW S3
end
time = function(value)
	if value then
		return (value.year * 10000) + (value.month * 100) + value.day
	end
	return 20260810
end

-- Load the code under test
-- (In a real Busted environment, we'd use loadfile)
local function LoadFile(path)
	local func, err = loadfile(path)
	if not func then
		error("Failed to load " .. path .. ": " .. err)
	end
	func(addonName, ns)
end

-- Setup test environment
describe("Weekly Data Loader", function()
	before_each(function()
		ns = {}
		LoadFile("Data/Loader.lua")
	end)

	it("should register and retrieve data correctly", function()
		local testData = { { type = "header", text = "Test Season" } }
		ns.Data:Register(11, 1, testData)

		local retrieved = ns.Data:Get(11, 1)
		assert.are.equal(testData, retrieved)
	end)

	it("should return recommended season for TWW Season 3", function()
		-- Mock TWW S3 build
		GetBuildInfo = function()
			return "11.2.7", "12345", "Dec 2025", 110207
		end

		local exp, sea = ns.Data:GetRecommendedSeason()
		assert.are.equal(11, exp)
		assert.are.equal(3, sea)
	end)

	it("should keep TWW Season 3 selected before the Midnight pre-patch", function()
		GetBuildInfo = function()
			return "11.2.8", "12345", "Dec 2025", 110208
		end

		local exp, sea = ns.Data:GetRecommendedSeason()
		assert.are.equal(11, exp)
		assert.are.equal(3, sea)
	end)

	it("should keep TWW Season 3 selected during the Midnight pre-patch", function()
		GetBuildInfo = function()
			return "12.0.0", "12345", "Jan 2026", 120000
		end

		local exp, sea = ns.Data:GetRecommendedSeason()
		assert.are.equal(11, exp)
		assert.are.equal(3, sea)
	end)

	it("should select Midnight Season 1 on 12.0.1 clients", function()
		GetBuildInfo = function()
			return "12.0.1", "12345", "Mar 2026", 120001
		end

		local exp, sea = ns.Data:GetRecommendedSeason()
		assert.are.equal(12, exp)
		assert.are.equal(1, sea)
	end)

	it("should select Midnight Season 2 on 12.1.0 clients", function()
		GetBuildInfo = function()
			return "12.1.0", "12345", "Aug 2026", 120100
		end

		local exp, sea = ns.Data:GetRecommendedSeason()
		assert.are.equal(12, exp)
		assert.are.equal(2, sea)
	end)

	it("should expose the Season 2 cache objective separately from the 15-hunt ledger", function()
		LoadFile("Data/Factories.lua")
		LoadFile("Data/Midnight/Season2.lua")
		local data = ns.Data:Get(12, 2)
		local cache = data[2].items[2]
		local hunts = data[3].items[1]

		assert.are.equal(93910, cache.id)
		assert.are.equal(3, cache.preyCacheMax)
		assert.are.equal(15, hunts.maxCount)
		assert.are.equal(93910, hunts.questId)
	end)

	it("should list registered expansions correctly", function()
		ns.Data:Register(11, 3, {})
		ns.Data:Register(12, 1, {})

		local exps = ns.Data:GetExpansions()
		assert.are.equal(2, #exps)
		assert.are.equal(11, exps[1])
		assert.are.equal(12, exps[2])
	end)

	it("should list seasons for a specific expansion correctly", function()
		ns.Data:Register(11, 3, {})
		ns.Data:Register(11, 4, {})

		local seasons = ns.Data:GetSeasons(11)
		assert.are.equal(2, #seasons)
		assert.are.equal(3, seasons[1])
		assert.are.equal(4, seasons[2])
	end)

	it("should handle automatic season selection based on config", function()
		ns.Config = {
			selectedExpansion = "auto",
			selectedSeason = "auto",
		}

		-- Register some data
		local s3Data = { { id = "s3" } }
		ns.Data:Register(11, 3, s3Data)

		-- Mock TWW S3 build
		GetBuildInfo = function()
			return "11.2.7", "12345", "Dec 2025", 110207
		end

		local data = ns:GetCurrentSeasonData()
		assert.are.equal(s3Data, data)
	end)

	it("should choose the latest season for a manually selected expansion", function()
		ns.Config = {
			selectedExpansion = 11,
			selectedSeason = "auto",
		}
		ns.Data:Register(11, 3, { { id = "latest-tww" } })
		local data = ns:GetCurrentSeasonData()
		assert.are.equal("latest-tww", data[1].id)
	end)

	it("should generate collision-free configuration keys for placeholder rows", function()
		local first = ns.Data:GetItemConfigKey({ type = "quest", id = 0, label = "First" })
		local second = ns.Data:GetItemConfigKey({ type = "quest", id = 0, label = "Second" })
		assert.are.equal("quest:First", first)
		assert.are.equal("quest:Second", second)
	end)

	it("should namespace configuration keys by tracker type", function()
		assert.are.equal("quest:123", ns.Data:GetItemConfigKey({ type = "quest", id = 123 }))
		assert.are.equal("currency:123", ns.Data:GetItemConfigKey({ type = "currency", id = 123 }))
	end)

	it("should apply shared section time gates", function()
		local section = { showAfter = "2026-08-11", hideAfter = "2026-08-20" }
		assert.is_false(ns.Data:IsSectionVisible(section, {}, 20260810))
		assert.is_true(ns.Data:IsSectionVisible(section, {}, 20260811))
		assert.is_false(ns.Data:IsSectionVisible(section, {}, 20260820))
		assert.is_true(ns.Data:IsSectionVisible(section, { debug = { ignoreTimeGates = true } }, 20260810))
	end)
end)

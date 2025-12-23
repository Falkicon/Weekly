-- test_data_loader.lua
-- Unit tests for Weekly data registration and loading

local addonName = "Weekly"
local ns = {}

-- Mock WoW APIs
_G = _G or {}
GetBuildInfo = function()
	return "11.2.7", "67748", "Dec 20 2025", 110207 -- TWW S3
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
		LoadFile("_dev_/Weekly/Data/Loader.lua")
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

	it("should return recommended season for Midnight Pre-patch", function()
		-- Mock Midnight Pre-patch build
		GetBuildInfo = function()
			return "11.2.8", "12345", "Dec 2025", 110208
		end

		local exp, sea = ns.Data:GetRecommendedSeason()
		assert.are.equal(11, exp)
		assert.are.equal(3.5, sea)
	end)

	it("should return recommended season for Midnight", function()
		-- Mock Midnight build
		GetBuildInfo = function()
			return "12.0.0", "12345", "Jan 2026", 120000
		end

		local exp, sea = ns.Data:GetRecommendedSeason()
		assert.are.equal(12, exp)
		assert.are.equal(1, sea)
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
		ns.Data:Register(11, 3.5, {})

		local seasons = ns.Data:GetSeasons(11)
		assert.are.equal(2, #seasons)
		assert.are.equal(3, seasons[1])
		assert.are.equal(3.5, seasons[2])
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
end)

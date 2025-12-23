-- test_journal.lua
-- Unit tests for Weekly Journal logic

local addonName = "Weekly"
local ns = {}

-- Mock WoW APIs
_G = _G or {}
C_DateAndTime = {
	GetServerTimeLocal = function()
		return 1734566400
	end, -- A Tuesday
	GetCurrentCalendarTime = function()
		return {
			weekday = 3, -- Tuesday
			monthDay = 17,
			month = 12,
			hour = 10,
			minute = 0,
		}
	end,
}
time = function()
	return 1734566400
end
GetRealZoneText = function()
	return "Dornogal"
end
LibStub = function(name)
	return {
		GetLocale = function()
			return setmetatable({}, {
				__index = function(_, k)
					return k
				end,
			})
		end,
	}
end
CreateFrame = function()
	return {
		RegisterEvent = function() end,
		SetScript = function() end,
		UnregisterAllEvents = function() end,
	}
end

-- Mock TrackerCore
ns.TrackerCore = {
	CreateTracker = function(self, name, opts)
		local tracker = {
			items = {},
			itemCount = 0,
			LogItem = function(t, cat, id, data)
				t.items[cat] = t.items[cat] or {}
				if not t.items[cat][id] then
					t.items[cat][id] = data
					t.itemCount = t.itemCount + 1
					return true
				end
				return false
			end,
			Clear = function(t, cat)
				if cat then
					t.items[cat] = {}
				else
					t.items = {}
					t.itemCount = 0
				end
			end,
			GetCount = function(t, cat)
				local count = 0
				if t.items[cat] then
					for _ in pairs(t.items[cat]) do
						count = count + 1
					end
				end
				return count
			end,
			GetItems = function(t, filter)
				local results = {}
				for cat, items in pairs(t.items) do
					for id, data in pairs(items) do
						if filter(cat, id, data) then
							table.insert(results, { category = cat, id = id, data = data })
						end
					end
				end
				return results
			end,
			RegisterEvents = function() end,
			UnregisterEvents = function() end,
		}
		return tracker
	end,
}

-- Load the code under test
local function LoadFile(path)
	local func, err = loadfile(path)
	if not func then
		error("Failed to load " .. path .. ": " .. err)
	end
	func(addonName, ns)
end

describe("Weekly Journal", function()
	before_each(function()
		ns.Config = {
			journal = {
				enabled = true,
				weekStart = 1734566400,
				categories = {},
				gathering = {},
			},
		}
		LoadFile("_dev_/Weekly/Journal/Journal.lua")
		ns.Journal:Initialize()
	end)

	it("should calculate total item count correctly", function()
		ns.Journal.tracker:LogItem("mount", 123, { name = "Test Mount" })
		ns.Journal.tracker:LogItem("achievement", 456, { name = "Test Achievement" })

		assert.are.equal(2, ns.Journal:GetTotalCount())
	end)

	it("should calculate category count correctly", function()
		ns.Journal.tracker:LogItem("mount", 123, { name = "Test Mount" })
		ns.Journal.tracker:LogItem("mount", 124, { name = "Another Mount" })

		assert.are.equal(2, ns.Journal:GetCategoryCount("mount"))
		assert.are.equal(0, ns.Journal:GetCategoryCount("achievement"))
	end)

	it("should calculate achievement points correctly", function()
		ns.Journal.tracker:LogItem("achievement", 1, { points = 10 })
		ns.Journal.tracker:LogItem("achievement", 2, { points = 25 })

		assert.are.equal(35, ns.Journal:GetAchievementPointsThisWeek())
	end)

	it("should clear specific categories", function()
		ns.Journal.tracker:LogItem("mount", 123, { name = "Test Mount" })
		ns.Journal.tracker:LogItem("achievement", 456, { name = "Test Achievement" })

		ns.Journal:ClearCategory("mount")
		assert.are.equal(0, ns.Journal:GetCategoryCount("mount"))
		assert.are.equal(1, ns.Journal:GetCategoryCount("achievement"))
	end)

	it("should clear all data", function()
		ns.Journal.tracker:LogItem("mount", 123, { name = "Test Mount" })
		ns.Journal.gathering[123] = { count = 10 }

		ns.Journal:ClearAll()
		assert.are.equal(0, ns.Journal:GetTotalCount())
		assert.are.equal(0, ns.Journal:GetGatheringTotalCount())
	end)

	it("should detect weekly reset correctly", function()
		-- Mock current week as Tuesday Dec 17 2025 (1734566400)
		-- If saved weekStart is older, it should reset
		ns.Config.journal.weekStart = 1733875200 -- Previous Tuesday

		-- Re-initialize to trigger check
		ns.Journal.tracker = nil
		ns.Journal:Initialize()

		-- It should have updated weekStart to current Tuesday
		assert.are.equal(1734566400, ns.Config.journal.weekStart)
	end)
end)

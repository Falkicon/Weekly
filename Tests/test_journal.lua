-- test_journal.lua
-- Unit tests for Weekly Journal logic

local addonName = "Weekly"
local ns = {}

-- Mock WoW APIs
_G = _G or {}
_G.C_DateAndTime = {
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
	GetSecondsUntilWeeklyReset = function()
		return 604800
	end,
}
_G.time = function()
	return 1734566400
end
_G.GetServerTime = function()
	return 1734566400
end
_G.debugprofilestop = function()
	return 0
end
_G.GetRealZoneText = function()
	return "Dornogal"
end
_G.LibStub = function(name)
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
_G.CreateFrame = function()
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
			RegisterEvents = function(t, events)
				t.events = events
			end,
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
	setfenv(func, getfenv(1))
	func(addonName, ns)
end

LoadFile("Core/WeeklyReset.lua")

describe("Weekly Journal", function()
	before_each(function()
		_G.LOOT_ITEM_SELF = "You receive loot: %s."
		_G.LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %s x%d."
		local itemCached = true
		local requestedItemID
		_G.C_Item = {
			GetItemNameByID = function()
				return "Test Herb"
			end,
			GetItemIconByID = function()
				return 1234
			end,
			RequestLoadItemDataByID = function(id)
				requestedItemID = id
			end,
		}
		ns.Config = {
			journal = {
				enabled = true,
				weekStart = 1734566400,
				nextReset = 1734566400 + 604800,
				categories = {},
				gathering = {},
			},
		}
		ns.Context = {
			BuildLootClassifyContext = function(_, itemID)
				if not itemCached then
					return nil
				end
				return { itemID = itemID, itemSubClassID = 9 }
			end,
		}
		ns.Actions = {
			Journal = {
				ParseLootMessage = function(context)
					local itemLink = context.message:match("|c%x+|Hitem:[^|]+|h%[.-%]|h|r")
					local quantity = tonumber(context.message:match(" x(%d+)")) or 1
					return {
						success = true,
						data = {
							itemLink = itemLink,
							itemID = itemLink and tonumber(itemLink:match("item:(%d+)")),
							quantity = quantity,
						},
					}
				end,
				ClassifyLootItem = function(context)
					return { success = true, data = { isGathering = true, expansion = 11 } }
				end,
			},
		}
		LoadFile("Journal/Journal.lua")
		ns.Journal:Initialize()
		ns._journalTest = {
			setItemCached = function(value)
				itemCached = value
			end,
			getRequestedItemID = function()
				return requestedItemID
			end,
		}
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
		-- Simulate logging in after the saved reset boundary has passed.
		ns.Config.journal.nextReset = 1734566399

		-- Re-initialize to trigger check
		ns.Journal.tracker = nil
		ns.Journal:Initialize()

		-- It should have updated weekStart to current Tuesday
		assert.are.equal(1734566400, ns.Config.journal.weekStart)
		assert.are.equal(1734566400 + 604800, ns.Config.journal.nextReset)
	end)

	it("persists the outgoing profile before shutdown", function()
		ns.Journal.tracker:LogItem("mount", 123, { name = "Test Mount" })
		ns.Journal:Shutdown()

		assert.are.equal("Test Mount", ns.Config.journal.categories.mount[123].name)
		assert.is_nil(ns.Journal.tracker)
	end)

	it("only records loot received by this character", function()
		local link = "|cffffffff|Hitem:12345::::::::|h[Test Herb]|h|r"
		local onLoot = ns.Journal.tracker.events.CHAT_MSG_LOOT
		onLoot(ns.Journal.tracker, "CHAT_MSG_LOOT", "Another player receives loot: " .. link .. " x5.")
		assert.are.equal(0, ns.Journal:GetGatheringTotalCount())

		onLoot(ns.Journal.tracker, "CHAT_MSG_LOOT", (_G.LOOT_ITEM_SELF_MULTIPLE):format(link, 5))
		assert.are.equal(5, ns.Journal:GetGatheringTotalCount())
	end)

	it("retries gathering loot after item data becomes available", function()
		local link = "|cffffffff|Hitem:12345::::::::|h[Test Herb]|h|r"
		ns._journalTest.setItemCached(false)
		ns.Journal.tracker.events.CHAT_MSG_LOOT(
			ns.Journal.tracker,
			"CHAT_MSG_LOOT",
			(_G.LOOT_ITEM_SELF_MULTIPLE):format(link, 3)
		)
		assert.are.equal(12345, ns._journalTest.getRequestedItemID())
		assert.are.equal(0, ns.Journal:GetGatheringTotalCount())

		ns._journalTest.setItemCached(true)
		ns.Journal.tracker.events.GET_ITEM_INFO_RECEIVED(ns.Journal.tracker, "GET_ITEM_INFO_RECEIVED", 12345, true)
		assert.are.equal(3, ns.Journal:GetGatheringTotalCount())
	end)
end)

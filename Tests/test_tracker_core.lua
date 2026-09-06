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

describe("Weekly TrackerCore", function()
	before_each(function()
		ns = {}
		_G.time = function()
			return 1000
		end
		_G.date = function()
			return "1970-01-01 00:16:40"
		end
		LoadFile("TrackerCore.lua")
	end)

	it("deduplicates logged items and keeps its count accurate", function()
		local tracker = ns.TrackerCore:CreateTracker("Test")

		assert.is_true(tracker:LogItem("quest", 7, { name = "First" }))
		assert.is_false(tracker:LogItem("quest", 7, { name = "Duplicate" }))
		assert.are.equal(1, tracker:GetCount())
		assert.are.equal("First", tracker:GetItem("quest", 7).name)

		tracker:Clear("quest")
		assert.are.equal(0, tracker:GetCount())
	end)

	it("uses deterministic category and numeric ID ordering for tied timestamps", function()
		local tracker = ns.TrackerCore:CreateTracker("Test")
		tracker.items = {
			quest = {
				[10] = { firstSeen = 100 },
				[2] = { firstSeen = 100 },
			},
			currency = {
				[4] = { firstSeen = 100 },
			},
		}

		local items = tracker:GetItems()
		assert.are.equal("currency", items[1].category)
		assert.are.equal(4, items[1].id)
		assert.are.equal(2, items[2].id)
		assert.are.equal(10, items[3].id)

		local exported = tracker:ExportToString(function(category, id)
			return category .. ":" .. id
		end)
		assert.are.equal("-- === CURRENCY ===\ncurrency:4\n\n-- === QUEST ===\nquest:2\nquest:10\n", exported)
	end)

	it("releases AceGUI export windows when they close", function()
		local released
		local popup = {
			events = {},
			SetCallback = function(self, event, callback)
				self.events[event] = callback
			end,
			SetTitle = function() end,
			SetWidth = function() end,
			SetHeight = function() end,
			SetLayout = function() end,
			AddChild = function() end,
			Show = function() end,
		}
		local editBox = {
			editBox = { SetScript = function() end },
			SetLabel = function() end,
			SetText = function() end,
			DisableButton = function() end,
			SetFullWidth = function() end,
			SetFullHeight = function() end,
		}
		local AceGUI = {
			Create = function(_, kind)
				return kind == "Frame" and popup or editBox
			end,
			Release = function(_, widget)
				released = widget
			end,
		}
		_G.LibStub = function(name)
			if name == "AceGUI-3.0" then
				return AceGUI
			end
		end

		local tracker = ns.TrackerCore:CreateTracker("Test")
		tracker:ShowExportPopup("example")
		popup.events.OnClose(popup)

		assert.are.equal(popup, released)
	end)
end)

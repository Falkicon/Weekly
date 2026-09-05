local addonName = "Weekly"
local ns
local registration
local buttons
local now

local originalGlobals = {
	LibStub = _G.LibStub,
	C_AddOns = _G.C_AddOns,
	CreateFrame = _G.CreateFrame,
	UIParent = _G.UIParent,
	wipe = _G.wipe,
	time = _G.time,
	GetTime = _G.GetTime,
	print = _G.print,
}

local function NewWidget()
	local widget = {
		scripts = {},
		shown = false,
	}

	function widget:CreateFontString()
		return NewWidget()
	end

	function widget:SetPoint(...)
		self.point = { ... }
	end

	function widget:SetSize(width, height)
		self.size = { width, height }
	end

	function widget:SetText(text)
		self.text = text
	end

	function widget:SetScript(script, callback)
		self.scripts[script] = callback
	end

	function widget:IsShown()
		return self.shown
	end

	function widget:Click()
		self.scripts.OnClick(self)
	end

	function widget:SetWidth(width)
		self.width = width
	end

	function widget:SetJustifyH(justification)
		self.justification = justification
	end

	function widget:SetTextColor(...)
		self.textColor = { ... }
	end

	return widget
end

local function LoadIntegration()
	local chunk, err = loadfile("MechanicIntegration.lua")
	assert(chunk, err)
	setfenv(chunk, getfenv(1))
	chunk(addonName, ns)
end

describe("Weekly Mechanic integration", function()
	before_each(function()
		local mechanicLib = {}
		function mechanicLib:Register(_addon, config)
			registration = config
		end

		ns = {
			Config = {
				debug = {
					ignoreTimeGates = true,
				},
			},
			Weekly = {},
		}
		buttons = {}
		now = 100
		_G.GetTime = function()
			return now
		end

		_G.LibStub = function(name)
			if name == "AceAddon-3.0" then
				return {
					NewAddon = function()
						return ns.Weekly
					end,
				}
			elseif name == "AceLocale-3.0" then
				return {
					GetLocale = function()
						return {}
					end,
				}
			elseif name == "MechanicLib-1.0" then
				return mechanicLib
			end
		end
		_G.C_AddOns = {
			GetAddOnMetadata = function()
				return "test"
			end,
		}
		_G.CreateFrame = function()
			local button = NewWidget()
			table.insert(buttons, button)
			return button
		end
		_G.UIParent = NewWidget()
		_G.wipe = function(value)
			for key in pairs(value) do
				value[key] = nil
			end
		end
		_G.time = function()
			return 0
		end
		_G.print = function() end

		local core = assert(loadfile("Core.lua"))
		setfenv(core, getfenv(1))
		core(addonName, ns)
		ns.Weekly.active = true
		ns.Weekly.RegisterEvent = function() end
		ns.Weekly.UnregisterEvent = function() end
		LoadIntegration()
	end)

	after_each(function()
		_G.LibStub = originalGlobals.LibStub
		_G.C_AddOns = originalGlobals.C_AddOns
		_G.CreateFrame = originalGlobals.CreateFrame
		_G.UIParent = originalGlobals.UIParent
		_G.wipe = originalGlobals.wipe
		_G.time = originalGlobals.time
		_G.GetTime = originalGlobals.GetTime
		_G.print = originalGlobals.print
	end)

	it("reports zero initially and samples cumulative milliseconds per elapsed second", function()
		ns.PerfBlocks.uiRefresh = 100
		local metrics = registration.performance.getSubMetrics()
		for _, metric in ipairs(metrics) do
			assert.are.equal(0, metric.msPerSec)
		end
		ns.PerfBlocks.uiRefresh = 108
		ns.PerfBlocks.dataQuery = 6
		ns.PerfBlocks.vaultLookup = 4
		ns.PerfBlocks.journalTrack = 2
		now = 102
		metrics = registration.performance.getSubMetrics()
		assert.are.equal(4, metrics[1].msPerSec)
		assert.are.equal(3, metrics[2].msPerSec)
		assert.are.equal(2, metrics[3].msPerSec)
		assert.are.equal(1, metrics[4].msPerSec)
	end)

	it("shares cached rates across consumers and returns zero after an idle interval", function()
		registration.performance.getSubMetrics()
		ns.PerfBlocks.uiRefresh = 8
		now = 101
		assert.are.equal(8, registration.performance.getSubMetrics()[1].msPerSec)
		assert.are.equal(8, registration.performance.getSubMetrics()[1].msPerSec)
		now = 101.5
		assert.are.equal(8, registration.performance.getSubMetrics()[1].msPerSec)
		now = 102
		assert.are.equal(0, registration.performance.getSubMetrics()[1].msPerSec)
	end)

	it("rebases safely if the clock or a counter moves backward", function()
		registration.performance.getSubMetrics()
		ns.PerfBlocks.uiRefresh = 8
		now = 101
		assert.are.equal(8, registration.performance.getSubMetrics()[1].msPerSec)
		now = 99
		assert.are.equal(0, registration.performance.getSubMetrics()[1].msPerSec)
		now = 100
		ns.PerfBlocks.uiRefresh = 1
		assert.are.equal(0, registration.performance.getSubMetrics()[1].msPerSec)
		now = 101
		ns.PerfBlocks.uiRefresh = 3
		assert.are.equal(2, registration.performance.getSubMetrics()[1].msPerSec)
	end)

	it("reads and updates the debug flag without replacing sibling settings", function()
		local registeredEvents = {}
		local unregisteredEvents = {}
		ns.Weekly.RegisterEvent = function(_, event)
			table.insert(registeredEvents, event)
		end
		ns.Weekly.UnregisterEvent = function(_, event)
			table.insert(unregisteredEvents, event)
		end

		assert.is_false(registration.settings.debugMode.get())
		registration.settings.debugMode.set(true)

		assert.is_table(ns.Config.debug)
		assert.is_true(ns.Config.debug.enabled)
		assert.is_true(ns.Config.debug.ignoreTimeGates)
		assert.are.same({ "QUEST_TURNED_IN", "QUEST_ACCEPTED" }, registeredEvents)

		registration.settings.debugMode.set(false)
		assert.is_false(ns.Config.debug.enabled)
		assert.are.same({ "QUEST_TURNED_IN", "QUEST_ACCEPTED" }, unregisteredEvents)
	end)

	it("migrates a legacy boolean debug value before applying a toggle", function()
		ns.Config.debug = true
		assert.is_true(registration.settings.debugMode.get())

		registration.settings.debugMode.set(false)

		assert.is_table(ns.Config.debug)
		assert.is_false(ns.Config.debug.enabled)
	end)

	it("routes tool buttons through public UI methods and saves reset position", function()
		local trackerShown = false
		local trackerToggles = 0
		local positionSaves = 0
		local resetPoint
		local trackerFrame = {
			IsShown = function()
				return trackerShown
			end,
			ClearAllPoints = function()
				resetPoint = nil
			end,
			SetPoint = function(_, ...)
				resetPoint = { ... }
			end,
		}
		ns.UI = {
			frame = trackerFrame,
			Toggle = function()
				trackerToggles = trackerToggles + 1
				trackerShown = not trackerShown
			end,
			SavePosition = function()
				positionSaves = positionSaves + 1
			end,
		}

		local journalToggles = 0
		ns.JournalUI = {
			Toggle = function(self)
				journalToggles = journalToggles + 1
				self.frame = {
					IsShown = function()
						return true
					end,
				}
			end,
		}

		registration.tools.createPanel(NewWidget())
		assert.are.equal(7, #buttons)

		buttons[1]:Click()
		assert.are.equal(1, trackerToggles)
		assert.is_true(trackerShown)

		buttons[2]:Click()
		assert.are.equal(1, journalToggles)
		assert.is_table(ns.JournalUI.frame)

		buttons[4]:Click()
		assert.are.same({ "CENTER", _G.UIParent, "CENTER", 0, 0 }, resetPoint)
		assert.are.equal(1, positionSaves)
	end)
end)

local function Fixture(withBroker)
	local ns, frames, timers = {}, {}, {}
	local env = setmetatable({}, { __index = getfenv(1) })
	env._G = env
	env.WeeklyDB = {}
	local function Frame()
		local f = { events = {}, scripts = {}, shown = false }
		function f:RegisterEvent(event)
			self.events[event] = true
		end
		function f:UnregisterEvent(event)
			self.events[event] = nil
		end
		function f:UnregisterAllEvents()
			self.events = {}
		end
		function f:SetScript(key, callback)
			self.scripts[key] = callback
		end
		function f:SetShown(shown)
			self.shown = shown
		end
		function f:Show()
			self.shown = true
		end
		function f:Hide()
			self.shown = false
		end
		function f:IsShown()
			return self.shown
		end
		function f:Emit(event, ...)
			if self.events[event] and self.scripts.OnEvent then
				self.scripts.OnEvent(self, event, ...)
			end
		end
		frames[#frames + 1] = f
		return f
	end
	local weekly = Frame()
	weekly.Printf = function() end
	weekly.RegisterChatCommand = function() end
	local icon = { registered = 0 }
	function icon:Register()
		self.registered = self.registered + 1
	end
	function icon:Show()
		self.shown = true
	end
	function icon:Hide()
		self.shown = false
	end
	local ldb = {
		NewDataObject = function(_, _, object)
			return object
		end,
	}
	local locale = setmetatable({}, {
		__index = function(_, key)
			return key
		end,
	})
	env.LibStub = function(name)
		if name == "AceAddon-3.0" then
			return {
				NewAddon = function()
					return weekly
				end,
			}
		end
		if name == "AceLocale-3.0" then
			return {
				GetLocale = function()
					return locale
				end,
			}
		end
		if name == "AceDB-3.0" then
			return {}
		end
		if withBroker and name == "LibDataBroker-1.1" then
			return ldb
		end
		if withBroker and name == "LibDBIcon-1.0" then
			return icon
		end
	end
	env.CreateFrame = Frame
	env.time = function()
		return 1734566400
	end
	env.date = os.date
	env.GetServerTime = env.time
	env.GetRealZoneText = function()
		return "Test"
	end
	env.debugprofilestop = function()
		return 0
	end
	env.C_DateAndTime = {
		GetSecondsUntilWeeklyReset = function()
			return 604800
		end,
	}
	env.C_Timer = {
		After = function(_, callback)
			timers[#timers + 1] = callback
		end,
	}
	env.GetExpansionLevel = function()
		return 11
	end
	env.print = function() end
	env.LOOT_ITEM_SELF_MULTIPLE = "%s x%d"
	env.C_Item = {
		GetItemNameByID = function()
			return "Herb"
		end,
		GetItemIconByID = function()
			return 1
		end,
		RequestLoadItemDataByID = function() end,
	}
	local cached = false
	ns.Context = {
		BuildLootClassifyContext = function()
			if cached then
				return {}
			end
		end,
	}
	ns.Actions = {
		Journal = {
			ParseLootMessage = function()
				return { success = true, data = { itemLink = "loot", itemID = 123, quantity = 2 } }
			end,
			ClassifyLootItem = function()
				return { success = true, data = { isGathering = true, expansion = 11 } }
			end,
		},
	}
	local function Load(path)
		local chunk = assert(loadfile(path))
		setfenv(chunk, env)
		chunk("Weekly", ns)
	end
	for _, path in ipairs({
		"Core.lua",
		"Core/WeeklyReset.lua",
		"Core/ConfigMigrations.lua",
		"Config.lua",
		"TrackerCore.lua",
		"Journal/Journal.lua",
		"Journal/JournalBroker.lua",
		"PreyTracker.lua",
		"UI.lua",
		"Dev/Discovery.lua",
	}) do
		Load(path)
	end
	ns.PreyTracker.RefreshActiveQuest = function() end
	ns.Discovery.CreateUI = function(self)
		self.tracker.frame = Frame()
	end
	ns.ConfigUI = { Initialize = function() end, RefreshTrackingOptions = function() end }
	ns.UI.Initialize = function(self)
		self.frame = self.frame or Frame()
	end
	ns.UI.RestorePosition = function() end
	ns.UI.RefreshRows = function(self)
		self.refreshes = (self.refreshes or 0) + 1
	end
	local function Profile()
		return {
			autoShow = false,
			visible = true,
			debug = { enabled = true },
			journal = {
				enabled = true,
				weekStart = env.time(),
				nextReset = env.time() + 604800,
				categories = {},
				gathering = {},
			},
		}
	end
	ns.db = { profile = Profile(), char = {} }
	ns.Config, ns.CharConfig = ns.db.profile, ns.db.char
	ns:MigrateConfig()
	return ns, weekly, Profile, icon, timers, function()
		cached = true
	end
end

describe("Weekly lifecycle integration", function()
	it("handles the single quest ID payload after restoring saved debug mode", function()
		local ns, weekly = Fixture(false)
		local message, acceptedID, acceptedType
		weekly.Printf = function(_, text)
			message = text
		end
		ns.Discovery.OnQuestEvent = function(_, questID, eventType)
			acceptedID, acceptedType = questID, eventType
		end
		weekly:OnEnable()
		assert.is_true(weekly.events.QUEST_ACCEPTED)
		weekly:QUEST_ACCEPTED("QUEST_ACCEPTED", 91175)
		ns.Discovery.tracker.eventFrame:Emit("QUEST_ACCEPTED", 91175)
		assert.are.equal("Quest Accepted: ID 91175", message)
		assert.are.equal(91175, acceptedID)
		assert.are.equal("accepted", acceptedType)
	end)

	for _, librariesPresent in ipairs({ false, true }) do
		it("disables and reenables tracking with broker libraries " .. tostring(librariesPresent), function()
			local ns, weekly, _, icon = Fixture(librariesPresent)
			weekly:OnEnable()
			assert.is_true(weekly.events.QUEST_ACCEPTED)
			assert.is_not_nil(ns.Journal.tracker)
			local oldTracker = ns.Journal.tracker
			local discovery = ns.Discovery.tracker
			local preyFrame = ns.PreyTracker.eventFrame
			oldTracker:LogItem("mount", 1, { name = "Mount" })
			weekly:OnDisable()
			assert.is_nil(ns.Journal.tracker)
			assert.is_nil(next(oldTracker.events))
			assert.is_nil(next(discovery.events))
			assert.is_nil(next(preyFrame.events))
			assert.is_nil(next(weekly.events))
			assert.is_false(ns.UI.frame:IsShown())
			weekly:OnEnable()
			assert.are.equal(1, ns.Journal:GetTotalCount())
			assert.are.equal(discovery, ns.Discovery.tracker)
			assert.are.equal(preyFrame, ns.PreyTracker.eventFrame)
			assert.is_not_nil(discovery.events.QUEST_ACCEPTED)
			if librariesPresent then
				assert.are.equal(1, icon.registered)
				assert.is_true(icon.shown)
			end
		end)
	end

	it("uses autoShow only at login and applies profile debug and visibility", function()
		local ns, weekly, Profile = Fixture(false)
		ns.Config.autoShow, ns.Config.visible = true, false
		weekly:OnEnable()
		assert.is_true(ns.UI.frame:IsShown())
		local profile = Profile()
		profile.autoShow, profile.visible, profile.debug.enabled = true, false, false
		ns:PrepareProfileChange()
		ns.db.profile = profile
		ns:RefreshConfig()
		assert.is_false(ns.UI.frame:IsShown())
		assert.is_nil(weekly.events.QUEST_ACCEPTED)
		weekly:OnDisable()
		weekly:OnEnable()
		assert.is_false(ns.UI.frame:IsShown())
	end)

	it("discards pending loot on copy/reset and ignores callbacks while disabled", function()
		local ns, weekly, Profile, _, _, cache = Fixture(false)
		weekly:OnEnable()
		local old = ns.Journal.tracker
		old:LogItem("mount", 1, { name = "Old" })
		old.eventFrame:Emit("CHAT_MSG_LOOT", "loot x2")
		assert.are.equal(2, ns.Journal.pendingGathering[123])
		-- AceDB copy/reset may mutate the same profile table without shutdown.
		local replacement = Profile()
		for key in pairs(ns.db.profile) do
			ns.db.profile[key] = nil
		end
		for key, value in pairs(replacement) do
			ns.db.profile[key] = value
		end
		ns:RefreshConfig()
		cache()
		old.eventFrame:Emit("GET_ITEM_INFO_RECEIVED", 123, true)
		ns.Journal.tracker.eventFrame:Emit("GET_ITEM_INFO_RECEIVED", 123, true)
		assert.are.equal(0, ns.Journal:GetTotalCount())
		assert.are.equal(0, ns.Journal:GetGatheringTotalCount())
		local current = ns.Journal.tracker
		weekly:OnDisable()
		current.eventFrame:Emit("CHAT_MSG_LOOT", "loot x2")
		weekly:OnEnable()
		assert.are.equal(0, ns.Journal:GetGatheringTotalCount())
	end)

	it("invalidates queued UI refreshes across disable and reenable", function()
		local ns, weekly, _, _, timers = Fixture(false)
		weekly:OnEnable()
		ns.UI:QueueRefresh()
		weekly:OnDisable()
		weekly:OnEnable()
		ns.UI:QueueRefresh()
		timers[1]()
		assert.is_nil(ns.UI.refreshes)
		assert.is_true(ns.UI.refreshPending)
		timers[2]()
		assert.are.equal(1, ns.UI.refreshes)
	end)

	it("defers profile activation while disabled and honors journal settings", function()
		local ns, weekly, Profile = Fixture(false)
		weekly:OnEnable()
		weekly:OnDisable()
		ns.db.profile = Profile()
		ns.db.profile.journal.enabled = false
		ns:RefreshConfig()
		assert.is_nil(ns.Journal.tracker)
		assert.is_nil(next(weekly.events))
		weekly:OnEnable()
		assert.is_nil(ns.Journal.tracker)
		ns.Config.journal.enabled = true
		weekly:ApplyConfig("settings")
		ns.Journal.tracker:LogItem("mount", 7, { name = "Saved" })
		ns.Config.journal.enabled = false
		weekly:ApplyConfig("settings")
		assert.is_nil(ns.Journal.tracker)
		ns.Config.journal.enabled = true
		weekly:ApplyConfig("settings")
		assert.are.equal(1, ns.Journal:GetTotalCount())
	end)
end)

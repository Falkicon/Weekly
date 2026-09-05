local addonName, ns = ...
local Weekly = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Weekly")
ns.Weekly = Weekly

function Weekly:OnInitialize()
	self:Printf(L["Loaded. Type /weekly to open."])

	-- Load Config (AceDB)
	ns:LoadConfig()

	-- Create settings and frames before activation.
	ns.ConfigUI:Initialize()
	ns.UI:Initialize()

	-- Chat Command (Handled by AceConsole)
	self:RegisterChatCommand("weekly", "SlashHandler")

	-- Register with Addon Compartment (Blizzard's dropdown menu)
	if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
		AddonCompartmentFrame:RegisterAddon({
			text = "Weekly",
			icon = "Interface\\Icons\\INV_Misc_Book_09",
			notCheckable = true,
			func = function()
				-- Check which button was clicked using WoW API
				local button = GetMouseButtonClicked and GetMouseButtonClicked() or "LeftButton"
				if button == "RightButton" then
					-- Right-click: Open settings
					if ns.ConfigUI and ns.ConfigUI.categoryID then
						Settings.OpenToCategory(ns.ConfigUI.categoryID)
					else
						Settings.OpenToCategory(Settings.GetCategory("Weekly"))
					end
				else
					-- Left-click: Toggle tracker
					ns.UI:Toggle()
				end
			end,
			funcOnEnter = function(menuButtonFrame)
				GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_RIGHT")
				GameTooltip:AddLine("Weekly", 1, 0.82, 0)
				GameTooltip:AddLine(L["Left-click: Toggle tracker"], 0.7, 0.7, 0.7)
				GameTooltip:AddLine(L["Right-click: Open settings"], 0.7, 0.7, 0.7)
				GameTooltip:Show()
			end,
			funcOnLeave = function()
				GameTooltip:Hide()
			end,
		})
	end
end

function Weekly:SlashHandler(msg)
	local cmd = msg:trim():lower()

	-- Help
	if cmd == "help" or cmd == "?" then
		self:Printf(L["Commands:"])
		self:Printf(L["  /weekly - Toggle weekly tracker window"])
		self:Printf(L["  /weekly journal - Toggle journal window"])
		self:Printf(L["  /weekly settings - Open settings"])
		self:Printf(L["  /weekly help - Show this help"])
		return
	end

	-- Journal
	if cmd == "journal" or cmd == "j" then
		if ns.JournalUI then
			ns.JournalUI:Toggle()
		else
			self:Printf(L["Journal is not available. Check settings to enable it."])
		end
		return
	end

	-- Settings
	if cmd == "settings" or cmd == "config" or cmd == "options" then
		if ns.ConfigUI and ns.ConfigUI.categoryID then
			Settings.OpenToCategory(ns.ConfigUI.categoryID)
		else
			-- Last resort fallback
			Settings.OpenToCategory(Settings.GetCategory("Weekly"))
		end
		return
	end

	-- Discovery Tool (available when Mechanic is loaded)
	if cmd == "discovery" or cmd == "disc" then
		if ns.Discovery then
			ns.Discovery:Toggle()
		else
			self:Printf(L["Discovery tool requires Mechanic addon"])
		end
		return
	end

	if cmd == "debug" then
		self:SetDebugEnabled(not (type(ns.Config.debug) == "table" and ns.Config.debug.enabled))
		self:Printf(L["Debug Mode: %s"]:format(ns.Config.debug.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"))

		-- Dump Vault Info
		self:Printf(L["--- DEBUG VAULT (Raid) ---"])
		local acts = C_WeeklyRewards.GetActivities(3) -- Raid
		local tierID = nil

		if acts then
			self:Printf(L["Activities Found: %d"], #acts)
			for i, act in ipairs(acts) do
				self:Printf(
					format(
						L["Slot %d: Tier %s, Level %s, Progress %s/%s"],
						i,
						tostring(act.activityTierID),
						tostring(act.level),
						tostring(act.progress),
						tostring(act.threshold)
					)
				)
				if act.activityTierID then
					tierID = act.activityTierID
				end
			end
		else
			self:Printf(L["No Raid Activities found."])
		end

		if tierID then
			self:Printf(L["Using Tier ID: %s"], tierID)
			local i = 1
			while true do
				local encID = C_WeeklyRewards.GetActivityEncounterInfo(tierID, i)
				if not encID then
					self:Printf(L["Index %d: nil (End)"], i)
					break
				end
				if encID == 0 then
					self:Printf(L["Index %d: 0 (End?)"], i)
					break
				end

				local name = EJ_GetEncounterInfo(encID)
				self:Printf(L["Index %d: EncID %d (%s)"], i, encID, name or L["Unknown"])
				i = i + 1
				if i > 20 then
					break
				end -- Safety
			end
		end
		self:Printf(L["--- END DEBUG VAULT ---"])

		self:Printf(L["--- DEBUG LOCKOUTS ---"])
		-- Check Saved Instances (Lockouts)
		local num = GetNumSavedInstances()
		self:Printf(L["Saved Instances: %d"], num)
		for i = 1, num do
			local name, _id, _reset, _diff, locked, _extended, _instanceIDMostSig, isRaid, _maxPlayers, diffName, numEncounters, _encounterProgress =
				GetSavedInstanceInfo(i)
			if isRaid then
				self:Printf(L["Raid %d: %s (%s) - Locked: %s"], i, name, diffName, tostring(locked))
				if locked then
					for j = 1, numEncounters do
						local bossName, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
						if isKilled then
							self:Printf(L["  - %s (Killed)"], bossName)
						end
					end
				end
			end
		end
		self:Printf(L["--- END DEBUG LOCKOUTS ---"])
	else
		self:Printf(L["Toggling UI..."])
		ns.UI:Toggle()
	end
end

function Weekly:QUEST_TURNED_IN(_event, questID, _xp, _money)
	if type(ns.Config.debug) == "table" and ns.Config.debug.enabled then
		self:Printf(L["Quest Completed: ID %s"]:format(questID))
	end
end

function Weekly:QUEST_ACCEPTED(_event, questID)
	if type(ns.Config.debug) == "table" and ns.Config.debug.enabled then
		self:Printf(L["Quest Accepted: ID %s"]:format(questID))
	end
end

function Weekly:SetDebugEnabled(enabled)
	if type(ns.Config.debug) ~= "table" then
		ns.Config.debug = { ignoreTimeGates = false }
	end
	ns.Config.debug.enabled = enabled == true
	local method = self.active and enabled and "RegisterEvent" or "UnregisterEvent"
	self[method](self, "QUEST_TURNED_IN")
	self[method](self, "QUEST_ACCEPTED")
end

-- One ordered path for startup, profile changes, and settings application.
function Weekly:ApplyConfig(reason)
	if not self.active then
		return
	end
	self:SetDebugEnabled(type(ns.Config.debug) == "table" and ns.Config.debug.enabled)
	if ns.PreyTracker then
		ns.PreyTracker:Initialize()
	end
	if ns.Journal then
		ns.Journal:ApplyConfig(reason)
	end
	if ns.JournalBroker then
		ns.JournalBroker:ApplyConfig()
	end
	if ns.Discovery then
		ns.Discovery:Initialize()
	end
	if ns.UI then
		ns.UI:ApplyConfig(reason)
	end
	if ns.JournalUI and ns.JournalUI.frame then
		ns.JournalUI:RestorePosition()
		ns.JournalUI:SelectTab(ns.Config.journal.selectedTab or "dashboard")
	end
	if ns.ConfigUI then
		ns.ConfigUI:RefreshTrackingOptions()
	end
end

function Weekly:OnEnable()
	self.active = true
	self:ApplyConfig(self.hasEnabled and "enable" or "login")
	self.hasEnabled = true
end

function Weekly:OnDisable()
	self.active = false
	self:UnregisterAllEvents()
	for _, name in ipairs({ "Journal", "Discovery", "PreyTracker", "JournalBroker", "UI" }) do
		local module = ns[name]
		if module and module.Shutdown then
			module:Shutdown()
		end
	end
	if ns.JournalUI and ns.JournalUI.frame then
		ns.JournalUI.frame:Hide()
	end
end

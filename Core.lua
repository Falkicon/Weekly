local addonName, ns = ...
local Weekly = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Weekly")
ns.Weekly = Weekly

function Weekly:OnInitialize()
	self:Printf(L["Loaded. Type /weekly to open."])

	-- Load Config (AceDB)
	ns:LoadConfig()

	-- Initialize Modules
	-- Note: We can make these real AceAddon modules later, for now just init headers
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
				ns.UI:Toggle()
			end,
			funcOnEnter = function(menuButtonFrame)
				GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_RIGHT")
				GameTooltip:AddLine("Weekly", 1, 0.82, 0)
				GameTooltip:AddLine(L["Left-click: Toggle tracker"], 0.7, 0.7, 0.7)
				GameTooltip:AddLine(L["Right-click: Open Journal"], 0.7, 0.7, 0.7)
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

	-- Discovery Tool (dev-only)
	if cmd == "discovery" or cmd == "disc" then
		if ns.IS_DEV_MODE and ns.Discovery then
			ns.Discovery:Toggle()
		else
			self:Printf(L["Discovery tool is only available in dev mode"])
		end
		return
	end

	if cmd == "debug" then
		ns.Config.debug = not ns.Config.debug
		self:Printf(L["Debug Mode: %s"]:format(ns.Config.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
		if ns.Config.debug then
			self:RegisterEvent("QUEST_TURNED_IN")
			self:RegisterEvent("QUEST_ACCEPTED")
		else
			self:UnregisterEvent("QUEST_TURNED_IN")
			self:UnregisterEvent("QUEST_ACCEPTED")
		end

		-- Dump Vault Info
		self:Printf("--- DEBUG VAULT (Raid) ---")
		local acts = C_WeeklyRewards.GetActivities(3) -- Raid
		local tierID = nil

		if acts then
			self:Printf("Activities Found: " .. #acts)
			for i, act in ipairs(acts) do
				self:Printf(
					format(
						"Slot %d: Tier %s, Level %s, Progress %s/%s",
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
			self:Printf("No Raid Activities found.")
		end

		if tierID then
			self:Printf("Using Tier ID: " .. tierID)
			local i = 1
			while true do
				local encID = C_WeeklyRewards.GetActivityEncounterInfo(tierID, i)
				if not encID then
					self:Printf("Index " .. i .. ": nil (End)")
					break
				end
				if encID == 0 then
					self:Printf("Index " .. i .. ": 0 (End?)")
					break
				end

				local name = EJ_GetEncounterInfo(encID)
				self:Printf("Index " .. i .. ": EncID " .. encID .. " (" .. (name or "Unknown") .. ")")
				i = i + 1
				if i > 20 then
					break
				end -- Safety
			end
		end
		self:Printf("--- END DEBUG VAULT ---")

		self:Printf("--- DEBUG LOCKOUTS ---")
		-- Check Saved Instances (Lockouts)
		local num = GetNumSavedInstances()
		self:Printf("Saved Instances: " .. num)
		for i = 1, num do
			local name, id, reset, diff, locked, extended, instanceIDMostSig, isRaid, maxPlayers, diffName, numEncounters, encounterProgress =
				GetSavedInstanceInfo(i)
			if isRaid then
				self:Printf(format("Raid %d: %s (%s) - Locked: %s", i, name, diffName, tostring(locked)))
				if locked then
					for j = 1, numEncounters do
						local bossName, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
						if isKilled then
							self:Printf(format("  - %s (Killed)", bossName))
						end
					end
				end
			end
		end
		self:Printf("--- END DEBUG LOCKOUTS ---")
	else
		self:Printf(L["Toggling UI..."])
		ns.UI:Toggle()
	end
end

function Weekly:QUEST_TURNED_IN(event, questID, xp, money)
	if ns.Config.debug then
		self:Printf(L["Quest Completed: ID %s"]:format(questID))
	end
end

function Weekly:QUEST_ACCEPTED(event, questID)
	if ns.Config.debug then
		self:Printf(L["Quest Accepted: ID %s"]:format(questID))
	end
end

-- Auto-Show on Login (respects config)
function Weekly:OnEnable()
	if ns.Config.autoShow or ns.Config.visible then
		ns.UI:Toggle()
	end
end

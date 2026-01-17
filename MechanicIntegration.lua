--------------------------------------------------------------------------------
-- Weekly Addon - MechanicLib Integration
-- Registers with Mechanic ecosystem for dashboard, testing, and debugging
--------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

-- Attempt to load MechanicLib (optional dependency)
local MechanicLib = LibStub("MechanicLib-1.0", true)
if not MechanicLib then
	return -- Mechanic not installed, skip integration
end

--------------------------------------------------------------------------------
-- Debug Buffer for Console Integration
--------------------------------------------------------------------------------

local debugBuffer = {}
local MAX_BUFFER_SIZE = 500

--------------------------------------------------------------------------------
-- Performance Tracking
--------------------------------------------------------------------------------

local perfBlocks = {
	uiRefresh = 0, -- Row rendering
	dataQuery = 0, -- Currency/Quest API polling
	vaultLookup = 0, -- Vault activities API
	journalTrack = 0, -- Loot message processing
}

-- Expose for UI to update
ns.PerfBlocks = perfBlocks

local function AddToDebugBuffer(message, category)
	table.insert(debugBuffer, {
		timestamp = time(),
		message = message,
		category = category or "INFO",
	})

	-- Trim buffer if too large
	while #debugBuffer > MAX_BUFFER_SIZE do
		table.remove(debugBuffer, 1)
	end
end

-- Hook into Weekly's print function to capture debug output
local originalPrintf = ns.Weekly and ns.Weekly.Printf
if originalPrintf then
	ns.Weekly.Printf = function(self, ...)
		local message = string.format(...)
		AddToDebugBuffer(message, "OUTPUT")
		return originalPrintf(self, ...)
	end
end

--------------------------------------------------------------------------------
-- Test Definitions
--------------------------------------------------------------------------------

local testDefinitions = {
	-- Core Action Tests
	{
		id = "core.currency.capped",
		name = "Currency Status - Capped Detection",
		category = "Core Actions",
		description = "Verifies that currencies at weekly cap are correctly identified as capped",
		run = function()
			local startTime = debugprofilestop()
			local context = {
				quantity = 500,
				maxWeeklyQuantity = 500,
				quantityEarnedThisWeek = 500,
			}
			local result = ns.Actions.Tracker.GetCurrencyStatus(context)
			local duration = (debugprofilestop() - startTime) / 1000

			local passed = result.success and result.data.isCapped
			return passed,
				{
					duration = duration,
					message = passed and "Currency correctly identified as capped"
						or "Failed to detect capped currency",
					details = {
						{
							label = "success",
							value = tostring(result.success),
							status = result.success and "pass" or "fail",
						},
						{
							label = "isCapped",
							value = tostring(result.data and result.data.isCapped),
							status = (result.data and result.data.isCapped) and "pass" or "fail",
						},
						{
							label = "amount",
							value = result.data and tostring(result.data.amount) or "nil",
							status = "pass",
						},
						{ label = "max", value = result.data and tostring(result.data.max) or "nil", status = "pass" },
					},
				}
		end,
	},
	{
		id = "core.currency.uncapped",
		name = "Currency Status - Uncapped Handling",
		category = "Core Actions",
		description = "Verifies that uncapped currencies (max=0) are handled correctly",
		run = function()
			local startTime = debugprofilestop()
			local context = {
				quantity = 12345,
				maxWeeklyQuantity = 0,
				maxQuantity = 0,
			}
			local result = ns.Actions.Tracker.GetCurrencyStatus(context)
			local duration = (debugprofilestop() - startTime) / 1000

			local passed = result.success and not result.data.isCapped
			return passed,
				{
					duration = duration,
					message = passed and "Uncapped currency handled correctly" or "Failed uncapped currency handling",
					details = {
						{
							label = "success",
							value = tostring(result.success),
							status = result.success and "pass" or "fail",
						},
						{
							label = "isCapped",
							value = tostring(result.data and result.data.isCapped),
							status = (result.data and not result.data.isCapped) and "pass" or "fail",
						},
						{
							label = "amount",
							value = result.data and tostring(result.data.amount) or "nil",
							status = "pass",
						},
					},
				}
		end,
	},
	{
		id = "core.quest.completed",
		name = "Quest Status - Completed Detection",
		category = "Core Actions",
		description = "Verifies that completed quests are correctly detected",
		run = function()
			local startTime = debugprofilestop()
			local context = {
				ids = { 12345 },
				isCompleted = function()
					return true
				end,
				isOnQuest = function()
					return false
				end,
				getObjectives = function()
					return {}
				end,
			}
			local result = ns.Actions.Tracker.GetQuestStatus(context)
			local duration = (debugprofilestop() - startTime) / 1000

			local passed = result.success and result.data.isCompleted
			return passed,
				{
					duration = duration,
					message = passed and "Quest completion detected" or "Failed to detect quest completion",
					details = {
						{
							label = "success",
							value = tostring(result.success),
							status = result.success and "pass" or "fail",
						},
						{
							label = "isCompleted",
							value = tostring(result.data and result.data.isCompleted),
							status = (result.data and result.data.isCompleted) and "pass" or "fail",
						},
						{
							label = "resolvedId",
							value = result.data and tostring(result.data.resolvedId) or "nil",
							status = "pass",
						},
					},
				}
		end,
	},
	{
		id = "core.quest.multiid",
		name = "Quest Status - Multi-ID Resolution",
		category = "Core Actions",
		description = "Verifies that rotating quests (multiple IDs) resolve to the active variant",
		run = function()
			local startTime = debugprofilestop()
			local context = {
				ids = { 111, 222, 333 },
				isCompleted = function()
					return false
				end,
				isOnQuest = function(id)
					return id == 222
				end,
				getObjectives = function()
					return { { numFulfilled = 3, numRequired = 5 } }
				end,
			}
			local result = ns.Actions.Tracker.GetQuestStatus(context)
			local duration = (debugprofilestop() - startTime) / 1000

			local passed = result.success and result.data.resolvedId == 222 and result.data.progress == 3
			return passed,
				{
					duration = duration,
					message = passed and "Multi-ID quest resolved correctly" or "Failed multi-ID resolution",
					details = {
						{
							label = "success",
							value = tostring(result.success),
							status = result.success and "pass" or "fail",
						},
						{
							label = "resolvedId",
							value = result.data and tostring(result.data.resolvedId) or "nil",
							status = (result.data and result.data.resolvedId == 222) and "pass" or "fail",
						},
						{
							label = "progress",
							value = result.data and tostring(result.data.progress) or "nil",
							status = (result.data and result.data.progress == 3) and "pass" or "fail",
						},
						{ label = "max", value = result.data and tostring(result.data.max) or "nil", status = "pass" },
					},
				}
		end,
	},
	{
		id = "core.vault.slots",
		name = "Vault Status - Slot Counting",
		category = "Core Actions",
		description = "Verifies vault slot completion counting (1 of 3 slots unlocked)",
		run = function()
			local startTime = debugprofilestop()
			local context = {
				activities = {
					{ threshold = 1, progress = 1, level = 450 },
					{ threshold = 4, progress = 2, level = 0 },
					{ threshold = 8, progress = 0, level = 0 },
				},
			}
			local result = ns.Actions.Tracker.GetVaultStatus(context)
			local duration = (debugprofilestop() - startTime) / 1000

			local passed = result.success and result.data.completed == 1 and result.data.max == 3
			return passed,
				{
					duration = duration,
					message = passed and "Vault slots counted correctly" or "Failed vault slot counting",
					details = {
						{
							label = "success",
							value = tostring(result.success),
							status = result.success and "pass" or "fail",
						},
						{
							label = "completed",
							value = result.data and tostring(result.data.completed) or "nil",
							status = (result.data and result.data.completed == 1) and "pass" or "fail",
						},
						{
							label = "max",
							value = result.data and tostring(result.data.max) or "nil",
							status = (result.data and result.data.max == 3) and "pass" or "fail",
						},
					},
				}
		end,
	},

	-- Journal Tests
	{
		id = "journal.loot.parse",
		name = "Journal - Loot Message Parsing",
		category = "Journal",
		description = "Parses item link and quantity from loot chat messages",
		run = function()
			local startTime = debugprofilestop()
			local result = ns.Actions.Journal.ParseLootMessage({
				message = "You receive loot: |cff1eff00|Hitem:12345:0:0:0:0:0:0:0:0|h[Test Item]|h|r x5.",
			})
			local duration = (debugprofilestop() - startTime) / 1000

			local passed = result.success and result.data.itemID == 12345 and result.data.quantity == 5
			return passed,
				{
					duration = duration,
					message = passed and "Loot message parsed successfully" or "Failed to parse loot message",
					details = {
						{
							label = "success",
							value = tostring(result.success),
							status = result.success and "pass" or "fail",
						},
						{
							label = "itemID",
							value = result.data and tostring(result.data.itemID) or "nil",
							status = (result.data and result.data.itemID == 12345) and "pass" or "fail",
						},
						{
							label = "quantity",
							value = result.data and tostring(result.data.quantity) or "nil",
							status = (result.data and result.data.quantity == 5) and "pass" or "fail",
						},
					},
				}
		end,
	},
	{
		id = "journal.classify.herbs",
		name = "Journal - Classify Gathering Material",
		category = "Journal",
		description = "Classifies trade goods by subclass (herbs, ore, leather, etc.)",
		run = function()
			local startTime = debugprofilestop()
			local result = ns.Actions.Journal.ClassifyLootItem({
				itemClassID = 7, -- Trade Goods
				itemSubClassID = 9, -- Herb
				expansionID = 10,
			})
			local duration = (debugprofilestop() - startTime) / 1000

			local passed = result.success and result.data.isGathering and result.data.category == "Herb"
			return passed,
				{
					duration = duration,
					message = passed and "Herb correctly classified as gathering material"
						or "Failed gathering classification",
					details = {
						{
							label = "success",
							value = tostring(result.success),
							status = result.success and "pass" or "fail",
						},
						{
							label = "isGathering",
							value = tostring(result.data and result.data.isGathering),
							status = (result.data and result.data.isGathering) and "pass" or "fail",
						},
						{
							label = "category",
							value = result.data and tostring(result.data.category) or "nil",
							status = (result.data and result.data.category == "Herb") and "pass" or "fail",
						},
					},
				}
		end,
	},

	-- Data Layer Tests
	{
		id = "data.loader.seasons",
		name = "Data Loader - Season Registration",
		category = "Data",
		description = "Verifies The War Within season data is registered and retrievable",
		run = function()
			local startTime = debugprofilestop()
			local seasons = ns.Data and ns.Data:GetSeasons(11) -- The War Within (Exp 11)
			local duration = (debugprofilestop() - startTime) / 1000

			local passed = seasons and #seasons > 0
			local seasonList = {}
			if seasons then
				for _, s in ipairs(seasons) do
					table.insert(seasonList, tostring(s))
				end
			end

			return passed,
				{
					duration = duration,
					message = passed and string.format("Found %d seasons for TWW", seasons and #seasons or 0)
						or "No seasons found",
					details = {
						{
							label = "Data module",
							value = ns.Data and "loaded" or "missing",
							status = ns.Data and "pass" or "fail",
						},
						{
							label = "Season count",
							value = seasons and tostring(#seasons) or "0",
							status = (seasons and #seasons > 0) and "pass" or "fail",
						},
						{
							label = "Seasons",
							value = #seasonList > 0 and table.concat(seasonList, ", ") or "none",
							status = #seasonList > 0 and "pass" or "warn",
						},
					},
				}
		end,
	},
}

local testResults = {}

--------------------------------------------------------------------------------
-- MechanicLib Registration
--------------------------------------------------------------------------------

MechanicLib:Register(ADDON_NAME, {
	version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version"),

	-- Console Integration
	getDebugBuffer = function()
		return debugBuffer
	end,
	clearDebugBuffer = function()
		wipe(debugBuffer)
	end,

	-- Testing Integration
	tests = {
		getAll = function()
			local tests = {}
			for _, def in ipairs(testDefinitions) do
				table.insert(tests, {
					id = def.id,
					name = def.name,
					category = def.category,
				})
			end
			return tests
		end,
		getCategories = function()
			return { "Core Actions", "Journal", "Data" }
		end,
		run = function(id)
			for _, def in ipairs(testDefinitions) do
				if def.id == id then
					local success, passedOrErr, resultData = pcall(def.run)

					if not success then
						-- pcall failed, passedOrErr contains error message
						testResults[id] = {
							passed = false,
							error = tostring(passedOrErr),
							timestamp = time(),
						}
						return false
					end

					-- Test ran successfully, passedOrErr is the boolean result
					-- resultData contains { duration, message, details }
					local testPassed = passedOrErr == true
					testResults[id] = {
						passed = testPassed,
						duration = resultData and resultData.duration,
						message = resultData and resultData.message,
						details = resultData and resultData.details,
						timestamp = time(),
					}
					return testPassed
				end
			end
			return false
		end,
		runAll = function()
			local passedCount = 0
			local total = 0
			for _, def in ipairs(testDefinitions) do
				total = total + 1
				local success, passedOrErr, resultData = pcall(def.run)

				if not success then
					testResults[def.id] = {
						passed = false,
						error = tostring(passedOrErr),
						timestamp = time(),
					}
				else
					local testPassed = passedOrErr == true
					testResults[def.id] = {
						passed = testPassed,
						duration = resultData and resultData.duration,
						message = resultData and resultData.message,
						details = resultData and resultData.details,
						timestamp = time(),
					}
					if testPassed then
						passedCount = passedCount + 1
					end
				end
			end
			return passedCount, total -- Return two values, not a table
		end,
		getResult = function(id)
			return testResults[id]
		end,
	},

	-- Inspect Integration (Watch List)
	inspect = {
		getWatchFrames = function()
			local frames = {}

			-- Main Tracker Window
			if ns.UI and ns.UI.frame then
				table.insert(frames, {
					label = "Weekly Tracker",
					frame = ns.UI.frame,
					property = "Visibility",
				})
			end

			-- Journal Window
			if ns.JournalUI and ns.JournalUI.frame then
				table.insert(frames, {
					label = "Weekly Journal",
					frame = ns.JournalUI.frame,
					property = "Visibility",
				})
			end

			return frames
		end,
	},

	-- Performance Integration (Sub-metrics)
	performance = {
		getSubMetrics = function()
			return {
				{
					name = "UI Refresh",
					msPerSec = perfBlocks.uiRefresh,
					description = "Tracker row rendering and updates",
				},
				{
					name = "Data Query",
					msPerSec = perfBlocks.dataQuery,
					description = "Currency and quest API polling",
				},
				{
					name = "Vault Lookup",
					msPerSec = perfBlocks.vaultLookup,
					description = "Weekly vault activities API",
				},
				{
					name = "Journal",
					msPerSec = perfBlocks.journalTrack,
					description = "Loot message parsing and tracking",
				},
			}
		end,
	},

	-- Tools Integration (Custom Panel)
	tools = {
		createPanel = function(container)
			-- Title
			local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
			title:SetPoint("TOPLEFT", 10, -10)
			title:SetText("Weekly Tools")

			local desc = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			desc:SetPoint("TOPLEFT", 10, -35)
			desc:SetText("Quick actions for Weekly tracker management.")

			-- Helper function to create buttons
			local function CreateToolButton(parent, x, y, width, text, onClick)
				local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
				btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
				btn:SetSize(width, 24)
				btn:SetText(text)
				btn:SetScript("OnClick", onClick)
				return btn
			end

			-- Row 1: Window Controls
			local row1Label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			row1Label:SetPoint("TOPLEFT", 10, -65)
			row1Label:SetText("Windows:")

			CreateToolButton(container, 80, -60, 100, "Toggle Tracker", function()
				if ns.UI and ns.UI.frame then
					if ns.UI.frame:IsShown() then
						ns.UI.frame:Hide()
						print("|cff00ff00Weekly:|r Tracker hidden.")
					else
						ns.UI.frame:Show()
						print("|cff00ff00Weekly:|r Tracker shown.")
					end
				else
					print("|cffff0000Weekly:|r Tracker not available.")
				end
			end)

			CreateToolButton(container, 185, -60, 100, "Toggle Journal", function()
				if ns.JournalUI and ns.JournalUI.frame then
					if ns.JournalUI.frame:IsShown() then
						ns.JournalUI.frame:Hide()
						print("|cff00ff00Weekly:|r Journal hidden.")
					else
						ns.JournalUI.frame:Show()
						print("|cff00ff00Weekly:|r Journal shown.")
					end
				else
					print("|cffff0000Weekly:|r Journal not available.")
				end
			end)

			-- Row 2: Data Controls
			local row2Label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			row2Label:SetPoint("TOPLEFT", 10, -100)
			row2Label:SetText("Data:")

			CreateToolButton(container, 80, -95, 100, "Refresh Now", function()
				if ns.UI and ns.UI.RefreshRows then
					ns.UI:RefreshRows()
					print("|cff00ff00Weekly:|r Tracker refreshed.")
				else
					print("|cffff0000Weekly:|r RefreshRows not available.")
				end
			end)

			CreateToolButton(container, 185, -95, 120, "Reset Position", function()
				if ns.UI and ns.UI.frame then
					ns.UI.frame:ClearAllPoints()
					ns.UI.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
					print("|cff00ff00Weekly:|r Position reset to center.")
				end
			end)

			-- Row 3: Sort Options
			local row3Label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			row3Label:SetPoint("TOPLEFT", 10, -135)
			row3Label:SetText("Sorting:")

			CreateToolButton(container, 80, -130, 150, "Toggle Complete Sort", function()
				if ns.Config then
					ns.Config.sortCompletedBottom = not ns.Config.sortCompletedBottom
					local state = ns.Config.sortCompletedBottom and "ON" or "OFF"
					print("|cff00ff00Weekly:|r Sort completed to bottom: " .. state)
					if ns.UI and ns.UI.RefreshRows then
						ns.UI:RefreshRows()
					end
				end
			end)

			-- Row 4: Discovery Tool (Dev)
			local row4Label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			row4Label:SetPoint("TOPLEFT", 10, -170)
			row4Label:SetText("Discovery:")

			-- Discovery info text
			local discoveryInfo = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			discoveryInfo:SetPoint("TOPLEFT", 10, -195)
			discoveryInfo:SetWidth(280)
			discoveryInfo:SetJustifyH("LEFT")

			-- Update discovery info
			local function UpdateDiscoveryInfo()
				if ns.Discovery and ns.Discovery.tracker then
					local tracker = ns.Discovery.tracker
					local currCount = 0
					local questCount = 0
					if tracker.items then
						for _id in pairs(tracker.items.currency or {}) do
							currCount = currCount + 1
						end
						for _id in pairs(tracker.items.quest or {}) do
							questCount = questCount + 1
						end
					end
					local lastSaved = ""
					if WeeklyDB and WeeklyDB.dev and WeeklyDB.dev.discovery then
						lastSaved = WeeklyDB.dev.discovery.lastSavedFormatted or ""
					end
					local text = string.format("Logged: %d currencies, %d quests", currCount, questCount)
					if lastSaved ~= "" then
						text = text .. "\nLast saved: " .. lastSaved
					end
					discoveryInfo:SetText(text)
					discoveryInfo:SetTextColor(1, 1, 1)
				elseif ns.Discovery then
					discoveryInfo:SetText("Discovery not initialized yet")
					discoveryInfo:SetTextColor(0.7, 0.7, 0.7)
				else
					discoveryInfo:SetText("Discovery not available (dev build only)")
					discoveryInfo:SetTextColor(0.5, 0.5, 0.5)
				end
			end
			UpdateDiscoveryInfo()

			CreateToolButton(container, 80, -165, 130, "Open Discovery...", function()
				if ns.Discovery then
					if not ns.Discovery.tracker and ns.TrackerCore then
						ns.Discovery:Initialize()
					end
					ns.Discovery:Toggle()
					UpdateDiscoveryInfo()
				else
					print("|cffff0000Weekly:|r Discovery not available (dev build only).")
				end
			end)

			CreateToolButton(container, 215, -165, 100, "Clear Logged", function()
				if ns.Discovery and ns.Discovery.tracker then
					ns.Discovery.tracker:Clear()
					ns.Discovery:Save()
					print("|cff00ff00Weekly:|r Discovery log cleared.")
					UpdateDiscoveryInfo()
				else
					print("|cffff0000Weekly:|r Discovery not available.")
				end
			end)

			-- Footer
			local footer = container:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
			footer:SetPoint("BOTTOM", 0, 10)
			footer:SetText("Use /weekly for more options. Tests available in Tests tab.")
		end,
	},

	-- Settings exposed in Mechanic
	settings = {
		debugMode = {
			type = "toggle",
			name = "Debug Mode",
			get = function()
				return ns.Config and ns.Config.debug or false
			end,
			set = function(v)
				if ns.Config then
					ns.Config.debug = v
				end
			end,
		},
		sortCompletedBottom = {
			type = "toggle",
			name = "Sort Completed to Bottom",
			get = function()
				return ns.Config and ns.Config.sortCompletedBottom or false
			end,
			set = function(v)
				if ns.Config then
					ns.Config.sortCompletedBottom = v
					if ns.UI then
						ns.UI:RefreshRows()
					end
				end
			end,
		},
	},
})

-- Log successful registration
AddToDebugBuffer("MechanicLib integration loaded", "LOAD")

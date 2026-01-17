local _addonName, ns = ...
local ConfigUI = {}
ns.ConfigUI = ConfigUI

-- Libs match what we put in embeds.xml
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Weekly")

function ConfigUI:Initialize()
	-- 1. Main Options (General)
	local mainOptions = {
		name = "Weekly",
		type = "group",
		args = {
			general = {
				type = "group",
				name = L["General"],
				order = 1,
				inline = true,
				args = {
					dataSelection = {
						type = "group",
						name = L["Data Source"],
						inline = true,
						order = 0,
						args = {
							expansion = {
								type = "select",
								name = L["Expansion"],
								order = 1,
								values = function()
									local exps = ns.Data:GetExpansions()
									local t = { ["auto"] = L["Automatic (Recommended)"] }
									for _, id in ipairs(exps) do
										if id == 11 then
											t[id] = L["The War Within"]
										elseif id == 12 then
											t[id] = L["Midnight"]
										else
											t[id] = L["Expansion %d"]:format(id)
										end
									end
									return t
								end,
								get = function()
									return ns.Config.selectedExpansion
								end,
								set = function(_, val)
									ns.Config.selectedExpansion = val
									if val == "auto" then
										ns.Config.selectedSeason = "auto"
									else
										-- Reset Season to latest available for this expansion
										local seasons = ns.Data:GetSeasons(val)
										if seasons and #seasons > 0 then
											ns.Config.selectedSeason = seasons[#seasons]
										end
									end
									ns.UI:RefreshRows()
								end,
							},
							season = {
								type = "select",
								name = L["Season"],
								order = 2,
								values = function()
									local t = { ["auto"] = L["Automatic (Recommended)"] }
									local selectedExp = ns.Config.selectedExpansion

									-- If Expansion is Auto, we show all seasons for the RECOMMENDED expansion
									-- but labeled as Auto. Actually, better to just show "Auto" or specific
									-- seasons for the CURRENTLY ACTIVE expansion.
									local activeExp = selectedExp
									if activeExp == "auto" then
										activeExp = ns.Data:GetRecommendedSeason()
									end

									local seasons = ns.Data:GetSeasons(activeExp)
									for _, id in ipairs(seasons) do
										if id == 3.5 then
											t[id] = L["Season 3 (Midnight Pre-Patch)"]
										else
											t[id] = L["Season %s"]:format(id)
										end
									end
									return t
								end,
								get = function()
									return ns.Config.selectedSeason
								end,
								set = function(_, val)
									ns.Config.selectedSeason = val
									ns.UI:RefreshRows()
								end,
							},
							status = {
								type = "description",
								name = function()
									local exp, sea = ns.Data:GetRecommendedSeason()
									local expName = (exp == 11 and L["The War Within"])
										or (exp == 12 and L["Midnight"])
										or (L["Expansion %d"]:format(exp))
									local seaName = (sea == 3.5 and L["Season 3 (Midnight Pre-Patch)"])
										or (L["Season %s"]:format(sea))

									local currentStatus = ""
									if ns.Config.selectedExpansion == "auto" or ns.Config.selectedSeason == "auto" then
										currentStatus = "\n"
											.. L["Currently detecting: %s, %s"]:format("|cff888888", expName, seaName)
									end
									return currentStatus
								end,
								order = 3,
								width = "full",
							},
						},
					},
					sorting = {
						type = "toggle",
						name = L["Sort Completed to Bottom"],
						desc = L["Move completed quests and capped currencies to the bottom of their list."],
						order = 3,
						get = function()
							return ns.Config.sortCompletedBottom
						end,
						set = function(_, val)
							ns.Config.sortCompletedBottom = val
							ns.UI:RefreshRows()
						end,
					},
					locked = {
						type = "toggle",
						name = L["Lock Window"],
						desc = L["Lock the window in place and enable click-through"],
						order = 0,
						get = function()
							return ns.Config.locked
						end,
						set = function(_, val)
							ns.Config.locked = val
							ns.UI:ApplyFrameStyle()
						end,
					},
					ignoreTimeGates = {
						type = "toggle",
						name = L["Show All Gated Content"],
						desc = L["Show all time-gated sections regardless of current date. Useful for testing."],
						order = 5,
						get = function()
							return ns.Config.debug and ns.Config.debug.ignoreTimeGates
						end,
						set = function(_, val)
							if not ns.Config.debug then
								ns.Config.debug = {}
							end
							ns.Config.debug.ignoreTimeGates = val
							ns.UI:RefreshRows()
						end,
					},
				},
			},
		},
	}

	-- 2. Appearance Sub-Table
	local appearanceOptions = {
		name = L["Appearance"],
		type = "group",
		args = {
			font = {
				type = "select",
				dialogControl = "LSM30_Font", -- Standard Font Picker
				name = L["Font Face"],
				desc = L["Select the font used for the list."],
				values = LSM:HashTable("font"),
				order = 1,
				get = function()
					return ns.Config.font or "Friz Quadrata TT"
				end,
				set = function(_, val)
					ns.Config.font = val
					ns.UI:RefreshRows()
				end,
			},
			headerFontSize = {
				type = "range",
				name = L["Header Font Size"],
				min = 8,
				max = 32,
				step = 1,
				order = 3,
				get = function()
					return ns.Config.headerFontSize
				end,
				set = function(_, val)
					ns.Config.headerFontSize = val
					ns.UI:RefreshRows()
				end,
			},
			itemFontSize = {
				type = "range",
				name = L["Item Font Size"],
				min = 8,
				max = 24,
				step = 1,
				order = 4,
				get = function()
					return ns.Config.itemFontSize
				end,
				set = function(_, val)
					ns.Config.itemFontSize = val
					ns.UI:RefreshRows()
				end,
			},
			itemSpacing = {
				type = "range",
				name = L["Item Spacing"],
				min = 0,
				max = 20,
				step = 1,
				order = 5,
				get = function()
					return ns.Config.itemSpacing
				end,
				set = function(_, val)
					ns.Config.itemSpacing = val
					ns.UI:RefreshRows()
				end,
			},
			itemIndent = {
				type = "range",
				name = L["Item Indent"],
				min = 0,
				max = 50,
				step = 5,
				order = 6,
				get = function()
					return ns.Config.itemIndent
				end,
				set = function(_, val)
					ns.Config.itemIndent = val
					ns.UI:RefreshRows()
				end,
			},
			backgroundAlpha = {
				type = "range",
				name = L["Background Opacity"],
				min = 0,
				max = 100,
				step = 5,
				order = 7,
				get = function()
					return ns.Config.backgroundAlpha
				end,
				set = function(_, val)
					ns.Config.backgroundAlpha = val
					ns.UI:ApplyFrameStyle()
				end,
			},
		},
	}

	-- 3. Tracking Sub-Table
	local trackingOptions = {
		name = L["Tracked Items"],
		type = "group",
		args = {
			desc = {
				type = "description",
				name = L["Uncheck items to hide them from the list."],
				order = 0,
			},
		},
	}

	-- Dynamically generate tracking toggles
	local data = ns:GetCurrentSeasonData()
	local order = 10

	for _, section in ipairs(data) do
		-- Add Section Header
		if section.title then
			trackingOptions.args["header_" .. order] = {
				type = "header",
				name = section.title,
				order = order,
			}
			order = order + 1
		end

		if section.items then
			-- Create sorted copy of items (same logic as UI.lua)
			local sortedItems = {}
			for _, row in ipairs(section.items) do
				if
					row.id ~= nil
					and (
						row.type == "currency"
						or row.type == "currency_cap"
						or row.type == "quest"
						or row.type == "vault_visual"
						or row.type == "item"
					)
				then
					table.insert(sortedItems, row)
				end
			end

			-- Sort alphabetically (except for noSort sections and vault which has custom order)
			if not section.noSort then
				table.sort(sortedItems, function(a, b)
					-- Vault has custom order: Raid(3) -> Dungeons(1) -> World(6)
					if a.type == "vault_visual" and b.type == "vault_visual" then
						local vaultOrder = { [3] = 1, [1] = 2, [6] = 3 }
						local orderA = vaultOrder[a.id] or 99
						local orderB = vaultOrder[b.id] or 99
						return orderA < orderB
					end
					-- Alphabetical for everything else
					return (a.label or "") < (b.label or "")
				end)
			end

			for _, row in ipairs(sortedItems) do
				local configID = row.id
				if type(configID) == "table" then
					configID = configID[1]
				end

				trackingOptions.args["item_" .. configID] = {
					type = "toggle",
					name = row.label or L["Item %s"]:format(configID),
					width = "full",
					order = order,
					get = function()
						return not ns.Config.hiddenItems[configID]
					end,
					set = function(_, val)
						if val then
							ns.Config.hiddenItems[configID] = nil
						else
							ns.Config.hiddenItems[configID] = true
						end
						ns.UI:RefreshRows()
					end,
				}
				order = order + 1
			end
		end
	end

	-- Register Main
	AceConfig:RegisterOptionsTable("Weekly", mainOptions)
	local optionsFrame = AceConfigDialog:AddToBlizOptions("Weekly", "Weekly")

	-- In WoW 11.0+, AddToBlizOptions returns the frame, but we need the Category object
	-- to get the correct ID for Settings.OpenToCategory.
	local category = Settings.GetCategory("Weekly")
	if category then
		self.category = category
		self.categoryID = category:GetID()
	else
		-- Fallback for older versions or if GetCategory fails
		self.category = optionsFrame
		self.categoryID = optionsFrame and optionsFrame.name or "Weekly"
	end

	-- Register Sub-Categories
	AceConfig:RegisterOptionsTable("Weekly_Appearance", appearanceOptions)
	AceConfigDialog:AddToBlizOptions("Weekly_Appearance", L["Appearance"], "Weekly")

	AceConfig:RegisterOptionsTable("Weekly_Tracking", trackingOptions)
	AceConfigDialog:AddToBlizOptions("Weekly_Tracking", L["Tracked Items"], "Weekly")

	-- Register Profiles
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(ns.db)
	AceConfig:RegisterOptionsTable("Weekly_Profiles", profiles)
	AceConfigDialog:AddToBlizOptions("Weekly_Profiles", "Profiles", "Weekly")

	-- 4. Journal Tab
	local journalOptions = {
		name = L["Journal"],
		type = "group",
		args = {
			description = {
				type = "description",
				name = L["The Weekly Journal tracks collectibles you earn each week: achievements, mounts, pets, toys, and housing decor. Data resets automatically on weekly reset (Tuesday)."],
				fontSize = "medium",
				order = 1,
			},
			spacer1 = {
				type = "description",
				name = " ",
				order = 2,
			},
			enabled = {
				type = "toggle",
				name = L["Enable Journal"],
				desc = L["Enable tracking of collectibles earned this week."],
				width = "full",
				order = 10,
				get = function()
					return ns.Config.journal and ns.Config.journal.enabled
				end,
				set = function(_, val)
					if ns.Config.journal then
						ns.Config.journal.enabled = val
						if val then
							ns.Journal:Initialize()
						else
							ns.Journal:Shutdown()
						end
					end
				end,
			},
			showNotifications = {
				type = "toggle",
				name = L["Show Chat Notifications"],
				desc = L["Print a message to chat when a new item is logged to the journal."],
				width = "full",
				order = 11,
				disabled = function()
					return not ns.Config.journal or not ns.Config.journal.enabled
				end,
				get = function()
					return ns.Config.journal and ns.Config.journal.showNotifications
				end,
				set = function(_, val)
					if ns.Config.journal then
						ns.Config.journal.showNotifications = val
					end
				end,
			},
			showMinimapIcon = {
				type = "toggle",
				name = L["Show Minimap Icon"],
				desc = L["Show a separate minimap icon for the Journal. (Requires reload)"],
				width = "full",
				order = 12,
				disabled = function()
					return not ns.Config.journal or not ns.Config.journal.enabled
				end,
				get = function()
					return WeeklyDB and WeeklyDB.journalMinimapIcon and not WeeklyDB.journalMinimapIcon.hide
				end,
				set = function(_, val)
					if ns.JournalBroker then
						if val then
							ns.JournalBroker:ShowMinimapIcon()
						else
							ns.JournalBroker:HideMinimapIcon()
						end
					end
				end,
			},
			spacer2 = {
				type = "description",
				name = " ",
				order = 19,
			},
			openJournal = {
				type = "execute",
				name = L["Open Journal Window"],
				desc = L["Open the Weekly Journal window."],
				order = 20,
				disabled = function()
					return not ns.Config.journal or not ns.Config.journal.enabled
				end,
				func = function()
					if ns.JournalUI then
						ns.JournalUI:Show()
					end
				end,
			},
			spacer3 = {
				type = "description",
				name = "\n\n",
				order = 29,
			},
			statsHeader = {
				type = "header",
				name = L["This Week's Stats"],
				order = 30,
			},
			stats = {
				type = "description",
				name = function()
					if not ns.Journal or not ns.Journal.tracker then
						return "|cff888888" .. L["Journal not active"] .. "|r"
					end

					local total = ns.Journal:GetTotalCount()
					local points = ns.Journal:GetAchievementPointsThisWeek()

					local lines = {
						string.format("|cffffffff" .. L["Total items:"] .. "|r  %d", total),
						string.format("|cffffffff" .. L["Achievement points:"] .. "|r  %d", points),
						" ",
					}

					-- Category breakdown
					local categories = ns.Journal:GetOrderedCategories()
					for _, cat in ipairs(categories) do
						local count = ns.Journal:GetCategoryCount(cat.key)
						local color = count > 0 and "|cff00ff00" or "|cff888888"
						table.insert(lines, string.format("%s%s:|r  %d", color, L[cat.name] or cat.name, count))
					end

					return table.concat(lines, "\n")
				end,
				fontSize = "medium",
				order = 31,
			},
		},
	}

	AceConfig:RegisterOptionsTable("Weekly_Journal", journalOptions)
	AceConfigDialog:AddToBlizOptions("Weekly_Journal", L["Journal"], "Weekly")
end

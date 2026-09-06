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

local function NewRegion()
	local region = {
		events = {},
		scripts = {},
		shown = true,
		height = 18,
	}
	local function Noop() end

	region.SetFrameStrata = Noop
	region.SetClampedToScreen = Noop
	region.SetPoint = Noop
	region.ClearAllPoints = Noop
	region.RegisterForDrag = Noop
	region.RegisterForClicks = Noop
	region.SetAllPoints = Noop
	region.SetColorTexture = Noop
	region.SetText = Noop
	region.SetTextColor = Noop
	region.SetAlpha = Noop
	region.SetScale = Noop
	region.SetMovable = Noop
	region.EnableMouse = Noop
	region.SetSize = Noop
	region.SetWidth = Noop
	region.SetHeight = function(self, height)
		self.height = height
	end
	region.GetHeight = function(self)
		return self.height
	end
	region.SetFont = Noop
	region.SetNormalTexture = function(self)
		self.normalTexture = self.normalTexture or NewRegion()
	end
	region.GetNormalTexture = function(self)
		self.normalTexture = self.normalTexture or NewRegion()
		return self.normalTexture
	end
	region.SetTexCoord = Noop
	region.SetTexture = Noop
	region.SetBackdrop = Noop
	region.SetBackdropColor = Noop
	region.SetBackdropBorderColor = Noop
	region.GetStringWidth = function()
		return 0
	end
	region.GetLeft = function()
		return 100
	end
	region.GetTop = function()
		return 600
	end
	region.GetBottom = function()
		return 500
	end
	region.IsShown = function(self)
		return self.shown
	end
	region.Show = function(self)
		self.shown = true
	end
	region.Hide = function(self)
		self.shown = false
	end
	region.SetShown = function(self, shown)
		self.shown = shown
	end
	region.RegisterEvent = function(self, event)
		self.events[event] = true
	end
	region.SetScript = function(self, event, callback)
		self.scripts[event] = callback
	end
	region.CreateTexture = function()
		return NewRegion()
	end
	region.CreateFontString = function()
		return NewRegion()
	end

	return region
end

describe("Weekly tracker UI", function()
	local afterCallback

	before_each(function()
		ns = {
			Config = {
				anchor = "TOP",
				backgroundAlpha = 90,
				headerFontSize = 14,
				itemFontSize = 12,
				itemSpacing = 4,
				itemIndent = 10,
				locked = false,
				hiddenItems = {},
				collapsedSections = {},
			},
			Data = {
				IsSectionVisible = function()
					return true
				end,
			},
			GetCurrentSeasonData = function()
				return {}
			end,
		}
		_G.UIParent = NewRegion()
		_G.CreateFrame = function()
			return NewRegion()
		end
		_G.time = function()
			return 1000
		end
		_G.debugprofilestop = function()
			return 0
		end
		_G.FormatLargeNumber = tostring
		_G.C_Timer = {
			After = function(_, callback)
				afterCallback = callback
			end,
		}
		_G.GameTooltip = {
			SetOwner = function() end,
			SetItemByID = function(self, id)
				self.itemID = id
			end,
			Show = function() end,
			Hide = function() end,
		}
		local locale = setmetatable({}, {
			__index = function(_, key)
				return key
			end,
		})
		_G.LibStub = function(name)
			if name == "AceLocale-3.0" then
				return {
					GetLocale = function()
						return locale
					end,
				}
			elseif name == "LibSharedMedia-3.0" then
				return {
					Fetch = function()
						return "font"
					end,
				}
			end
		end
		afterCallback = nil
		LoadFile("UI.lua")
		ns.UI:ApplyConfig("login")
	end)

	it("refreshes when bag contents or item information changes", function()
		assert.is_true(ns.UI.frame.events.BAG_UPDATE_DELAYED)
		assert.is_true(ns.UI.frame.events.GET_ITEM_INFO_RECEIVED)

		local refreshes = 0
		ns.UI.RefreshRows = function()
			refreshes = refreshes + 1
		end
		ns.UI.frame:Show()
		ns.UI.frame.scripts.OnEvent()
		ns.UI.frame.scripts.OnEvent()
		assert.are.equal(0, refreshes)

		afterCallback()
		assert.are.equal(1, refreshes)
	end)

	it("accumulates performance counters across multiple refreshes", function()
		ns.PerfBlocks = { uiRefresh = 10, dataQuery = 20, vaultLookup = 30, journalTrack = 40 }
		local elapsed = 0
		_G.debugprofilestop = function()
			return elapsed
		end
		ns.UI.RenderRows = function()
			elapsed = elapsed + 5
			ns.PerfBlocks.dataQuery = ns.PerfBlocks.dataQuery + 2
			ns.PerfBlocks.vaultLookup = ns.PerfBlocks.vaultLookup + 1
		end
		ns.UI:RefreshRows()
		ns.UI:RefreshRows()
		assert.are.same({ uiRefresh = 20, dataQuery = 24, vaultLookup = 32, journalTrack = 40 }, ns.PerfBlocks)
	end)

	it("shows the item tooltip for item-backed tracker rows", function()
		local row = ns.UI:CreateRowFrame()
		row.iconBtn.type = "item"
		row.iconBtn.id = 273000

		row.iconBtn.scripts.OnEnter(row.iconBtn)

		assert.are.equal(273000, GameTooltip.itemID)
	end)
end)

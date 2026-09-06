-- Focused interaction tests for the Weekly Journal UI.

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

local function Noop() end

local function CreateFallbackRow()
	local row = {
		points = {},
		icon = {},
		name = {},
		extra = {},
	}
	function row:SetPoint(...)
		table.insert(self.points, { ... })
	end
	function row:Show()
		self.shown = true
	end
	function row:Hide()
		self.shown = false
	end
	function row.icon:SetTexture(value)
		self.texture = value
	end
	function row.icon:Show()
		self.shown = true
	end
	function row.name:SetPoint(...)
		self.point = { ... }
	end
	function row.name:SetText(value)
		self.text = value
	end
	row.name.SetFontObject = Noop
	row.name.SetTextColor = Noop
	function row.extra:SetText(value)
		self.text = value
	end
	row.extra.SetTextColor = Noop
	return row
end

describe("Weekly Journal UI", function()
	local opened
	local tooltip

	before_each(function()
		_G.FenUI = {}
		_G.LibStub = function()
			return {
				GetLocale = function()
					return setmetatable({}, {
						__index = function(_, key)
							return key
						end,
					})
				end,
			}
		end
		_G.time = function()
			return 1734566400
		end
		_G.date = os.date
		tooltip = { lines = {} }
		function tooltip:SetOwner(owner, anchor)
			self.owner = owner
			self.anchor = anchor
		end
		function tooltip:SetText(text)
			self.text = text
		end
		function tooltip:AddLine(text)
			table.insert(self.lines, text)
		end
		function tooltip:Show()
			self.shown = true
		end
		function tooltip:Hide()
			self.hidden = true
		end
		_G.GameTooltip = tooltip

		opened = nil
		ns.Journal = {
			GetCategoryItems = function(_, category)
				return {
					{
						category = category,
						id = 42,
						data = { name = "Test Mount", icon = 1234, firstSeen = 1734566300 },
					},
				}
			end,
			OpenOfficialUI = function(_, category, id, data)
				opened = { category = category, id = id, data = data }
			end,
		}
		LoadFile("Journal/JournalUI.lua")
	end)

	it("renders and opens a nonempty category without FenUI", function()
		local row = CreateFallbackRow()
		local scrollChild = {
			SetHeight = function(self, height)
				self.height = height
			end,
		}
		ns.JournalUI.frame = { scrollChild = scrollChild }
		ns.JournalUI.rowPool = {}
		ns.JournalUI.GetRow = function()
			return row
		end

		ns.JournalUI:RenderCategoryTab("mount")

		assert.is_true(row.shown)
		assert.are.equal(1234, row.icon.texture)
		assert.are.equal("Test Mount", row.name.text)
		assert.is_true(scrollChild.height > 10)

		row.clickFunc()
		assert.are.same({ category = "mount", id = 42, data = ns.Journal:GetCategoryItems("mount")[1].data }, opened)
	end)

	it("wires FenUI grid hover and click hooks to bound item actions", function()
		local capturedConfig
		local grid = { SetPoint = Noop }
		FenUI.CreateGrid = function(_, _parent, config)
			capturedConfig = config
			return grid
		end

		assert.are.equal(grid, ns.JournalUI:CreateItemGrid({}))
		assert.is_table(capturedConfig)

		local cells = {
			{ SetIcon = Noop },
			{ SetText = Noop },
			{
				SetText = function(self)
					self.fontString = { SetTextColor = Noop }
				end,
			},
		}
		local row = {
			GetCell = function(_, index)
				return cells[index]
			end,
		}
		local item = ns.Journal:GetCategoryItems("mount")[1]
		capturedConfig.onRowBind(row, item, 1)
		capturedConfig.onRowEnter(row, item, 1)

		assert.are.equal(row, tooltip.owner)
		assert.are.equal("ANCHOR_RIGHT", tooltip.anchor)
		assert.are.equal("Test Mount", tooltip.text)

		capturedConfig.onRowClick(row, item, 1)
		assert.are.equal("mount", opened.category)
		assert.are.equal(42, opened.id)

		capturedConfig.onRowLeave(row, item, 1)
		assert.is_true(tooltip.hidden)
	end)
end)

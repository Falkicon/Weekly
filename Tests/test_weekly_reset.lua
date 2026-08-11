local addonName = "Weekly"
local ns = {}

local function LoadFile(path)
	local func, err = loadfile(path)
	if not func then
		error("Failed to load " .. path .. ": " .. err)
	end
	func(addonName, ns)
end

describe("Weekly Reset Boundary", function()
	before_each(function()
		ns = {}
		LoadFile("Core/WeeklyReset.lua")
	end)

	it("establishes the first observed boundary without clearing data", function()
		local state = { nextReset = 0 }
		assert.is_false(ns.WeeklyReset:Check(state, 1000, 5000))
		assert.are.equal(5000, state.nextReset)
	end)

	it("detects a boundary that passed while the addon was offline", function()
		local state = { nextReset = 5000 }
		assert.is_true(ns.WeeklyReset:Check(state, 5001, 10000))
		assert.are.equal(10000, state.nextReset)
	end)

	it("detects when Blizzard's timer has rolled to the next week", function()
		local state = { nextReset = 5000 }
		assert.is_true(ns.WeeklyReset:Check(state, 4900, 700000))
		assert.are.equal(700000, state.nextReset)
	end)

	it("does not reset twice within one boundary", function()
		local state = { nextReset = 700000 }
		assert.is_false(ns.WeeklyReset:Check(state, 6000, 700000))
		assert.are.equal(700000, state.nextReset)
	end)

	it("exposes the shared boundary predicate", function()
		assert.is_false(ns.WeeklyReset:HasBoundaryPassed(0, 1000, 5000))
		assert.is_true(ns.WeeklyReset:HasBoundaryPassed(5000, 5001, 10000))
		assert.is_true(ns.WeeklyReset:HasBoundaryPassed(5000, 4900, 700000))
	end)
end)

-- test_mechanic_performance.lua
-- Tests Mechanic performance sampling without loading the WoW client.

local addonName = "Weekly"
local ns
local registration
local profileTime
local originalGetTime
local originalLibStub
local originalAddOns
local originalTime

local function LoadIntegration()
	local chunk, err = loadfile("MechanicIntegration.lua")
	if not chunk then
		error(err)
	end
	setfenv(chunk, getfenv(1))
	chunk(addonName, ns)
end

describe("Weekly Mechanic performance metrics", function()
	before_each(function()
		ns = {}
		registration = nil
		profileTime = 0
		originalGetTime = _G.GetTime
		originalLibStub = _G.LibStub
		originalAddOns = _G.C_AddOns
		originalTime = _G.time
		_G.GetTime = function()
			return profileTime / 1000
		end
		_G.LibStub = function(name)
			if name == "MechanicLib-1.0" then
				return {
					Register = function(_, registeredAddon, definition)
						assert.are.equal(addonName, registeredAddon)
						registration = definition
					end,
				}
			end
			return nil
		end
		_G.C_AddOns = {
			GetAddOnMetadata = function()
				return "test"
			end,
		}
		_G.time = function()
			return 0
		end
		LoadIntegration()
		-- Establish a baseline before accumulating work in the shared sampler.
		registration.performance.getSubMetrics()
	end)

	after_each(function()
		_G.GetTime = originalGetTime
		_G.LibStub = originalLibStub
		_G.C_AddOns = originalAddOns
		_G.time = originalTime
	end)

	it("reports accumulated work as a sampled rate that returns to zero while idle", function()
		ns.PerfBlocks.uiRefresh = 3
		ns.PerfBlocks.dataQuery = 1
		profileTime = 1000

		local metrics = registration.performance.getSubMetrics()
		assert.are.equal(3, metrics[1].msPerSec)
		assert.are.equal(1, metrics[2].msPerSec)

		profileTime = 2000
		metrics = registration.performance.getSubMetrics()
		assert.are.equal(0, metrics[1].msPerSec)
		assert.are.equal(0, metrics[2].msPerSec)
	end)

	it("does not discard work when polled more often than the sampling interval", function()
		ns.PerfBlocks.uiRefresh = 2
		profileTime = 1000
		local metrics = registration.performance.getSubMetrics()
		assert.are.equal(2, metrics[1].msPerSec)

		ns.PerfBlocks.uiRefresh = ns.PerfBlocks.uiRefresh + 4
		profileTime = 1200
		metrics = registration.performance.getSubMetrics()
		assert.are.equal(2, metrics[1].msPerSec)

		profileTime = 2000
		metrics = registration.performance.getSubMetrics()
		assert.are.equal(4, metrics[1].msPerSec)
	end)
end)

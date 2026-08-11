--------------------------------------------------------------------------------
-- WeeklyReset.lua
-- Shared weekly-reset boundary detection using Blizzard's live reset timer.
--------------------------------------------------------------------------------

local _, ns = ...

local WeeklyReset = {}
ns.WeeklyReset = WeeklyReset

function WeeklyReset:GetNow()
	if GetServerTime then
		return GetServerTime()
	end
	if time then
		return time()
	end
	return os.time()
end

function WeeklyReset:GetObservedNextReset(now)
	if not C_DateAndTime or not C_DateAndTime.GetSecondsUntilWeeklyReset then
		return nil
	end

	local ok, seconds = pcall(C_DateAndTime.GetSecondsUntilWeeklyReset)
	if not ok or type(seconds) ~= "number" or seconds <= 0 then
		return nil
	end
	return now + seconds
end

function WeeklyReset:HasBoundaryPassed(storedNextReset, now, observedNextReset)
	storedNextReset = tonumber(storedNextReset) or 0
	return storedNextReset > 0
		and (now >= storedNextReset or (observedNextReset and observedNextReset > storedNextReset + (6 * 60 * 60)))
end

-- Returns true once when the stored boundary has passed or Blizzard's timer
-- has rolled forward to the following reset. A first observation establishes
-- the boundary without discarding existing data.
function WeeklyReset:Check(state, now, observedNextReset)
	if not state then
		return false
	end

	now = now or self:GetNow()
	if observedNextReset == nil then
		observedNextReset = self:GetObservedNextReset(now)
	end

	local storedNextReset = tonumber(state.nextReset) or 0
	if storedNextReset <= 0 then
		state.nextReset = observedNextReset or 0
		return false
	end

	if not self:HasBoundaryPassed(storedNextReset, now, observedNextReset) then
		return false
	end

	state.nextReset = observedNextReset or 0
	return true
end

return WeeklyReset

--------------------------------------------------------------------------------
-- FenCoreCompat.lua
-- Graceful FenCore integration for Weekly
-- Provides fallbacks when FenCore is not available
--------------------------------------------------------------------------------

local _, ns = ...

local FenCore = _G.FenCore

local Compat = {}
ns.FenCore = Compat

--------------------------------------------------------------------------------
-- ActionResult
-- AFD-style structured results for all operations
--------------------------------------------------------------------------------

if FenCore and FenCore.ActionResult then
	Compat.ActionResult = FenCore.ActionResult
else
	-- Fallback implementation
	local ActionResult = {}

	function ActionResult.success(data, reasoning)
		return {
			success = true,
			data = data,
			reasoning = reasoning,
		}
	end

	function ActionResult.error(code, message, suggestion)
		return {
			success = false,
			error = {
				code = code,
				message = message,
				suggestion = suggestion,
			},
		}
	end

	function ActionResult.isSuccess(result)
		return result and result.success == true
	end

	function ActionResult.isError(result)
		return result and result.success == false
	end

	function ActionResult.unwrap(result)
		if result and result.success then
			return result.data
		end
		return nil
	end

	function ActionResult.getErrorCode(result)
		if result and result.error then
			return result.error.code
		end
		return nil
	end

	Compat.ActionResult = ActionResult
end

--------------------------------------------------------------------------------
-- Text Utilities
--------------------------------------------------------------------------------

if FenCore and FenCore.Text then
	Compat.Text = FenCore.Text
else
	-- Fallback implementation
	local Text = {}

	function Text.Pluralize(count, singular, plural)
		plural = plural or (singular .. "s")
		return count .. " " .. (count == 1 and singular or plural)
	end

	Compat.Text = Text
end

--------------------------------------------------------------------------------
-- Table Utilities
--------------------------------------------------------------------------------

if FenCore and FenCore.Tables then
	Compat.Tables = FenCore.Tables
else
	-- Fallback implementation
	local Tables = {}

	function Tables.Count(tbl)
		if not tbl then
			return 0
		end
		local count = 0
		for _ in pairs(tbl) do
			count = count + 1
		end
		return count
	end

	Compat.Tables = Tables
end

return Compat

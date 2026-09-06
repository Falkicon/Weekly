local _, ns = ...

local Data = assert(ns.Data, "Data/Loader.lua must be loaded before Data/Validation.lua")

local SUPPORTED_TYPES = {
	currency = true,
	currency_cap = true,
	item = true,
	prey = true,
	quest = true,
	vault_visual = true,
}

local VAULT_CATEGORIES = {
	[1] = true, -- Dungeons
	[3] = true, -- Raid
	[6] = true, -- World
}

local function AddError(errors, path, message)
	errors[#errors + 1] = string.format("%s: %s", path, message)
end

local function IsPositiveInteger(value)
	return type(value) == "number" and value > 0 and value % 1 == 0
end

local function ArrayLength(value, path, errors)
	if type(value) ~= "table" then
		AddError(errors, path, "must be an array")
		return nil
	end

	local count = 0
	local highest = 0
	local invalid = false
	for key in pairs(value) do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
			AddError(errors, path, string.format("must be an array; unexpected key %q", tostring(key)))
			invalid = true
		else
			count = count + 1
			highest = math.max(highest, key)
		end
	end
	if count ~= highest then
		AddError(errors, path, "must be a contiguous array without missing entries")
		invalid = true
	end
	if invalid then
		return nil
	end
	return highest
end

local function ValidatePositiveInteger(value, path, errors, description)
	if not IsPositiveInteger(value) then
		AddError(errors, path, "must be a positive integer" .. (description or ""))
		return false
	end
	return true
end

local function ValidatePositiveID(value, path, errors)
	return ValidatePositiveInteger(value, path, errors, " ID")
end

local function ValidateIDList(value, path, errors)
	local length = ArrayLength(value, path, errors)
	if not length then
		return false
	end
	if length == 0 then
		AddError(errors, path, "must contain at least one ID")
		return false
	end
	for index = 1, length do
		if value[index] ~= nil then
			ValidatePositiveID(value[index], string.format("%s[%d]", path, index), errors)
		end
	end
	return true
end

local function ValidateQuestID(item, path, errors)
	if item.placeholder then
		if item.id ~= 0 then
			AddError(errors, path .. ".id", "placeholder quests must use ID 0")
		end
		if type(item.label) ~= "string" or item.label == "" then
			AddError(errors, path .. ".label", "placeholder quests require a non-empty label")
		end
		return
	end

	if type(item.id) == "table" then
		ValidateIDList(item.id, path .. ".id", errors)
	else
		ValidatePositiveID(item.id, path .. ".id", errors)
	end
end

local function ValidateDate(value, path, errors)
	if type(value) ~= "string" then
		AddError(errors, path, "must use YYYY-MM-DD")
		return false
	end

	local yearText, monthText, dayText = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
	if not yearText then
		AddError(errors, path, "must use YYYY-MM-DD")
		return false
	end

	local year = tonumber(yearText)
	local month = tonumber(monthText)
	local day = tonumber(dayText)
	local leapYear = year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
	local daysByMonth = { 31, leapYear and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
	if year < 1 or month < 1 or month > 12 or day < 1 or day > (daysByMonth[month] or 0) then
		AddError(errors, path, "must be a real calendar date")
		return false
	end
	return true
end

local function ValidateCoords(coords, path, errors)
	if type(coords) ~= "table" then
		AddError(errors, path, "must be a table with mapID, x, and y")
		return
	end
	ValidatePositiveID(coords.mapID, path .. ".mapID", errors)
	local xIsFinite = type(coords.x) == "number"
		and coords.x == coords.x
		and coords.x ~= math.huge
		and coords.x ~= -math.huge
	if not xIsFinite or coords.x < 0 or coords.x > 1 then
		AddError(errors, path .. ".x", "must be a number from 0 through 1")
	end
	local yIsFinite = type(coords.y) == "number"
		and coords.y == coords.y
		and coords.y ~= math.huge
		and coords.y ~= -math.huge
	if not yIsFinite or coords.y < 0 or coords.y > 1 then
		AddError(errors, path .. ".y", "must be a number from 0 through 1")
	end
end

local function ValidateOptionalText(value, path, errors)
	if value ~= nil and (type(value) ~= "string" or value == "") then
		AddError(errors, path, "must be a non-empty string when provided")
	end
end

local function ValidateOptionalIcon(value, path, errors)
	if value == nil then
		return
	end
	if type(value) == "string" and value ~= "" then
		return
	end
	if IsPositiveInteger(value) then
		return
	end
	AddError(errors, path, "must be a non-empty texture path or positive integer file ID when provided")
end

local function GetConfigKey(item)
	local ok, key = pcall(Data.GetItemConfigKey, Data, item)
	if ok and key ~= nil then
		return tostring(key)
	end
	return nil
end

local function ValidateItem(item, path, errors)
	if type(item) ~= "table" then
		AddError(errors, path, "must be a tracker table")
		return nil
	end

	if not SUPPORTED_TYPES[item.type] then
		AddError(errors, path .. ".type", string.format("unsupported tracker type %q", tostring(item.type)))
		return nil
	end
	ValidateOptionalText(item.label, path .. ".label", errors)
	ValidateOptionalIcon(item.icon, path .. ".icon", errors)

	if item.key ~= nil and (type(item.key) ~= "string" and type(item.key) ~= "number" or tostring(item.key) == "") then
		AddError(errors, path .. ".key", "must be a non-empty string or number when provided")
	end
	if item.placeholder ~= nil and type(item.placeholder) ~= "boolean" then
		AddError(errors, path .. ".placeholder", "must be a boolean when provided")
	end
	if item.placeholder and item.type ~= "quest" then
		AddError(errors, path .. ".placeholder", "is only supported for quest trackers")
	end

	if item.type == "quest" then
		ValidateQuestID(item, path, errors)
	elseif item.type == "prey" then
		ValidatePositiveInteger(item.maxCount, path .. ".maxCount", errors)
		if item.ids ~= nil then
			ValidateIDList(item.ids, path .. ".ids", errors)
		end
		if item.questId ~= nil then
			ValidatePositiveID(item.questId, path .. ".questId", errors)
		end
		if item.ids == nil and item.questId == nil then
			AddError(errors, path, "prey trackers require ids or questId")
		end
	elseif item.type == "vault_visual" then
		if ValidatePositiveID(item.id, path .. ".id", errors) and not VAULT_CATEGORIES[item.id] then
			AddError(errors, path .. ".id", "must be a supported vault category (1, 3, or 6)")
		end
	else
		ValidatePositiveID(item.id, path .. ".id", errors)
	end

	if item.preyCacheMax ~= nil then
		ValidatePositiveInteger(item.preyCacheMax, path .. ".preyCacheMax", errors)
	end
	if item.cacheMax ~= nil then
		ValidatePositiveInteger(item.cacheMax, path .. ".cacheMax", errors)
	end
	if item.coords ~= nil then
		ValidateCoords(item.coords, path .. ".coords", errors)
	end

	return GetConfigKey(item)
end

local function ValidateSection(section, path, errors, configKeys)
	if type(section) ~= "table" then
		AddError(errors, path, "must be a section table")
		return
	end
	if type(section.title) ~= "string" or section.title == "" then
		AddError(errors, path .. ".title", "must be a non-empty string")
	end
	if section.noSort ~= nil and type(section.noSort) ~= "boolean" then
		AddError(errors, path .. ".noSort", "must be a boolean when provided")
	end

	local showValid = section.showAfter == nil or ValidateDate(section.showAfter, path .. ".showAfter", errors)
	local hideValid = section.hideAfter == nil or ValidateDate(section.hideAfter, path .. ".hideAfter", errors)
	if
		showValid
		and hideValid
		and section.showAfter
		and section.hideAfter
		and section.showAfter >= section.hideAfter
	then
		AddError(errors, path, "showAfter must be earlier than hideAfter")
	end

	local itemCount = ArrayLength(section.items, path .. ".items", errors)
	if not itemCount then
		return
	end
	for itemIndex = 1, itemCount do
		local item = section.items[itemIndex]
		if item ~= nil then
			local itemPath = string.format("%s.items[%d]", path, itemIndex)
			local key = ValidateItem(item, itemPath, errors)
			if key and configKeys[key] then
				AddError(
					errors,
					itemPath .. ".key",
					string.format("configuration key %q conflicts with %s", key, configKeys[key])
				)
			elseif key then
				configKeys[key] = itemPath
			end
		end
	end
end

function Data:ValidateDataset(dataset, context)
	local errors = {}
	local rootPath = context or "dataset"
	local sectionCount = ArrayLength(dataset, rootPath .. ".sections", errors)
	if not sectionCount then
		return false, errors
	end

	local configKeys = {}
	for sectionIndex = 1, sectionCount do
		if dataset[sectionIndex] ~= nil then
			ValidateSection(
				dataset[sectionIndex],
				string.format("%s.sections[%d]", rootPath, sectionIndex),
				errors,
				configKeys
			)
		end
	end
	return #errors == 0, errors
end

local function SortedKeys(value)
	local keys = {}
	for key in pairs(value) do
		keys[#keys + 1] = key
	end
	table.sort(keys, function(left, right)
		if type(left) == "number" and type(right) == "number" then
			return left < right
		end
		return tostring(left) < tostring(right)
	end)
	return keys
end

function Data:ValidateRegistry()
	local errors = {}
	for _, expansionID in ipairs(SortedKeys(self.Registry)) do
		local expansionPath = string.format("Registry[%s]", tostring(expansionID))
		if not IsPositiveInteger(expansionID) then
			AddError(errors, expansionPath, "expansion ID must be a positive integer")
		end

		local seasons = self.Registry[expansionID]
		if type(seasons) ~= "table" then
			AddError(errors, expansionPath, "must contain a season table")
		else
			for _, seasonID in ipairs(SortedKeys(seasons)) do
				local registryPath = string.format("%s[%s]", expansionPath, tostring(seasonID))
				if not IsPositiveInteger(seasonID) then
					AddError(errors, registryPath, "season ID must be a positive integer")
				end

				local source = self.Sources and self.Sources[expansionID] and self.Sources[expansionID][seasonID]
				local context = source and string.format("%s (%s)", source, registryPath) or registryPath
				local _, datasetErrors = self:ValidateDataset(seasons[seasonID], context)
				for _, validationError in ipairs(datasetErrors) do
					errors[#errors + 1] = validationError
				end
			end
		end
	end
	return #errors == 0, errors
end

local _, ns = ...

local Factory = {}
ns.DataFactory = Factory

function Factory.Vault(id, label)
	return { type = "vault_visual", id = id, label = label }
end

function Factory.Quest(id, label, icon, coords)
	return { type = "quest", id = id, label = label, icon = icon, coords = coords }
end

-- Creates a visible row for content whose quest ID has not been confirmed yet.
-- Dataset validation rejects a bare zero ID so placeholders remain deliberate.
function Factory.PlaceholderQuest(label, icon, coords)
	return { type = "quest", id = 0, label = label, icon = icon, coords = coords, placeholder = true }
end

function Factory.Currency(id, label)
	return { type = "currency", id = id, label = label }
end

function Factory.Cap(id, label)
	return { type = "currency_cap", id = id, label = label }
end

function Factory.Item(id, label)
	return { type = "item", id = id, label = label }
end

function Factory.Prey(ids, label, maxCount, icon, questId)
	return {
		type = "prey",
		key = "midnight-prey-hunts",
		ids = ids,
		label = label,
		maxCount = maxCount,
		icon = icon,
		questId = questId,
	}
end

return Factory

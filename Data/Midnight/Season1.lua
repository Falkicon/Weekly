local _, ns = ...

--------------------------------------------------------------------------------
-- Midnight Season 1 (Expansion 12, 12.0.1+)
--------------------------------------------------------------------------------

local function Vault(id, label)
	return { type = "vault_visual", id = id, label = label }
end
local function Quest(id, label, icon, coords)
	return { type = "quest", id = id, label = label, icon = icon, coords = coords }
end
local function Currency(id, label)
	return { type = "currency", id = id, label = label }
end
local function Cap(id, label)
	return { type = "currency_cap", id = id, label = label }
end

local data = {
	{
		title = "Vault",
		items = {
			Vault(3, "Raid"),
			Vault(1, "Dungeons"),
			Vault(6, "World"),
		},
	},
	--------------------------------------------------------------------------------
	-- MIDNIGHT CAMPAIGN (One-time story - "The Light's Summons")
	--------------------------------------------------------------------------------
	{
		title = "Midnight Campaign",
		noSort = true,
		items = {
			Quest(91281, "Midnight", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(88719, "A Voice from the Light", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(86769, "Last Bastion of the Light", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(86770, "Champions of Quel'Danas", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(89271, "My Son", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(86780, "Where Heroes Hold", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(86805, "The Hour of Need", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(89012, "A Safe Path", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(86806, "Luminous Wings", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(86807, "The Gate", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(91274, "Severing the Void", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(86834, "Voidborn Banishing", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(86811, "Ethereal Eradication", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(86848, "Light's Arsenal", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(86849, "Wrath Unleashed", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(86850, "Broken Sun", "Interface\\GossipFrame\\AvailableQuestIcon"),
			Quest(86852, "Light's Last Stand", "Interface\\GossipFrame\\AvailableQuestIcon"),
		},
	},
	{
		title = "Weekly Quests",
		items = {
			Quest(0, "Weekly Quest Placeholder", "Interface\\Icons\\INV_Box_02"),
			Quest(0, "Another Weekly Placeholder", "Interface\\Icons\\INV_Misc_Book_09"),
		},
	},
	{
		title = "Upgrade Currencies",
		noSort = true,
		items = {
			-- Dawncrests (Ordered)
			Cap(0, "Veteran Dawncrest"),
			Cap(0, "Champion Dawncrest"),
			Cap(0, "Hero Dawncrest"),
			Cap(0, "Myth Dawncrest"),
		},
	},
	{
		title = "Currencies",
		items = {
			-- New Premium Currency
			Currency(0, "Hearthsteel"),
		},
	},
}

-- Register as Midnight (Expansion 12), Season 1
ns.Data:Register(12, 1, data)

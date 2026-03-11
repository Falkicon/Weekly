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
local function Item(id, label)
	return { type = "item", id = id, label = label }
end
local function Prey(ids, label, maxCount, icon)
	return { type = "prey", ids = ids, label = label, maxCount = maxCount, icon = icon }
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
	--------------------------------------------------------------------------------
	-- ONGOING EVENTS
	--------------------------------------------------------------------------------
	{
		title = "Ongoing Events",
		items = {
			Quest(0, "Abundant Offerings", "Interface\\Icons\\INV_Misc_Bag_17"),
			Quest(0, "Fortify the Runestones", "Interface\\Icons\\INV_Misc_Gem_01"),
			Quest(0, "Favor of the Court", "Interface\\Icons\\INV_Misc_Gem_01"),
			Quest(0, "Lost Legends", "Interface\\Icons\\INV_Misc_Book_09"),
			Quest(0, "Stand Your Ground", "Interface\\Icons\\Ability_Warrior_ShieldWall"),
		},
	},
	{
		title = "Weekly Quests",
		items = {
			Quest(93910, "Midnight: Prey"),
			Quest(93754, "Maisara Caverns"),
			Quest(95114, "Prey: A Crimson Summons"),
		},
	},
	{
		title = "Prey",
		noSort = true,
		items = {
			Prey({ 90912, 91151, 91402, 91098, 91102, 91099, 91135, 91123, 91120, 91154, 91118, 91142, 91108, 91136, 91119, 91143 }, "Prey Hunts", 4, "Interface\\Icons\\Achievement_Halloween_Witch_01"),
		},
	},
	{
		title = "Housing",
		noSort = true,
		items = {
			Quest(0, "Neighborhood Endeavors", "Interface\\Icons\\inv_misc_key_14"),
			Item(251764, "Ashwood Lumber"),
			Item(242691, "Olemba Lumber"),
			Item(245586, "Ironwood Lumber"),
			Item(248012, "Dornic Fir Lumber"),
			Item(251766, "Shadowmoon Lumber"),
			Item(256963, "Thalassian Lumber"),
			Currency(3363, "Community Coupons"),
		},
	},
	{
		title = "Upgrade Currencies",
		noSort = true,
		items = {
			Cap(3383, "Adventurer Dawncrest"),
			Cap(3341, "Veteran Dawncrest"),
			Cap(3343, "Champion Dawncrest"),
			Cap(3345, "Hero Dawncrest"),
			Cap(3347, "Myth Dawncrest"),
		},
	},
	{
		title = "Currencies",
		items = {
			Currency(3316, "Voidlight Marl"),
			Currency(3376, "Shard of Dundun"),
			Currency(3377, "Unalloyed Abundance"),
			Currency(3385, "Luminous Dust"),
			Currency(3392, "Remnant of Anguish"),
			Currency(3379, "Brimming Arcana"),
			Currency(3400, "Uncontaminated Void Sample"),
			Currency(3373, "Angler Pearls"),
		},
	},
	{
		title = "Artisan Moxie",
		items = {
			Currency(3256, "Artisan Alchemist's Moxie"),
			Currency(3257, "Artisan Blacksmith's Moxie"),
			Currency(3258, "Artisan Enchanter's Moxie"),
			Currency(3259, "Artisan Engineer's Moxie"),
			Currency(3260, "Artisan Herbalist's Moxie"),
			Currency(3261, "Artisan Scribe's Moxie"),
			Currency(3262, "Artisan Jewelcrafter's Moxie"),
			Currency(3263, "Artisan Leatherworker's Moxie"),
			Currency(3264, "Artisan Miner's Moxie"),
			Currency(3265, "Artisan Skinner's Moxie"),
			Currency(3266, "Artisan Tailor's Moxie"),
		},
	},
}

-- Register as Midnight (Expansion 12), Season 1
ns.Data:Register(12, 1, data)

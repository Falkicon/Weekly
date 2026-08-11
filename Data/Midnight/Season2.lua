local _, ns = ...

--------------------------------------------------------------------------------
-- Midnight Season 2 (Expansion 12, 12.1.0+)
-- New 12.1 IDs are PTR candidates and should be confirmed with Discovery.
--------------------------------------------------------------------------------

local Factory = ns.DataFactory
local Vault, Quest, Currency, Cap, Item, Prey =
	Factory.Vault, Factory.Quest, Factory.Currency, Factory.Cap, Factory.Item, Factory.Prey

local data = {
	{
		title = "Vault",
		items = {
			Vault(3, "Raid"),
			Vault(1, "Dungeons"),
			Vault(6, "World"),
		},
	},
	{
		title = "Weekly Quests",
		items = {
			Quest(93909, "Midnight: Delves"),
			{ type = "quest", id = 93910, label = "Midnight: Prey Cache", preyCacheMax = 3 },
			Quest(93913, "Midnight: World Boss"),
			Quest(94446, "A Nightmarish Task"),
			Quest(95842, "Midnight: Void Assaults"),
			Quest(95520, "Purging the Vaults"),
			Quest(97128, "Lair: Nymrissa Wavecaller"),
		},
	},
	{
		title = "Prey",
		noSort = true,
		items = {
			Prey(
				nil,
				"Prey Hunts",
				15,
				"Interface\\Icons\\Achievement_Halloween_Witch_01",
				93910
			),
		},
	},
	{
		title = "PvP",
		items = {
			Quest(94835, "Early Morning Training", "Interface\\Icons\\Achievement_BG_KillXEnemies_GeneralsBRoom"),
			Quest(47148, "Something Different"),
		},
	},
	{
		title = "Neighborhood",
		noSort = true,
		items = {
			Quest(95413, "Community Engagement"),
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
			Cap(3442, "Adventurer Mistcrest"),
			Cap(3443, "Veteran Mistcrest"),
			Cap(3444, "Champion Mistcrest"),
			Cap(3445, "Hero Mistcrest"),
			Cap(3446, "Myth Mistcrest"),
		},
	},
	{
		title = "Season 2",
		noSort = true,
		items = {
			Currency(3448, "Corrosive Coin"),
			Currency(3513, "Nebulous Voidcore"),
			Item(273000, "Corrosive Soul"),
			Item(274476, "Spark of Tides"),
			Currency(3405, "Field Accolade"),
			Currency(3316, "Voidlight Marl"),
		},
	},
	{
		title = "Currencies",
		items = {
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

-- Register as Midnight (Expansion 12), Season 2
ns.Data:Register(12, 2, data)

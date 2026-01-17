local _, ns = ...

--------------------------------------------------------------------------------
-- Midnight Pre-Patch (Season 3.5) - TWW content with pre-expansion additions
--------------------------------------------------------------------------------
-- TOC 120000 (12.0.0) triggers this season
-- Contains TWW Season 3 content PLUS:
--   - Twilight Ascension event (Jan 27)
--   - Housing (Jan 20 for Early Access)
--   - Pre-patch currencies
--
-- TODO: Update placeholder IDs (0) when patch launches
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

local data = {
	--------------------------------------------------------------------------------
	-- VAULT (Always first)
	--------------------------------------------------------------------------------
	{
		title = "Vault",
		items = {
			Vault(3, "Raid"),
			Vault(1, "Dungeons"),
			Vault(6, "World"),
		},
	},
	--------------------------------------------------------------------------------
	-- TWILIGHT ASCENSION (Pre-patch event - Starts Jan 27)
	-- TEMPORARY: Remove this section when Midnight S1 launches
	--------------------------------------------------------------------------------
	{
		title = "Twilight Ascension (Pre-patch Event)",
		items = {
			-- Weekly wrapper quests
			Quest(0, "Twilight's Call", "Interface\\Icons\\spell_shadow_twilight"),
			Quest(91795, "Disrupt the Call", "Interface\\Icons\\spell_shadow_twilight"),
			-- Event currency
			Currency(3319, "Twilight's Blade Insignia"),
		},
	},
	--------------------------------------------------------------------------------
	-- MIDNIGHT CAMPAIGN (One-time story - "The Light's Summons")
	-- Players can track progress through the pre-patch campaign
	--------------------------------------------------------------------------------
	{
		title = "Midnight Campaign",
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
	-- ONGOING EVENTS (TWW world events - still active during pre-patch)
	--------------------------------------------------------------------------------
	{
		title = "Ongoing Events",
		items = {
			Quest(82483, "Worldsoul Weekly", "Interface\\Icons\\inv_misc_bag_34"),
			Quest(83240, "The Theater Troupe", "Interface\\Icons\\INV_Mask_02"),
			Quest(83333, "Awakening the Machine", "Interface\\Icons\\inv_10_blacksmithing_consumable_repairhammer_color2"),
			Quest(76586, "Spreading the Light", "Interface\\Icons\\spell_holy_holybolt"),
			Quest(85460, "Ecological Succession", "Interface\\Icons\\inv_misc_web_01"),
		},
	},
	--------------------------------------------------------------------------------
	-- WEEKLY QUESTS (Standard TWW weeklies)
	--------------------------------------------------------------------------------
	{
		title = "Weekly Quests",
		items = {
			Quest(91175, "Weekly Cache", "Interface\\Icons\\INV_Box_02"),
			Quest(82706, "Delves: Worldwide Research", "Interface\\Icons\\inv_helmet_148"),
			Quest({ 83363, 83365, 83359, 83362, 83364, 83360, 86731, 88805 }, "Timewalking Event", "Interface\\Icons\\spell_holy_borrowedtime"),
			Quest(82679, "Archives: Seeking History", "Interface\\Icons\\inv_misc_book_09"),
			-- PvP
			Quest(80185, "Preserving Solo", "Interface\\Icons\\achievement_bg_killflagcarriers_grabflag_capit"),
			Quest(80186, "Preserving in War", "Interface\\Icons\\achievement_bg_winwsg"),
			Quest({ 81793, 81794, 81795, 81796, 86853 }, "Sparks of War", "Interface\\Icons\\spell_fire_felfire"),
			-- World/Zone Weekly Quests
			Quest(85459, "Anima Reclamation Program"),
			Quest(85462, "A Challenge for Dominance"),
			Quest(85470, "Root Redux"),
			Quest(86372, "Wasting the Wastelanders"),
			Quest(86391, "Taking Back our Power"),
			Quest(89057, "Pee-Yew de Foxy"),
			Quest(89194, "Shake your Bee-hind"),
			Quest(90545, "A Reel Problem"),
			Quest(91093, "More Than Just a Phase"),
		},
	},
	--------------------------------------------------------------------------------
	-- HOUSING (New permanent section - Starts Jan 20 for Early Access)
	-- PERMANENT: Keep this section in Midnight S1 and beyond
	--------------------------------------------------------------------------------
	{
		title = "Housing",
		items = {
			-- Weekly wrapper (ID TBD - update Jan 20)
			Quest(0, "Neighborhood Endeavors", "Interface\\Icons\\inv_misc_key_14"),
			-- Housing currency
			Currency(3363, "Community Coupons"),
			-- Lumber types (up to 1000 stacks each)
			Item(251764, "Ashwood Lumber"),
			Item(242691, "Olemba Lumber"),
			Item(245586, "Ironwood Lumber"),
			Item(248012, "Dornic Fir Lumber"),
			Item(251766, "Shadowmoon Lumber"),
		},
	},
	--------------------------------------------------------------------------------
	-- UPGRADE CURRENCIES
	--------------------------------------------------------------------------------
	{
		title = "Upgrade Currencies",
		noSort = true,
		items = {
			Cap(3008, "Valorstones"),
			Cap(3284, "Weathered Ethereal Crest"),
			Cap(3286, "Carved Ethereal Crest"),
			Cap(3288, "Runed Ethereal Crest"),
			Cap(3290, "Gilded Ethereal Crest"),
		},
	},
	--------------------------------------------------------------------------------
	-- CURRENCIES
	--------------------------------------------------------------------------------
	{
		title = "Currencies",
		items = {
			-- TWW Currencies (still active during pre-patch)
			Currency(3056, "Kej"),
			Currency(2815, "Resonance Crystals"),
			Currency(3093, "Nerub-ar Finery"),
			Currency(2803, "Undercoin"),
			Currency(3028, "Restored Coffer Key"),
			Currency(3055, "Mereldar Derby Mark"),
			Currency(3090, "Flame-Blessed Iron"),
			Currency(3149, "Displaced Corrupted Mementos"),
			Currency(3089, "Residual Memories"),
			Currency(3303, "Untethered Coin"),
			Currency(3269, "Ethereal Voidsplinter"),
			Currency(3141, "Starlight Spark Dust"),
			Currency(3356, "Untainted Mana Crystals"),
			Currency(1166, "Timewarped Badge"),
			Currency(2778, "Bronze"),
		},
	},
}

-- Register as Expansion 11, Season 3.5 (Midnight Pre-Patch)
-- Triggered by TOC 120000 (12.0.0) but content is still TWW-based
ns.Data:Register(11, 3.5, data)

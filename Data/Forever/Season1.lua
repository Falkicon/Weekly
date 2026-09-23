local _, ns = ...

--------------------------------------------------------------------------------
-- World of Warcraft: Forever - Launch (Expansion 1, Content Update 1, 1.60.x)
--
-- Forever ships content updates rather than seasons; the registry's season slot
-- numbers those updates. Forever has no Great Vault or Mythic+, so this dataset
-- must never use Factory.Vault. Weekly objectives, currency IDs, and raid
-- lockouts (raids open 2026-12-09) need in-game confirmation after the
-- 2026-11-04 launch.
--
-- Merchant's Favor is confirmed in the beta client (Waylaid Supplies turn-ins
-- for Azeroth Commerce Authority / Durotar Supply and Logistics). ID 3402 was
-- confirmed in the beta client on 2026-09-21. Its cap is unknown, so it uses a
-- plain currency row rather than Cap.
--------------------------------------------------------------------------------

local Factory = ns.DataFactory
local Currency, PlaceholderQuest = Factory.Currency, Factory.PlaceholderQuest

local data = {
	{
		title = "Currencies",
		items = {
			Currency(3402, "Merchant's Favor"),
		},
	},
	{
		title = "Forever",
		noSort = true,
		items = {
			PlaceholderQuest("Weekly objectives arrive with the November 4 launch", "Interface\\GossipFrame\\AvailableQuestIcon"),
		},
	},
}

ns.Data:Register(ns.Data.FOREVER_EXPANSION, 1, data, "Data/Forever/Season1.lua")

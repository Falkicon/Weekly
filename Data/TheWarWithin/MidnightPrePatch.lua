local _, ns = ...

--------------------------------------------------------------------------------
-- Helper Functions for Data Entries
--------------------------------------------------------------------------------
-- Vault(id, label)
--   id: Blizzard's weekly vault category ID (1=Dungeons, 3=Raid, 6=World)
--
-- Quest(id, label, icon, coords)
--   id: Can be a single quest ID (number) OR a table of quest IDs for rotating/variant quests
--       Single ID:   Quest(91175, "Weekly Cache")
--       Multi-ID:    Quest({83363, 83365, 83359}, "Timewalking Event")
--   label: Display name shown in the UI
--   icon: Optional texture path (defaults to book icon if omitted)
--   coords: Optional table { mapID = 123, x = 0.5, y = 0.5 } for map marker navigation
--
--   MULTI-ID QUESTS: Use a table of IDs when the same weekly objective has different
--   quest IDs depending on the week/rotation (e.g., Timewalking, Sparks of War).
--   The addon will automatically detect which variant the player has and enable
--   click-to-open-quest-log for the correct one.
--
-- Currency(id, label) / Cap(id, label)
--   id: Currency ID from C_CurrencyInfo
--   Use Cap() for currencies with weekly maximums (shows X/Y format)
--   Use Currency() for uncapped currencies (shows current amount)
--------------------------------------------------------------------------------

local function Vault(id, label) return { type = "vault_visual", id = id, label = label } end
local function Quest(id, label, icon, coords) return { type = "quest", id = id, label = label, icon = icon, coords = coords } end
local function Currency(id, label) return { type = "currency", id = id, label = label } end
local function Cap(id, label) return { type = "currency_cap", id = id, label = label } end

local data = {
    {
        title = "Vault",
        items = {
            Vault(3, "Raid"),
            Vault(1, "Dungeons"),
            Vault(6, "World"),
        }
    },
    {
        title = "Ongoing Events",
        items = {
            Quest(82483, "Worldsoul Weekly", "Interface\\Icons\\inv_misc_bag_34"), -- Worldsoul Satchel
            Quest(83240, "The Theater Troupe", "Interface\\Icons\\INV_Mask_02"), -- Drama Mask
            Quest(83333, "Awakening the Machine", "Interface\\Icons\\inv_10_blacksmithing_consumable_repairhammer_color2"),
            Quest(76586, "Spreading the Light", "Interface\\Icons\\spell_holy_holybolt"),
            Quest(85460, "Ecological Succession", "Interface\\Icons\\inv_misc_web_01"),
        }
    },
    {
        title = "Weekly Quests",
        items = {
            Quest(91175, "Weekly Cache", "Interface\\Icons\\INV_Box_02"), -- Standard Chest
            Quest(82706, "Delves: Worldwide Research", "Interface\\Icons\\inv_helmet_148"), 
            -- Multi-ID: Different quest ID each week based on which Timewalking event is active
            Quest({83363, 83365, 83359, 83362, 83364, 83360, 86731, 88805}, "Timewalking Event", "Interface\\Icons\\spell_holy_borrowedtime"),
            Quest(82679, "Archives: Seeking History", "Interface\\Icons\\inv_misc_book_09"),
            -- PvP
            Quest(80185, "Preserving Solo", "Interface\\Icons\\achievement_bg_killflagcarriers_grabflag_capit"),
            Quest(80186, "Preserving in War", "Interface\\Icons\\achievement_bg_winwsg"),
            -- Multi-ID: Different quest ID based on which PvP brawl is active
            Quest({81793, 81794, 81795, 81796, 86853}, "Sparks of War", "Interface\\Icons\\spell_fire_felfire"),
            -- World/Zone Weekly Quests (discovered via Discovery Tool)
            Quest(85459, "Anima Reclamation Program"),
            Quest(85462, "A Challenge for Dominance"),
            Quest(85470, "Root Redux"),
            Quest(86372, "Wasting the Wastelanders"),
            Quest(86391, "Taking Back our Power"),
            Quest(89057, "Pee-Yew de Foxy"),
            Quest(89194, "Shake your Bee-hind"),
            Quest(90545, "A Reel Problem"),
            Quest(91093, "More Than Just a Phase"),
        }
    },
    {
        title = "Upgrade Currencies",
        noSort = true,
        items = {
            Cap(3008, "Valorstones"),
            Cap(3284, "Weathered Ethereal Crest"),
            Cap(3286, "Carved Ethereal Crest"),
            Cap(3288, "Runed Ethereal Crest"),
            Cap(3290, "Gilded Ethereal Crest"),
        }
    },
    {
        title = "Currencies",
        items = {
            -- TWW Currencies
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
        }
    }
}

-- Register as Expansion 11, Season 3.5 (Midnight Pre-Patch)
ns.Data:Register(11, 3.5, data)

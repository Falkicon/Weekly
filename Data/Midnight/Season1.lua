local _, ns = ...

-- Helper for easier reading
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
        title = "Weekly Quests",
        items = {
            Quest(0, "Weekly Quest Placeholder", "Interface\\Icons\\INV_Box_02"),
            Quest(0, "Another Weekly Placeholder", "Interface\\Icons\\INV_Misc_Book_09"),
        }
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
        }
    },
    {
        title = "Currencies",
        items = {
            -- New Premium Currency
            Currency(0, "Hearthsteel"), 
        }
    }
}

-- Register as "Midnight" (Expansion 12?), Season 1
-- Note: Expansion ID 12 is speculative. TWW is 11.
ns.Data:Register(12, 1, data)

--------------------------------------------------------------------------------
-- Weekly Addon - Type Definitions (LuaCATS)
-- Pure Lua 5.1 compatible type annotations for Core layer
--------------------------------------------------------------------------------

---@class ActionResult<T>
---@field success boolean Whether the action completed successfully
---@field data? T Action-specific result data
---@field error? ActionError Error details if success=false
---@field reasoning? string Human-readable explanation of the result
---@field warnings? Warning[] Non-fatal issues encountered

---@class ActionError
---@field code string Machine-readable error code (e.g., "INVALID_INPUT")
---@field message string Human-readable error message
---@field suggestion? string What to do about it
---@field retryable? boolean Whether the action can be retried

---@class Warning
---@field code string Warning code
---@field message string Warning message

--------------------------------------------------------------------------------
-- Tracker Action Types
--------------------------------------------------------------------------------

---@class CurrencyContext
---@field id number Currency ID
---@field quantity number Current quantity
---@field maxQuantity number Total maximum (0 = uncapped)
---@field maxWeeklyQuantity number Weekly maximum (0 = no weekly cap)
---@field quantityEarnedThisWeek number Amount earned this week
---@field name? string Currency name from API
---@field iconFileID? number Icon texture ID

---@class CurrencyStatusResult
---@field amount number Display amount (earned this week if weekly-capped, else total)
---@field max number Cap value (weekly max if available, else total max)
---@field isCapped boolean Whether the cap has been reached
---@field displayText string Formatted display string (e.g., "500 / 500")
---@field name? string Currency name
---@field iconFileID? number Icon texture ID

---@class QuestContext
---@field ids number[] Quest ID(s) - single ID or multiple for rotating quests
---@field isOnQuest fun(id: number): boolean Function to check if quest is active
---@field isCompleted fun(id: number): boolean Function to check if quest is completed
---@field getObjectives fun(id: number): QuestObjective[]|nil Function to get quest objectives

---@class QuestObjective
---@field text? string Objective text
---@field numFulfilled? number Current progress
---@field numRequired? number Required for completion
---@field finished? boolean Whether this objective is complete

---@class QuestStatusResult
---@field isCompleted boolean Quest is flagged as completed
---@field isOnQuest boolean Player currently has this quest
---@field progress number Current progress value
---@field max number Maximum progress value
---@field isPercent boolean Progress should display as percentage
---@field resolvedId? number The actual quest ID (for multi-ID quests)

---@class VaultContext
---@field categoryID number Vault category (1=Dungeon, 3=Raid, 6=World)
---@field activities VaultActivity[] Activities from C_WeeklyRewards
---@field runHistory? MythicPlusRun[] M+ runs (for dungeons)
---@field savedInstances? RaidLockout[] Raid lockouts (for raids)

---@class VaultActivity
---@field index number Slot index
---@field threshold number Required count
---@field progress number Current progress
---@field level? number Item level of reward

---@class MythicPlusRun
---@field mapChallengeModeID number Dungeon ID
---@field level number Key level
---@field completed boolean Whether timed

---@class RaidLockout
---@field bossName string Boss name
---@field diffName string Difficulty name
---@field isKilled boolean Whether boss is defeated

---@class VaultStatusResult
---@field completed number Number of slots unlocked
---@field max number Total number of slots
---@field slots VaultSlot[] Individual slot details

---@class VaultSlot
---@field threshold number Required count
---@field progress number Current progress
---@field level number Item level (0 if not unlocked)
---@field completed boolean Whether slot is unlocked

---@class VaultDetailsResult : VaultStatusResult
---@field history VaultHistoryEntry[] M+ runs or raid kills

---@class VaultHistoryEntry
---@field name string Dungeon/boss name
---@field level string|number Key level or difficulty name
---@field completed boolean Whether completed/killed

--------------------------------------------------------------------------------
-- Journal Action Types
--------------------------------------------------------------------------------

---@class JournalResetContext
---@field currentServerTime number Current server time
---@field savedWeekStart? number Saved week start timestamp
---@field resetDayOfWeek number Day of week for reset (3 = Tuesday)
---@field resetHour number Hour of reset (typically 7 or 8 AM)

---@class JournalResetResult
---@field shouldReset boolean Whether journal should be reset
---@field newWeekStart number New week start timestamp
---@field reasoning string Explanation of decision

---@class LootClassifyContext
---@field itemID number Item ID
---@field itemClassID number Item class ID
---@field itemSubClassID number Item subclass ID
---@field expansionID? number Expansion the item is from

---@class LootClassifyResult
---@field isGathering boolean Whether this is a gathering material
---@field category? string Category name (e.g., "Herbs", "Ore")
---@field expansion? string Expansion name

--------------------------------------------------------------------------------
-- Sort Action Types
--------------------------------------------------------------------------------

---@class SortContext
---@field items TrackerItem[] Items to sort
---@field sortCompletedBottom boolean Whether to sort completed items to bottom
---@field getQuestStatus fun(id: number|number[]): QuestStatusResult Quest status lookup
---@field getCurrencyStatus fun(id: number): CurrencyStatusResult Currency status lookup

---@class TrackerItem
---@field type string Item type (header, quest, currency, currency_cap, vault_visual)
---@field id? number|number[] Item ID (or array for multi-ID quests)
---@field label? string Display label
---@field icon? string Icon path
---@field coords? {mapID: number, x: number, y: number} Quest coordinates

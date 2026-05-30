--[[
=============================================================================
  LevelStats.lua  -  Random stat bonuses on level up
=============================================================================
  Adapted for AzerothCore + mod-ale (AzerothCore Lua Engine).
  Original: https://github.com/Brytenwally/LevelStats  (Eluna)

  HOW IT WORKS:
    - Every time a player levels up, a random stat is chosen
      (Strength, Agility, Stamina, Intellect or Spirit) and a random
      bonus between MinAmount and MaxAmount is granted.
    - The bonus is stored cumulatively in the SQL table
      "custom_level_stats" in the characters database.
    - On login and after each level-up, the total bonus is reapplied
      as a stackable aura (uses "Blessing of ..." spells).
    - Command .bonus  ->  shows your total bonuses or the selected
      player's bonuses.

  DATABASE REQUIREMENTS (run on acore_characters):
  -----------------------------------------------------------------------
    CREATE TABLE IF NOT EXISTS `custom_level_stats` (
      `guid` INT UNSIGNED NOT NULL,
      `str`  INT UNSIGNED NOT NULL DEFAULT 0,
      `agi`  INT UNSIGNED NOT NULL DEFAULT 0,
      `sta`  INT UNSIGNED NOT NULL DEFAULT 0,
      `int`  INT UNSIGNED NOT NULL DEFAULT 0,
      `spi`  INT UNSIGNED NOT NULL DEFAULT 0,
      PRIMARY KEY (`guid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  -----------------------------------------------------------------------

  mod-ale COMPATIBILITY NOTES:
    - Player hooks used:
        3  = PLAYER_EVENT_ON_LOGIN          (event, player)
        13 = PLAYER_EVENT_ON_LEVEL_CHANGE   (event, player, oldLevel)
        42 = PLAYER_EVENT_ON_COMMAND        (event, player, command, chatHandler)
    - Player-bound timer:
        player:RegisterEvent(fn, delay_ms [, repeats])
        callback receives (eventId, delay, repeats, worldobject)
    - SetData / GetData come from the mod-ale extension "DataExt" (.ext).
      If that extension is not loaded, the anti-double-roll guard still
      works safely using the local fallback table.
=============================================================================
]]

-- ============================================================================
-- CONFIGURATION
-- ============================================================================
local Config = {
    MinAmount    = 1,
    MaxAmount    = 5,
    SyncDelayMs  = 500,    -- delay after level-up before reapplying auras (ms)
    LoginDelayMs = 1200,   -- delay after login before reapplying auras (ms)
    DebugEnabled = false,  -- set to true to enable print() debug messages
    Stats = {
        [0] = { name = "Strength",  db = "str", spellId = 7464, color = "ff0000" },
        [1] = { name = "Agility",   db = "agi", spellId = 7471, color = "00ff00" },
        [2] = { name = "Stamina",   db = "sta", spellId = 7477, color = "ffffff" },
        [3] = { name = "Intellect", db = "int", spellId = 7468, color = "00ccff" },
        [4] = { name = "Spirit",    db = "spi", spellId = 7474, color = "ffcc00" },
    }
}

-- Auto-crea la tabla en acore_characters si no existe (solo inserta si falta)
local function EnsureTable()
    CharDBExecute([[
        CREATE TABLE IF NOT EXISTS `custom_level_stats` (
            `guid` INT UNSIGNED NOT NULL,
            `str`  INT UNSIGNED NOT NULL DEFAULT 0,
            `agi`  INT UNSIGNED NOT NULL DEFAULT 0,
            `sta`  INT UNSIGNED NOT NULL DEFAULT 0,
            `int`  INT UNSIGNED NOT NULL DEFAULT 0,
            `spi`  INT UNSIGNED NOT NULL DEFAULT 0,
            PRIMARY KEY (`guid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end
EnsureTable()

-- Named hook IDs for readability
local PLAYER_EVENT_ON_LOGIN        = 3
local PLAYER_EVENT_ON_LEVEL_CHANGE = 13
local PLAYER_EVENT_ON_COMMAND      = 42

-- Local fallback table for the anti-double-roll guard.
-- Used when the DataExt extension is not loaded (GetData/SetData unavailable).
-- Key: player GUIDLow, value: last processed level.
local LastBonusLevel = {}

-- ============================================================================
-- UTILITIES
-- ============================================================================
local function dbg(...)
    if Config.DebugEnabled then
        print("[LevelStats]", ...)
    end
end

-- Returns the last processed level for this player
-- (uses DataExt if available, otherwise falls back to local table)
local function GetLastProcessed(player)
    if player.GetData then
        local v = player:GetData("LastLevelBonus")
        if v ~= nil then return v end
    end
    return LastBonusLevel[player:GetGUIDLow()]
end

-- Stores the last processed level for this player
local function SetLastProcessed(player, level)
    if player.SetData then
        player:SetData("LastLevelBonus", level)
    end
    LastBonusLevel[player:GetGUIDLow()] = level
end

-- ============================================================================
-- CORE LOGIC
-- ============================================================================

-- Reads accumulated bonuses from the DB and reapplies them as stackable auras.
local function SyncStatsFromDB(player)
    if not player or not player:IsInWorld() then return end

    local guid = tonumber(player:GetGUIDLow()) or 0
    local q = CharDBQuery(string.format(
        "SELECT str, agi, sta, `int`, spi FROM custom_level_stats WHERE guid = %d",
        guid
    ))

    if not q then
        dbg("SyncStatsFromDB: no record found for guid", guid)
        return
    end

    for i = 0, 4 do
        local count = q:GetUInt32(i)
        local stat  = Config.Stats[i]
        if count and count > 0 and stat then
            -- Remove existing aura first to refresh the visual and tooltip
            player:RemoveAura(stat.spellId)
            -- Apply buff (caster = the player themselves)
            player:AddAura(stat.spellId, player)
            local aura = player:GetAura(stat.spellId)
            if aura then
                aura:SetStackAmount(count)
            end
        end
    end
end

-- Hook: ON_LEVEL_CHANGE
local function OnLevelChange(event, player, oldLevel)
    if not player then return end

    -- Anti-double-roll guard: some core events fire this hook twice for the
    -- same level. We ensure each level is processed only once.
    local currentLevel  = player:GetLevel()
    local lastProcessed = GetLastProcessed(player)
    if lastProcessed == currentLevel then
        dbg("OnLevelChange: level", currentLevel, "already processed, skipping")
        return
    end
    SetLastProcessed(player, currentLevel)

    -- Random roll
    local statID   = math.random(0, 4)
    local amount   = math.random(Config.MinAmount, Config.MaxAmount)
    local statData = Config.Stats[statID]
    local guid     = tonumber(player:GetGUIDLow()) or 0

    -- 1. Persist to DB (cumulative INSERT/UPSERT)
    CharDBExecute(string.format(
        "INSERT INTO custom_level_stats (guid, `%s`) VALUES (%d, %d) " ..
        "ON DUPLICATE KEY UPDATE `%s` = `%s` + %d",
        statData.db, guid, amount, statData.db, statData.db, amount
    ))

    dbg(player:GetName(), "reached level", currentLevel, "->", statData.name, "+" .. amount)

    -- 2. Reapply auras after a short delay so the level-up sequence finishes
    --    before we touch the player's aura slots.
    player:RegisterEvent(function(eventId, delay, repeats, worldobject)
        local p = worldobject and worldobject:ToPlayer() or player
        if not p or not p:IsInWorld() then return end
        SyncStatsFromDB(p)
        p:SendAreaTriggerMessage("Level Up Bonus: +" .. amount .. " " .. statData.name .. "!")
        p:SendBroadcastMessage(string.format(
            "|cff00ff00[Level Bonus]:|r Gained |cff%s+%d %s|r.",
            statData.color, amount, statData.name
        ))
    end, Config.SyncDelayMs, 1)
end

-- Hook: ON_LOGIN
local function OnLogin(event, player)
    if not player then return end

    -- Mark current level as already processed so a login mid-level
    -- does not trigger a bonus roll.
    SetLastProcessed(player, player:GetLevel())

    -- Reapply stored bonuses after a short delay to ensure the client
    -- has finished loading the buff bar.
    player:RegisterEvent(function(eventId, delay, repeats, worldobject)
        local p = worldobject and worldobject:ToPlayer() or player
        if not p or not p:IsInWorld() then return end
        SyncStatsFromDB(p)
    end, Config.LoginDelayMs, 1)
end

-- Hook: ON_COMMAND  ->  .bonus
local function OnCommand(event, player, command, chatHandler)
    if not player then return end  -- command run from the server console
    if not command then return end

    -- Accept ".bonus" with optional trailing spaces or arguments
    local cmd = command:lower():match("^%s*(%S+)")
    if cmd ~= "bonus" then return end

    -- Resolve target: selected player if valid, otherwise self
    local target       = player:GetSelection()
    local targetPlayer = player
    if target and target.ToPlayer then
        local tp = target:ToPlayer()
        if tp then targetPlayer = tp end
    end

    local guid   = tonumber(targetPlayer:GetGUIDLow()) or 0
    local name   = targetPlayer:GetName() or "Unknown"
    local isSelf = (player:GetGUIDLow() == targetPlayer:GetGUIDLow())

    -- Header
    if isSelf then
        player:SendBroadcastMessage("|cffFFFF00--- Your Level Up Bonuses ---|r")
    else
        player:SendBroadcastMessage(string.format(
            "|cffFFFF00--- %s's Level Up Bonuses ---|r", name
        ))
    end

    -- Query DB
    local q = CharDBQuery(string.format(
        "SELECT str, agi, sta, `int`, spi FROM custom_level_stats WHERE guid = %d",
        guid
    ))

    if q then
        for i = 0, 4 do
            local total = q:GetUInt32(i) or 0
            local stat  = Config.Stats[i]
            player:SendBroadcastMessage(string.format(
                "|cff%s%s:|r +%d", stat.color, stat.name, total
            ))
        end
    else
        if isSelf then
            player:SendBroadcastMessage("You haven't gained any bonuses yet.")
        else
            player:SendBroadcastMessage(string.format(
                "%s hasn't gained any bonuses yet.", name
            ))
        end
    end

    return false  -- suppress "unknown command" message
end

-- ============================================================================
-- REGISTER HOOKS
-- ============================================================================
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,        OnLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_LEVEL_CHANGE, OnLevelChange)
RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND,      OnCommand)

print("[LevelStats] Loaded successfully.")

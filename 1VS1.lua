-- 1v1 PvP Queue System for AzerothCore with mod-ale (ALE)
-- Original author: PrivateDonut
-- Ported to mod-ale (AzerothCore Lua Engine) — API fixes applied

-- ==========================================
-- CONFIGURATION SECTION - Edit values below
-- ==========================================

local CONFIG = {
    -- NPC Settings
    NPC_ID    = 1000000,                       -- NPC entry ID for the Arena Master
    NPC_NAME  = "Arena Master",                -- Name stored in creature_template
    NPC_LEVEL = 80,                            -- Level stored in creature_template

    -- Gossip Menu Options
    MENU_JOIN_TEXT = "Join 1v1 Queue",         -- Text shown for joining queue
    MENU_LEAVE_TEXT = "Leave 1v1 Queue",       -- Text shown for leaving queue
    GOSSIP_ICON = 0,                           -- Icon type (0 = chat bubble, 1 = vendor, 2 = taxi, etc.)

    -- System Messages
    MSG_JOINED = "You have joined the 1v1 queue.",
    MSG_LEFT = "You have left the 1v1 queue.",
    MSG_ALREADY_IN_QUEUE = "You are already in the 1v1 queue.",
    MSG_NOT_IN_QUEUE = "You are not in the 1v1 queue.",
    MSG_MATCH_FOUND = "Match found! Prepare to fight.",

    -- Message Formatting
    MSG_PREFIX = "[1v1 Arena] ",               -- Prefix for all messages
    USE_PREFIX = true,                         -- Enable/disable message prefix
    USE_COLOR = true,                          -- Enable/disable colored messages
    COLOR_CODE = "|cFFFF6060",                 -- Color code (currently light red)

    -- Arena Settings (Gurubashi Arena, Eastern Kingdoms, map 0)
    ARENA_MAP_ID = 0,
    ARENA_PLAYER1_X = -13173.569,
    ARENA_PLAYER1_Y = 249.4476,
    ARENA_PLAYER1_Z = 21.857931,
    ARENA_PLAYER1_O = 2.6241155,

    ARENA_PLAYER2_X = -13241.986,
    ARENA_PLAYER2_Y = 287.11407,
    ARENA_PLAYER2_Z = 21.857931,
    ARENA_PLAYER2_O = 5.789287,

    -- Matchmaking Settings
    MATCHMAKING_INTERVAL = 5000,               -- Check for matches every 5 seconds (milliseconds)

    -- Countdown Settings
    COUNTDOWN_DURATION = 5,                    -- Countdown duration in seconds
    ROOT_AURA_ID = 45524,                      -- Chains of Ice (root aura used at round start)
    MSG_COUNTDOWN_PREFIX = "Match starts in: ",
    MSG_FIGHT = "|cFFFFFF00FIGHT!|r",

    -- Round End Messages
    MSG_ROUND_WINNER = "|cFF00FF00%s wins the round!|r",

    -- Match Settings
    WINNING_SCORE = 2,                         -- Rounds needed to win (best of 3)

    -- Match End Messages
    MSG_MATCH_WINNER = "|cFFFFD700%s has won the match %d-%d!|r",
    MSG_NEXT_ROUND = "|cFF00FFFF Round %d starting soon...|r",
    MSG_CURRENT_SCORE = "|cFFFFFFFF Score: %s [%d] - [%d] %s|r",

    -- Round Transition Settings
    ROUND_TRANSITION_DELAY = 2000,             -- Delay before starting next round (milliseconds)

    -- Logout/Disconnect Messages
    MSG_REMOVED_FROM_QUEUE = "You have been removed from the 1v1 queue due to logout.",
    MSG_OPPONENT_FORFEITED = "|cFFFFD700Your opponent has disconnected. You win by forfeit!|r",
    MSG_FORFEIT_LOSS = "|cFFFF0000You forfeited the match by disconnecting.|r",

    -- Status Command Messages
    MSG_STATUS_IN_QUEUE = "You are in the 1v1 queue. Position: %d of %d",
    MSG_STATUS_IN_MATCH = "You are currently in a 1v1 match. Score: %s [%d] - [%d] %s",
    MSG_STATUS_NOT_IN_SYSTEM = "You are not in the queue or any active match.",
    MSG_COMMAND_USAGE = "Usage: .1v1 status - Check your queue position or match status",

    -- Arena Area Settings
    ARENA_AREA_ID = 2177,                      -- Gurubashi Arena floor area ID
    MSG_LEFT_ARENA_FORFEIT = "|cFFFF0000%s has left the arena and forfeited the match!|r",
    MSG_LEFT_ARENA_WARNING = "|cFFFF8800You have left the arena! You forfeit!|r"
}

-- ==========================================
-- STATE
-- Queue and active matches use GetGUID() (ObjectGuid string) as the player identifier.
-- GetGUID() returns a string that GetPlayerByGUID() accepts directly.
-- GetGUIDLow() returns a plain uint32 that cannot be passed to GetPlayerByGUID().
-- ==========================================

local pvpQueue      = {}   -- array of GUID strings
local activeMatches = {}   -- array of match tables

-- ==========================================
-- NPC INITIALISATION
-- Inserts a minimal creature_template row if the NPC does not exist yet.
-- Runs once on WORLD_EVENT_ON_STARTUP; safe to re-run on .reload ale.
-- After first run, spawn the NPC in-world with: .npc add 1000000
-- Column names match the real creature_template schema exactly.
-- Reserved words escaped with backticks: `rank`, `type`, `family`.
-- ==========================================

local function InitNPC()
    -- -------------------------------------------------------
    -- STEP 1: Insert creature_template row if missing
    -- -------------------------------------------------------
    if not WorldDBQuery("SELECT 1 FROM creature_template WHERE entry=" .. CONFIG.NPC_ID .. " LIMIT 1") then
        -- Columnas garantizadas en todo AzerothCore WotLK
        local cols = {"entry", "name", "subname", "minlevel", "maxlevel", "faction", "npcflag"}
        local vals = {
            tostring(CONFIG.NPC_ID),
            "'" .. CONFIG.NPC_NAME .. "'",
            "'Queue Master'",
            tostring(CONFIG.NPC_LEVEL),
            tostring(CONFIG.NPC_LEVEL),
            "35",
            "1"
        }

        -- Columnas opcionales: verificar si existen antes de incluirlas
        local optional = {
            {col = "`rank`",          val = "0"},
            {col = "`type`",          val = "7"},
            {col = "`family`",        val = "0"},
            {col = "unit_class",      val = "1"},
            {col = "unit_flags",      val = "2"},
            {col = "speed_walk",      val = "1.0"},
            {col = "speed_run",       val = "1.14286"},
            {col = "BaseAttackTime",  val = "2000"},
            {col = "RangeAttackTime", val = "2000"},
            {col = "scale",           val = "1.0"},
        }

        for _, opt in ipairs(optional) do
            -- strip backticks for the column name check
            local colName = opt.col:gsub("`", "")
            local exists = WorldDBQuery(
                "SELECT 1 FROM information_schema.COLUMNS " ..
                "WHERE TABLE_SCHEMA = DATABASE() " ..
                "AND TABLE_NAME = 'creature_template' " ..
                "AND COLUMN_NAME = '" .. colName .. "' LIMIT 1"
            )
            if exists then
                cols[#cols + 1] = opt.col
                vals[#vals + 1] = opt.val
            end
        end

        local sql = "INSERT INTO creature_template (" .. table.concat(cols, ", ") .. ") VALUES (" .. table.concat(vals, ", ") .. ")"
        WorldDBExecute(sql)
        WorldDBExecute("UPDATE creature_template SET npcflag=1 WHERE entry=" .. CONFIG.NPC_ID)
    end

    -- -------------------------------------------------------
    -- STEP 2: Insert creature (spawn) rows if missing.
    -- Two permanent spawns are created next to the Portal Master NPC:
    --   Spawn 1 — Stormwind Trade District (map 0)
    --             guid=6001001  x=-8842.09  y=624.828  z=94.2999  o=0.44062
    --             (Portal Master is at x=-8845.09 y=624.828; offset +3 in X)
    --   Spawn 2 — Valley of Strength, Orgrimmar (map 1)
    --             guid=6001002  x=1602.25  y=-4375.85  z=10.0872  o=5.23641
    --             (Portal Master is at x=1599.25 y=-4375.85; offset +3 in X)
    -- Each spawn is checked individually by (id1, map) to
    -- avoid duplicates on repeated .reload ale calls.
    -- Columns id1/id2/id3 vs legacy `id` are detected at
    -- runtime via information_schema (same pattern as STEP 3).
    -- -------------------------------------------------------
    local usesId1 = WorldDBQuery(
        "SELECT 1 FROM information_schema.COLUMNS " ..
        "WHERE TABLE_SCHEMA = DATABASE() " ..
        "AND TABLE_NAME = 'creature' " ..
        "AND COLUMN_NAME = 'id1' LIMIT 1"
    )

    -- Stormwind spawn (map 0) — guid 6001001, next to Portal Master
    local swQuery = usesId1
        and ("SELECT 1 FROM creature WHERE id1=" .. CONFIG.NPC_ID .. " AND map=0 LIMIT 1")
        or  ("SELECT 1 FROM creature WHERE id="  .. CONFIG.NPC_ID .. " AND map=0 LIMIT 1")

    if not WorldDBQuery(swQuery) then
        local spawnSql
        if usesId1 then
            spawnSql = string.format(
                "INSERT INTO creature (guid, id1, id2, id3, map, position_x, position_y, position_z, orientation, spawntimesecs, wander_distance, MovementType, phaseMask, spawnMask) " ..
                "VALUES (6001001, %d, 0, 0, 0, -8842.09, 624.828, 94.2999, 0.44062, 300, 0, 0, 1, 1)",
                CONFIG.NPC_ID
            )
        else
            spawnSql = string.format(
                "INSERT INTO creature (guid, id, map, position_x, position_y, position_z, orientation, spawntimesecs, wander_distance, MovementType, phaseMask, spawnMask) " ..
                "VALUES (6001001, %d, 0, -8842.09, 624.828, 94.2999, 0.44062, 300, 0, 0, 1, 1)",
                CONFIG.NPC_ID
            )
        end
        WorldDBExecute(spawnSql)
        print("[1VS1] Spawn insertado en Stormwind (map 0) para entry " .. CONFIG.NPC_ID .. ".")
    else
        print("[1VS1] Spawn Stormwind (map 0) ya existe para entry " .. CONFIG.NPC_ID .. ".")
    end

    -- Orgrimmar spawn (map 1, Valley of Strength) — guid 6001002, next to Portal Master
    local ogQuery = usesId1
        and ("SELECT 1 FROM creature WHERE id1=" .. CONFIG.NPC_ID .. " AND map=1 LIMIT 1")
        or  ("SELECT 1 FROM creature WHERE id="  .. CONFIG.NPC_ID .. " AND map=1 LIMIT 1")

    if not WorldDBQuery(ogQuery) then
        local spawnSql
        if usesId1 then
            spawnSql = string.format(
                "INSERT INTO creature (guid, id1, id2, id3, map, position_x, position_y, position_z, orientation, spawntimesecs, wander_distance, MovementType, phaseMask, spawnMask) " ..
                "VALUES (6001002, %d, 0, 0, 1, 1602.25, -4375.85, 10.0872, 5.23641, 300, 0, 0, 1, 1)",
                CONFIG.NPC_ID
            )
        else
            spawnSql = string.format(
                "INSERT INTO creature (guid, id, map, position_x, position_y, position_z, orientation, spawntimesecs, wander_distance, MovementType, phaseMask, spawnMask) " ..
                "VALUES (6001002, %d, 1, 1602.25, -4375.85, 10.0872, 5.23641, 300, 0, 0, 1, 1)",
                CONFIG.NPC_ID
            )
        end
        WorldDBExecute(spawnSql)
        print("[1VS1] Spawn insertado en Orgrimmar (map 1) para entry " .. CONFIG.NPC_ID .. ".")
    else
        print("[1VS1] Spawn Orgrimmar (map 1) ya existe para entry " .. CONFIG.NPC_ID .. ".")
    end

    -- -------------------------------------------------------
    -- STEP 3: Insert creature_template_model rows if missing.
    -- The core refuses to load any creature without a row in
    -- this table (error: "has no model defined in
    -- creature_template_model").
    --
    -- Idx=0  DisplayID 3167  — Stormwind Guard (confirmed by user).
    -- Idx=1  DisplayID <horde> — Orgrimmar Guard if found in DB,
    --        otherwise only Idx=0 is inserted.
    --
    -- DisplayScale and Probability columns are verified via
    -- information_schema for safety (present in all known
    -- AzerothCore repacks).
    -- -------------------------------------------------------
    if not WorldDBQuery("SELECT 1 FROM creature_template_model WHERE CreatureID=" .. CONFIG.NPC_ID .. " LIMIT 1") then
        -- Determine the exact name of the entry column (CreatureID is standard
        -- in modern AzerothCore; older repacks may use a different name).
        local hasCreatureID = WorldDBQuery(
            "SELECT 1 FROM information_schema.COLUMNS " ..
            "WHERE TABLE_SCHEMA = DATABASE() " ..
            "AND TABLE_NAME = 'creature_template_model' " ..
            "AND COLUMN_NAME = 'CreatureID' LIMIT 1"
        )
        local entryCol = hasCreatureID and "CreatureID" or "entry"

        -- Fixed Alliance display ID confirmed by user: Stormwind Guard = 3167
        local allianceDisplayID = 3167

        -- Try to obtain an Orgrimmar Guard display ID for the Horde model slot.
        local hordeDisplayID = 0
        local hordeRes = WorldDBQuery(
            "SELECT ctm.CreatureDisplayID FROM creature_template_model ctm " ..
            "JOIN creature_template ct ON ct.entry = ctm." .. entryCol .. " " ..
            "WHERE ct.name LIKE '%Orgrimmar Guard%' " ..
            "AND ctm.Idx = 0 AND ctm.CreatureDisplayID > 0 LIMIT 1"
        )
        if hordeRes then
            hordeDisplayID = hordeRes:GetUInt32(0)
            print("[1VS1] DisplayID Horda obtenido de Orgrimmar Guard: " .. hordeDisplayID)
        else
            print("[1VS1] No se encontro Orgrimmar Guard en DB; solo se insertara el modelo Alianza.")
        end

        -- Determine whether DisplayScale and Probability columns exist.
        local hasDisplayScale = WorldDBQuery(
            "SELECT 1 FROM information_schema.COLUMNS " ..
            "WHERE TABLE_SCHEMA = DATABASE() " ..
            "AND TABLE_NAME = 'creature_template_model' " ..
            "AND COLUMN_NAME = 'DisplayScale' LIMIT 1"
        )
        local hasProbability = WorldDBQuery(
            "SELECT 1 FROM information_schema.COLUMNS " ..
            "WHERE TABLE_SCHEMA = DATABASE() " ..
            "AND TABLE_NAME = 'creature_template_model' " ..
            "AND COLUMN_NAME = 'Probability' LIMIT 1"
        )

        -- Insert Idx=0 (Alliance / Stormwind Guard)
        local modelSql0
        if hasDisplayScale and hasProbability then
            modelSql0 = string.format(
                "INSERT INTO creature_template_model (%s, Idx, CreatureDisplayID, DisplayScale, Probability) " ..
                "VALUES (%d, 0, %d, 1.0, 1.0)",
                entryCol, CONFIG.NPC_ID, allianceDisplayID
            )
        else
            modelSql0 = string.format(
                "INSERT INTO creature_template_model (%s, Idx, CreatureDisplayID) " ..
                "VALUES (%d, 0, %d)",
                entryCol, CONFIG.NPC_ID, allianceDisplayID
            )
        end
        WorldDBExecute(modelSql0)
        print("[1VS1] Modelo Idx=0 insertado (DisplayID=" .. allianceDisplayID .. " Stormwind Guard) para entry " .. CONFIG.NPC_ID)

        -- Insert Idx=1 (Horde / Orgrimmar Guard) only if a display ID was found.
        if hordeDisplayID > 0 then
            local modelSql1
            if hasDisplayScale and hasProbability then
                modelSql1 = string.format(
                    "INSERT INTO creature_template_model (%s, Idx, CreatureDisplayID, DisplayScale, Probability) " ..
                    "VALUES (%d, 1, %d, 1.0, 1.0)",
                    entryCol, CONFIG.NPC_ID, hordeDisplayID
                )
            else
                modelSql1 = string.format(
                    "INSERT INTO creature_template_model (%s, Idx, CreatureDisplayID) " ..
                    "VALUES (%d, 1, %d)",
                    entryCol, CONFIG.NPC_ID, hordeDisplayID
                )
            end
            WorldDBExecute(modelSql1)
            print("[1VS1] Modelo Idx=1 insertado (DisplayID=" .. hordeDisplayID .. " Orgrimmar Guard) para entry " .. CONFIG.NPC_ID)
        end
    else
        print("[1VS1] creature_template_model ya tiene modelo para entry " .. CONFIG.NPC_ID)
    end
end

-- ==========================================
-- HELPERS
-- ==========================================

-- Format and send a broadcast message to a player.
local function sendMessage(player, message)
    if not player then return end
    local msg = message
    if CONFIG.USE_PREFIX then msg = CONFIG.MSG_PREFIX .. msg end
    if CONFIG.USE_COLOR  then msg = CONFIG.COLOR_CODE .. msg .. "|r" end
    player:SendBroadcastMessage(msg)
end

-- Return true if a GUID string is already in the queue.
local function isPlayerInQueue(guid)
    for i = 1, #pvpQueue do
        if pvpQueue[i] == guid then return true end
    end
    return false
end

-- Return the 1-based queue position of a GUID string, or nil if absent.
local function getQueuePosition(guid)
    for i = 1, #pvpQueue do
        if pvpQueue[i] == guid then return i end
    end
    return nil
end

-- Remove a GUID string from the queue. Returns true if an entry was removed.
local function removePlayerFromQueue(guid)
    for i = #pvpQueue, 1, -1 do
        if pvpQueue[i] == guid then
            table.remove(pvpQueue, i)
            return true
        end
    end
    return false
end

-- Capture a player's current map/position as a plain table.
local function savePlayerLocation(player)
    local x, y, z, o = player:GetLocation()
    return { mapId = player:GetMapId(), x = x, y = y, z = z, o = o }
end

-- Teleport a player to one of the two arena spawn points and apply the root aura.
local function teleportToArena(player, spawnPoint)
    if spawnPoint == 1 then
        player:Teleport(CONFIG.ARENA_MAP_ID,
            CONFIG.ARENA_PLAYER1_X, CONFIG.ARENA_PLAYER1_Y,
            CONFIG.ARENA_PLAYER1_Z, CONFIG.ARENA_PLAYER1_O)
    else
        player:Teleport(CONFIG.ARENA_MAP_ID,
            CONFIG.ARENA_PLAYER2_X, CONFIG.ARENA_PLAYER2_Y,
            CONFIG.ARENA_PLAYER2_Z, CONFIG.ARENA_PLAYER2_O)
    end
    player:AddAura(CONFIG.ROOT_AURA_ID, player)
end

-- ==========================================
-- COUNTDOWN
-- Re-fetches live player objects every tick via GetPlayerByGUID(guid string).
-- ==========================================

local function startCountdown(p1Guid, p2Guid, secondsLeft)
    local p1 = GetPlayerByGUID(p1Guid)
    local p2 = GetPlayerByGUID(p2Guid)
    if not p1 or not p2 then return end

    if secondsLeft > 0 then
        local msg = CONFIG.MSG_COUNTDOWN_PREFIX .. secondsLeft .. "..."
        sendMessage(p1, msg)
        sendMessage(p2, msg)
        CreateLuaEvent(function()
            startCountdown(p1Guid, p2Guid, secondsLeft - 1)
        end, 1000, 1)
    else
        sendMessage(p1, CONFIG.MSG_FIGHT)
        sendMessage(p2, CONFIG.MSG_FIGHT)
        p1:RemoveAura(CONFIG.ROOT_AURA_ID)
        p2:RemoveAura(CONFIG.ROOT_AURA_ID)
    end
end

-- ==========================================
-- MATCH LOOKUP
-- Returns (match, index) or (nil, nil) — always two return values.
-- ==========================================

local function findActiveMatchByPlayer(guid)
    for i, match in ipairs(activeMatches) do
        if match.player1.guid == guid or match.player2.guid == guid then
            return match, i
        end
    end
    return nil, nil
end

-- ==========================================
-- FORFEIT  (disconnect / left arena)
-- reason: "disconnect" | "left_arena"
-- ==========================================

local function forfeitMatch(match, matchIndex, forfeitingGuid, reason)
    local winnerGuid, winnerLoc
    local loserGuid

    if match.player1.guid == forfeitingGuid then
        winnerGuid = match.player2.guid
        loserGuid  = match.player1.guid
        winnerLoc  = match.player2.originalLocation
    else
        winnerGuid = match.player1.guid
        loserGuid  = match.player2.guid
        winnerLoc  = match.player1.originalLocation
    end

    local winner = GetPlayerByGUID(winnerGuid)
    local loser  = GetPlayerByGUID(loserGuid)

    if winner then
        local msg
        if reason == "left_arena" then
            local loserName = loser and loser:GetName() or "Your opponent"
            msg = string.format(CONFIG.MSG_LEFT_ARENA_FORFEIT, loserName)
        else
            msg = CONFIG.MSG_OPPONENT_FORFEITED
        end
        sendMessage(winner, msg)

        if winner:IsDead() then winner:ResurrectPlayer(1.0, false) end
        winner:SetHealth(winner:GetMaxHealth())
        -- Unit:SetPower(amount, type) — amount first, power type second (0 = Mana)
        winner:SetPower(winner:GetMaxPower(0), 0)
        winner:RemoveAura(CONFIG.ROOT_AURA_ID)
        winner:Teleport(winnerLoc.mapId, winnerLoc.x, winnerLoc.y, winnerLoc.z, winnerLoc.o)
    end

    table.remove(activeMatches, matchIndex)
end

-- ==========================================
-- END MATCH  (a player reached WINNING_SCORE)
-- ==========================================

local function endMatch(match, matchIndex)
    local p1 = GetPlayerByGUID(match.player1.guid)
    local p2 = GetPlayerByGUID(match.player2.guid)

    local winner, loser, winnerScore, loserScore
    if match.player1.score >= CONFIG.WINNING_SCORE then
        winner = p1;  loser = p2
        winnerScore = match.player1.score; loserScore = match.player2.score
    else
        winner = p2;  loser = p1
        winnerScore = match.player2.score; loserScore = match.player1.score
    end

    if winner and loser then
        local msg = string.format(CONFIG.MSG_MATCH_WINNER, winner:GetName(), winnerScore, loserScore)
        sendMessage(winner, msg)
        sendMessage(loser,  msg)

        if winner:IsDead() then winner:ResurrectPlayer(1.0, false) end
        if loser:IsDead()  then loser:ResurrectPlayer(1.0, false)  end

        winner:SetHealth(winner:GetMaxHealth())
        winner:SetPower(winner:GetMaxPower(0), 0)
        loser:SetHealth(loser:GetMaxHealth())
        loser:SetPower(loser:GetMaxPower(0), 0)

        winner:RemoveAura(CONFIG.ROOT_AURA_ID)
        loser:RemoveAura(CONFIG.ROOT_AURA_ID)

        local loc1 = match.player1.originalLocation
        local loc2 = match.player2.originalLocation
        if p1 then p1:Teleport(loc1.mapId, loc1.x, loc1.y, loc1.z, loc1.o) end
        if p2 then p2:Teleport(loc2.mapId, loc2.x, loc2.y, loc2.z, loc2.o) end
    end

    table.remove(activeMatches, matchIndex)
end

-- ==========================================
-- NEXT ROUND  (neither player reached WINNING_SCORE yet)
-- ==========================================

local function prepareNextRound(match)
    local p1 = GetPlayerByGUID(match.player1.guid)
    local p2 = GetPlayerByGUID(match.player2.guid)
    if not p1 or not p2 then return end

    match.currentRound = match.currentRound + 1

    local p1Name = p1:GetName()
    local p2Name = p2:GetName()
    local scoreMsg = string.format(CONFIG.MSG_CURRENT_SCORE,
        p1Name, match.player1.score, match.player2.score, p2Name)
    local roundMsg = string.format(CONFIG.MSG_NEXT_ROUND, match.currentRound)

    sendMessage(p1, scoreMsg)
    sendMessage(p2, scoreMsg)
    sendMessage(p1, roundMsg)
    sendMessage(p2, roundMsg)

    if p1:IsDead() then p1:ResurrectPlayer(1.0, false) end
    if p2:IsDead() then p2:ResurrectPlayer(1.0, false) end

    p1:SetHealth(p1:GetMaxHealth()); p1:SetPower(p1:GetMaxPower(0), 0)
    p2:SetHealth(p2:GetMaxHealth()); p2:SetPower(p2:GetMaxPower(0), 0)

    p1:ResetAllCooldowns()
    p2:ResetAllCooldowns()

    p1:Teleport(CONFIG.ARENA_MAP_ID,
        CONFIG.ARENA_PLAYER1_X, CONFIG.ARENA_PLAYER1_Y,
        CONFIG.ARENA_PLAYER1_Z, CONFIG.ARENA_PLAYER1_O)
    p2:Teleport(CONFIG.ARENA_MAP_ID,
        CONFIG.ARENA_PLAYER2_X, CONFIG.ARENA_PLAYER2_Y,
        CONFIG.ARENA_PLAYER2_Z, CONFIG.ARENA_PLAYER2_O)

    -- Apply root and start countdown after the transition delay
    CreateLuaEvent(function()
        local rp1 = GetPlayerByGUID(match.player1.guid)
        local rp2 = GetPlayerByGUID(match.player2.guid)
        if rp1 and rp2 then
            rp1:AddAura(CONFIG.ROOT_AURA_ID, rp1)
            rp2:AddAura(CONFIG.ROOT_AURA_ID, rp2)
            startCountdown(match.player1.guid, match.player2.guid, CONFIG.COUNTDOWN_DURATION)
        end
    end, CONFIG.ROUND_TRANSITION_DELAY, 1)
end

-- ==========================================
-- ROUND END  (one player died inside an active match)
-- ==========================================

local function handleRoundEnd(winnerGuid, loserGuid, match, matchIndex)
    local winner = GetPlayerByGUID(winnerGuid)
    local loser  = GetPlayerByGUID(loserGuid)
    if not winner or not loser then return end

    -- Increment the winner's score
    if match.player1.guid == winnerGuid then
        match.player1.score = match.player1.score + 1
    else
        match.player2.score = match.player2.score + 1
    end

    local roundWinMsg = string.format(CONFIG.MSG_ROUND_WINNER, winner:GetName())
    sendMessage(winner, roundWinMsg)
    sendMessage(loser,  roundWinMsg)

    -- Brief delay so the death animation plays before resurrection
    CreateLuaEvent(function()
        local loserPlayer = GetPlayerByGUID(loserGuid)
        -- ResurrectPlayer(healthPercent, ressSickness): percent is a float 0.0-1.0
        if loserPlayer and loserPlayer:IsDead() then
            loserPlayer:ResurrectPlayer(1.0, false)
        end
    end, 500, 1)

    if match.player1.score >= CONFIG.WINNING_SCORE or
       match.player2.score >= CONFIG.WINNING_SCORE then
        endMatch(match, matchIndex)
    else
        prepareNextRound(match)
    end
end

-- ==========================================
-- CREATE MATCH
-- ==========================================

local function createMatch(p1Guid, p2Guid, p1Location, p2Location)
    local matchData = {
        player1 = { guid = p1Guid, originalLocation = p1Location, score = 0 },
        player2 = { guid = p2Guid, originalLocation = p2Location, score = 0 },
        currentRound = 1,
        startTime    = os.time()
    }
    table.insert(activeMatches, matchData)
    return matchData
end

-- ==========================================
-- MATCHMAKING  (called every MATCHMAKING_INTERVAL ms)
-- ==========================================

local function processMatchmaking()
    if #pvpQueue < 2 then return end

    local p1Guid = pvpQueue[1]
    local p2Guid = pvpQueue[2]
    local p1 = GetPlayerByGUID(p1Guid)
    local p2 = GetPlayerByGUID(p2Guid)

    if p1 and p2 then
        local loc1 = savePlayerLocation(p1)
        local loc2 = savePlayerLocation(p2)
        createMatch(p1Guid, p2Guid, loc1, loc2)

        -- Remove both from queue BEFORE teleporting to prevent re-entry race
        table.remove(pvpQueue, 1)
        table.remove(pvpQueue, 1)

        teleportToArena(p1, 1)
        teleportToArena(p2, 2)

        sendMessage(p1, CONFIG.MSG_MATCH_FOUND)
        sendMessage(p2, CONFIG.MSG_MATCH_FOUND)

        startCountdown(p1Guid, p2Guid, CONFIG.COUNTDOWN_DURATION)
    else
        -- Purge offline players from the front of the queue
        if not p1 then table.remove(pvpQueue, 1) end
        -- After possible removal of p1, re-check whether p2 is now at index 1
        if not p2 and #pvpQueue > 0 and pvpQueue[1] == p2Guid then
            table.remove(pvpQueue, 1)
        end
    end
end

-- ==========================================
-- GOSSIP HANDLERS
-- mod-ale uses RegisterCreatureGossipEvent (not RegisterCreatureEvent 19/20).
-- Hello  callback signature: (event, player, object)
-- Select callback signature: (event, player, object, sender, intid, code, menu_id)
-- GossipMenuAddItem requires exactly 7 parameters: (icon, text, sender, intid, code, popup, money)
-- ==========================================

local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    -- 7 params: icon, text, sender, intid, code, popup, money
    player:GossipMenuAddItem(CONFIG.GOSSIP_ICON, CONFIG.MENU_JOIN_TEXT,  0, 1, false, "", 0)
    player:GossipMenuAddItem(CONFIG.GOSSIP_ICON, CONFIG.MENU_LEAVE_TEXT, 0, 2, false, "", 0)
    player:GossipSendMenu(1, creature)
end

-- mod-ale GOSSIP_EVENT_ON_SELECT signature: (event, player, object, sender, intid, code, menu_id)
local function OnGossipSelect(event, player, creature, sender, intid, code, menu_id)
    -- Use GetGUID() string as the stable, comparable player identifier
    -- (GetPlayerByGUID takes ObjectGuid string, NOT a GUIDLow number)
    local guid = player:GetGUID()

    if intid == 1 then
        if isPlayerInQueue(guid) then
            sendMessage(player, CONFIG.MSG_ALREADY_IN_QUEUE)
        else
            table.insert(pvpQueue, guid)
            sendMessage(player, CONFIG.MSG_JOINED)
        end
    elseif intid == 2 then
        if removePlayerFromQueue(guid) then
            sendMessage(player, CONFIG.MSG_LEFT)
        else
            sendMessage(player, CONFIG.MSG_NOT_IN_QUEUE)
        end
    end

    player:GossipComplete()
end

-- ==========================================
-- PLAYER DEATH  (event 6: PLAYER_EVENT_ON_KILL_PLAYER)
-- Signature: (event, killer, killed) — both are Player objects
-- ==========================================

local function OnPlayerDeath(event, killer, killed)
    if not killer or not killed then return end

    local killedGuid = killed:GetGUID()
    local killerGuid = killer:GetGUID()

    local match, matchIndex = findActiveMatchByPlayer(killedGuid)
    if not match then return end

    -- Verify the kill came from the designated opponent, not a bystander
    local isValidKill =
        (match.player1.guid == killedGuid and match.player2.guid == killerGuid) or
        (match.player2.guid == killedGuid and match.player1.guid == killerGuid)

    if not isValidKill then return end

    handleRoundEnd(killerGuid, killedGuid, match, matchIndex)
end

-- ==========================================
-- PLAYER LOGOUT  (event 4: PLAYER_EVENT_ON_LOGOUT)
-- Signature: (event, player)
-- ==========================================

local function OnPlayerLogout(event, player)
    local guid = player:GetGUID()

    -- Remove from queue if present
    removePlayerFromQueue(guid)

    -- If in an active match, forfeit it
    local match, matchIndex = findActiveMatchByPlayer(guid)
    if match then
        forfeitMatch(match, matchIndex, guid, "disconnect")
    end
end

-- ==========================================
-- PLAYER UPDATE AREA  (event 47: PLAYER_EVENT_ON_UPDATE_AREA)
-- Signature: (event, player, oldArea, newArea)
-- Handles forfeit when a player physically leaves the arena floor.
-- ==========================================

local function OnPlayerUpdateArea(event, player, oldArea, newArea)
    local guid = player:GetGUID()
    local match, matchIndex = findActiveMatchByPlayer(guid)
    if not match then return end

    if oldArea == CONFIG.ARENA_AREA_ID and newArea ~= CONFIG.ARENA_AREA_ID then
        local opponentGuid
        if match.player1.guid == guid then
            opponentGuid = match.player2.guid
        else
            opponentGuid = match.player1.guid
        end

        local opponent = GetPlayerByGUID(opponentGuid)
        if opponent then
            sendMessage(opponent, string.format(CONFIG.MSG_LEFT_ARENA_FORFEIT, player:GetName()))
        end

        sendMessage(player, CONFIG.MSG_LEFT_ARENA_WARNING)
        forfeitMatch(match, matchIndex, guid, "left_arena")
    end
end

-- ==========================================
-- PLAYER COMMAND  (event 42: PLAYER_EVENT_ON_COMMAND)
-- Signature: (event, player, command, chatHandler)
-- player can be nil when the command originates from the server console.
-- Return false to suppress further processing of the command.
-- ==========================================

local function OnPlayerCommand(event, player, command, chatHandler)
    if not player then return true end  -- console source, ignore

    if command:find("^1v1") then
        local args = {}
        for word in command:gmatch("%S+") do
            table.insert(args, word:lower())
        end

        if args[2] == "status" then
            local guid = player:GetGUID()

            local queuePos = getQueuePosition(guid)
            if queuePos then
                sendMessage(player, string.format(CONFIG.MSG_STATUS_IN_QUEUE, queuePos, #pvpQueue))
                return false
            end

            local match = findActiveMatchByPlayer(guid)
            if match then
                local mp1 = GetPlayerByGUID(match.player1.guid)
                local mp2 = GetPlayerByGUID(match.player2.guid)
                if mp1 and mp2 then
                    sendMessage(player, string.format(CONFIG.MSG_STATUS_IN_MATCH,
                        mp1:GetName(), match.player1.score, match.player2.score, mp2:GetName()))
                else
                    sendMessage(player, "You are in a match but opponent information is unavailable.")
                end
                return false
            end

            sendMessage(player, CONFIG.MSG_STATUS_NOT_IN_SYSTEM)
            return false
        else
            sendMessage(player, CONFIG.MSG_COMMAND_USAGE)
            return false
        end
    end

    return true
end

-- ==========================================
-- SERVER STARTUP  (event 14: WORLD_EVENT_ON_STARTUP)
-- ==========================================

local function OnServerStartup(event)
    InitNPC()
    print("[1v1] 1v1 PvP queue system loaded successfully.")
end

-- ==========================================
-- REGISTRATIONS
-- ==========================================

-- RegisterGossipEvents: registers gossip callbacks only after the NPC row is
-- confirmed present in creature_template. WorldDBExecute (used inside InitNPC)
-- is asynchronous — the INSERT may still be queued when this code runs, so we
-- poll with WorldDBQuery and retry after 2 s if the row is not visible yet.
local function RegisterGossipEvents()
    if WorldDBQuery("SELECT 1 FROM creature_template WHERE entry=" .. CONFIG.NPC_ID .. " LIMIT 1") then
        RegisterCreatureGossipEvent(CONFIG.NPC_ID, 1, OnGossipHello)
        RegisterCreatureGossipEvent(CONFIG.NPC_ID, 2, OnGossipSelect)
        print("[1VS1] Gossip events registrados para NPC " .. CONFIG.NPC_ID .. ".")
    else
        print("[1VS1] NPC no en DB todavia, reintentando en 2s...")
        CreateLuaEvent(function(e) RegisterGossipEvents() end, 2000, 1)
    end
end

-- Ensure the NPC row exists in creature_template, then register gossip with retry.
-- InitNPC() runs synchronous WorldDBQuery first (no-op if row exists) and only
-- calls WorldDBExecute (async) when the row is absent, so RegisterGossipEvents()
-- handles the race via polling.
InitNPC()
RegisterGossipEvents()

RegisterPlayerEvent(6,  OnPlayerDeath)       -- PLAYER_EVENT_ON_KILL_PLAYER
RegisterPlayerEvent(4,  OnPlayerLogout)      -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(42, OnPlayerCommand)     -- PLAYER_EVENT_ON_COMMAND
RegisterPlayerEvent(47, OnPlayerUpdateArea)  -- PLAYER_EVENT_ON_UPDATE_AREA

-- Keep the startup hook so InitNPC() also runs on a clean server boot.
RegisterServerEvent(14, OnServerStartup)     -- WORLD_EVENT_ON_STARTUP

-- Matchmaking timer: fires every MATCHMAKING_INTERVAL ms, repeats = 0 (infinite)
CreateLuaEvent(processMatchmaking, CONFIG.MATCHMAKING_INTERVAL, 0)

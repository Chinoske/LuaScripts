-- AzerothCore ALE + AIO spell charges (server side).
-- Original author: Crow (crow0385)
-- Requirements:
--   * mod-ale (AzerothCore Lua Engine) installed and active.
--   * AIO v1.75 server library installed at: lua_scripts/AIO_Server/AIO.lua
--   * AIO v1.75 client addon installed at:   WoW/Interface/AddOns/AIO_Client/
--   * spell_charges_client.lua placed next to this file (lua_scripts/spell_charges_client.lua).
--   * spell_charges.sql executed on the world database (acore_world).
-- Reload in game with: .reload ale

local AIO = AIO or require("AIO")

if AIO.IsMainState and not AIO.IsMainState() then
    return
end

local PREFIX = "SpellCharges"

local PLAYER_EVENT_ON_LOGIN = 3
local PLAYER_EVENT_ON_LOGOUT = 4
local PLAYER_EVENT_ON_TALENTS_RESET = 17
local PLAYER_EVENT_ON_COMMAND = 42
local PLAYER_EVENT_ON_LEARN_SPELL = 44

local SPELL_EVENT_ON_PREPARE = 1
local SPELL_EVENT_ON_CAST = 2

local RESET_AFTER_LOGOUT_MS = 15 * 60 * 1000

local spells = {}
local groups = {}
local playerState = {}
local spellCount = 0
local recentCasts = {}
local CAST_DEBOUNCE_MS = 300

local MSG_BEGIN = PREFIX .. "_Begin"
local MSG_ROW = PREFIX .. "_Row"
local MSG_END = PREFIX .. "_End"
local MSG_REQUEST = PREFIX .. "_Request"

local function log(message)
    print("[SpellCharges] " .. message)
end

local function ensureTable()
    WorldDBExecute([[
        CREATE TABLE IF NOT EXISTS spell_charges_spells (
            spell_id INT UNSIGNED NOT NULL,
            group_id INT UNSIGNED NOT NULL DEFAULT 0,
            max_charges TINYINT UNSIGNED NOT NULL,
            base_cooldown INT UNSIGNED NOT NULL,
            PRIMARY KEY (spell_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

local function getNow()
    return GetCurrTime()
end

local function getPlayerByGuidLow(guidLow)
    local players = GetPlayersInWorld()
    for _, player in ipairs(players) do
        if player:GetGUIDLow() == guidLow then
            return player
        end
    end

    return nil
end

local function normalizeGroupId(spellId, groupId)
    if groupId == nil or groupId == 0 then
        return spellId
    end

    return groupId
end

local function loadConfig()
    spells = {}
    groups = {}
    spellCount = 0

    ensureTable()

    local query = WorldDBQuery([[
        SELECT spell_id, group_id, max_charges, base_cooldown
        FROM spell_charges_spells
        ORDER BY spell_id ASC
    ]])

    if not query then
        log("No configured spells found in spell_charges_spells.")
        return
    end

    repeat
        local spellId = query:GetUInt32(0)
        local groupId = normalizeGroupId(spellId, query:GetUInt32(1))
        local maxCharges = query:GetUInt8(2)
        local baseCooldown = query:GetUInt32(3)

        if maxCharges >= 2 and baseCooldown > 0 then
            spells[spellId] = {
                spellId = spellId,
                groupId = groupId,
                maxCharges = maxCharges,
                baseCooldown = baseCooldown,
            }

            if not groups[groupId] then
                groups[groupId] = {
                    groupId = groupId,
                    maxCharges = maxCharges,
                    baseCooldown = baseCooldown,
                    spellIds = {},
                }
            end

            local group = groups[groupId]
            group.maxCharges = math.max(group.maxCharges, maxCharges)
            group.baseCooldown = math.max(group.baseCooldown, baseCooldown)
            table.insert(group.spellIds, spellId)
            spellCount = spellCount + 1
        end
    until not query:NextRow()
end

local function getGuidState(guidLow)
    if not playerState[guidLow] then
        playerState[guidLow] = {
            groups = {},
            logoutAt = 0,
        }
    end

    return playerState[guidLow]
end

local function ensureGroupState(guidLow, groupId)
    local guidState = getGuidState(guidLow)
    local group = groups[groupId]
    if not group then
        return nil
    end

    if not guidState.groups[groupId] then
        guidState.groups[groupId] = {
            charges = group.maxCharges,
            effectiveCooldown = group.baseCooldown,
            readyAt = 0,
            timerId = nil,
        }
    end

    return guidState.groups[groupId]
end

local function removeTimer(state)
    if state and state.timerId then
        RemoveEventById(state.timerId)
        state.timerId = nil
    end
end

local function resetSpellCooldowns(player, group)
    for _, spellId in ipairs(group.spellIds) do
        if player:HasSpell(spellId) then
            player:ResetSpellCooldown(spellId, true)
        end
    end
end

local function buildEntryPayload(spellId, groupState, group)
    local now = getNow()
    local remaining = 0

    if groupState.readyAt and groupState.readyAt > now then
        remaining = groupState.readyAt - now
    end

    return table.concat({
        "R",
        tostring(spellId),
        tostring(group.maxCharges),
        tostring(math.max(0, math.min(group.maxCharges, groupState.charges))),
        tostring(groupState.effectiveCooldown or group.baseCooldown),
        tostring(remaining),
    }, "|")
end

local function sendStatus(player)
    if not player then
        return
    end

    local guidLow = player:GetGUIDLow()

    AIO.Msg():Add(MSG_BEGIN):Send(player)

    for spellId, info in pairs(spells) do
        if player:HasSpell(spellId) then
            local group = groups[info.groupId]
            local groupState = ensureGroupState(guidLow, info.groupId)
            AIO.Msg():Add(MSG_ROW, buildEntryPayload(spellId, groupState, group)):Send(player)
        end
    end

    AIO.Msg():Add(MSG_END):Send(player)
end

local function scheduleRecharge(guidLow, groupId, delay)
    local group = groups[groupId]
    local state = ensureGroupState(guidLow, groupId)
    if not group or not state then
        return
    end

    if state.charges >= group.maxCharges or state.timerId then
        return
    end

    delay = math.max(1, delay or group.baseCooldown)
    state.readyAt = getNow() + delay
    state.timerId = CreateLuaEvent(function()
        state.timerId = nil
        state.charges = math.min(group.maxCharges, state.charges + 1)
        state.readyAt = 0

        local player = getPlayerByGuidLow(guidLow)
        if player then
            resetSpellCooldowns(player, group)
            sendStatus(player)
        end

        if state.charges < group.maxCharges then
            scheduleRecharge(guidLow, groupId, state.effectiveCooldown or group.baseCooldown)
        end
    end, delay, 1)
end

local function advanceOfflineRecharge(guidLow)
    local guidState = playerState[guidLow]
    if not guidState or not guidState.logoutAt or guidState.logoutAt == 0 then
        return
    end

    local elapsed = getNow() - guidState.logoutAt
    if elapsed >= RESET_AFTER_LOGOUT_MS then
        playerState[guidLow] = nil
        return
    end

    for groupId, state in pairs(guidState.groups) do
        local group = groups[groupId]
        if group then
            local cooldown = state.effectiveCooldown or group.baseCooldown
            if cooldown > 0 and state.charges < group.maxCharges then
                local gained = math.floor(elapsed / cooldown)
                state.charges = math.min(group.maxCharges, state.charges + gained)
                removeTimer(state)

                if state.charges < group.maxCharges then
                    local remainder = cooldown - (elapsed % cooldown)
                    scheduleRecharge(guidLow, groupId, remainder)
                end
            end
        end
    end

    guidState.logoutAt = 0
end

local function getSpellInfo(spellId)
    return spells[spellId]
end

local function shouldProcessCast(guidLow, spellId)
    local key = guidLow .. ":" .. spellId
    local now = getNow()

    if recentCasts[key] and (now - recentCasts[key]) < CAST_DEBOUNCE_MS then
        return false
    end

    recentCasts[key] = now
    return true
end

local function onSpellPrepare(_, caster, spell)
    if not caster or not spell or not caster:IsPlayer() then
        return
    end

    local player = caster:ToPlayer()
    if not player then
        return
    end

    local spellId = spell:GetEntry()
    local info = getSpellInfo(spellId)
    if not info then
        return
    end

    local state = ensureGroupState(player:GetGUIDLow(), info.groupId)
    if not state or state.charges < 1 then
        spell:Cancel()
    end
end

local function onSpellCast(_, caster, spell)
    if not caster or not spell or not caster:IsPlayer() then
        return
    end

    local player = caster:ToPlayer()
    if not player then
        return
    end

    local spellId = spell:GetEntry()
    local info = getSpellInfo(spellId)
    if not info then
        return
    end

    local group = groups[info.groupId]
    local state = ensureGroupState(player:GetGUIDLow(), info.groupId)
    if not group or not state then
        return
    end

    if state.charges < 1 then
        return
    end

    if not shouldProcessCast(player:GetGUIDLow(), spellId) then
        return
    end

    state.charges = state.charges - 1

    local cooldown = player:GetSpellCooldownDelay(spellId)
    if not cooldown or cooldown <= 0 then
        cooldown = group.baseCooldown
    end

    state.effectiveCooldown = cooldown

    if state.charges > 0 then
        resetSpellCooldowns(player, group)
    end

    scheduleRecharge(player:GetGUIDLow(), info.groupId, cooldown)
    sendStatus(player)
end

local function onLogin(_, player)
    advanceOfflineRecharge(player:GetGUIDLow())
    sendStatus(player)
end

local function onLogout(_, player)
    local guidLow = player:GetGUIDLow()
    local guidState = getGuidState(guidLow)
    guidState.logoutAt = getNow()

    for _, state in pairs(guidState.groups) do
        removeTimer(state)
    end
end

local function resetPlayer(player)
    local guidLow = player:GetGUIDLow()
    local guidState = playerState[guidLow]
    if guidState then
        for _, state in pairs(guidState.groups) do
            removeTimer(state)
        end
    end

    playerState[guidLow] = nil
    sendStatus(player)
end

local function onTalentsReset(_, player)
    resetPlayer(player)
end

local function onLearnSpell(_, player)
    sendStatus(player)
end

local function onCommand(_, player, command)
    local cmd = string.lower(command or "")
    if cmd ~= "spellcharges" and cmd ~= "spellcharges reset" then
        return true
    end

    if not player or player:GetGMRank() < 3 then
        return true
    end

    resetPlayer(player)
    player:SendNotification("Spell charges reset.")
    return false
end

local function onRequest(player)
    sendStatus(player)
end

AIO.AddAddon("lua_scripts/spell_charges_client.lua", "SpellChargesClient")
loadConfig()

for spellId, _ in pairs(spells) do
    RegisterSpellEvent(spellId, SPELL_EVENT_ON_PREPARE, onSpellPrepare)
    RegisterSpellEvent(spellId, SPELL_EVENT_ON_CAST, onSpellCast)
end

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, onLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT, onLogout)
RegisterPlayerEvent(PLAYER_EVENT_ON_TALENTS_RESET, onTalentsReset)
RegisterPlayerEvent(PLAYER_EVENT_ON_LEARN_SPELL, onLearnSpell)
RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, onCommand)
AIO.RegisterEvent(MSG_REQUEST, onRequest)

log("Loaded " .. tostring(spellCount) .. " configured spell(s).")

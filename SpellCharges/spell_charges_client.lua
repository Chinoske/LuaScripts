-- AzerothCore ALE + AIO spell charges (client side).
-- Original author: Crow (crow0385) https://github.com/crow0385
-- This file is sent to the client by spell_charges.lua via AIO.AddAddon().
-- Requirements:
--   * AIO v1.75 client addon installed at: WoW/Interface/AddOns/AIO_Client/
--     (the client addon is what receives and executes this code in the WoW UI).
--   * The matching server file spell_charges.lua must be loaded by mod-ale on the worldserver.
-- Reload on the client by relogging or /reload after the server pushes the addon.

local AIO = AIO or require("AIO")

if AIO.AddAddon() then
    return
end

local PREFIX = "SpellCharges"

local actionBarButtonPrefixes = {
    "ActionButton",
    "BonusActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarLeftButton",
    "MultiBarRightButton",
}

-- Persist across AIO script re-injection (e.g. /reload ale) so state and hooks stay in sync.
local SC = _G.SpellChargesClient or {}
_G.SpellChargesClient = SC

SC.spells = SC.spells or {}
SC.spellsByName = SC.spellsByName or {}

local MSG_BEGIN = PREFIX .. "_Begin"
local MSG_ROW = PREFIX .. "_Row"
local MSG_END = PREFIX .. "_End"
local MSG_REQUEST = PREFIX .. "_Request"

if not SC.origGetActionCount then
    SC.origGetActionCount = GetActionCount
    SC.origGetActionCooldown = GetActionCooldown
    SC.origIsStackableAction = IsStackableAction
    SC.origIsUsableAction = IsUsableAction
end

local function requestStatus()
    AIO.Msg():Add(MSG_REQUEST):Send()
end

local function splitMessage(message)
    local parts = {}
    for value in string.gmatch(message or "", "([^|]+)") do
        table.insert(parts, value)
    end
    return parts
end

local function getSpellIdFromLink(link)
    if not link then
        return nil
    end

    return tonumber(string.match(link, "spell:(%d+)"))
end

local function addSpellId(ids, spellId)
    if spellId and spellId > 0 then
        ids[spellId] = true
    end
end

local function addSpellName(names, spellName)
    if spellName and spellName ~= "" then
        names[spellName] = true
    end
end

local function addSpellInfoFromId(ids, names, spellId)
    if not spellId or spellId <= 0 then
        return
    end

    addSpellId(ids, spellId)

    local spellName = GetSpellInfo(spellId)
    addSpellName(names, spellName)
end

local function addSpellInfoFromBook(ids, names, bookIndex, bookType)
    if not bookIndex then
        return
    end

    local spellName = GetSpellInfo(bookIndex, bookType or BOOKTYPE_SPELL)
    addSpellName(names, spellName)

    local link = GetSpellLink(bookIndex, bookType or BOOKTYPE_SPELL)
    addSpellId(ids, getSpellIdFromLink(link))
end

local function getActionSpellKeys(action)
    local ids = {}
    local names = {}
    if not action or not HasAction(action) then
        return ids, names
    end

    local actionType, actionId, actionSubType, actionSpellId = GetActionInfo(action)
    if actionType ~= "spell" then
        return ids, names
    end

    -- Depending on client/core, actionId may be a spell ID or a spellbook index.
    addSpellInfoFromId(ids, names, actionId)
    addSpellInfoFromId(ids, names, actionSpellId)
    addSpellInfoFromBook(ids, names, actionId, actionSubType)

    return ids, names
end

local function getButtonAction(button)
    if not button then
        return nil
    end

    local action = button.action
    if not action and button.GetAttribute then
        action = button:GetAttribute("action")
    end

    if not action and ActionButton_GetPagedID then
        action = ActionButton_GetPagedID(button)
    end

    if not action or not HasAction(action) then
        return nil
    end

    return action
end

local function getButtonSpellKeys(button)
    return getActionSpellKeys(getButtonAction(button))
end

local function getChargeText(button)
    return _G[button:GetName() .. "Count"]
end

local function getCooldown(button)
    return _G[button:GetName() .. "Cooldown"]
end

local function clearButton(button)
    if not button then
        return
    end

    local text = getChargeText(button)
    if text and button.spellChargesActive then
        text:Hide()
    end

    button.spellChargesActive = nil
end

local function updateButton(button, data)
    local cooldown = getCooldown(button)
    local text = getChargeText(button)
    local remaining = 0

    button.spellChargesActive = true

    if data.rechargeEnd and data.rechargeEnd > GetTime() then
        remaining = data.rechargeEnd - GetTime()
    end

    if cooldown and data.currentCharges < data.maxCharges and remaining > 0 and data.effectiveCooldown > 0 then
        local duration = data.effectiveCooldown / 1000
        local start = data.rechargeStart or (GetTime() - (duration - remaining))
        if CooldownFrame_SetTimer then
            CooldownFrame_SetTimer(cooldown, start, duration, 1)
        else
            cooldown:SetCooldown(start, duration)
        end
        cooldown:Show()
    elseif cooldown then
        cooldown:Hide()
    end

    if text and data.maxCharges > 1 then
        text:SetText(tostring(data.currentCharges))
        text:Show()
    elseif text then
        text:Hide()
    end
end

local function updateUsable(button, data)
    local name = button:GetName()
    local icon = _G[name .. "Icon"]
    local normalTexture = _G[name .. "NormalTexture"]

    if not icon or not normalTexture then
        return
    end

    if data.currentCharges > 0 then
        icon:SetVertexColor(1.0, 1.0, 1.0)
        normalTexture:SetVertexColor(1.0, 1.0, 1.0)
    else
        icon:SetVertexColor(0.4, 0.4, 0.4)
        normalTexture:SetVertexColor(1.0, 1.0, 1.0)
    end
end

local function findSpellDataForButton(button)
    local spellIds, spellNames = getButtonSpellKeys(button)
    local spells = SC.spells
    local byName = SC.spellsByName

    for spellId in pairs(spellIds) do
        if spells[spellId] then
            return spells[spellId]
        end
    end

    for spellName in pairs(spellNames) do
        if byName[spellName] then
            return byName[spellName]
        end
    end

    return nil
end

local function findSpellDataForAction(action)
    local spellIds, spellNames = getActionSpellKeys(action)
    local spells = SC.spells
    local byName = SC.spellsByName

    for spellId in pairs(spellIds) do
        if spells[spellId] then
            return spells[spellId]
        end
    end

    for spellName in pairs(spellNames) do
        if byName[spellName] then
            return byName[spellName]
        end
    end

    return nil
end

local function getRechargeCooldown(data)
    local remaining = 0
    if data and data.rechargeEnd and data.rechargeEnd > GetTime() then
        remaining = data.rechargeEnd - GetTime()
    end

    if not data or data.currentCharges >= data.maxCharges or remaining <= 0 or data.effectiveCooldown <= 0 then
        return nil
    end

    local duration = data.effectiveCooldown / 1000
    local start = data.rechargeStart or (GetTime() - (duration - remaining))
    return start, duration, 1
end

GetActionCount = function(action)
    local data = findSpellDataForAction(action)
    if data then
        return data.currentCharges
    end

    return SC.origGetActionCount(action)
end

IsStackableAction = function(action)
    if findSpellDataForAction(action) then
        return 1
    end

    return SC.origIsStackableAction(action)
end

GetActionCooldown = function(action)
    local data = findSpellDataForAction(action)
    if data then
        local start, duration, enable = getRechargeCooldown(data)
        if start then
            return start, duration, enable
        end
    end

    return SC.origGetActionCooldown(action)
end

IsUsableAction = function(action)
    local data = findSpellDataForAction(action)
    if data then
        return data.currentCharges > 0, false
    end

    return SC.origIsUsableAction(action)
end

local function updateActionBars()
    local matchedButtons = 0

    for _, prefix in ipairs(actionBarButtonPrefixes) do
        for index = 1, 12 do
            local button = _G[prefix .. index]
            local spellData = findSpellDataForButton(button)

            if spellData then
                matchedButtons = matchedButtons + 1
                updateButton(button, spellData)
                updateUsable(button, spellData)
            else
                clearButton(button)
            end
        end
    end

    SC.lastMatched = matchedButtons
end

local function handleStatusRow(message)
    local target = SC.pending or SC.spells
    local parts = splitMessage(message)

    if parts[1] ~= "R" then
        return
    end

    local spellId = tonumber(parts[2])
    if not spellId then
        return
    end

    local effectiveCooldown = tonumber(parts[5]) or 0
    local currentCooldown = tonumber(parts[6]) or 0
    local rechargeEnd = 0
    local rechargeStart = 0

    if currentCooldown > 0 and effectiveCooldown > 0 then
        rechargeEnd = GetTime() + (currentCooldown / 1000)
        rechargeStart = rechargeEnd - (effectiveCooldown / 1000)
    end

    target[spellId] = {
        spellId = spellId,
        spellName = GetSpellInfo(spellId),
        maxCharges = tonumber(parts[3]) or 0,
        currentCharges = tonumber(parts[4]) or 0,
        effectiveCooldown = effectiveCooldown,
        currentCooldown = currentCooldown,
        rechargeEnd = rechargeEnd,
        rechargeStart = rechargeStart,
    }
end

SC.onBegin = function()
    SC.pending = {}
end

SC.onRow = function(_, message)
    handleStatusRow(message)
end

SC.onEnd = function()
    local spells = SC.spells
    for key in pairs(spells) do
        spells[key] = nil
    end

    if SC.pending then
        for spellId, spellData in pairs(SC.pending) do
            spells[spellId] = spellData
        end
    end

    local byName = SC.spellsByName
    for key in pairs(byName) do
        byName[key] = nil
    end
    for _, spellData in pairs(spells) do
        if spellData.spellName then
            byName[spellData.spellName] = spellData
        end
    end

    SC.pending = nil
    updateActionBars()
end

local function reapplyButton(button)
    local spellData = findSpellDataForButton(button)
    if spellData then
        updateButton(button, spellData)
        updateUsable(button, spellData)
    end
end

if hooksecurefunc and not SC.hooksInstalled then
    hooksecurefunc("ActionButton_UpdateCount", reapplyButton)
    hooksecurefunc("ActionButton_UpdateCooldown", reapplyButton)
    hooksecurefunc("ActionButton_UpdateUsable", reapplyButton)
    hooksecurefunc("ActionButton_Update", reapplyButton)
    SC.hooksInstalled = true
end

if not SC.eventsRegistered then
    AIO.RegisterEvent(MSG_BEGIN, function(...)
        SC.onBegin(...)
    end)
    AIO.RegisterEvent(MSG_ROW, function(...)
        SC.onRow(...)
    end)
    AIO.RegisterEvent(MSG_END, function(...)
        SC.onEnd(...)
    end)
    SC.eventsRegistered = true
end

if not SC.frame then
    SC.frame = CreateFrame("Frame")
    SC.frame:RegisterEvent("PLAYER_LOGIN")
    SC.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    SC.frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    SC.frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
    SC.frame:RegisterEvent("SPELLS_CHANGED")
    SC.frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    SC.frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")

    SC.loginDelay = 2
    SC.elapsedSinceUpdate = 0

    SC.frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
            SC.loginDelay = 2
        end

        requestStatus()
        updateActionBars()
    end)

    SC.frame:SetScript("OnUpdate", function(_, elapsed)
        if SC.loginDelay > 0 then
            SC.loginDelay = SC.loginDelay - elapsed
            if SC.loginDelay <= 0 then
                requestStatus()
            end
        end

        SC.elapsedSinceUpdate = SC.elapsedSinceUpdate + elapsed
        if SC.elapsedSinceUpdate < 0.1 then
            return
        end

        SC.elapsedSinceUpdate = 0
        updateActionBars()
    end)
end

SLASH_SPELLCHARGES1 = "/spellcharges"
SlashCmdList.SPELLCHARGES = function()
    requestStatus()
    updateActionBars()

    local known = 0
    for _ in pairs(SC.spells) do
        known = known + 1
    end

    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. ": known=" .. known .. " matchedButtons=" .. (SC.lastMatched or 0))
    end
end

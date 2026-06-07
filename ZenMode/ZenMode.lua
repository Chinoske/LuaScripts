-- ZenMode.lua — Sentarse (X) o AFK activa escudo de inmunidad + regen de HP/poder

local ZEN_AURA       = 642   -- Divine Shield (8 s de inmunidad total)
local AURA_REFRESH   = 7     -- re-aplicar cada N segundos (aura dura 8 s)
local REGEN_INTERVAL = 1.0   -- tick de regen cada 1 s
local REGEN_PCT      = 0.10  -- 10 % del máximo por tick
local MOVE_THRESHOLD = 0.5   -- unidades mínimas de movimiento para cancelar (AFK)

local zenActive  = {}
local zenTimer   = {}
local regenTimer = {}
local lastPos    = {}

local function ActivateZen(player)
    local guid = player:GetGUIDLow()
    if zenActive[guid] then return end
    zenActive[guid]  = true
    zenTimer[guid]   = AURA_REFRESH   -- dispara refresh en el primer tick
    regenTimer[guid] = REGEN_INTERVAL -- dispara regen en el primer tick
    player:AddAura(ZEN_AURA, player)
    player:SendBroadcastMessage("|cFF00CCFF[Zen Mode]|r Modo Zen activado.")
end

local function DeactivateZen(player)
    local guid = player:GetGUIDLow()
    if not zenActive[guid] then return end
    zenActive[guid]  = false
    zenTimer[guid]   = nil
    regenTimer[guid] = nil
    lastPos[guid]    = nil
    player:RemoveAura(ZEN_AURA)
    player:SendBroadcastMessage("|cFF00CCFF[Zen Mode]|r Modo Zen desactivado.")
end

CreateLuaEvent(function()
    local elapsed = 0.5
    local players = GetPlayersInWorld()
    if not players then return end

    for _, player in pairs(players) do
        if not player or not player:IsInWorld() then goto skip end

        local guid  = player:GetGUIDLow()
        local isSit = player:GetStandState() >= 1
        local isAFK = player:IsAFK()
        local inZen = zenActive[guid] or false

        -- Muerte o combate cancela/bloquea zen
        if player:IsDead() or player:IsInCombat() then
            if inZen then DeactivateZen(player) end
            goto skip
        end

        -- Detectar movimiento en AFK (sentarse ya cancela por stand state)
        if inZen and isAFK and not isSit then
            local x, y = player:GetX(), player:GetY()
            local prev = lastPos[guid]
            if prev then
                local dx, dy = x - prev[1], y - prev[2]
                if dx * dx + dy * dy > MOVE_THRESHOLD * MOVE_THRESHOLD then
                    DeactivateZen(player)
                    goto skip
                end
            end
            lastPos[guid] = {x, y}
        end

        -- Activar / desactivar según estado
        if isSit or isAFK then
            if not inZen then ActivateZen(player) end
        else
            if inZen then DeactivateZen(player) end
        end

        if not zenActive[guid] then goto skip end

        -- Refresh del aura de inmunidad
        zenTimer[guid] = zenTimer[guid] + elapsed
        if zenTimer[guid] >= AURA_REFRESH then
            zenTimer[guid] = 0
            player:RemoveAura(ZEN_AURA)
            player:AddAura(ZEN_AURA, player)
        end

        -- Regen de HP y poder
        regenTimer[guid] = regenTimer[guid] + elapsed
        if regenTimer[guid] >= REGEN_INTERVAL then
            regenTimer[guid] = 0

            local hp, maxHp = player:GetHealth(), player:GetMaxHealth()
            if hp < maxHp then
                player:SetHealth(math.min(hp + math.floor(maxHp * REGEN_PCT), maxHp))
            end

            local pType = player:GetPowerType()
            -- 0=mana 1=rage 2=focus(pet) 3=energy 4=happiness(pet) 5=rune 6=runic_power
            -- Firma: SetPower(amount, type)  — amount va primero
            if type(pType) == "number" and pType ~= 2 and pType ~= 4 and pType ~= 5 then
                local pw, maxPw = player:GetPower(pType), player:GetMaxPower(pType)
                if type(pw) == "number" and type(maxPw) == "number" and pw < maxPw then
                    player:SetPower(math.min(pw + math.floor(maxPw * REGEN_PCT), maxPw), pType)
                end
            end
        end

        ::skip::
    end
end, 500, 0)

RegisterPlayerEvent(3, function(event, player)  -- PLAYER_EVENT_ON_LOGIN
    local guid = player:GetGUIDLow()
    zenActive[guid]  = false
    zenTimer[guid]   = nil
    regenTimer[guid] = nil
    lastPos[guid]    = nil
end)

RegisterPlayerEvent(4, function(event, player)  -- PLAYER_EVENT_ON_LOGOUT
    DeactivateZen(player)
    local guid = player:GetGUIDLow()
    zenActive[guid]  = nil
    zenTimer[guid]   = nil
    regenTimer[guid] = nil
    lastPos[guid]    = nil
end)

print("[ZenMode] Sistema cargado.")

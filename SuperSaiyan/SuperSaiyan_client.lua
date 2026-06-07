-- SuperSaiyan_client.lua — Barra de Ki minimalista (sin fondo, sin texto)

local AIO = AIO or require("AIO")
if AIO.AddAddon() then return end

local curKi    = 0
local targetKi = 0
local curState = "normal"

local COLORS = {
    normal      = { 0.15, 0.35, 1.00 },
    high        = { 1.00, 0.80, 0.00 },
    sequencing  = { 1.00, 0.45, 0.00 },
    transformed = { 1.00, 0.95, 0.05 },
}

local KiUI = _G.SuperSaiyanKiUI
if not KiUI then
    -- Marco invisible solo para poder arrastrar
    local root = CreateFrame("Frame", "SuperSaiyanKiFrame", UIParent)
    root:SetWidth(220)
    root:SetHeight(12)
    root:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 128)
    root:SetMovable(true)
    root:EnableMouse(true)
    root:RegisterForDrag("LeftButton")
    root:SetScript("OnDragStart", root.StartMoving)
    root:SetScript("OnDragStop",  root.StopMovingOrSizing)
    root:SetClampedToScreen(true)

    -- Fondo sutil de la barra (parte vacia)
    local barBg = root:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    barBg:SetVertexColor(0.05, 0.05, 0.10, 0.55)

    -- Barra de progreso
    local bar = CreateFrame("StatusBar", nil, root)
    bar:SetAllPoints()
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    bar:SetStatusBarColor(0.15, 0.35, 1.0, 1.0)
    root.bar = bar

    -- Capa de brillo (ADD) — efecto energetico
    local glow = bar:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints()
    glow:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(0.15, 0.35, 1.0, 0.0)
    root.glow = glow

    -- Chispa en el borde de carga
    local spark = bar:CreateTexture(nil, "OVERLAY")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetWidth(16)
    spark:SetHeight(28)
    spark:SetBlendMode("ADD")
    spark:SetAlpha(0)
    spark:SetPoint("CENTER", bar, "LEFT", 0, 0)
    root.spark = spark

    root:SetScript("OnUpdate", function(self, elapsed)
        if math.abs(curKi - targetKi) > 0.15 then
            local spd = 85 * elapsed
            if targetKi > curKi then
                curKi = math.min(curKi + spd, targetKi)
            else
                curKi = math.max(curKi - spd, targetKi)
            end
        else
            curKi = targetKi
        end

        self.bar:SetValue(curKi)

        -- Chispa
        if curKi > 1 and curKi < 100 then
            local w = self.bar:GetWidth()
            if w and w > 0 then
                self.spark:SetPoint("CENTER", self.bar, "LEFT", (curKi / 100) * w, 0)
            end
            self.spark:SetAlpha(0.65 + 0.35 * math.sin(GetTime() * 10))
        else
            self.spark:SetAlpha(0)
        end

        -- Pulso de brillo
        local t = GetTime()
        local ga = 0
        if curState == "transformed" then
            ga = 0.20 + 0.20 * math.sin(t * 3.5)
        elseif curState == "sequencing" then
            ga = 0.25 + 0.25 * math.sin(t * 7)
        elseif targetKi >= 75 then
            ga = 0.10 + 0.10 * math.sin(t * 2)
        end
        self.glow:SetAlpha(ga)
    end)

    _G.SuperSaiyanKiUI = root
    KiUI = root
end

local function ApplyColor(c)
    KiUI.bar:SetStatusBarColor(c[1], c[2], c[3], 1.0)
    KiUI.glow:SetVertexColor(c[1], c[2], c[3], 1.0)
    KiUI.spark:SetVertexColor(c[1], c[2], c[3], 1.0)
end

local function UpdateKi(ki, state)
    ki    = tonumber(ki)   or 0
    state = tostring(state or "normal")
    targetKi = ki
    curState = state

    if state == "transformed" then
        ApplyColor(COLORS.transformed)
    elseif state == "sequencing" then
        ApplyColor(COLORS.sequencing)
    elseif ki >= 75 then
        ApplyColor(COLORS.high)
    else
        ApplyColor(COLORS.normal)
    end

    KiUI:Show()
end

if not _G.SS_KiHandlerRegistered then
    AIO.RegisterEvent("SS_KiUpdate", function(player, ki, state)
        UpdateKi(ki, state)
    end)
    _G.SS_KiHandlerRegistered = true
end

SLASH_SUPERSAIYAN1 = "/ki"
SlashCmdList["SUPERSAIYAN"] = function()
    if KiUI:IsShown() then KiUI:Hide() else KiUI:Show() end
end

KiUI:Show()

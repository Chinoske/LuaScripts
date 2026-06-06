-- ============================================================
-- SuperSaiyan_client.lua  — Lado CLIENTE (enviado por AIO)
-- Barra de Ki animada: glow + chispa + color progresivo
-- Patrón: AIO.RegisterEvent (igual que SpellCharges)
-- ============================================================

local AIO = AIO or require("AIO")

-- Guard estándar AIO: si corre en el servidor, salir
if AIO.AddAddon() then return end

-- ─── Estado interno ───────────────────────────────────────────
local curKi    = 0
local targetKi = 0
local curState = "normal"

-- ─── Paleta de colores ────────────────────────────────────────
local COLORS = {
    normal      = { 0.15, 0.35, 1.00 },   -- azul
    high        = { 1.00, 0.80, 0.00 },   -- dorado  (Ki >= 75)
    sequencing  = { 1.00, 0.45, 0.00 },   -- naranja
    transformed = { 1.00, 0.95, 0.05 },   -- amarillo SS
}

-- ─── Construir frame (una sola vez, persiste en _G) ──────────
local KiUI = _G.SuperSaiyanKiUI
if not KiUI then
    local root = CreateFrame("Frame", "SuperSaiyanKiFrame", UIParent)
    root:SetWidth(240)
    root:SetHeight(52)
    root:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 120)
    root:SetMovable(true)
    root:EnableMouse(true)
    root:RegisterForDrag("LeftButton")
    root:SetScript("OnDragStart", root.StartMoving)
    root:SetScript("OnDragStop",  root.StopMovingOrSizing)
    root:SetClampedToScreen(true)

    -- Fondo oscuro
    root:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false, tileSize = 0, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    root:SetBackdropColor(0.03, 0.03, 0.10, 0.92)
    root:SetBackdropBorderColor(0.20, 0.20, 0.45, 0.85)

    -- "Ki" arriba izquierda
    local title = root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 8, -4)
    title:SetTextColor(1.0, 0.85, 0.0, 1.0)
    title:SetText("Ki")
    root.title = title

    -- Número grande arriba derecha (solo el número, sin "/100")
    local kiNum = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    kiNum:SetPoint("TOPRIGHT", root, "TOPRIGHT", -8, -2)
    kiNum:SetTextColor(1, 1, 1, 0.85)
    kiNum:SetText("0")
    root.kiNum = kiNum

    -- ── Contenedor de la barra ──────────────────────────────
    local barFrame = CreateFrame("Frame", nil, root)
    barFrame:SetPoint("TOPLEFT",  root, "TOPLEFT",  8, -22)
    barFrame:SetPoint("TOPRIGHT", root, "TOPRIGHT", -8, -22)
    barFrame:SetHeight(16)

    -- Fondo oscuro de la barra
    local barBg = barFrame:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    barBg:SetVertexColor(0.04, 0.04, 0.12, 1.0)

    -- Barra de progreso principal
    local bar = CreateFrame("StatusBar", nil, barFrame)
    bar:SetAllPoints()
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    bar:SetStatusBarColor(0.15, 0.35, 1.0, 1.0)
    root.bar = bar

    -- Capa de brillo ADD — efecto de energía
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
    spark:SetHeight(32)
    spark:SetBlendMode("ADD")
    spark:SetAlpha(0)
    spark:SetPoint("CENTER", bar, "LEFT", 0, 0)
    root.spark = spark

    -- Texto de estado abajo centrado
    local stateText = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    stateText:SetPoint("BOTTOMLEFT",  root, "BOTTOMLEFT",  8, 5)
    stateText:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -8, 5)
    stateText:SetJustifyH("CENTER")
    stateText:SetTextColor(0.55, 0.55, 0.65, 1.0)
    stateText:SetText("Acumula Ki en combate")
    root.stateText = stateText

    -- ── Animación OnUpdate ──────────────────────────────────
    root:SetScript("OnUpdate", function(self, elapsed)
        -- Suavizado hacia el Ki objetivo
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
        self.kiNum:SetText(math.floor(curKi))

        -- Chispa moviéndose al borde de la barra
        if curKi > 1 and curKi < 100 then
            local w = self.bar:GetWidth()
            if w and w > 0 then
                self.spark:SetPoint("CENTER", self.bar, "LEFT", (curKi / 100) * w, 0)
            end
            self.spark:SetAlpha(0.65 + 0.35 * math.sin(GetTime() * 10))
        else
            self.spark:SetAlpha(0)
        end

        -- Pulso de brillo según estado
        local t = GetTime()
        local ga = 0
        if curState == "transformed" then
            ga = 0.18 + 0.18 * math.sin(t * 3.5)
        elseif curState == "sequencing" then
            ga = 0.22 + 0.22 * math.sin(t * 7)
        elseif targetKi >= 75 then
            ga = 0.08 + 0.08 * math.sin(t * 2)
        end
        self.glow:SetAlpha(ga)
    end)

    _G.SuperSaiyanKiUI = root
    KiUI = root
end

-- ─── Aplicar color a la barra y sus capas ────────────────────
local function ApplyColor(c)
    KiUI.bar:SetStatusBarColor(c[1], c[2], c[3], 1.0)
    KiUI.glow:SetVertexColor(c[1], c[2], c[3], 1.0)
    KiUI.spark:SetVertexColor(c[1], c[2], c[3], 1.0)
end

-- ─── Actualizar UI ───────────────────────────────────────────
local function UpdateKi(ki, state)
    ki    = tonumber(ki)   or 0
    state = tostring(state or "normal")
    targetKi = ki
    curState = state

    if state == "transformed" then
        ApplyColor(COLORS.transformed)
        KiUI.title:SetTextColor(1, 1, 0, 1)
        KiUI.stateText:SetText("|cFFFFFF00★ SUPER SAIYAN ★|r")
    elseif state == "sequencing" then
        ApplyColor(COLORS.sequencing)
        KiUI.title:SetTextColor(1, 0.5, 0, 1)
        KiUI.stateText:SetText("|cFFFF8000Transformandose...|r")
    elseif ki >= 75 then
        ApplyColor(COLORS.high)
        KiUI.title:SetTextColor(1, 0.85, 0, 1)
        KiUI.stateText:SetText("|cFFFFD700El Ki esta al limite!|r")
    else
        ApplyColor(COLORS.normal)
        KiUI.title:SetTextColor(1, 0.85, 0, 1)
        KiUI.stateText:SetText("Acumula Ki en combate")
    end

    KiUI:Show()
end

-- ─── Registro del handler AIO ────────────────────────────────
-- Firma correcta: handler(player, ...) — player es el primer arg siempre
-- Servidor envía: AIO.Msg():Add("SS_KiUpdate", ki, state)
-- AIO_HandleBlock llama: func(player, ki, state)  ← player obligatorio
if not _G.SS_KiHandlerRegistered then
    AIO.RegisterEvent("SS_KiUpdate", function(player, ki, state)
        UpdateKi(ki, state)
    end)
    _G.SS_KiHandlerRegistered = true
end

-- ─── /ki — mostrar/ocultar ───────────────────────────────────
SLASH_SUPERSAIYAN1 = "/ki"
SlashCmdList["SUPERSAIYAN"] = function()
    if KiUI:IsShown() then KiUI:Hide() else KiUI:Show() end
end

KiUI:Show()

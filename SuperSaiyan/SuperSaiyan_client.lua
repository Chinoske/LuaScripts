-- ============================================================
-- SuperSaiyan_client.lua
-- Barra de Ki — UI lado cliente (WoW 3.3.5a / AIO)
-- Recibe: SS_KiUpdate(ki, state)
-- ============================================================

local AIO = AIO or require("AIO")
if not AIO.IsMainState then return end
if not AIO.IsMainState() then return end

-- ──────────────────────────────────────────────────────────────
-- Colores por estado
-- ──────────────────────────────────────────────────────────────
local COLORS = {
    normal      = { r = 0.20, g = 0.40, b = 1.00 },   -- azul
    high        = { r = 1.00, g = 0.85, b = 0.00 },   -- dorado (Ki >= 75)
    sequencing  = { r = 1.00, g = 0.50, b = 0.00 },   -- naranja
    transformed = { r = 1.00, g = 1.00, b = 0.10 },   -- amarillo brillante
}

-- ──────────────────────────────────────────────────────────────
-- Crear o recuperar el frame (persistente entre recargas de UI)
-- ──────────────────────────────────────────────────────────────
if not _G.SuperSaiyanUI then
    local frame = CreateFrame("Frame", "SuperSaiyanUIFrame", UIParent)
    frame:SetWidth(260)
    frame:SetHeight(52)
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 140)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:SetFrameStrata("MEDIUM")

    -- Fondo semitransparente
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.9)

    -- Etiqueta "Ki"
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
    label:SetTextColor(1, 0.85, 0, 1)
    label:SetText("Ki")
    frame.label = label

    -- Barra de progreso
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  8, -20)
    bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -20)
    bar:SetHeight(14)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    bar:SetStatusBarColor(0.20, 0.40, 1.00, 1)

    -- Fondo de la barra
    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    barBg:SetVertexColor(0, 0, 0, 0.5)
    frame.bar = bar

    -- Texto de valor (e.g. "47 / 100")
    local valueText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valueText:SetAllPoints()
    valueText:SetJustifyH("CENTER")
    valueText:SetText("0 / 100")
    frame.valueText = valueText

    -- Texto de estado
    local stateText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stateText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 6)
    stateText:SetTextColor(0.7, 0.7, 0.7, 1)
    stateText:SetText("Normal")
    frame.stateText = stateText

    _G.SuperSaiyanUI = frame
end

local UI = _G.SuperSaiyanUI

-- ──────────────────────────────────────────────────────────────
-- Función de actualización
-- ──────────────────────────────────────────────────────────────
local function UpdateBar(ki, state)
    ki = tonumber(ki) or 0
    state = tostring(state or "normal")

    local c
    if state == "transformed" then
        c = COLORS.transformed
    elseif state == "sequencing" then
        c = COLORS.sequencing
    elseif ki >= 75 then
        c = COLORS.high
    else
        c = COLORS.normal
    end

    UI.bar:SetValue(ki)
    UI.bar:SetStatusBarColor(c.r, c.g, c.b, 1)
    UI.valueText:SetText(ki .. " / 100")

    local stateLabels = {
        normal      = "Normal",
        sequencing  = "|cFFFF8000Transformandose...|r",
        transformed = "|cFFFFFF00SUPER SAIYAN|r",
    }
    UI.stateText:SetText(stateLabels[state] or "Normal")

    -- Animación de destello al transformarse
    if state == "transformed" then
        UI.label:SetTextColor(1, 1, 0, 1)
    else
        UI.label:SetTextColor(1, 0.85, 0, 1)
    end
end

-- ──────────────────────────────────────────────────────────────
-- Manejador AIO
-- ──────────────────────────────────────────────────────────────
local handlers = AIO.AddHandlers("SS_KiUpdate", {})
handlers.SS_KiUpdate = function(_, ki, state)
    UpdateBar(ki, state)
end

-- ──────────────────────────────────────────────────────────────
-- Slash command /ki — mostrar/ocultar barra
-- ──────────────────────────────────────────────────────────────
SLASH_SUPERSAIYAN1 = "/ki"
SlashCmdList["SUPERSAIYAN"] = function(msg)
    if UI:IsShown() then
        UI:Hide()
    else
        UI:Show()
    end
end

UI:Show()

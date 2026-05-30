--[[
    AIO_HelloTest.lua — Script de prueba para verificar AIO con mod-ale
    Instala primero AIO_Server/ en lua_scripts/ y AIO_Client/ en WoW/Interface/AddOns/

    Uso:
      En-game: .aiotest
      El cliente mostrará una ventana con "¡AIO funciona con mod-ale!" y un botón.
      Al hacer clic en el botón, el servidor recibe el mensaje y responde con la hora del servidor.
]]

local AIO = AIO or require("AIO")

-- Solo en main state del servidor
if not AIO.IsMainState() then
    return
end

-- ============================================================
-- AddAddon devuelve true en servidor → el servidor no ejecuta
-- el código cliente. El cliente SÍ lo recibe y ejecuta.
-- ============================================================
if AIO.AddAddon() then

    -- ────────────────────────────────────────────────────────
    -- CÓDIGO SERVER-SIDE
    -- ────────────────────────────────────────────────────────
    local Handlers = AIO.AddHandlers("AIOTest", {})

    -- El cliente hace clic en "Ping Server" → servidor responde con hora actual
    function Handlers.PingServer(player, clientTime)
        local serverTime = os.time()
        local name = player:GetName()
        print("[AIO Test] Ping recibido de " .. name .. " (client time: " .. tostring(clientTime) .. ")")
        AIO.Handle(player, "AIOTest", "PongClient", serverTime, name)
    end

    -- Comando .aiotest → abrir la ventana en el cliente
    RegisterPlayerEvent(42, function(event, player, command)
        if command == "aiotest" then
            AIO.Handle(player, "AIOTest", "ShowWindow")
            return false
        end
    end)

    print("[AIO Test] Server-side cargado correctamente con mod-ale!")
    return
end

-- ============================================================
-- CÓDIGO CLIENT-SIDE (addon que recibe el cliente)
-- ============================================================
local Handlers = AIO.AddHandlers("AIOTest", {})

-- ─── Frame principal ──────────────────────────────────────
local frame = CreateFrame("Frame", "AIOTestFrame", UIParent)
frame:SetSize(320, 160)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetPoint("CENTER")
frame:SetBackdrop({
    bgFile   = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    edgeSize = 32,
    insets   = { left=8, right=8, top=8, bottom=8 }
})
frame:SetBackdropColor(0, 0, 0, 0.85)
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
frame:Hide()

-- Guardar posición entre sesiones
AIO.SavePosition(frame)

-- ─── Botón cerrar ─────────────────────────────────────────
local btnClose = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
btnClose:SetPoint("TOPRIGHT", -4, -4)

-- ─── Título ───────────────────────────────────────────────
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -16)
title:SetText("|cff00ff00AIO + mod-ale|r")

-- ─── Texto de estado ──────────────────────────────────────
local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
statusText:SetPoint("CENTER", 0, 10)
statusText:SetText("|cffffffcc¡AIO funciona con mod-ale!\nHaz clic en Ping para probar la comunicación.|r")
statusText:SetWidth(280)
statusText:SetJustifyH("CENTER")

-- ─── Botón Ping ───────────────────────────────────────────
local btnPing = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
btnPing:SetSize(120, 28)
btnPing:SetPoint("BOTTOM", 0, 16)
btnPing:SetText("Ping Server")
btnPing:SetScript("OnClick", function()
    statusText:SetText("|cffffff00Enviando ping al servidor...|r")
    AIO.Handle("AIOTest", "PingServer", time())
end)

-- ─── Handler: servidor responde con PongClient ────────────
function Handlers.ShowWindow(player)
    frame:Show()
end

function Handlers.PongClient(player, serverTime, playerName)
    local now = time()
    statusText:SetText(
        "|cff00ff00¡Pong recibido!\n|r" ..
        "|cffffffffServidor timestamp: " .. tostring(serverTime) .. "\n|r" ..
        "|cffadd8e6Jugador: " .. tostring(playerName) .. "|r"
    )
    print("[AIO Test] Pong recibido del servidor (server time: " .. tostring(serverTime) .. ")")
end

print("[AIO Test] Cliente cargado. Usa .aiotest para abrir la ventana.")

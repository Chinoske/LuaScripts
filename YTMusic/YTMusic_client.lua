-- YTMusic_client.lua — Client-side addon code for the YouTube Music URL helper.
-- AIO sends this file to the WoW client automatically; players do not install it manually.
-- The server script (YTMusic.lua) registers it via AIO.AddAddon().
--
-- WoW client version: 3.3.5a (Wrath of the Lich King)
-- Compatibility notes:
--   * SetColorTexture() is NOT available in 3.3.5a — use texture:SetTexture(r,g,b,a).
--   * Backdrop must be set with frame:SetBackdrop({}) directly (no XML templates).
--   * No emoji characters — the WotLK font does not support them.

-- If AIO.AddAddon() returns true we are on the server; skip all client code.
if AIO.AddAddon() then return end

-- Handler table for messages that the server sends to this client.
local YTMusicClient = AIO.AddHandlers("YTMusic", {})

-- The main frame is created lazily (only when ShowUI is first called).
local mainFrame = nil

-- URL that will be displayed in the EditBox.
local YTMUSIC_URL = "https://music.youtube.com/"

-- ---------------------------------------------------------------------------
-- CreateYTMusicFrame()
-- Builds the entire UI once and stores it in mainFrame.
-- ---------------------------------------------------------------------------
local function CreateYTMusicFrame()
    -- -----------------------------------------------------------------------
    -- Main frame
    -- -----------------------------------------------------------------------
    local f = CreateFrame("Frame", "YTMusicMainFrame", UIParent)
    f:SetSize(400, 270)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)
    f:SetFrameStrata("HIGH")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)

    -- Dark background with a red YouTube border.
    f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.07, 0.07, 0.07, 0.97)
    f:SetBackdropBorderColor(0.85, 0.1, 0.1, 1)

    -- -----------------------------------------------------------------------
    -- Header bar (red strip across the top, 38 px tall)
    -- -----------------------------------------------------------------------
    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetPoint("TOPLEFT",  f, "TOPLEFT",   4,  -4)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT",  -4, -4)
    header:SetHeight(38)
    -- SetTexture with RGBA values creates a solid color in WotLK.
    header:SetTexture(0.85, 0.1, 0.1, 1)

    -- Title text inside the header.
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", header, "LEFT", 12, 0)
    title:SetText("YouTube Music")
    title:SetTextColor(1, 1, 1, 1)

    -- -----------------------------------------------------------------------
    -- Close button (standard WoW panel close button)
    -- -----------------------------------------------------------------------
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- -----------------------------------------------------------------------
    -- Separator line below the header
    -- -----------------------------------------------------------------------
    local separator = f:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("TOPLEFT",  f, "TOPLEFT",   4, -42)
    separator:SetPoint("TOPRIGHT", f, "TOPRIGHT",  -4, -42)
    separator:SetHeight(1)
    separator:SetTexture(0.85, 0.1, 0.1, 0.6)

    -- -----------------------------------------------------------------------
    -- Instruction label above the URL box
    -- -----------------------------------------------------------------------
    local instrLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instrLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -58)
    instrLabel:SetText("Copy the link below and open it in your browser:")
    instrLabel:SetTextColor(0.75, 0.75, 0.75, 1)

    -- -----------------------------------------------------------------------
    -- URL EditBox container (gives the URL box a visible framed background)
    -- -----------------------------------------------------------------------
    local urlContainer = CreateFrame("Frame", nil, f)
    urlContainer:SetPoint("TOPLEFT",  f, "TOPLEFT",   16, -80)
    urlContainer:SetPoint("TOPRIGHT", f, "TOPRIGHT",  -16, -80)
    urlContainer:SetHeight(28)
    urlContainer:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile     = true,
        tileSize = 8,
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    urlContainer:SetBackdropColor(0.15, 0.15, 0.15, 1)
    urlContainer:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)

    -- EditBox inside the container.
    local urlBox = CreateFrame("EditBox", nil, urlContainer)
    urlBox:SetPoint("TOPLEFT",     urlContainer, "TOPLEFT",     6, -4)
    urlBox:SetPoint("BOTTOMRIGHT", urlContainer, "BOTTOMRIGHT", -6, 4)
    urlBox:SetFontObject("GameFontHighlight")
    urlBox:SetText(YTMUSIC_URL)
    urlBox:SetAutoFocus(false)
    urlBox:SetMaxLetters(0)
    urlBox:EnableMouse(true)

    -- Highlight all text when the box gains keyboard focus.
    urlBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    -- Allow mouse click inside the box to focus and select.
    urlBox:SetScript("OnMouseUp", function(self)
        self:SetFocus()
        self:HighlightText()
    end)

    -- Pressing Escape clears focus (does not close the frame).
    urlBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- Prevent the user from accidentally changing the URL text.
    urlBox:SetScript("OnTextChanged", function(self)
        local current = self:GetText()
        if current ~= YTMUSIC_URL then
            self:SetText(YTMUSIC_URL)
            self:HighlightText()
        end
    end)

    -- -----------------------------------------------------------------------
    -- "Select URL" button — focuses and highlights the EditBox
    -- -----------------------------------------------------------------------
    local selectBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    selectBtn:SetSize(175, 28)
    selectBtn:SetPoint("TOP", urlContainer, "BOTTOM", 0, -10)
    selectBtn:SetText("Select URL")
    selectBtn:SetScript("OnClick", function()
        urlBox:SetFocus()
        urlBox:HighlightText()
    end)

    -- -----------------------------------------------------------------------
    -- Step-by-step instructions panel
    -- -----------------------------------------------------------------------
    local stepsContainer = CreateFrame("Frame", nil, f)
    stepsContainer:SetPoint("TOPLEFT",  f, "TOPLEFT",   16, -160)
    stepsContainer:SetPoint("TOPRIGHT", f, "TOPRIGHT",  -16, -160)
    stepsContainer:SetHeight(72)
    stepsContainer:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile     = true,
        tileSize = 8,
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    stepsContainer:SetBackdropColor(0.1, 0.1, 0.1, 1)
    stepsContainer:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    local stepsText = stepsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stepsText:SetPoint("TOPLEFT",     stepsContainer, "TOPLEFT",     10, -8)
    stepsText:SetPoint("BOTTOMRIGHT", stepsContainer, "BOTTOMRIGHT", -10, 8)
    stepsText:SetJustifyH("LEFT")
    stepsText:SetJustifyV("TOP")
    stepsText:SetTextColor(0.8, 0.8, 0.8, 1)
    stepsText:SetText(
        "1. Click the URL field above\n" ..
        "2. Press Ctrl+A to select all\n" ..
        "3. Press Ctrl+C to copy\n" ..
        "4. Paste in your browser (Ctrl+V)"
    )

    -- -----------------------------------------------------------------------
    -- Footer hint
    -- -----------------------------------------------------------------------
    local footer = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footer:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    footer:SetText("Type /ytmusic to open this window")
    footer:SetTextColor(0.5, 0.5, 0.5, 1)

    -- Hide by default; ShowUI will call f:Show().
    f:Hide()

    return f
end

-- ---------------------------------------------------------------------------
-- Local helper: opens the frame (used by both slash command and AIO handler)
-- ---------------------------------------------------------------------------
local function OpenFrame()
    if not mainFrame then
        mainFrame = CreateYTMusicFrame()
    end
    mainFrame:Show()
    mainFrame:Raise()
end

-- ---------------------------------------------------------------------------
-- /ytmusic slash command — runs entirely client-side, no server round-trip
-- ---------------------------------------------------------------------------
SLASH_YTMUSIC1 = "/ytmusic"
SlashCmdList["YTMUSIC"] = function()
    OpenFrame()
end

-- ---------------------------------------------------------------------------
-- AIO handler — called by the server if needed
-- Signature: function(handler, player, ...)
-- ---------------------------------------------------------------------------
function YTMusicClient.ShowUI(handler, player)
    OpenFrame()
end

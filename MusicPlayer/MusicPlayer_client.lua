-- ============================================================
-- MusicPlayer_client.lua — Client-side WoW addon (3.3.5a)
-- Delivered via AIO v1.75 from the AzerothCore server.
-- ============================================================
-- HOW TO ADD SONGS:
--   Drop MP3/OGG files in  WoW/Interface/AddOns/MusicPlayer/music/
--   then add an entry to TRACKS below and reload the script on
--   the server (.reload ale) so AIO re-sends the updated addon.
-- ============================================================

-- If running on the server, register this file with AIO and stop.
if AIO.AddAddon() then return end

-- ─────────────────────────────────────────────────────────────
-- TRACK LIST — edit this table to add/remove songs
-- ─────────────────────────────────────────────────────────────
local TRACKS = {
    { name = "Track 01", artist = "Artist 1", file = "Interface/AddOns/MusicPlayer/music/track01.mp3", duration = 180 },
    { name = "Track 02", artist = "Artist 2", file = "Interface/AddOns/MusicPlayer/music/track02.mp3", duration = 210 },
    { name = "Track 03", artist = "Artist 3", file = "Interface/AddOns/MusicPlayer/music/track03.mp3", duration = 240 },
}

-- ─────────────────────────────────────────────────────────────
-- PLAYER STATE
-- ─────────────────────────────────────────────────────────────
local state = {
    current   = 1,
    playing   = false,
    startTime = 0,   -- GetTime() when Play/Resume was called
    elapsed   = 0,   -- seconds accumulated before the last pause
}

-- ─────────────────────────────────────────────────────────────
-- HELPER: elapsed seconds since track started (respects pauses)
-- ─────────────────────────────────────────────────────────────
local function GetElapsed()
    if state.playing then
        return state.elapsed + (GetTime() - state.startTime)
    end
    return state.elapsed
end

-- ─────────────────────────────────────────────────────────────
-- HELPER: "M:SS" formatter
-- ─────────────────────────────────────────────────────────────
local function FormatTime(secs)
    secs = math.floor(secs)
    if secs < 0 then secs = 0 end
    local m = math.floor(secs / 60)
    local s = secs % 60
    return string.format("%d:%02d", m, s)
end

-- ─────────────────────────────────────────────────────────────
-- FORWARD DECLARATIONS (UI references filled after frame creation)
-- ─────────────────────────────────────────────────────────────
local MusicPlayerFrame
local trackNameText, trackArtistText
local progressBarFill, timeText
local playPauseBtn
local playlistButtons = {}

-- ─────────────────────────────────────────────────────────────
-- CORE PLAYBACK FUNCTIONS
-- ─────────────────────────────────────────────────────────────
local function UpdatePlaylistHighlight()
    for i, btn in ipairs(playlistButtons) do
        if i == state.current then
            btn:GetFontString():SetTextColor(1, 1, 0)     -- yellow = active
        else
            btn:GetFontString():SetTextColor(0.8, 0.8, 0.8) -- grey
        end
    end
end

local function UpdateNowPlaying()
    local t = TRACKS[state.current]
    if not t then return end
    if trackNameText   then trackNameText:SetText(t.name)   end
    if trackArtistText then trackArtistText:SetText(t.artist) end
    UpdatePlaylistHighlight()
end

local function PlayTrack(index)
    if index < 1 then index = #TRACKS end
    if index > #TRACKS then index = 1 end
    state.current   = index
    state.playing   = true
    state.startTime = GetTime()
    state.elapsed   = 0
    StopMusic()
    PlayMusic(TRACKS[state.current].file)
    UpdateNowPlaying()
    if playPauseBtn then playPauseBtn:SetText("|| Pause") end
end

local function PauseTrack()
    if not state.playing then return end
    state.elapsed = GetElapsed()
    state.playing = false
    StopMusic()
    if playPauseBtn then playPauseBtn:SetText("|> Play") end
end

-- WoW 3.3.5a has no seek API, so Resume re-starts from the beginning.
local function ResumeTrack()
    if state.playing then return end
    state.elapsed   = 0
    state.startTime = GetTime()
    state.playing   = true
    PlayMusic(TRACKS[state.current].file)
    if playPauseBtn then playPauseBtn:SetText("|| Pause") end
end

local function NextTrack()
    local next = state.current + 1
    if next > #TRACKS then next = 1 end
    PlayTrack(next)
end

local function PrevTrack()
    local prev = state.current - 1
    if prev < 1 then prev = #TRACKS end
    PlayTrack(prev)
end

-- ─────────────────────────────────────────────────────────────
-- VOLUME HELPERS
-- ─────────────────────────────────────────────────────────────
local volumeText   -- forward ref filled below

local function GetVolume()
    return tonumber(GetCVar("Sound_MusicVolume")) or 0.8
end

local function SetVolume(v)
    if v < 0.0 then v = 0.0 end
    if v > 1.0 then v = 1.0 end
    v = math.floor(v * 10 + 0.5) / 10   -- snap to 0.1 steps
    SetCVar("Sound_MusicVolume", tostring(v))
    if volumeText then
        volumeText:SetText(math.floor(v * 100 + 0.5) .. "%")
    end
end

-- ─────────────────────────────────────────────────────────────
-- FRAME BUILDER
-- ─────────────────────────────────────────────────────────────
local function BuildFrame()
    if MusicPlayerFrame then
        MusicPlayerFrame:Show()
        return
    end

    -- ── MAIN FRAME ──────────────────────────────────────────
    local f = CreateFrame("Frame", "MusicPlayerFrame", UIParent)
    MusicPlayerFrame = f
    f:SetWidth(360)
    f:SetHeight(340)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("HIGH")
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    -- Background
    f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.06, 0.06, 0.06, 0.96)
    f:SetBackdropBorderColor(0.85, 0.1, 0.1, 1)

    -- ── HEADER ──────────────────────────────────────────────
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(38)
    header:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    header:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        tile   = true, tileSize = 16,
    })
    header:SetBackdropColor(0.85, 0.1, 0.1, 1)

    local headerIcon = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    headerIcon:SetPoint("LEFT", header, "LEFT", 8, 0)
    headerIcon:SetText("|> Music Player")
    headerIcon:SetTextColor(1, 1, 1)

    -- Close button (standard WoW style)
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Make header draggable too
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    -- ── NOW PLAYING ─────────────────────────────────────────
    local nowY = -52   -- below header

    trackNameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    trackNameText:SetPoint("TOP", f, "TOP", 0, nowY)
    trackNameText:SetWidth(320)
    trackNameText:SetJustifyH("CENTER")
    trackNameText:SetTextColor(1, 1, 1)
    trackNameText:SetText(TRACKS[1].name)

    trackArtistText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trackArtistText:SetPoint("TOP", trackNameText, "BOTTOM", 0, -4)
    trackArtistText:SetWidth(320)
    trackArtistText:SetJustifyH("CENTER")
    trackArtistText:SetTextColor(0.7, 0.7, 0.7)
    trackArtistText:SetText(TRACKS[1].artist)

    -- ── PROGRESS BAR ────────────────────────────────────────
    local barContainer = CreateFrame("Frame", nil, f)
    barContainer:SetPoint("TOPLEFT",  f, "TOPLEFT",  14, -108)
    barContainer:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -108)
    barContainer:SetHeight(12)
    barContainer:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        tile   = true, tileSize = 8,
    })
    barContainer:SetBackdropColor(0.15, 0.15, 0.15, 1)

    local fillTex = barContainer:CreateTexture(nil, "ARTWORK")
    fillTex:SetPoint("TOPLEFT",  barContainer, "TOPLEFT",  0, 0)
    fillTex:SetPoint("BOTTOMLEFT", barContainer, "BOTTOMLEFT", 0, 0)
    fillTex:SetWidth(1)   -- updated each frame via OnUpdate
    fillTex:SetTexture(0.85, 0.1, 0.1, 1)
    progressBarFill = fillTex

    timeText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("TOP", barContainer, "BOTTOM", 0, -4)
    timeText:SetTextColor(0.6, 0.6, 0.6)
    timeText:SetText("0:00 / " .. FormatTime(TRACKS[1].duration))

    -- ── TRANSPORT CONTROLS ──────────────────────────────────
    -- Row centered at y = -148 from top
    local ctrlY = -150

    -- Helper to create a transport button
    local function MakeBtn(label, w, xOff, onClick)
        local btn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
        btn:SetWidth(w)
        btn:SetHeight(28)
        btn:SetPoint("TOP", f, "TOP", xOff, ctrlY)
        btn:SetText(label)
        btn:SetScript("OnClick", onClick)
        return btn
    end

    -- [|<]  go to previous track
    MakeBtn("|<", 36, -120, function() PrevTrack() end)

    -- [<<]  if elapsed >= 5s restart track, else prev track
    MakeBtn("<<", 36, -76, function()
        if GetElapsed() >= 5 then
            PlayTrack(state.current)
        else
            PrevTrack()
        end
    end)

    -- [|> Play] / [|| Pause]
    playPauseBtn = MakeBtn("|> Play", 80, 0, function()
        if state.playing then
            PauseTrack()
        else
            if state.elapsed > 0 then
                ResumeTrack()
            else
                PlayTrack(state.current)
            end
        end
    end)

    -- [>>]  next track
    MakeBtn(">>", 36, 76, function() NextTrack() end)

    -- [>|]  next track (skip-to-end style)
    MakeBtn(">|", 36, 120, function() NextTrack() end)

    -- ── VOLUME CONTROL ──────────────────────────────────────
    local volY = -192

    local volLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    volLabel:SetPoint("TOP", f, "TOP", -60, volY)
    volLabel:SetTextColor(0.9, 0.9, 0.9)
    volLabel:SetText("Volume:")

    local volMinus = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    volMinus:SetWidth(28)
    volMinus:SetHeight(22)
    volMinus:SetPoint("TOP", f, "TOP", -10, volY)
    volMinus:SetText("-")
    volMinus:SetScript("OnClick", function() SetVolume(GetVolume() - 0.1) end)

    local volPlus = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    volPlus:SetWidth(28)
    volPlus:SetHeight(22)
    volPlus:SetPoint("TOP", f, "TOP", 22, volY)
    volPlus:SetText("+")
    volPlus:SetScript("OnClick", function() SetVolume(GetVolume() + 0.1) end)

    volumeText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    volumeText:SetPoint("TOP", f, "TOP", 60, volY)
    volumeText:SetTextColor(1, 1, 0)
    volumeText:SetText(math.floor(GetVolume() * 100 + 0.5) .. "%")

    -- ── PLAYLIST (scrollable) ────────────────────────────────
    local scrollFrame = CreateFrame("ScrollFrame", "MusicPlayerScrollFrame", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",  14, -222)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", "MusicPlayerScrollContent", scrollFrame)
    content:SetWidth(scrollFrame:GetWidth())
    local rowH = 22
    content:SetHeight(rowH * #TRACKS)
    scrollFrame:SetScrollChild(content)

    for i, track in ipairs(TRACKS) do
        local btn = CreateFrame("Button", nil, content)
        btn:SetHeight(rowH)
        btn:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -(i - 1) * rowH)
        btn:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(i - 1) * rowH)

        -- Hover highlight texture
        local hlTex = btn:CreateTexture(nil, "BACKGROUND")
        hlTex:SetAllPoints(btn)
        hlTex:SetTexture(1, 1, 1, 0)
        btn:SetHighlightTexture(hlTex)

        -- Label
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", btn, "LEFT", 6, 0)
        label:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        label:SetJustifyH("LEFT")
        label:SetText(i .. ". " .. track.name .. " -- " .. track.artist)

        -- Store ref so highlight can update it
        btn.GetFontString = function() return label end

        btn:SetScript("OnClick", function() PlayTrack(i) end)
        btn:SetScript("OnEnter", function()
            if i ~= state.current then label:SetTextColor(1, 1, 1) end
        end)
        btn:SetScript("OnLeave", function()
            if i == state.current then
                label:SetTextColor(1, 1, 0)
            else
                label:SetTextColor(0.8, 0.8, 0.8)
            end
        end)

        playlistButtons[i] = btn
    end

    -- Apply initial colors
    UpdatePlaylistHighlight()

    -- ── ONUPDATE TICKER ─────────────────────────────────────
    -- Uses a separate invisible frame to avoid touching the main frame's script.
    local ticker = CreateFrame("Frame")
    ticker:SetScript("OnUpdate", function()
        if not state.playing then return end

        local track    = TRACKS[state.current]
        local elapsed  = GetElapsed()
        local duration = track.duration

        -- Auto-advance to next track
        if elapsed >= duration then
            NextTrack()
            return
        end

        -- Progress bar fill: scale width to [0, barContainer width]
        local barW = barContainer:GetWidth()
        if barW and barW > 0 then
            local fillW = math.max(1, math.floor(barW * (elapsed / duration)))
            progressBarFill:SetWidth(fillW)
        end

        -- Time text
        if timeText then
            timeText:SetText(FormatTime(elapsed) .. " / " .. FormatTime(duration))
        end

        -- Play/pause button label sync
        if playPauseBtn then
            playPauseBtn:SetText("|| Pause")
        end
    end)

    f:Show()
end

-- ─────────────────────────────────────────────────────────────
-- PUBLIC OPEN FUNCTION
-- ─────────────────────────────────────────────────────────────
local function OpenFrame()
    BuildFrame()
    if MusicPlayerFrame then MusicPlayerFrame:Show() end
end

-- ─────────────────────────────────────────────────────────────
-- AIO CLIENT-SIDE HANDLER TABLE
-- ─────────────────────────────────────────────────────────────
local MusicPlayerClient = AIO.AddHandlers("MusicPlayer", {})

function MusicPlayerClient.ShowUI(handler, player)
    OpenFrame()
end

-- ─────────────────────────────────────────────────────────────
-- MINIMAP BUTTON
-- ─────────────────────────────────────────────────────────────
local minimapAngle = 220  -- degrees; drag to reposition

local function UpdateMinimapPos(btn)
    local rad = math.rad(minimapAngle)
    btn:SetPoint("CENTER", Minimap, "CENTER",
        80 * math.cos(rad),
        80 * math.sin(rad))
end

local minimapBtn = CreateFrame("Button", "MusicPlayerMinimapBtn", Minimap)
minimapBtn:SetSize(31, 31)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)

-- Small icon (17px) so it fits inside the circular border — same as native WoW minimap buttons
local icon = minimapBtn:CreateTexture(nil, "BACKGROUND")
icon:SetSize(17, 17)
icon:SetTexture("Interface/Icons/INV_Misc_Note_01")
icon:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)

-- Circular golden border (54px) on top — this is what makes it look round
local border = minimapBtn:CreateTexture(nil, "OVERLAY")
border:SetSize(54, 54)
border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
border:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)

-- Subtle glow on hover
minimapBtn:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")

UpdateMinimapPos(minimapBtn)

-- Drag around the minimap border
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        minimapAngle = math.deg(math.atan2((cy / s) - my, (cx / s) - mx))
        UpdateMinimapPos(self)
    end)
end)
minimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

-- Click: toggle player frame
minimapBtn:SetScript("OnClick", function()
    if MusicPlayerFrame and MusicPlayerFrame:IsShown() then
        MusicPlayerFrame:Hide()
    else
        OpenFrame()
    end
end)

-- Tooltip
minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Music Player")
    GameTooltip:AddLine("Click to toggle", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Drag to reposition", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- ─────────────────────────────────────────────────────────────
-- SLASH COMMANDS
-- ─────────────────────────────────────────────────────────────
SLASH_MUSICPLAYER1 = "/musicplayer"
SLASH_MUSICPLAYER2 = "/mp"
SlashCmdList["MUSICPLAYER"] = function(msg)
    OpenFrame()
end

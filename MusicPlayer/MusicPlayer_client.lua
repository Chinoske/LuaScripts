-- ============================================================
-- MusicPlayer_client.lua — Client-side WoW addon (3.3.5a)
-- Delivered via AIO v1.75 from the AzerothCore server.
-- Drop MP3/OGG files in:  WoW/Interface/AddOns/MusicPlayer/music/
-- The server scans the folder automatically on load.
-- ============================================================

if AIO.AddAddon() then return end

-- ─────────────────────────────────────────────────────────────
-- TRACK LIST — filled dynamically by the server via SetTracks
-- ─────────────────────────────────────────────────────────────
local TRACKS = {}

-- ─────────────────────────────────────────────────────────────
-- PLAYER STATE
-- ─────────────────────────────────────────────────────────────
local state = {
    current   = 1,
    playing   = false,
    startTime = 0,
    elapsed   = 0,
}

-- ─────────────────────────────────────────────────────────────
-- FORWARD REFS — filled after frame creation
-- ─────────────────────────────────────────────────────────────
local MusicPlayerFrame
local trackNameText, trackArtistText
local progressBarFill, timeText, barContainer
local playPauseBtn
local volumeText
local playlistContent, playlistScroll
local playlistButtons = {}

-- ─────────────────────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────────────────────
local function GetElapsed()
    if state.playing then
        return state.elapsed + (GetTime() - state.startTime)
    end
    return state.elapsed
end

local function FormatTime(secs)
    if not secs or secs <= 0 then return "0:00" end
    secs = math.floor(secs)
    return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

local function GetVolume()
    return tonumber(GetCVar("Sound_MusicVolume")) or 0.8
end

local function SetVolume(v)
    v = math.max(0.0, math.min(1.0, v))
    v = math.floor(v * 10 + 0.5) / 10
    SetCVar("Sound_MusicVolume", tostring(v))
    if volumeText then
        volumeText:SetText(math.floor(v * 100 + 0.5) .. "%")
    end
end

-- ─────────────────────────────────────────────────────────────
-- PLAYLIST HIGHLIGHT
-- ─────────────────────────────────────────────────────────────
local function UpdatePlaylistHighlight()
    for i, btn in ipairs(playlistButtons) do
        if btn:IsShown() then
            if i == state.current then
                btn:GetFontString():SetTextColor(1, 1, 0)
            else
                btn:GetFontString():SetTextColor(0.8, 0.8, 0.8)
            end
        end
    end
end

local function UpdateNowPlaying()
    local t = TRACKS[state.current]
    if not t then return end
    if trackNameText   then trackNameText:SetText(t.name)   end
    if trackArtistText then trackArtistText:SetText(t.artist) end
    if timeText then
        timeText:SetText("0:00 / " .. FormatTime(t.duration))
    end
    UpdatePlaylistHighlight()
end

-- ─────────────────────────────────────────────────────────────
-- PLAYBACK
-- ─────────────────────────────────────────────────────────────
local function PlayTrack(index)
    if not TRACKS[index] then return end
    state.current   = index
    state.playing   = true
    state.startTime = GetTime()
    state.elapsed   = 0

    -- Make sure music is enabled and audible
    SetCVar("Sound_EnableMusic", "1")
    if (tonumber(GetCVar("Sound_MusicVolume")) or 0) < 0.1 then
        SetCVar("Sound_MusicVolume", "0.7")
        if volumeText then volumeText:SetText("70%") end
    end

    local file = TRACKS[index].file
    print("[MusicPlayer] Playing: " .. file)
    StopMusic()
    PlayMusic(file)

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

local function ResumeTrack()
    if state.playing then return end
    state.elapsed   = 0
    state.startTime = GetTime()
    state.playing   = true
    PlayMusic(TRACKS[state.current].file)
    if playPauseBtn then playPauseBtn:SetText("|| Pause") end
end

local function NextTrack()
    if #TRACKS == 0 then return end
    PlayTrack((state.current % #TRACKS) + 1)
end

local function PrevTrack()
    if #TRACKS == 0 then return end
    PlayTrack(((state.current - 2) % #TRACKS) + 1)
end

-- ─────────────────────────────────────────────────────────────
-- REBUILD PLAYLIST (called on frame creation and after SetTracks)
-- ─────────────────────────────────────────────────────────────
local function RebuildPlaylist()
    if not playlistContent then return end

    local rowH = 22
    playlistContent:SetHeight(math.max(rowH, rowH * #TRACKS))

    -- Show/update existing buttons, create new ones if needed
    for i, track in ipairs(TRACKS) do
        local btn = playlistButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, playlistContent)
            btn:SetHeight(rowH)
            btn:SetPoint("TOPLEFT",  playlistContent, "TOPLEFT",  4, -(i-1)*rowH)
            btn:SetPoint("TOPRIGHT", playlistContent, "TOPRIGHT", -4, -(i-1)*rowH)

            local hl = btn:CreateTexture(nil, "BACKGROUND")
            hl:SetAllPoints()
            hl:SetTexture(1, 1, 1, 0.05)
            btn:SetHighlightTexture(hl)

            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("LEFT",  btn, "LEFT",  2, 0)
            lbl:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
            lbl:SetJustifyH("LEFT")
            btn.GetFontString = function() return lbl end

            btn:SetScript("OnEnter", function(self)
                if self._idx ~= state.current then
                    self:GetFontString():SetTextColor(1, 1, 1)
                end
            end)
            btn:SetScript("OnLeave", function(self)
                if self._idx == state.current then
                    self:GetFontString():SetTextColor(1, 1, 0)
                else
                    self:GetFontString():SetTextColor(0.8, 0.8, 0.8)
                end
            end)
            playlistButtons[i] = btn
        end

        btn._idx = i
        local dur = (track.duration and track.duration > 0)
            and ("  |cff666666[" .. FormatTime(track.duration) .. "]|r")
            or ""
        btn:GetFontString():SetText(
            "|cffcccccc" .. i .. ".|r  " .. track.name ..
            "  |cff888888— " .. track.artist .. "|r" .. dur
        )
        btn:SetScript("OnClick", function(self) PlayTrack(self._idx) end)
        btn:Show()
    end

    -- Hide unused buttons
    for i = #TRACKS + 1, #playlistButtons do
        playlistButtons[i]:Hide()
    end

    -- Empty state label
    if not playlistContent._emptyLbl then
        local lbl = playlistContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("CENTER", playlistContent, "CENTER", 0, 0)
        lbl:SetTextColor(0.5, 0.5, 0.5)
        lbl:SetJustifyH("CENTER")
        playlistContent._emptyLbl = lbl
    end
    if #TRACKS == 0 then
        playlistContent._emptyLbl:SetText(
            "No tracks found.\n" ..
            "Drop MP3/OGG files in:\n" ..
            "Interface/AddOns/MusicPlayer/music/\n" ..
            "then click  Rescan."
        )
        playlistContent._emptyLbl:Show()
    else
        playlistContent._emptyLbl:Hide()
    end

    UpdatePlaylistHighlight()
end

-- ─────────────────────────────────────────────────────────────
-- BUILD MAIN FRAME (called once, lazily)
-- ─────────────────────────────────────────────────────────────
local function BuildFrame()
    if MusicPlayerFrame then return end

    local f = CreateFrame("Frame", "MusicPlayerFrame", UIParent)
    MusicPlayerFrame = f
    f:SetSize(360, 340)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("HIGH")
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    f:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.06, 0.06, 0.06, 0.96)
    f:SetBackdropBorderColor(0.85, 0.1, 0.1, 1)

    -- Header
    local header = CreateFrame("Frame", nil, f)
    header:SetHeight(38)
    header:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
    header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    header:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 16 })
    header:SetBackdropColor(0.85, 0.1, 0.1, 1)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local titleLbl = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleLbl:SetPoint("LEFT", header, "LEFT", 10, 0)
    titleLbl:SetText("|> Music Player")
    titleLbl:SetTextColor(1, 1, 1)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Now Playing
    trackNameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    trackNameText:SetPoint("TOP", f, "TOP", 0, -52)
    trackNameText:SetWidth(320)
    trackNameText:SetJustifyH("CENTER")
    trackNameText:SetTextColor(1, 1, 1)
    trackNameText:SetText("No track loaded")

    trackArtistText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trackArtistText:SetPoint("TOP", trackNameText, "BOTTOM", 0, -4)
    trackArtistText:SetWidth(320)
    trackArtistText:SetJustifyH("CENTER")
    trackArtistText:SetTextColor(0.7, 0.7, 0.7)
    trackArtistText:SetText("—")

    -- Progress bar
    barContainer = CreateFrame("Frame", nil, f)
    barContainer:SetPoint("TOPLEFT",  f, "TOPLEFT",  14, -108)
    barContainer:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -108)
    barContainer:SetHeight(12)
    barContainer:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = true, tileSize = 8 })
    barContainer:SetBackdropColor(0.15, 0.15, 0.15, 1)

    progressBarFill = barContainer:CreateTexture(nil, "ARTWORK")
    progressBarFill:SetPoint("TOPLEFT",    barContainer, "TOPLEFT",    0, 0)
    progressBarFill:SetPoint("BOTTOMLEFT", barContainer, "BOTTOMLEFT", 0, 0)
    progressBarFill:SetWidth(1)
    progressBarFill:SetTexture(0.85, 0.1, 0.1, 1)

    timeText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("TOP", barContainer, "BOTTOM", 0, -3)
    timeText:SetTextColor(0.6, 0.6, 0.6)
    timeText:SetText("0:00 / 0:00")

    -- Transport controls
    local ctrlY = -150
    local function MakeBtn(label, w, xOff, onClick)
        local btn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
        btn:SetSize(w, 26)
        btn:SetPoint("TOP", f, "TOP", xOff, ctrlY)
        btn:SetText(label)
        btn:SetScript("OnClick", onClick)
        return btn
    end

    MakeBtn("|<", 34, -122, PrevTrack)
    MakeBtn("<<", 34, -80, function()
        if GetElapsed() >= 5 then PlayTrack(state.current) else PrevTrack() end
    end)
    playPauseBtn = MakeBtn("|> Play", 76, 0, function()
        if state.playing then
            PauseTrack()
        elseif state.elapsed > 0 then
            ResumeTrack()
        else
            PlayTrack(state.current)
        end
    end)
    MakeBtn(">>", 34, 80,  NextTrack)
    MakeBtn(">|", 34, 122, NextTrack)

    -- Volume
    local volY = -188
    local volLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    volLbl:SetPoint("TOP", f, "TOP", -58, volY)
    volLbl:SetTextColor(0.9, 0.9, 0.9)
    volLbl:SetText("Volume:")

    local volMinus = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    volMinus:SetSize(26, 22)
    volMinus:SetPoint("TOP", f, "TOP", -8, volY)
    volMinus:SetText("-")
    volMinus:SetScript("OnClick", function() SetVolume(GetVolume() - 0.1) end)

    local volPlus = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    volPlus:SetSize(26, 22)
    volPlus:SetPoint("TOP", f, "TOP", 20, volY)
    volPlus:SetText("+")
    volPlus:SetScript("OnClick", function() SetVolume(GetVolume() + 0.1) end)

    volumeText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    volumeText:SetPoint("TOP", f, "TOP", 58, volY)
    volumeText:SetTextColor(1, 1, 0)
    volumeText:SetText(math.floor(GetVolume() * 100 + 0.5) .. "%")

    -- Rescan button
    local rescanBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    rescanBtn:SetSize(70, 22)
    rescanBtn:SetPoint("TOP", f, "TOP", 132, volY)
    rescanBtn:SetText("Rescan")
    rescanBtn:SetScript("OnClick", function()
        rescanBtn:SetText("...")
        local msg = AIO.Msg():Add("MusicPlayer", "Rescan")
        msg:Send()
        C_Timer_After(1, function() rescanBtn:SetText("Rescan") end)
    end)

    -- Playlist scroll
    playlistScroll = CreateFrame("ScrollFrame", "MPScrollFrame", f, "UIPanelScrollFrameTemplate")
    playlistScroll:SetPoint("TOPLEFT",     f, "TOPLEFT",   14, -218)
    playlistScroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 10)

    playlistContent = CreateFrame("Frame", "MPScrollContent", playlistScroll)
    playlistContent:SetWidth(playlistScroll:GetWidth())
    playlistContent:SetHeight(1)
    playlistScroll:SetScrollChild(playlistContent)

    -- OnUpdate ticker (invisible frame)
    local ticker = CreateFrame("Frame")
    ticker:SetScript("OnUpdate", function()
        if not state.playing then return end
        local track = TRACKS[state.current]
        if not track then return end
        local elapsed  = GetElapsed()
        local duration = track.duration or 0

        -- Auto-advance
        if duration > 0 and elapsed >= duration then
            NextTrack()
            return
        end

        -- Progress bar
        if duration > 0 then
            local barW = barContainer:GetWidth()
            if barW and barW > 0 then
                progressBarFill:SetWidth(math.max(1, math.floor(barW * (elapsed / duration))))
            end
            if timeText then
                timeText:SetText(FormatTime(elapsed) .. " / " .. FormatTime(duration))
            end
        else
            if timeText then
                timeText:SetText(FormatTime(elapsed) .. " / --:--")
            end
        end
    end)

    -- Build playlist with whatever tracks we have at this point
    RebuildPlaylist()

    f:Show()
end

-- ─────────────────────────────────────────────────────────────
-- OPEN FRAME
-- ─────────────────────────────────────────────────────────────
local function OpenFrame()
    BuildFrame()
    MusicPlayerFrame:Show()
    MusicPlayerFrame:Raise()
end

-- ─────────────────────────────────────────────────────────────
-- AIO HANDLERS
-- ─────────────────────────────────────────────────────────────
local MusicPlayerClient = AIO.AddHandlers("MusicPlayer", {})

-- Server sends the full track list (on login and after rescan)
function MusicPlayerClient.SetTracks(handler, trackList)
    TRACKS = trackList or {}
    -- Reset playback if current track is now out of range
    if state.current > #TRACKS then
        state.current = 1
        PauseTrack()
        if trackNameText then
            trackNameText:SetText(#TRACKS > 0 and TRACKS[1].name or "No track loaded")
            trackArtistText:SetText(#TRACKS > 0 and TRACKS[1].artist or "—")
        end
    end
    RebuildPlaylist()
    if #TRACKS > 0 then
        print(string.format("[MusicPlayer] %d track(s) loaded.", #TRACKS))
    else
        print("[MusicPlayer] No tracks found. Drop MP3/OGG in Interface/AddOns/MusicPlayer/music/")
    end
end

function MusicPlayerClient.ShowUI(handler)
    OpenFrame()
end

-- ─────────────────────────────────────────────────────────────
-- MINIMAP BUTTON
-- ─────────────────────────────────────────────────────────────
local minimapAngle = 220

local function UpdateMinimapPos(btn)
    local rad = math.rad(minimapAngle)
    btn:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(rad), 80 * math.sin(rad))
end

local minimapBtn = CreateFrame("Button", "MusicPlayerMinimapBtn", Minimap)
minimapBtn:SetSize(31, 31)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)

local icon = minimapBtn:CreateTexture(nil, "BACKGROUND")
icon:SetSize(17, 17)
icon:SetTexture("Interface/Icons/INV_Misc_Note_01")
icon:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)

local border = minimapBtn:CreateTexture(nil, "OVERLAY")
border:SetSize(54, 54)
border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
border:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)

minimapBtn:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")

UpdateMinimapPos(minimapBtn)

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
minimapBtn:SetScript("OnClick", function()
    if MusicPlayerFrame and MusicPlayerFrame:IsShown() then
        MusicPlayerFrame:Hide()
    else
        OpenFrame()
    end
end)
minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Music Player")
    GameTooltip:AddLine(#TRACKS .. " track(s) loaded", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Click to toggle  |  Drag to move", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ─────────────────────────────────────────────────────────────
-- SLASH COMMANDS
-- ─────────────────────────────────────────────────────────────
SLASH_MUSICPLAYER1 = "/musicplayer"
SLASH_MUSICPLAYER2 = "/mp"
SlashCmdList["MUSICPLAYER"] = function() OpenFrame() end

-- ============================================================
-- MusicPlayer.lua — Server-side AIO script
-- AzerothCore + mod-ale (ALE) + AIO v1.75
-- ============================================================

local AIO = AIO or require("AIO")
if not AIO.IsMainState() then return end

AIO.AddAddon("lua_scripts/MusicPlayer_client.lua", "MusicPlayer")

-- ============================================================================
-- CONFIGURATION
-- MUSIC_FOLDER  : full path on THIS machine where you drop MP3/OGG files
-- WOW_MUSIC_PATH: path the WoW CLIENT uses to play those same files
-- ============================================================================
local MUSIC_FOLDER   = "C:/Users/guill/WoW/Interface/AddOns/MusicPlayer/music"
local WOW_MUSIC_PATH = "Interface/AddOns/MusicPlayer/music"
-- ============================================================================

-- ---------------------------------------------------------------------------
-- GetAudioDuration(filepath, ext)
-- Reads the MPEG frame header (MP3) or estimates from file size (OGG/fallback).
-- Returns duration in whole seconds.
-- ---------------------------------------------------------------------------
local function GetAudioDuration(filepath, ext)
    local f = io.open(filepath, "rb")
    if not f then return 0 end

    if ext == "mp3" then
        local header = f:read(10)
        if not header or #header < 10 then f:close(); return 0 end

        -- Skip ID3v2 tag (syncsafe integer size field)
        local id3_offset = 0
        if header:sub(1, 3) == "ID3" then
            local b7, b8, b9, b10 = header:byte(7, 10)
            id3_offset = 10 + ((b7 * 128 + b8) * 128 + b9) * 128 + b10
        end

        f:seek("set", id3_offset)
        local frame = f:read(4)
        local filesize = f:seek("end")
        f:close()

        if not frame or #frame < 4 then return 0 end

        local b1, b2, b3 = frame:byte(1, 3)

        -- MPEG sync: 0xFF + upper 3 bits of byte2 set
        if b1 ~= 0xFF or b2 < 0xE0 then
            return math.floor((filesize - id3_offset) / 16000) -- fallback 128kbps
        end

        -- Bitrate index = upper 4 bits of byte 3
        local br_idx  = math.floor(b3 / 16)
        local br_tbl  = {0,32,40,48,56,64,80,96,112,128,160,192,224,256,320,0}
        local bitrate = br_tbl[br_idx + 1] or 128
        if bitrate == 0 then bitrate = 128 end

        local audio_bytes = math.max(0, filesize - id3_offset)
        return math.floor(audio_bytes * 8 / (bitrate * 1000))
    end

    -- OGG / unknown: estimate at ~96 kbps
    local filesize = f:seek("end")
    f:close()
    return math.floor(filesize / 12000)
end

-- ---------------------------------------------------------------------------
-- ScanMusicFolder()
-- Lists MP3/OGG files, parses "Artist - Title" filenames, reads duration.
-- ---------------------------------------------------------------------------
local function ScanMusicFolder()
    local tracks = {}
    local handle = io.popen('dir "' .. MUSIC_FOLDER .. '" /b /a-d 2>NUL')
    if not handle then
        print("[MusicPlayer] ERROR: Cannot scan folder: " .. MUSIC_FOLDER)
        return tracks
    end
    for filename in handle:lines() do
        local ext = filename:match("%.([^%.]+)$")
        if ext and (ext:lower() == "mp3" or ext:lower() == "ogg") then
            local basename = filename:sub(1, -(#ext + 2))
            local artist, name = basename:match("^(.-)%s*%-%s*(.+)$")
            if not artist then
                artist = "Unknown"
                name   = basename:gsub("_", " ")
            end
            local duration = GetAudioDuration(MUSIC_FOLDER .. "/" .. filename, ext:lower())
            table.insert(tracks, {
                name     = name,
                artist   = artist,
                file     = WOW_MUSIC_PATH .. "/" .. filename,
                duration = duration,
            })
        end
    end
    handle:close()
    print(string.format("[MusicPlayer] %d track(s) found in: %s", #tracks, MUSIC_FOLDER))
    return tracks
end

-- Scan once at startup
local CACHED_TRACKS = ScanMusicFolder()

-- ---------------------------------------------------------------------------
-- Handlers (server-side, called by client)
-- ---------------------------------------------------------------------------
local MusicPlayerHandlers = AIO.AddHandlers("MusicPlayer", {})

-- Client requests a rescan (e.g. player dropped new files while server is up)
function MusicPlayerHandlers.Rescan(player)
    CACHED_TRACKS = ScanMusicFolder()
    AIO.Handle(player, "MusicPlayer", "SetTracks", CACHED_TRACKS)
end

-- ---------------------------------------------------------------------------
-- Send track list to every player on login (event 3 = ON_LOGIN)
-- ---------------------------------------------------------------------------
RegisterPlayerEvent(3, function(event, player)
    AIO.Handle(player, "MusicPlayer", "SetTracks", CACHED_TRACKS)
end)

print("[MusicPlayer] Loaded.")

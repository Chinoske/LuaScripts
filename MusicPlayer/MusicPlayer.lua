-- ============================================================
-- MusicPlayer.lua — Server-side AIO script
-- AzerothCore + mod-ale (ALE) + AIO v1.75
-- ============================================================

local AIO = AIO or require("AIO")

if not AIO.IsMainState() then return end

-- Register the client addon file so AIO sends it to every player on login.
AIO.AddAddon("lua_scripts/MusicPlayer/MusicPlayer_client.lua", "MusicPlayer")

-- Handler table (server-side handlers that the client can call).
-- Currently the player manages everything locally; the table is kept
-- empty but wired up so future server callbacks can be added here.
local MusicPlayerHandlers = AIO.AddHandlers("MusicPlayer", {})

-- Example: client sends  AIO.Msg():Add("MusicPlayer","ShowUI"):Send()
-- to request the server to push the UI open (useful for GM commands, etc.)
function MusicPlayerHandlers.ShowUI(player)
    if not player then return end
    AIO.Handle(player, "MusicPlayer", "ShowUI")
end

print("[MusicPlayer] Loaded.")

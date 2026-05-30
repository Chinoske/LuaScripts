-- YTMusic.lua — Server-side script for the YouTube Music URL helper.
-- Registers the addon client file for AIO distribution and handles the
-- .ytmusic chat command, which triggers the client UI.
--
-- Requirements:
--   * mod-ale (AzerothCore Lua Engine)
--   * AIO v1.75 server library at: lua_scripts/AIO_Server/AIO.lua
--   * AIO v1.75 client addon at:   WoW/Interface/AddOns/AIO_Client/
--   * YTMusic_client.lua in the same directory as this file
--
-- Reload without restart: .reload ale

local AIO = AIO or require("AIO")

-- AIO communication only works from the main Lua state.
if not AIO.IsMainState() then
    return
end

-- Register the client file so AIO sends it to players on login.
AIO.AddAddon("lua_scripts/YTMusic/YTMusic_client.lua", "YTMusic")

-- Server-side handler table. Currently empty — the server only
-- pushes the UI; no messages are expected back from the client.
local YTMusicHandlers = AIO.AddHandlers("YTMusic", {})

-- Listen for the .ytmusic player command (ON_COMMAND, event 42).
-- Returning false consumes the command so the server does not echo an error.
local function OnCommand(event, player, command)
    if command == "ytmusic" then
        AIO.Handle(player, "YTMusic", "ShowUI")
        return false
    end
    -- Return true to let other commands pass through normally.
    return true
end

RegisterPlayerEvent(42, OnCommand)

print("[YTMusic] Loaded.")

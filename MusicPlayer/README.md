# MusicPlayer — AzerothCore WotLK 3.3.5a
A server-delivered in-game music player built with mod-ale (ALE) + AIO v1.75.

---

## Requirements

| Component | Where |
|-----------|-------|
| AzerothCore 3.3.5a | Server |
| mod-ale (ALE) | Server module |
| AIO v1.75 | `lua_scripts/AIO_Server/` + `Interface/AddOns/AIO_Client/` |

AIO must already be installed and working before you install MusicPlayer.

---

## Server Installation

1. Copy the two Lua files to your server scripts folder:

```
server/lua_scripts/MusicPlayer/MusicPlayer.lua
server/lua_scripts/MusicPlayer/MusicPlayer_client.lua
```

2. Reload the Lua engine without restarting the worldserver:

```
.reload ale
```

You should see `[MusicPlayer] Loaded.` in the worldserver console.

---

## Client Installation (optional — zero-install by default)

AIO automatically delivers `MusicPlayer_client.lua` to every player on login.
Players do **not** need to install any addon manually.

However, music files must exist on the **player's own PC** at:

```
World of Warcraft/Interface/AddOns/MusicPlayer/music/
```

Create that folder if it does not exist. Place your `.mp3` or `.ogg` files there.

---

## Adding Songs

### Step 1 — Put the audio file on the client

Copy your file to:

```
WoW/Interface/AddOns/MusicPlayer/music/track04.mp3
```

### Step 2 — Register the track in the server script

Open `MusicPlayer_client.lua` and add an entry to the `TRACKS` table near the top:

```lua
local TRACKS = {
    { name="Track 01", artist="Artist 1", file="Interface/AddOns/MusicPlayer/music/track01.mp3", duration=180 },
    { name="Track 02", artist="Artist 2", file="Interface/AddOns/MusicPlayer/music/track02.mp3", duration=210 },
    { name="Track 03", artist="Artist 3", file="Interface/AddOns/MusicPlayer/music/track03.mp3", duration=240 },
    -- NEW:
    { name="Track 04", artist="Artist 4", file="Interface/AddOns/MusicPlayer/music/track04.mp3", duration=195 },
}
```

Fields:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name shown in the player UI |
| `artist` | string | Artist name shown below the track name |
| `file` | string | Path relative to the WoW root (use forward slashes) |
| `duration` | number | Track length **in seconds** — used for progress bar and auto-advance |

### Step 3 — Reload on the server

```
.reload ale
```

AIO will push the updated addon to players the next time they log in (or do `/reload`).

---

## In-Game Usage

Open the player with either slash command:

```
/musicplayer
/mp
```

### Controls

| Button | Action |
|--------|--------|
| `|<` | Jump to previous track |
| `<<` | Restart current track if more than 5 seconds in; otherwise go to previous track |
| `|> Play` / `|| Pause` | Toggle playback |
| `>>` | Skip to next track |
| `>|` | Skip to next track |
| `-` / `+` | Decrease / increase music volume by 10% |

Click any track in the playlist to play it immediately.

The player auto-advances to the next track when the current one reaches its duration.

---

## Notes on WoW 3.3.5a Audio API

- `PlayMusic(path)` starts a music file from the beginning. There is no seek.
- "Resume" after pause restarts the track from the beginning — this is a WoW API limitation.
- Volume is controlled via the `Sound_MusicVolume` CVar (range 0.0 to 1.0).
- Supported formats: `.mp3` and `.ogg`.

---

## File Layout Summary

```
Server:
  lua_scripts/
    MusicPlayer/
      MusicPlayer.lua            <- server entry point (AIO registration)
      MusicPlayer_client.lua     <- client addon code (edit TRACKS here)

Client (each player's PC):
  Interface/
    AddOns/
      MusicPlayer/
        music/
          track01.mp3            <- your audio files go here
          track02.mp3
          ...
```

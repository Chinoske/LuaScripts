# YTMusic — YouTube Music URL Helper for AzerothCore

A lightweight AIO addon that shows players a styled in-game window containing
the YouTube Music URL (`https://music.youtube.com/`) so they can copy it and
open it in their browser. WoW's sandbox prevents opening URLs directly, so the
window gives players a one-click-to-select EditBox and step-by-step copy
instructions.

---

## Requirements

| Component | Version |
|-----------|---------|
| AzerothCore | 3.3.5a (WotLK) |
| mod-ale (AzerothCore Lua Engine) | any current build |
| AIO | v1.75 |

AIO must already be installed:
- Server library: `lua_scripts/AIO_Server/AIO.lua` (and its dependencies)
- Client addon: `WoW/Interface/AddOns/AIO_Client/` (and its dependencies)

---

## Installation

1. Copy both Lua files into your server's `lua_scripts/` directory, keeping
   the `YTMusic/` subfolder:

   ```
   lua_scripts/YTMusic/YTMusic.lua
   lua_scripts/YTMusic/YTMusic_client.lua
   ```

2. Reload the Lua engine without restarting the worldserver:

   ```
   .reload ale
   ```

   The server will register `YTMusic_client.lua` as an AIO addon. Players who
   are already online will receive the addon on their next `/reload` or relog.
   Players who log in after `.reload ale` receive it automatically.

---

## Usage

Type the following command in any chat channel while in-game:

```
.ytmusic
```

A window will appear with:
- An EditBox pre-filled with `https://music.youtube.com/`
- A **Select URL** button that focuses and highlights the box
- Step-by-step instructions for copying and pasting the URL

### How to copy the URL

1. Click the URL field (or press **Select URL**) — the text is highlighted.
2. Press **Ctrl+A** to make sure everything is selected.
3. Press **Ctrl+C** to copy.
4. Switch to your browser and press **Ctrl+V** to paste.

The window is movable (drag the header) and closes with the X button or the
standard Escape key binding.

---

## File Overview

| File | Side | Purpose |
|------|------|---------|
| `YTMusic.lua` | Server | Loads AIO, registers the client addon, handles `.ytmusic` command |
| `YTMusic_client.lua` | Client (via AIO) | Builds and displays the UI frame |

# AIO HelloTest

Test script to verify that **AIO v1.75** works correctly with **mod-ale** on AzerothCore WotLK 3.3.5a.

---

## Purpose

Confirms that server → client and client → server communication is working after installing AIO. Opens a window on the client with a **Ping Server** button that replies with the server timestamp.

---

## Requirements

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)
- [AIO v1.75](https://github.com/Rochet2/AIO) — server at `lua_scripts/AIO_Server/`, client at `WoW/Interface/AddOns/AIO_Client/`

---

## Installation

```
AIO_HelloTest.lua  →  <server>/lua_scripts/
.reload ale
```

---

## Usage

Type in the in-game chat:
```
.aiotest
```

A window will appear with the text **"¡AIO funciona con mod-ale!"** and a **Ping Server** button. Clicking it sends a ping to the server — if a response appears with the server timestamp, AIO is working correctly.

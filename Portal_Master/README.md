# Portal Master NPC

Teleportation NPC for **AzerothCore WotLK 3.3.5a** with **mod-ale (AzerothCore Lua Engine)**.

All gossip logic, faction conditions, level requirements and teleports are handled 100% in Lua — no `gossip_menu`, `gossip_menu_option`, `conditions` or `smart_scripts` needed in the database.

---

## Features

- 131 teleport destinations across all expansions
- **Capital cities** — Stormwind, Orgrimmar, Ironforge, Darnassus, Exodar, Thunder Bluff, Undercity, Silvermoon City, Dalaran, Shattrath, Booty Bay, Gurubashi Arena
- **Classic Dungeons** — 19 instances
- **Burning Crusade Dungeons** — 6 instances
- **Wrath of the Lich King Dungeons** — 12 instances
- **Raids** — 22 raids (Classic through WotLK)
- **Eastern Kingdoms zones** — 24 locations
- **Kalimdor zones** — 19 locations
- **Outland zones** — 7 locations
- **Northrend zones** — 10 locations
- **GM Island** — restricted to GM rank ≥ 1 (invisible to regular players)
- Unique texture icons per destination (`|TInterface/ICONS/...|t`)
- Faction & level filtering (destinations hidden if requirements not met)

---

## Files

| File | Description |
|------|-------------|
| `Portal_Master.lua` | Main script — gossip, teleport logic, all destinations + auto-registro en DB |

---

## Installation

```
Portal_Master.lua  →  <server>/lua_scripts/
```

Al cargar el script, registra automáticamente el NPC y sus 12 spawns en la base de datos si no existen.  
Si es la primera vez que se instala, reiniciar el servidor una vez para que el cache se actualice.

```
.reload ale
```

---

## NPC Details

| Field | Value |
|-------|-------|
| Entry | 190000 |
| Name | Portal Master |
| Subname | Teleporter |
| Model | 21572 (Human Mage) |
| Faction | 35 (Friendly to all) |
| Spawns | 12 locations (GUIDs 5001001–5001012) |

### Quick teleport to a spawn
```
.go creature 5001001   → Stormwind
.go creature 5001005   → Orgrimmar
.go creature 5001011   → Dalaran
```

---

## Configuration

All destinations are in the `DESTS` table in `Portal_Master.lua`.  
Each entry format: `{name, mapId, x, y, z, orientation, minLevel, faction, minGMRank}`

| Field | Description |
|-------|-------------|
| `faction` | `nil` = all, `0` = Alliance only, `1` = Horde only |
| `minLevel` | Minimum player level required (0 = no restriction) |
| `minGMRank` | `nil`/not set = all players, `1`+ = GM only |

---

## Requirements

- AzerothCore WotLK 3.3.5a
- [mod-ale (AzerothCore Lua Engine)](https://github.com/azerothcore/mod-ale)

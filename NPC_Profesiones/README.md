# NPC Profesiones

> **Original author:** pangolp (Walter Pagani)

NPC that maxes all professions to **450** for **AzerothCore WotLK 3.3.5a** with **mod-ale**.

Requires level 80 and the profession already learned from a trainer. Does not grant recipes.

---

## Professions covered

Alchemy · Skinning · Enchanting · Blacksmithing · Engineering · Inscription · Jewelcrafting · Mining · Leatherworking · Tailoring · Herbalism · Cooking · Fishing · First Aid

---

## Files

| File | Description |
|------|-------------|
| `npc_professions.lua` | NPC script (gossip + logic + auto DB registration) |

---

## Installation

```
npc_professions.lua  →  <server>/lua_scripts/
.reload ale
```

The script automatically registers the NPC in the database if it does not exist.  
On a fresh install, restart the server once after the first load to update the creature cache.

---

## NPC

| Field | Value |
|-------|-------|
| Entry | 200004 |
| Name | Oscar Isidro Parrilli |
| Subname | Profesiones 450 |
| Spawn | Northrend / Dalaran (map 571) |

---

## Requirements

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)

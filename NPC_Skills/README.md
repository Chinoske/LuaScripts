# NPC Skills

> **Original author:** pangolp (Walter Pagani)

NPC that maxes weapon skills to **400** for **AzerothCore WotLK 3.3.5a** with **mod-ale**.

Requires level 80 and the skill already learned from a trainer. Includes an "Learn all" button to max every available skill at once.

---

## Skills covered

Bows · Crossbows · Thrown · Daggers · Polearms · Maces · Two-handed Maces · Guns · One-handed Swords · Two-handed Swords · Wands · One-handed Axes · Two-handed Axes · Staves · Defense · Unarmed

---

## Files

| File | Description |
|------|-------------|
| `npc_skills.lua` | NPC script (gossip + logic + auto DB registration) |

---

## Installation

```
npc_skills.lua  →  <server>/lua_scripts/
.reload ale
```

The script automatically registers the NPC in the database if it does not exist.  
On a fresh install, restart the server once after the first load to update the creature cache.

---

## NPC

| Field | Value |
|-------|-------|
| Entry | 200005 |
| Name | René Favaloro |
| Subname | Skills: 400 |
| Spawn | Northrend / Dalaran (map 571) |

---

## Requirements

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)

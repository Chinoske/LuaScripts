# Quest Complete DK

> **Original author:** pangolp (Walter Pagani)

NPC that automatically completes all **Death Knight starting zone quests** for **AzerothCore WotLK 3.3.5a** with **mod-ale**.

Only available to DK characters who have not yet completed the starting chain. After completion, teleports the player to their capital city based on faction and race.

---

## Features

- Completes ~45 quests from the DK starting zone (Acherus / Scarlet Enclave)
- Detects faction (Alliance/Horde) and race to complete the final quest accordingly
- Automatically teleports to Stormwind (Alliance) or Orgrimmar (Horde)

---

## Files

| File | Description |
|------|-------------|
| `npc_misiones_dk.lua` | NPC script (gossip + logic + auto DB registration) |

---

## Installation

```
npc_misiones_dk.lua  →  <server>/lua_scripts/
.reload ale
```

The script automatically registers the NPC in the database if it does not exist.  
On a fresh install, restart the server once after the first load to update the creature cache.

---

## NPC

| Field | Value |
|-------|-------|
| Entry | 200000 |
| Name | The Lich King |
| Subname | Completar misiones dk |
| Spawn | Acherus (map 609) |

---

## Requirements

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)

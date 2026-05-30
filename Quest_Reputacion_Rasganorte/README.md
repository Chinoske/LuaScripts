# Quest Reputacion Rasganorte

> **Original author:** pangolp (Walter Pagani)

NPC that raises key Northrend reputations to **Exalted** for **AzerothCore WotLK 3.3.5a** with **mod-ale**.

Requires level 80. Available for both Alliance and Horde with faction-specific options.

---

## Reputations covered

| Faction | Method |
|---------|--------|
| **Knights of the Ebon Blade** | Completes quest chain (different per faction) |
| **Kirin Tor** | Sets directly to Exalted |
| **The Wyrmrest Accord** | Sets directly to Exalted |
| **The Ashen Verdict** | Sets directly to Exalted |
| **The Sons of Hodir** | Completes quest chain |
| **Argent Crusade** | Sets directly to Exalted |

---

## Files

| File | Description |
|------|-------------|
| `npc_misiones_rasganorte.lua` | NPC script (gossip + logic + auto DB registration) |

---

## Installation

```
npc_misiones_rasganorte.lua  →  <server>/lua_scripts/
.reload ale
```

The script automatically registers the NPC in the database if it does not exist.  
On a fresh install, restart the server once after the first load to update the creature cache.

---

## NPC

| Field | Value |
|-------|-------|
| Entry | 200003 |
| Name | Jaime Stiuso |
| Subname | Reputaciones Rasganorte |
| Spawn | Northrend / Dalaran (map 571) |

---

## Requirements

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)

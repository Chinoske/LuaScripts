# Scarlet Enclave — Death Knight Starting Zone

Full Lua reimplementation of the **Death Knight starting zone** for **AzerothCore WotLK 3.3.5a** with **[mod-ale](https://github.com/azerothcore/mod-ale)**.

Reimplements the original AzerothCore C++ scripts in Lua:  
`zone_the_scarlet_enclave.cpp` · `chapter1.cpp` · `chapter2.cpp` · `chapter3.cpp` · `chapter5.cpp`

---

## Content

### Chapter 1 — Acherus: The Ebon Hold
| NPC | Behavior |
|-----|----------|
| **Val'kyr Battle-Maiden** | Revives the DK on death — multi-phase aerial sequence |
| **Scarlet Ghoul** | Interaction with Gothik DKC1 |
| **Gothik DKC1** | Raising ritual in Acherus |
| **The Lich King** | 16 random whispers throughout the zone |

### Chapter 2 — The Grand Offensive
| NPC | Behavior |
|-----|----------|
| **Koltira Deathweaver** | Full breakout sequence with Scarlet Crusader waves + Valroth |
| **Scarlet Courier** | Hides behind a tree and ambushes the player |
| **A Special Surprise** | 10 hometown NPCs recognize and speak to the DK (Ellen Stanbridge, Kug Ironjaw, etc.) |
| **Acherus Necromancer** | Corpse-raising ritual |
| **Gothik the Harvester** | Harvesting ritual with animations |
| **Persuasive Strike** | Quest *How to Win Friends and Influence Enemies* |

### Chapter 3 — An End to All Things
| NPC | Behavior |
|-----|----------|
| **Hearthglen / Tirisfal Crusader** | Devour Humanoid — DK devours the crusaders |

### Chapter 5 — The Light of Dawn
| Event | Description |
|-------|-------------|
| **Intro** | Highlord Darion Mograine rallies the forces |
| **Battle** | Abominations, Ghouls and Warriors of the Frozen Wastes vs Defenders of the Light |
| **Countdown** | Full countdown with dialogue lines |
| **Outro** | Tirion Fordring arrives, Alexandros Mograine appears, Darion surrenders the Ashbringer |
| **Return to Capital** | Stormwind / Orgrimmar guards insult the arriving DK |

---

## Installation

```
scarlet_enclave_dk.lua  →  <server>/lua_scripts/
.reload ale
```

> No database changes required.

---

## NPCs covered

| Entry | Name |
|-------|------|
| 24536 | Val'kyr Battle-Maiden |
| 28658 | Gothik DKC1 |
| 28845 | Scarlet Ghoul |
| 28889 | Acherus Necromancer |
| 28890 | Gothik the Harvester |
| 28912 | Koltira Deathweaver |
| 29001 | High Inquisitor Valroth |
| 29053 | Plaguefist |
| 29061–29074 | A Special Surprise NPCs (10 NPCs) |
| 29076 | Scarlet Courier |
| 29102–29103 | Hearthglen / Tirisfal Crusader |
| 29173 | Highlord Darion Mograine |
| 29174–29182 | Defenders of the Light + Champions |
| 29175 | Highlord Tirion Fordring |
| 29186–29219 | Acherus forces (abominations, ghouls, warriors) |

---

## Requirements

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)
- The DK starting zone must be enabled on the server

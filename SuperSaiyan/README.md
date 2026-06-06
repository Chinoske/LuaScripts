# SuperSaiyan

Dual Ki + resurrection system for **AzerothCore WotLK 3.3.5a** with **mod-ale**.

Accumulate Ki in combat and trigger a 14-second cinematic Super Saiyan transformation. Die and a Val'kyr will appear over your corpse, deliver an epic dialogue sequence, and resurrect you with 30% health.

---

## Features

**Super Saiyan System**
- Ki builds up by killing enemies, dealing damage, and taking damage
- Transformation triggers **automatically** when Ki reaches 100
- 5-phase cinematic sequence (14 seconds): Awakening → First Energy → Acceleration → Climax → Transformation
- While transformed: stats x10, speed x1.5, damage x2, healing x1.5, GM visual gear, golden hair
- Ki drains 5/sec during transformation; exit sequence plays when Ki hits 0
- 60-second cooldown between transformations

**Val'kyr Resurrection System**
- Upon death, a Val'kyr spawns above the death location
- 10-second epic dialogue sequence (5 lines of speech)
- Resurrects the player with 30% health
- 5-minute cooldown between resurrections

---

## Files

| File | Description |
|------|-------------|
| `SuperSaiyan.lua` | Main script — Super Saiyan Ki system + Val'kyr resurrection |

---

## Installation

```
SuperSaiyan.lua  →  <server>/lua_scripts/
```

```
.reload ale
```

No SQL or additional configuration required.

---

## Commands

### Super Saiyan Commands (GM)

| Command | Description |
|---------|-------------|
| `.saiyan on` | Force transformation for testing (sets Ki to 100) |
| `.saiyan off` | Cancel active transformation |
| `.saiyan status` | Show current Ki and transformation state |
| `.saiyan reset` | Reset Ki to 0 |
| `.saiyan hair <N>` | Test hair color index N (0–12) live |

### Val'kyr Commands (GM)

| Command | Description |
|---------|-------------|
| `.valkyr` | Trigger Val'kyr resurrection sequence (test) |
| `.valkyr reset` | Reset Val'kyr cooldown |

---

## Configuration

All settings are in the `CFG` table at the top of `SuperSaiyan.lua`.

### Ki Settings

| Field | Default | Description |
|-------|---------|-------------|
| `KI_MAX` | `100` | Ki required to trigger transformation |
| `KI_PER_KILL` | `10` | Ki gained per kill |
| `KI_PER_DAMAGE_TAKEN` | `5` | Ki gained per hit received |
| `KI_PER_DAMAGE_DEALT` | `2` | Ki gained per hit dealt |
| `KI_DRAIN_PER_SECOND` | `5` | Ki drained per second while transformed |
| `TRANSFORM_COOLDOWN` | `60` | Seconds between transformations |

### Multipliers

| Field | Default | Description |
|-------|---------|-------------|
| `SPEED_MULTIPLIER` | `1.5` | Run speed multiplier while transformed |
| `DAMAGE_MULTIPLIER` | `2.0` | Damage dealt multiplier while transformed |
| `HEAL_MULTIPLIER` | `1.5` | Healing received multiplier while transformed |
| `STAT_MULTIPLIER` | `10` | All stats multiplier (Str/Agi/Sta/Int/Spi) while transformed |

### Visual Aura Spell IDs

| Field | Default | Description |
|-------|---------|-------------|
| `AURA_SPELL_SURGE` | `57819` | Layer 1 — energy column |
| `AURA_SPELL_RADIANT` | `24018` | Layer 2 — radiant circular glow |
| `AURA_SPELL_SWIRL` | `34477` | Layer 3 — orbital particles |
| `AURA_SPELL_POWER` | `20375` | Persistent aura re-applied every 300 ms |
| `LIGHTNING_SPELL_2` | `63494` | Lightning visual during sequence |
| `HURRICANE_SPELL` | `16914` | Hurricane channeling during build-up |
| `EARTHQUAKE_SPELL` | `42499` | Shockwave effect during climax |

### GM Gear (equipped during transformation)

| Field | Default | Description |
|-------|---------|-------------|
| `SS_GEAR_HEAD` | `12064` | GM Hood (slot 0 — head) |
| `SS_GEAR_CHEST` | `2586` | GM Robe (slot 4 — chest) |
| `SS_GEAR_FEET` | `11508` | GM Slipper (slot 7 — feet) |

### Hair Settings (Human Male defaults)

| Field | Default | Description |
|-------|---------|-------------|
| `SS_HAIR_STYLE` | `13` | Hair style index (13 = spiky) |
| `SS_HAIR_COLOR` | `5` | Hair color while transformed (5 = golden blonde) |
| `SS_HAIR_COLOR_NORMAL` | `0` | Hair color restored after transformation (0 = black) |

### Val'kyr Settings (`CFG_SH` table)

| Field | Default | Description |
|-------|---------|-------------|
| `NPC_ENTRY` | `38392` | Val'kyr NPC entry ID |
| `COOLDOWN` | `300` | Seconds between resurrections |
| `HEALTH_PCT` | `30` | Player health % on resurrection |
| `SPAWN_Z_OFFSET` | `3` | Height above death position |
| `SPAWN_SCALE` | `3.0` | Val'kyr visual scale |

---

## Requirements

- AzerothCore WotLK 3.3.5a
- [mod-ale (AzerothCore Lua Engine)](https://github.com/azerothcore/mod-ale)

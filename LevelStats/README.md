# LevelStats

Random stat bonus on level up for **AzerothCore WotLK 3.3.5a** with **[mod-ale](https://github.com/azerothcore/mod-ale)**.

Adapted for mod-ale from the original by [Brytenwally (Eluna)](https://github.com/Brytenwally/LevelStats).

---

## How it works

Every time a player levels up, a random stat is chosen and a cumulative bonus is granted:

| Stat | Spell (stackable aura) | Color |
|------|------------------------|-------|
| Strength  | Blessing of Might (7464)   | 🔴 Red    |
| Agility   | Blessing of Agility (7471) | 🟢 Green  |
| Stamina   | Blessing of Stamina (7477) | ⚪ White  |
| Intellect | Blessing of Wisdom (7468)  | 🔵 Blue   |
| Spirit    | Blessing of Spirit (7474)  | 🟡 Yellow |

- Bonuses are stored cumulatively in the database (`custom_level_stats`).
- On login, all bonuses are automatically reapplied as stackable auras.
- Use `.bonus` to view your total bonuses or those of a selected player.

### Bulk level jumps

If a player jumps from level 1 to 80 all at once (GM command or any other method), the system applies **one roll per level gained** — none are lost.

- Normal level-up (1 level): shows the stat gained on screen.
- Bulk jump (multiple levels): shows a summary and suggests using `.bonus`.

---

## Installation

```
LevelStats.lua  →  <server>/lua_scripts/
.reload ale
```

> The `custom_level_stats` table is created automatically in `acore_characters` on first load.

---

## Configuration

Edit the `Config` block at the top of `LevelStats.lua`:

| Variable | Description | Default |
|----------|-------------|---------|
| `MinAmount` | Minimum bonus per level | `1` |
| `MaxAmount` | Maximum bonus per level | `5` |
| `SyncDelayMs` | Delay after level-up before reapplying auras (ms) | `500` |
| `LoginDelayMs` | Delay after login before reapplying auras (ms) | `1200` |
| `DebugEnabled` | Enable debug messages in server console | `false` |

---

## Commands

| Command | Description |
|---------|-------------|
| `.bonus` | Show your accumulated bonuses |
| `.bonus` (with player selected) | Show the selected player's bonuses |

---

## Files

| File | Description |
|------|-------------|
| `LevelStats.lua` | Main script (auto-creates the DB table on load) |
| `LevelStats_db.sql` | SQL reference (optional — the script creates it automatically) |

---

## Requirements

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)

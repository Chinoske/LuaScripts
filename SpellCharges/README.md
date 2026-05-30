# SpellCharges

> **Original author:** Crow (crow0385)

Spell charge system for **AzerothCore WotLK 3.3.5a** with **mod-ale** + **AIO v1.75**.

Assigns a maximum number of charges to any spell. Charges recharge automatically on a configurable cooldown and are displayed on the client's action bar in real time.

---

## How it works

- Configure which spells have charges, how many, and the recharge time in the database.
- Casting a spell consumes one charge. If no charges are available, the cast is cancelled.
- Charges recover automatically after the configured cooldown.
- Spell ranks can share the same charge pool via `group_id`.
- The action bar shows remaining charges and recharge cooldown in real time (AIO addon).

---

## Files

| File | Description |
|------|-------------|
| `spell_charges.lua` | Server script — charge logic, events, timers, AIO communication |
| `spell_charges_client.lua` | Client addon (auto-sent via AIO) — updates action bars |
| `spell_charges.sql` | Spell configuration table in `acore_world` |

---

## Requirements

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)
- [AIO v1.75](https://github.com/Rochet2/AIO) — server at `lua_scripts/AIO_Server/`, client at `WoW/Interface/AddOns/AIO_Client/`

---

## Installation

### 1. Install AIO (if not already installed)
```
AIO_Server/  →  <server>/lua_scripts/AIO_Server/
AIO_Client/  →  WoW/Interface/AddOns/AIO_Client/
```

### 2. Apply the SQL to acore_world
```bash
mysql -u acore -p acore_world < spell_charges.sql
```

### 3. Configure spells
Edit `spell_charges.sql` or insert directly into the table:
```sql
INSERT INTO `spell_charges_spells` (`spell_id`, `group_id`, `max_charges`, `base_cooldown`)
VALUES
  (1953, 0, 2, 15000)  -- Blink: 2 charges, 15s recharge
ON DUPLICATE KEY UPDATE
  `group_id` = VALUES(`group_id`),
  `max_charges` = VALUES(`max_charges`),
  `base_cooldown` = VALUES(`base_cooldown`);
```

### 4. Copy the Lua scripts
```
spell_charges.lua        →  <server>/lua_scripts/
spell_charges_client.lua →  <server>/lua_scripts/
```

### 5. Reload
```
.reload ale
```

---

## Table `spell_charges_spells`

| Column | Type | Description |
|--------|------|-------------|
| `spell_id` | INT UNSIGNED | Spell ID (Spell.dbc) |
| `group_id` | INT UNSIGNED | `0` = own pool · same value = shared pool across ranks |
| `max_charges` | TINYINT UNSIGNED | Maximum charges (minimum 2) |
| `base_cooldown` | INT UNSIGNED | Recharge time per charge **in milliseconds** |

---

## Included SQL examples

| Spell | group_id | Charges | Recharge |
|-------|----------|---------|----------|
| Heroism / Bloodlust (shared pool) | 32182 | 2 | 5 min |
| Flash Heal (all ranks) | 2061 | 3 | 8 s |
| Shield Bash (all ranks) | 72 | 2 | 12 s |
| Blink | 0 (own) | 2 | 15 s |

---

## GM command

```
.spellcharges reset
```
Resets the current player's charges to maximum (requires GM rank 3).

---

## Client command

```
/spellcharges
```
Shows in chat how many tracked spells the client knows and how many action bar buttons are active.

---

## Notes

- Charges are kept in server memory. A server restart resets them to maximum.
- After 15 minutes offline, charges are recalculated automatically based on elapsed time.
- The client addon is distributed automatically via AIO — players do not need to install anything.

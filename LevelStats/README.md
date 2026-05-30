# LevelStats

Bonus de estadísticas aleatorio al subir de nivel para **AzerothCore WotLK 3.3.5a** con **[mod-ale](https://github.com/azerothcore/mod-ale)**.

Adaptado para mod-ale a partir del original de [Brytenwally (Eluna)](https://github.com/Brytenwally/LevelStats).

---

## ¿Cómo funciona?

Cada vez que un jugador sube de nivel, el sistema elige **aleatoriamente** una de las 5 estadísticas principales y concede un bonus acumulativo:

| Estadística | Spell (aura stackable) | Color |
|-------------|------------------------|-------|
| Strength    | Blessing of Might (7464) | 🔴 Rojo |
| Agility     | Blessing of Agility (7471) | 🟢 Verde |
| Stamina     | Blessing of Stamina (7477) | ⚪ Blanco |
| Intellect   | Blessing of Wisdom (7468) | 🔵 Azul |
| Spirit      | Blessing of Spirit (7474) | 🟡 Amarillo |

- El bonus se guarda de forma acumulativa en la base de datos (`custom_level_stats`).
- Al hacer login, todos los bonuses se reaplicán automáticamente como auras stackables.
- Comando `.bonus` para ver los bonuses propios o los del jugador seleccionado.

---

## Instalación

### 1. Crear la tabla en la base de datos de personajes
```bash
mysql -u acore -p acore_characters < LevelStats_db.sql
```

### 2. Copiar el script Lua
```
LevelStats.lua  →  <server>/lua_scripts/
```

### 3. Recargar en la consola del worldserver
```
.reload ale
```

---

## Configuración

Edita el bloque `Config` al inicio de `LevelStats.lua`:

| Variable | Descripción | Default |
|----------|-------------|---------|
| `MinAmount` | Bonus mínimo por nivel | `1` |
| `MaxAmount` | Bonus máximo por nivel | `5` |
| `SyncDelayMs` | Delay tras subir de nivel antes de reaplicar auras (ms) | `500` |
| `LoginDelayMs` | Delay tras login antes de reaplicar auras (ms) | `1200` |
| `DebugEnabled` | Activa mensajes de debug en consola | `false` |

---

## Comandos

| Comando | Descripción |
|---------|-------------|
| `.bonus` | Muestra tus bonuses acumulados |
| `.bonus` (con jugador seleccionado) | Muestra los bonuses del jugador seleccionado |

---

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `LevelStats.lua` | Script principal |
| `LevelStats_db.sql` | Tabla `custom_level_stats` en `acore_characters` |

---

## Requisitos

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)

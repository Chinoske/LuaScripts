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

### Saltos masivos de nivel

Si un jugador sube de nivel 1 a 80 de golpe (por comando GM o cualquier otro medio), el sistema aplica **un roll por cada nivel ganado** — no se pierde ninguno.

- Subida normal (1 nivel): muestra el stat ganado en pantalla.
- Salto masivo (varios niveles): muestra un resumen e invita a usar `.bonus`.

---

## Instalación

```
LevelStats.lua  →  <server>/lua_scripts/
.reload ale
```

> La tabla `custom_level_stats` se crea automáticamente en `acore_characters` al cargar el script si no existe.

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
| `LevelStats.lua` | Script principal (auto-crea la tabla al cargar) |
| `LevelStats_db.sql` | Tabla SQL de referencia (opcional, el script la crea solo) |

---

## Requisitos

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)

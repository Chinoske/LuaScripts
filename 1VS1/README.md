# 1VS1 — Sistema de Cola PvP 1v1

Sistema de cola y combate PvP 1 contra 1 para **AzerothCore WotLK 3.3.5a** con **mod-ale (AzerothCore Lua Engine)**.

Toda la lógica de cola, matchmaking, countdown, rondas y forfeit está implementada 100% en Lua — sin necesidad de modificar la base de datos manualmente ni usar `smart_scripts`.

---

## Features

- **Cola automática** — los jugadores se unen/abandonan la cola desde un NPC con gossip
- **Matchmaking cada 5 s** — empareja al primer par disponible en la cola
- **Teleport a Gurubashi Arena** — cada jugador va a su spawn point asignado
- **Countdown con root** — cuenta regresiva antes de empezar (aura Chains of Ice)
- **Sistema de rondas** — mejor de 3 (configurable via `WINNING_SCORE`)
- **Reinicio de ronda** — HP/mana/cooldowns restaurados al empezar cada ronda
- **Forfeit por desconexión** — el oponente gana automáticamente si alguien se desconecta
- **Forfeit por salir de la arena** — detectado via `PLAYER_EVENT_ON_UPDATE_AREA`
- **Comando `.1v1 status`** — muestra posición en cola o marcador del partido actual
- **Auto-registro en DB** — crea el NPC y sus spawns en Stormwind y Orgrimmar automáticamente
- **Mensajes configurables** — prefijo, color y textos editables en la sección `CONFIG`

---

## Files

| File | Description |
|------|-------------|
| `1VS1.lua` | Script principal — cola, matchmaking, gossip, rondas, forfeit |

---

## Installation

```
1VS1.lua  →  <server>/lua_scripts/
```

Al cargar el script se registra automáticamente el NPC y sus spawns si no existen.  
Recargar con:

```
.reload ale
```

---

## NPC Details

| Field | Value |
|-------|-------|
| Entry | 1000000 |
| Name | Arena Master |
| Subname | Queue Master |
| Model | 3167 (Stormwind Guard) |
| Faction | 35 (Friendly to all) |
| Spawns | Stormwind (GUID 6001001) · Orgrimmar (GUID 6001002) |

### Ir al NPC rápidamente
```
.go creature 6001001   → Stormwind
.go creature 6001002   → Orgrimmar
```

---

## Configuration

Edita la tabla `CONFIG` al inicio de `1VS1.lua`:

| Campo | Descripción |
|-------|-------------|
| `NPC_ID` | Entry del NPC Arena Master |
| `WINNING_SCORE` | Rondas necesarias para ganar (default: 2) |
| `MATCHMAKING_INTERVAL` | Frecuencia del matchmaking en ms (default: 5000) |
| `COUNTDOWN_DURATION` | Segundos de cuenta regresiva antes del combate |
| `ROOT_AURA_ID` | Aura de root durante el countdown (default: 45524 Chains of Ice) |
| `ARENA_MAP_ID` | Mapa de la arena (default: 0 = Eastern Kingdoms) |
| `ARENA_AREA_ID` | Área ID del suelo de Gurubashi (default: 2177) |
| `ARENA_PLAYER1_X/Y/Z/O` | Coordenadas del spawn 1 en la arena |
| `ARENA_PLAYER2_X/Y/Z/O` | Coordenadas del spawn 2 en la arena |
| `USE_COLOR` / `COLOR_CODE` | Activar color en los mensajes y código de color |
| `USE_PREFIX` / `MSG_PREFIX` | Activar prefijo y texto del prefijo |

---

## Commands

| Comando | Descripción |
|---------|-------------|
| `.1v1 status` | Muestra tu posición en cola o el marcador de tu partida actual |

---

## Requirements

- AzerothCore WotLK 3.3.5a
- [mod-ale (AzerothCore Lua Engine)](https://github.com/azerothcore/mod-ale)
# ZenMode

Sistema de Modo Zen para **AzerothCore WotLK 3.3.5a** con **mod-ale**.

Cuando el jugador se sienta (tecla X) o queda AFK, activa automaticamente un escudo de inmunidad total (Divine Shield) y regeneracion acelerada de HP y poder. Al levantarse, moverse, entrar en combate o morir, el modo se cancela sin intervencion del jugador.

---

## Caracteristicas

- Activacion automatica al sentarse (stand state >= 1) o entrar en estado AFK
- Escudo de inmunidad via **Divine Shield** (spell 642) reaplicado cada 7 segundos para que nunca expire
- Regeneracion de HP y poder del 10% del maximo por segundo
- Compatible con todos los tipos de poder: mana, rabia, energia, poder runico (excluye runa, mascota)
- Cancelacion automatica al levantarse, moverse (umbral de 0.5 unidades para AFK), entrar en combate o morir
- Limpieza de estado en login y logout para evitar fugas de memoria
- Bucle de 500 ms para respuesta rapida sin sobrecarga del servidor
- Mensaje de chat al activar y desactivar el modo

---

## Archivos

| Archivo | Descripcion |
|---------|-------------|
| `ZenMode.lua` | Script servidor — sin archivo cliente, no requiere AIO |

---

## Instalacion

Copiar el archivo en la carpeta `lua_scripts/` del servidor:

```
ZenMode.lua  →  <servidor>/lua_scripts/
```

Recargar con:

```
.reload ale
```

No requiere SQL ni configuracion adicional.

---

## Configuracion

Todos los ajustes se encuentran al inicio de `ZenMode.lua`.

| Campo | Valor por defecto | Descripcion |
|-------|-------------------|-------------|
| `ZEN_AURA` | `642` | Spell ID del escudo de inmunidad (Divine Shield) |
| `AURA_REFRESH` | `7` | Segundos entre reaplicaciones del aura (aura dura 8 s) |
| `REGEN_INTERVAL` | `1.0` | Segundos entre ticks de regeneracion |
| `REGEN_PCT` | `0.10` | Porcentaje del maximo regenerado por tick (10%) |
| `MOVE_THRESHOLD` | `0.5` | Distancia minima en unidades para cancelar el modo en AFK |

---

## Comportamiento por tipo de poder

| Tipo de poder | Regenera |
|---------------|----------|
| Mana (0) | Si |
| Rabia (1) | Si |
| Energia (3) | Si |
| Poder runico (6) | Si |
| Runa (5) | No (gestionado por el sistema de runas del DK) |
| Foco mascota (2) / Felicidad mascota (4) | No |

---

## Notas tecnicas

- El aura se reaaplica 1 segundo antes de que expire (dura 8 s, se reaplica cada 7 s) para garantizar inmunidad continua.
- El bucle usa `goto skip` para evitar procesamiento innecesario en jugadores fuera del mundo o muertos.
- Los timers se acumulan con el `elapsed` fijo de 0.5 s del intervalo del bucle, sin depender de delta time variable.

---

## Requisitos

- AzerothCore WotLK 3.3.5a
- [mod-ale (AzerothCore Lua Engine)](https://github.com/azerothcore/mod-ale)
# SuperSaiyan

Sistema dual de Ki + resurreccion para **AzerothCore WotLK 3.3.5a** con **mod-ale**.

Acumula Ki en combate y activa una transformacion cinematica Super Saiyan de 14 segundos. Al morir, una Val'kyr aparece sobre tu cadaver, entrega una secuencia de dialogo epico y te resucita con el 30% de vida.

---

## Caracteristicas

**Sistema Super Saiyan**
- El Ki se acumula al matar enemigos, causar dano y recibir dano
- La transformacion se activa **automaticamente** al llegar a 100 de Ki
- Secuencia cinematica de 5 fases (14 segundos): Despertar → Primera Energia → Aceleracion → Climax → Transformacion
- Transformado: stats x10, velocidad x7, dano x2, curacion x1.5, equipo visual GM, cabello dorado
- El Ki se drena 5/seg durante la transformacion; al llegar a 0 se reproduce la secuencia de salida
- Sin cooldown entre transformaciones — el Ki volviendo a 0 es la unica limitacion natural
- **Barra de Ki animada en pantalla** via AIO (requiere addon `AIO_Client` en el cliente WoW)

**Sistema de Resurreccion Val'kyr**
- Al morir, una Val'kyr aparece sobre el lugar de muerte
- Secuencia de dialogo epica de 10 segundos (5 lineas de discurso)
- Resucita al jugador con el 30% de vida
- Cooldown de 5 minutos entre resurrecciones

---

## Archivos

| Archivo | Descripcion |
|---------|-------------|
| `SuperSaiyan.lua` | Script servidor — sistema Ki Super Saiyan + resurreccion Val'kyr |
| `SuperSaiyan_client.lua` | Addon AIO — barra de Ki animada en la UI del cliente WoW |

---

## Instalacion

Copiar ambos archivos en la carpeta `lua_scripts/` del servidor:

```
SuperSaiyan.lua        →  <servidor>/lua_scripts/
SuperSaiyan_client.lua →  <servidor>/lua_scripts/
```

El cliente WoW necesita el addon **AIO_Client** instalado en `Interface/AddOns/AIO_Client/`.
El archivo `SuperSaiyan_client.lua` es enviado automaticamente al cliente al hacer login — no requiere copia manual en el cliente.

```
.reload ale
```

No requiere SQL ni configuracion adicional.

---

## Barra de Ki (UI)

La barra aparece en la parte inferior de la pantalla y se actualiza en tiempo real con animacion de chispa y glow pulsante:

| Estado | Color |
|--------|-------|
| Acumulando Ki | Azul |
| Ki >= 75% | Dorado |
| Transformandose (secuencia) | Naranja pulsante |
| Super Saiyan activo | Amarillo brillante |

Usa `/ki` para mostrar u ocultar la barra. Es arrastrable con clic izquierdo.

---

## Comandos

### Super Saiyan (GM)

| Comando | Descripcion |
|---------|-------------|
| `.saiyan on` | Forzar transformacion para pruebas (Ki a 100) |
| `.saiyan off` | Cancelar transformacion activa |
| `.saiyan status` | Mostrar Ki actual y estado de transformacion |
| `.saiyan reset` | Reiniciar Ki a 0 |
| `.saiyan hair <N>` | Probar color de cabello N (0-12) en vivo |

### Val'kyr (GM)

| Comando | Descripcion |
|---------|-------------|
| `.valkyr` | Activar secuencia de resurreccion Val'kyr (prueba) |
| `.valkyr reset` | Resetear cooldown de Val'kyr |

---

## Configuracion

Todos los ajustes se encuentran en la tabla `CFG` al inicio de `SuperSaiyan.lua`.

### Ki

| Campo | Valor | Descripcion |
|-------|-------|-------------|
| `KI_MAX` | `100` | Ki necesario para activar la transformacion |
| `KI_PER_KILL` | `10` | Ki ganado por matar |
| `KI_PER_DAMAGE_TAKEN` | `5` | Ki ganado al recibir un golpe |
| `KI_PER_DAMAGE_DEALT` | `2` | Ki ganado al causar dano |
| `KI_DRAIN_PER_SECOND` | `5` | Ki drenado por segundo mientras transformado |

### Multiplicadores

| Campo | Valor | Descripcion |
|-------|-------|-------------|
| `SPEED_MULTIPLIER` | `1.5` | Multiplicador de velocidad base (referencia; velocidad real = 7x) |
| `DAMAGE_MULTIPLIER` | `2.0` | Multiplicador de dano causado |
| `HEAL_MULTIPLIER` | `1.5` | Multiplicador de curacion recibida |
| `STAT_MULTIPLIER` | `10` | Multiplicador de todas las estadisticas |

### Auras Visuales

| Campo | Valor | Descripcion |
|-------|-------|-------------|
| `AURA_SPELL_SURGE` | `57819` | Capa 1 — columna de energia ascendente |
| `AURA_SPELL_RADIANT` | `24018` | Capa 2 — brillo circular radiante |
| `AURA_SPELL_SWIRL` | `34477` | Capa 3 — particulas orbitales |
| `AURA_SPELL_POWER` | `20375` | Aura persistente reaplicada cada 300 ms |
| `LIGHTNING_SPELL_2` | `63494` | Rayos durante la secuencia |
| `HURRICANE_SPELL` | `16914` | Huracan durante la acumulacion |
| `EARTHQUAKE_SPELL` | `42499` | Onda de choque en el climax |

### Equipo GM (equipado durante la transformacion)

| Campo | Valor | Descripcion |
|-------|-------|-------------|
| `SS_GEAR_HEAD` | `12064` | Capucha GM (slot cabeza) |
| `SS_GEAR_CHEST` | `2586` | Bata GM (slot pecho) |
| `SS_GEAR_FEET` | `11508` | Zapatillas GM (slot pies) |

### Cabello (Human Male por defecto)

| Campo | Valor | Descripcion |
|-------|-------|-------------|
| `SS_HAIR_STYLE` | `13` | Estilo de cabello transformado (13 = puntiagudo) |
| `SS_HAIR_COLOR` | `5` | Color de cabello transformado (5 = rubio dorado) |
| `SS_HAIR_COLOR_NORMAL` | `0` | Color de cabello restaurado (0 = negro) |

### Val'kyr (tabla `CFG_SH`)

| Campo | Valor | Descripcion |
|-------|-------|-------------|
| `NPC_ENTRY` | `38392` | Entry ID del NPC Val'kyr |
| `COOLDOWN` | `300` | Segundos entre resurrecciones |
| `HEALTH_PCT` | `30` | % de vida al resucitar |
| `SPAWN_Z_OFFSET` | `3` | Altura sobre el punto de muerte |
| `SPAWN_SCALE` | `3.0` | Escala visual de la Val'kyr |

---

## Notas tecnicas

- Al hacer `.reload ale`, el sistema detecta automaticamente jugadores con efectos SS activos (velocidad >= 5x) y restaura sus estadisticas, velocidad y auras sin necesidad de reloguear.
- La barra de Ki usa el sistema AIO para comunicacion servidor→cliente en tiempo real.

---

## Requisitos

- AzerothCore WotLK 3.3.5a
- [mod-ale (AzerothCore Lua Engine)](https://github.com/azerothcore/mod-ale)
- [AIO_Client](https://github.com/Rochet2/AIO) — addon WoW necesario para la barra de Ki

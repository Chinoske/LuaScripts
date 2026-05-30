# SpellCharges

> **Autor original:** [Crow (crow0385)](https://github.com/crow0385)

Sistema de cargas para hechizos en **AzerothCore WotLK 3.3.5a** con **mod-ale** + **AIO v1.75**.

Permite asignar un número máximo de cargas a cualquier hechizo del juego. Las cargas se recargan automáticamente con un cooldown configurable y se muestran en la action bar del cliente en tiempo real.

---

## ¿Cómo funciona?

- Configuras en la base de datos qué hechizos tienen cargas, cuántas y cada cuánto tiempo se recargan.
- Al lanzar el hechizo, se consume una carga. Si no hay cargas disponibles, el hechizo se cancela.
- Las cargas se recuperan automáticamente pasado el cooldown configurado.
- Los rangos del mismo hechizo pueden compartir el mismo pool de cargas (`group_id`).
- La action bar muestra el número de cargas restantes y el cooldown de recarga en tiempo real (addon AIO).

---

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `spell_charges.lua` | Script servidor — lógica de cargas, eventos, timers, comunicación AIO |
| `spell_charges_client.lua` | Addon cliente (se envía automáticamente vía AIO) — actualiza action bars |
| `spell_charges.sql` | Tabla de configuración de hechizos en `acore_world` |

---

## Requisitos

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)
- [AIO v1.75](https://github.com/Rochet2/AIO) — servidor en `lua_scripts/AIO_Server/`, cliente en `WoW/Interface/AddOns/AIO_Client/`

---

## Instalación

### 1. Instalar AIO (si aún no está instalado)
```
AIO_Server/  →  <server>/lua_scripts/AIO_Server/
AIO_Client/  →  WoW/Interface/AddOns/AIO_Client/
```

### 2. Aplicar el SQL en acore_world
```bash
mysql -u acore -p acore_world < spell_charges.sql
```

### 3. Configurar hechizos
Edita `spell_charges.sql` o inserta directamente en la tabla:
```sql
INSERT INTO `spell_charges_spells` (`spell_id`, `group_id`, `max_charges`, `base_cooldown`)
VALUES
  (1953, 0, 2, 15000)  -- Blink: 2 cargas, 15s de recarga
ON DUPLICATE KEY UPDATE
  `group_id` = VALUES(`group_id`),
  `max_charges` = VALUES(`max_charges`),
  `base_cooldown` = VALUES(`base_cooldown`);
```

### 4. Copiar el script Lua
```
spell_charges.lua        →  <server>/lua_scripts/
spell_charges_client.lua →  <server>/lua_scripts/
```

### 5. Recargar
```
.reload ale
```

---

## Tabla `spell_charges_spells`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `spell_id` | INT UNSIGNED | ID del hechizo (Spell.dbc) |
| `group_id` | INT UNSIGNED | `0` = pool propio · mismo valor = pool compartido entre rangos |
| `max_charges` | TINYINT UNSIGNED | Cargas máximas (mínimo 2) |
| `base_cooldown` | INT UNSIGNED | Tiempo de recarga por carga **en milisegundos** |

---

## Ejemplos incluidos en el SQL

| Hechizo | group_id | Cargas | Recarga |
|---------|----------|--------|---------|
| Heroism / Bloodlust (pool compartido) | 32182 | 2 | 5 min |
| Flash Heal (todos los rangos) | 2061 | 3 | 8 s |
| Shield Bash (todos los rangos) | 72 | 2 | 12 s |
| Blink | 0 (propio) | 2 | 15 s |

---

## Comando GM

```
.spellcharges reset
```
Reinicia las cargas del jugador actual a máximo (requiere GM rank 3).

---

## Comando cliente

```
/spellcharges
```
Muestra en el chat cuántos hechizos con cargas conoce el cliente y cuántos botones de la action bar están activos.

---

## Notas

- Las cargas se mantienen en memoria del servidor. Si el servidor se reinicia, se restablecen al máximo.
- Tras 15 minutos desconectado, las cargas se recalculan automáticamente según el tiempo transcurrido.
- El addon cliente se distribuye automáticamente vía AIO — los jugadores no necesitan instalar nada.

# Quest Complete DK

> **Autor original:** pangolp (Walter Pagani)

NPC que completa automáticamente todas las misiones de la zona de inicio del **Caballero de la Muerte** para **AzerothCore WotLK 3.3.5a** con **mod-ale**.

Solo disponible para personajes clase DK que aún no hayan completado la cadena de inicio. Al terminar, teleporta al jugador a su ciudad capital según facción y raza.

---

## Funcionalidad

- Completa las ~45 misiones de la zona de inicio de DK (Acherus / Enclave Escarlata)
- Detecta la facción (Alianza/Horda) y la raza para completar la misión final correspondiente
- Teleporta automáticamente a Ventormenta (Alianza) u Orgrimmar (Horda) al finalizar

---

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `npc_misiones_dk.lua` | Script del NPC (gossip + lógica + auto-registro en DB) |

---

## Instalación

```
npc_misiones_dk.lua  →  <server>/lua_scripts/
```

Al cargar el script, registra automáticamente el NPC en la base de datos si no existe.
Si es la primera vez que se instala, reiniciar el servidor una vez para que el cache se actualice.

```
.reload ale
```

---

## NPC

| Campo | Valor |
|-------|-------|
| Entry | 200000 |
| Nombre | The Lich King |
| Subtítulo | Completar misiones dk |
| Spawn | Acherus (map 609) |

---

## Requisitos

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)

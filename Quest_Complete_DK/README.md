# Quest Complete DK

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
| `npc_misiones_dk.lua` | Script del NPC (gossip + lógica) |
| `npc_misiones_dk.sql` | Template del NPC entry 200000 + spawn en Acherus |

---

## Instalación

```bash
mysql -u acore -p acore_world < npc_misiones_dk.sql
```
```
npc_misiones_dk.lua  →  <server>/lua_scripts/
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

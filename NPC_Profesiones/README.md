# NPC Profesiones

NPC que sube todas las profesiones a 450 para **AzerothCore WotLK 3.3.5a** con **mod-ale**.

Solo funciona con jugadores nivel 80 que ya tengan aprendida la profesión. No otorga recetas.

---

## Profesiones cubiertas

Alquimia · Desuello · Encantamiento · Herrería · Ingeniería · Inscripción · Joyería · Minería · Peletería · Sastrería · Herboristería · Cocina · Pesca · Primeros Auxilios

---

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `npc_professions.lua` | Script del NPC (gossip + lógica) |
| `npc_professions.sql` | Template del NPC entry 200004 + spawn en Rasganorte |

---

## Instalación

```bash
mysql -u acore -p acore_world < npc_professions.sql
```
```
npc_professions.lua  →  <server>/lua_scripts/
.reload ale
```

---

## NPC

| Campo | Valor |
|-------|-------|
| Entry | 200004 |
| Nombre | Oscar Isidro Parrilli |
| Subtítulo | Profesiones 450 |
| Spawn | Rasganorte (map 571) |

---

## Requisitos

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)

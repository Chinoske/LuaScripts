# NPC Skills

> **Autor original:** pangolp (Walter Pagani)

NPC que sube las habilidades de armas a 400 para **AzerothCore WotLK 3.3.5a** con **mod-ale**.

Requiere nivel 80 y haber aprendido la habilidad previamente con el instructor. Incluye botón "Aprender todo" para subir todas las habilidades disponibles de una vez.

---

## Habilidades cubiertas

Arcos · Ballestas · Armas arrojadizas · Dagas · Arma de asta · Mazas · Mazas de dos manos · Armas de fuego · Espadas de una mano · Espadas de dos manos · Varitas · Hachas de una mano · Hachas de dos manos · Bastones · Defensa · Sin armas

---

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `npc_skills.lua` | Script del NPC (gossip + lógica + auto-registro en DB) |

---

## Instalación

```
npc_skills.lua  →  <server>/lua_scripts/
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
| Entry | 200005 |
| Nombre | René Favaloro |
| Subtítulo | Skills: 400 |
| Spawn | Rasganorte (map 571) |

---

## Requisitos

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)

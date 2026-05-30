# Quest Reputación Rasganorte

> **Autor original:** pangolp (Walter Pagani)

NPC que sube las reputaciones clave de Rasganorte a **Exaltado** para **AzerothCore WotLK 3.3.5a** con **mod-ale**.

Requiere nivel 80. Disponible para Alianza y Horda con opciones según facción.

---

## Reputaciones cubiertas

| Facción | Método |
|---------|--------|
| **Caballeros de la Espada de Ébano** | Completa misiones de la cadena (diferente por facción) |
| **Kirin Tor** | Sube directamente a Exaltado |
| **El Acuerdo del Reposo del Dragón** | Sube directamente a Exaltado |
| **El Veredicto Cinéreo** | Sube directamente a Exaltado |
| **Los Hijos de Hodir** | Completa misiones de la cadena |
| **Cruzada Argenta** | Sube directamente a Exaltado |

---

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `npc_misiones_rasganorte.lua` | Script del NPC (gossip + lógica + auto-registro en DB) |

---

## Instalación

```
npc_misiones_rasganorte.lua  →  <server>/lua_scripts/
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
| Entry | 200003 |
| Nombre | Jaime Stiuso |
| Subtítulo | Reputaciones Rasganorte |
| Spawn | Rasganorte (map 571) |

---

## Requisitos

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)

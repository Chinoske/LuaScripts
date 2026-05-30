# 🌙 LuaScripts — AzerothCore + mod-ale

> Scripts Lua para **AzerothCore WotLK 3.3.5a** usando **[mod-ale (AzerothCore Lua Engine)](https://github.com/azerothcore/mod-ale)**.  
> Cada script es autónomo e incluye su propio README con instrucciones de instalación.

---

## 📦 Scripts disponibles

---

### 🗺️ [Portal Master](./Portal_Master/)

> NPC teleportador con más de 130 destinos organizados en submenús por continente, mazmorra y raid.

| | |
|---|---|
| **Entrada NPC** | 190000 |
| **Destinos** | 131 (capitales, mazmorras, raids, zonas) |
| **Iconos** | Icono de textura único por destino |
| **Restricciones** | Facción, nivel mínimo y rango GM por destino |
| **Archivos** | `Portal_Master.lua` + `Portal_Master_npc.sql` |

**Menús incluidos:**
- 🏙️ Capitales — Stormwind, Orgrimmar, Ironforge, Darnassus, Exodar, Thunder Bluff, Undercity, Silvermoon, Dalaran, Shattrath
- ⚔️ Mazmorras Classic · BC · Wrath (37 instancias)
- 💀 Raids — Molten Core, Naxxramas, ICC, Ulduar y más (22 raids)
- 🌍 Zonas — Eastern Kingdoms, Kalimdor, Outland, Northrend (60 zonas)
- 🔑 GM Island — solo visible para GM rank ≥ 1

---

## ⚙️ Requisitos generales

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale) instalado y activo
- Scripts en la carpeta `lua_scripts/` del servidor
- Recarga con `.reload ale` en la consola del worldserver

---

## 📁 Estructura del repositorio

```
LuaScripts/
└── Portal_Master/
    ├── Portal_Master.lua        ← lógica principal (gossip, teleports, iconos)
    ├── Portal_Master_npc.sql    ← template NPC + 12 spawns en el mundo
    └── README.md                ← instrucciones detalladas
```

---

## 📜 Licencia

Scripts de libre uso para servidores privados de AzerothCore.  
Si los usas o adaptas, un crédito siempre es bienvenido. 🙂

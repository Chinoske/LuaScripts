# Scarlet Enclave — Death Knight Starting Zone

Script Lua completo de la zona de inicio de los **Caballeros de la Muerte** para **AzerothCore WotLK 3.3.5a** con **[mod-ale](https://github.com/azerothcore/mod-ale)**.

Reimplementa en Lua los scripts C++ originales de AzerothCore:
`zone_the_scarlet_enclave.cpp` · `chapter1.cpp` · `chapter2.cpp` · `chapter3.cpp` · `chapter5.cpp`

---

## Contenido

### Capítulo 1 — Acherus: The Ebon Hold
| NPC | Comportamiento |
|-----|----------------|
| **Val'kyr Battle-Maiden** | Revive al DK al morir — secuencia de vuelo multi-fase |
| **Scarlet Ghoul** | Interacción con Gothik DKC1 |
| **Gothik DKC1** | Ritual de levantamiento en Acherus |
| **The Lich King** | 16 whispers aleatorios durante la zona |

### Capítulo 2 — La Gran Ofensiva
| NPC | Comportamiento |
|-----|----------------|
| **Koltira Deathweaver** | Secuencia completa de breakout con oleadas de Scarlet Crusaders + Valroth |
| **Scarlet Courier** | Se oculta en el árbol y embosca al jugador |
| **A Special Surprise** | 10 NPCs del pueblo natal reconocen y hablan al DK (Ellen Stanbridge, Kug Ironjaw, etc.) |
| **Acherus Necromancer** | Ritual de levantamiento de cadáveres |
| **Gothik the Harvester** | Ritual con animaciones de cosecha |
| **Persuasive Strike** | Quest *How to Win Friends and Influence Enemies* |

### Capítulo 3 — An End to All Things
| NPC | Comportamiento |
|-----|----------------|
| **Hearthglen / Tirisfal Crusader** | Devour Humanoid — el DK devora a los cruzados |

### Capítulo 5 — The Light of Dawn
| Evento | Descripción |
|--------|-------------|
| **Intro** | Highlord Darion Mograine convoca las fuerzas |
| **Batalla** | Abominaciones, Ghouls y Warriors of the Frozen Wastes contra Defenders of the Light |
| **Countdown** | Cuenta atrás completa con diálogos |
| **Outro** | Tirion Fordring irrumpe, Alexandros Mograine aparece, Darion entrega el Ashbringer |
| **Return to Capital** | Guards de Stormwind / Orgrimmar insultan al DK recién llegado |

---

## Instalación

### 1. Copiar el script
```
scarlet_enclave_dk.lua  →  <server>/lua_scripts/
```

### 2. Recargar
```
.reload ale
```

> No requiere cambios en la base de datos.

---

## NPCs cubiertos

| Entry | Nombre |
|-------|--------|
| 24536 | Val'kyr Battle-Maiden |
| 28658 | Gothik DKC1 |
| 28845 | Scarlet Ghoul |
| 28889 | Acherus Necromancer |
| 28890 | Gothik the Harvester |
| 28912 | Koltira Deathweaver |
| 29001 | High Inquisitor Valroth |
| 29053 | Plaguefist |
| 29061–29074 | A Special Surprise NPCs (10 NPCs) |
| 29076 | Scarlet Courier |
| 29102–29103 | Hearthglen / Tirisfal Crusader |
| 29173 | Highlord Darion Mograine |
| 29174–29182 | Defenders of the Light + Champions |
| 29175 | Highlord Tirion Fordring |
| 29186–29219 | Fuerzas de Acherus (abominaciones, ghouls, warriors) |

---

## Requisitos

- AzerothCore WotLK **3.3.5a**
- [mod-ale](https://github.com/azerothcore/mod-ale)
- La zona de inicio de DK debe estar habilitada en el servidor

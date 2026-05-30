-- =============================================================================
-- Portal Master NPC — entry 190000
-- AzerothCore + mod-ale (ALE Lua Engine)
-- Toda la lógica de gossip, condiciones de facción, nivel mínimo y teleports
-- se maneja 100% en Lua. No requiere gossip_menu, gossip_menu_option,
-- conditions ni smart_scripts en la base de datos.
-- =============================================================================

local NPC_ENTRY = 190000

-- Códigos de menú (sender) usados en GossipMenuAddItem
local MENU_MAIN    = 1
local MENU_CLASSIC = 2
local MENU_BC      = 3
local MENU_WRATH   = 4
local MENU_RAIDS   = 5
local MENU_EK      = 6
local MENU_KALI    = 7
local MENU_OUTLAND = 8
local MENU_NORTHREND = 9

-- intid especiales reservados
local INTID_BACK         = 99   -- volver al menú principal
local INTID_NAV_CLASSIC  = 102
local INTID_NAV_BC       = 103
local INTID_NAV_WRATH    = 104
local INTID_NAV_RAIDS    = 105
local INTID_NAV_EK       = 106
local INTID_NAV_KALI     = 107
local INTID_NAV_OUTLAND  = 108
local INTID_NAV_NORTHREND= 109

-- Facciones
local TEAM_ALLIANCE = 0
local TEAM_HORDE    = 1

-- =============================================================================
-- ICONOS DE TEXTURA  (formato WoW: |TInterface/ICONS/Name:h:w:x:y|t)
-- Los iconos se incrustan directamente en el label del gossip item.
-- Dimensiones: 20×20 px, sin offset (0:0). El espacio final es el padding.
-- =============================================================================
local function Tex(name)
    return "|TInterface/ICONS/" .. name .. ":30:30:0:0|t "
end

-- Iconos genéricos por categoría de menú
local TEX_PORTAL  = Tex("Spell_Arcane_PortalOrgrimmar")    -- portal genérico (fallback)
local TEX_MAP     = Tex("INV_Misc_Map_01")                  -- mapa  → zonas / continentes
local TEX_DUNGEON = Tex("Ability_Warrior_OffensiveStance")  -- espada → mazmorras
local TEX_RAID    = Tex("Achievement_Boss_General")         -- cráneo → raids
local TEX_BACK    = Tex("INV_Misc_Rune_04")                  -- hearthstone → botón Volver

-- Iconos de portal específicos por ciudad / lugar (cada destino con icono único y temático)
local CITY_ICON = {
    -- ── MENU_MAIN: Capitales y lugares especiales ─────────────────────────────
    ["Stormwind"]       = Tex("Spell_Arcane_PortalStormwind"),
    ["Ironforge"]       = Tex("Spell_Arcane_PortalIronforge"),
    ["Darnassus"]       = Tex("Spell_Arcane_PortalDarnassus"),
    ["Exodar"]          = Tex("Spell_Arcane_PortalExodar"),
    ["Orgrimmar"]       = Tex("Spell_Arcane_PortalOrgrimmar"),
    ["Thunder Bluff"]   = Tex("Spell_Arcane_PortalThunderbluff"),
    ["Undercity"]       = Tex("Spell_Arcane_PortalUndercity"),
    ["Silvermoon City"] = Tex("Spell_Arcane_PortalSilvermoon"),
    ["Dalaran"]         = Tex("Spell_Arcane_PortalDalaran"),
    ["Shattrath"]       = Tex("Spell_Arcane_PortalShattrath"),
    ["Booty Bay"]       = Tex("INV_Misc_Coin_01"),                  -- moneda de oro pirata
    ["Gurubashi Arena"] = Tex("Ability_Warrior_Challange"),         -- puño levantado (arena)
    ["GM Island"]       = Tex("INV_Misc_Key_01"),                   -- llave → acceso restringido

    -- ── MENU_CLASSIC: Mazmorras clásicas ──────────────────────────────────────
    ["Gnomeregan"]        = Tex("Trade_Engineering"),               -- ingeniería gnoma
    ["The Deadmines"]     = Tex("Trade_Mining"),                    -- pico minero
    ["The Stockade"]      = Tex("INV_Misc_Key_01"),                 -- prisión / llave
    ["Ragefire Chasm"]    = Tex("Spell_Fire_Volcano"),              -- volcán/fuego bajo Orgrimmar
    ["Razorfen Downs"]    = Tex("Spell_Shadow_AnimateDead"),        -- undead quilboar
    ["Razorfen Kraul"]    = Tex("Ability_Hunter_BeastTraining"),    -- bestias quilboar
    ["Scarlet Monastery"] = Tex("Spell_Holy_HolyBolt"),              -- luz sagrada escarlata
    ["Shadowfang Keep"]   = Tex("Spell_Shadow_Shadowform"),         -- forma de sombra/worgen
    ["Wailing Caverns"]   = Tex("Spell_Nature_Entangling_roots"),   -- raíces/naturaleza
    ["Blackfathom Deeps"] = Tex("Spell_Frost_WaterBreathing"),      -- submarino/agua
    ["Blackrock Depths"]  = Tex("Spell_Fire_Fireball"),             -- fuego enano oscuro
    ["Blackrock Spire"]   = Tex("Ability_Hunter_Pet_Dragonhawk"),   -- dragonkin de la cumbre
    ["Dire Maul"]         = Tex("Spell_Nature_NatureGuardian"),     -- ogro/druidas antiguos
    ["Maraudon"]          = Tex("Spell_Nature_Earthquake"),          -- elementales de tierra
    ["Scholomance"]       = Tex("Spell_Shadow_ShadowBolt"),         -- escuela de nigromancia
    ["Stratholme"]        = Tex("Spell_Shadow_RaiseDead"),          -- ciudad plaga / undead
    ["Sunken Temple"]     = Tex("INV_Misc_Idol_03"),                -- templo troll hundido
    ["Uldaman"]           = Tex("INV_Misc_Rune_01"),                -- runas titanes
    ["Zul'Farrak"]        = Tex("Spell_Fire_FireBolt02"),           -- desierto trolls

    -- ── MENU_BC: Mazmorras Burning Crusade ────────────────────────────────────
    ["Auchindoun"]         = Tex("Spell_Shadow_SoulLeech_3"),        -- ciudad de los muertos draenei
    ["Caverns of Time"]    = Tex("Spell_Holy_BorrowedTime"),         -- bronze dragonflight / tiempo
    ["Coilfang Reservoir"] = Tex("Spell_Frost_FrostShock"),          -- naga acuático
    ["Hellfire Citadel"]   = Tex("Spell_Fire_FireBreath"),           -- ciudadela infernal
    ["Magisters' Terrace"] = Tex("Spell_Arcane_ArcaneMissiles"),    -- magos blood elf
    ["Tempest Keep"]       = Tex("Spell_Arcane_ArcaneBlast"),        -- fortaleza Kael'thas

    -- ── MENU_WRATH: Mazmorras Wrath of the Lich King ──────────────────────────
    ["Azjol-Nerub"]           = Tex("Spell_Nature_GuardianWard"),       -- nerubianos arácnidos
    ["Culling of Stratholme"] = Tex("Achievement_Dungeon_CullingStratholme"),
    ["Trial of the Champion"] = Tex("Ability_Warrior_BattleShout"),     -- combate de campeones
    ["Drak'Tharon Keep"]      = Tex("INV_Misc_Bone_01"),                -- trolls drakkari/undead
    ["Gundrak"]               = Tex("Ability_Hunter_Pet_Crocolisk"),    -- trolls Drakkari + saurios
    ["ICC Dungeons"]          = Tex("Achievement_Dungeon_HallsOfReflection"),
    ["The Nexus"]             = Tex("Achievement_Dungeon_Nexus80"),
    ["The Violet Hold"]       = Tex("Spell_Arcane_Blink"),              -- prisión arcana Dalaran
    ["Halls of Lightning"]    = Tex("Spell_Nature_LightningBolt"),       -- relámpago titán
    ["Halls of Stone"]        = Tex("Spell_Nature_StoneSkinTotem"),     -- piedra titán
    ["Utgarde Keep"]          = Tex("INV_Sword_62"),                    -- vrykul guerreros
    ["Utgarde Pinnacle"]      = Tex("Ability_Hunter_Pet_Wyvern"),      -- proto-dragones cumbre

    -- ── MENU_RAIDS: Raids ─────────────────────────────────────────────────────
    ["Black Temple"]         = Tex("Ability_Warrior_PunishingBlow"),    -- Illidan / templo negro
    ["Blackwing Lair"]       = Tex("Ability_Hunter_Pet_Dragonhawk"),    -- Nefarian dragón
    ["Hyjal Summit"]         = Tex("Spell_Nature_WispSplode"),          -- wisps del Monte Hyjal
    ["Serpentshrine Cavern"] = Tex("Ability_Hunter_Pet_Serpent"),       -- Vashj/serpiente
    ["Trial of the Crusader"]= Tex("Achievement_Dungeon_TrialOfTheCrusader10"),
    ["Gruul's Lair"]         = Tex("Ability_Warrior_Trauma"),           -- Gruul el matagigantes
    ["Magtheridon's Lair"]   = Tex("Spell_Shadow_SummonInfernal"),      -- señor demoníaco
    ["Icecrown Citadel"]     = Tex("Achievement_Boss_TheLichKing"),
    ["Karazhan"]             = Tex("INV_Misc_Book_06"),                 -- torre del mago Medivh
    ["Molten Core"]          = Tex("Spell_Fire_SelfDestruct"),          -- Ragnaros / núcleo
    ["Naxxramas"]            = Tex("Achievement_Dungeon_Naxxramas10"),
    ["Onyxia's Lair"]        = Tex("Achievement_Boss_Onyxia"),
    ["Ruins of Ahn'Qiraj"]   = Tex("INV_Misc_QirajiCrystal_03"),         -- ruinas insectoides
    ["Sunwell Plateau"]      = Tex("Spell_Holy_SurgeOfLight"),          -- pozo del sol / Kil'jaeden
    ["The Eye"]              = Tex("Spell_Arcane_FocusedPower"),        -- ojo de Kael'thas
    ["Temple of Ahn'Qiraj"]  = Tex("INV_Misc_AhnQirajTrinket_02"),       -- C'thun / templo qiraji
    ["The Eye of Eternity"]  = Tex("Spell_Frost_Stun"),                  -- Malygos dragón azul
    ["The Obsidian Sanctum"] = Tex("Spell_Fire_Incinerate"),             -- Sartharion / dragón negro
    ["Ulduar"]               = Tex("INV_Misc_Gear_01"),                  -- maquinaria titán
    ["Vault of Archavon"]    = Tex("Spell_Frost_FrostNova"),             -- Wintergrasp / invierno
    ["Zul'Gurub"]            = Tex("Ability_Hunter_Pet_Raptor"),        -- Hakkar / trolls
    ["Zul'Aman"]             = Tex("Ability_Hunter_Pet_Bear"),         -- Zul'jin trolls bestias

    -- ── MENU_EK: Zonas Eastern Kingdoms ───────────────────────────────────────
    ["Elwynn Forest"]       = Tex("Spell_Holy_Resurection"),            -- bosque humano sagrado
    ["Eversong Woods"]      = Tex("Spell_Arcane_Arcane01"),              -- bosques elfos de sangre
    ["Dun Morogh"]          = Tex("Spell_Frost_FrostArmor02"),           -- montañas nevadas enanas
    ["Tirisfal Glades"]     = Tex("Spell_Shadow_DeathPact"),             -- glade Forsaken
    ["Ghostlands"]          = Tex("Spell_Shadow_Twilight"),              -- tierras fantasmas
    ["Loch Modan"]          = Tex("Spell_Frost_SummonWaterElemental"),   -- lago enano
    ["Silverpine Forest"]   = Tex("Ability_Hunter_Pet_Wolf"),            -- worgens silvanos
    ["Westfall"]            = Tex("INV_Misc_Food_15"),                    -- granjas / Sentinel Hill
    ["Redridge Mountains"]  = Tex("Spell_Fire_FlameBolt"),                -- montañas rojas
    ["Duskwood"]            = Tex("Spell_Shadow_DemonBreath"),            -- bosque oscuro
    ["Hillsbrad Foothills"] = Tex("Achievement_Zone_Stormwind"),         -- colinas en disputa (genérico EK)
    ["Wetlands"]            = Tex("Spell_Nature_AcidBreath"),             -- pantanos / dragones
    ["Alterac Mountains"]   = Tex("Spell_Frost_FrostNova"),              -- montañas nevadas Alterac
    ["Arathi Highlands"]    = Tex("Ability_Warrior_BattleShout"),        -- BG Arathi Basin
    ["Stranglethorn Vale"]  = Tex("Spell_Nature_Thorns"),                 -- jungla / espinas
    ["Badlands"]            = Tex("Spell_Fire_FireBolt02"),               -- baldíos áridos
    ["Swamp of Sorrows"]    = Tex("Spell_Shadow_PlagueCloud"),           -- pantano sombrío
    ["The Hinterlands"]     = Tex("Ability_Hunter_AspectOfTheWild"),    -- tierras salvajes / trolls
    ["Searing Gorge"]       = Tex("Spell_Fire_Incinerate"),               -- garganta abrasadora
    ["The Blasted Lands"]   = Tex("Spell_Shadow_DeathScream"),           -- tierras devastadas
    ["Burning Steppes"]     = Tex("Spell_Fire_Pyroclasm"),                -- estepas ardientes
    ["Western Plaguelands"] = Tex("Spell_Shadow_Plaguecloud"),            -- tierras malditas oeste
    ["Eastern Plaguelands"] = Tex("Spell_Shadow_DeathCoil"),             -- tierras malditas este
    ["Isle of Quel'Danas"]  = Tex("Spell_Holy_Searinglight"),             -- isla del Pozo Solar

    -- ── MENU_KALI: Zonas Kalimdor ─────────────────────────────────────────────
    ["Azuremyst Isle"]       = Tex("Spell_Holy_HolyNova"),               -- isla draenei cristalina
    ["Teldrassil"]           = Tex("Ability_Druid_TreeofLife"),         -- árbol gigante kaldorei
    ["Durotar"]              = Tex("Achievement_Character_Orc_Male"),    -- patria orca
    ["Mulgore"]              = Tex("Achievement_Character_Tauren_Male"),  -- patria tauren
    ["Bloodmyst Isle"]       = Tex("Spell_Shadow_BloodBoil"),            -- isla draenei corrupta
    ["Darkshore"]            = Tex("Spell_Nature_MoonGlow"),              -- costa oscura kaldorei
    ["The Barrens"]          = Tex("Ability_Mount_Kodo_03"),             -- baldíos / kodos
    ["Stonetalon Mountains"] = Tex("Spell_Nature_EarthBindTotem"),       -- montañas tauren
    ["Ashenvale Forest"]     = Tex("Ability_Ambush"),                     -- bosque sombrío / disputa
    ["Thousand Needles"]     = Tex("INV_Spear_07"),                       -- mil agujas
    ["Desolace"]             = Tex("INV_Misc_Bone_08"),                   -- desolación / centauros
    ["Dustwallow Marsh"]     = Tex("Spell_Nature_AcidBreath"),            -- pantano polvoriento
    ["Feralas"]              = Tex("Ability_Druid_FerociousBite"),       -- selva salvaje
    ["Tanaris Desert"]       = Tex("Spell_Fire_FireBolt02"),              -- desierto Tanaris
    ["Azshara"]              = Tex("Ability_Hunter_Pet_Serpent"),         -- Azshara naga
    ["Felwood"]              = Tex("Spell_Shadow_AntiShadow"),            -- bosque corrupto
    ["Un'Goro Crater"]       = Tex("Ability_Hunter_Pet_Devilsaur"),       -- dinosaurios / cráter
    ["Silithus"]             = Tex("INV_Misc_QirajiCrystal_05"),          -- Silithus qiraji
    ["Winterspring"]         = Tex("Spell_Frost_IceShock"),               -- bosque nevado

    -- ── MENU_OUTLAND: Zonas Outland ───────────────────────────────────────────
    ["Hellfire Peninsula"] = Tex("Spell_Fire_Volcano"),                  -- península infernal
    ["Zangarmarsh"]        = Tex("INV_Mushroom_11"),                     -- pantanos sporeggar / hongos
    ["Terokkar Forest"]    = Tex("Ability_Hunter_Pet_Owl"),              -- bosque arrakoa
    ["Nagrand"]            = Tex("Achievement_Character_Orc_Male"),       -- llanuras orco / Mag'har
    ["Blade's Edge Mtns"]  = Tex("INV_Sword_36"),                         -- montañas filo del cuchillo
    ["Netherstorm"]        = Tex("Spell_Arcane_ManaTap"),                -- tormenta abisal
    ["Shadowmoon Valley"]  = Tex("Spell_Shadow_DemonicEmpathy"),         -- valle Illidan/demon

    -- ── MENU_NORTHREND: Zonas Northrend ───────────────────────────────────────
    ["Borean Tundra"]      = Tex("Achievement_Zone_BoreanTundra"),
    ["Howling Fjord"]      = Tex("Achievement_Zone_HowlingFjord"),
    ["Dragonblight"]       = Tex("Achievement_Zone_Dragonblight"),
    ["Grizzly Hills"]      = Tex("Achievement_Zone_Grizzlyhills"),
    ["Zul'Drak"]           = Tex("Achievement_Zone_Zuldrak"),
    ["Sholazar Basin"]     = Tex("Achievement_Zone_SholazarBasin"),
    ["Crystalsong Forest"] = Tex("INV_Misc_Gem_Crystal_02"),              -- bosque cristalino
    ["Storm Peaks"]        = Tex("Achievement_Zone_Stormpeaks"),
    ["Icecrown"]           = Tex("Achievement_Zone_Icecrown"),
    ["Wintergrasp"]        = Tex("Achievement_Zone_WintergraspFortress"),
}

-- =============================================================================
-- COLORES DE TEXTO (|cffRRGGBB ... |r)
-- =============================================================================
local C_ALLIANCE = "|cff4FC3F7"   -- azul claro   — ciudades Alianza
local C_HORDE    = "|cffEF5350"   -- rojo suave    — ciudades Horda
local C_NEUTRAL  = "|cffFFD54F"   -- dorado        — lugares neutros
local C_ZONE     = "|cff66BB6A"   -- verde         — zonas / continentes
local C_DUNGEON  = "|cffCE93D8"   -- violeta       — mazmorras
local C_RAID     = "|cffFFA726"   -- naranja       — raids
local C_LEVEL    = "|cffBDBDBD"   -- gris          — requisito de nivel
local C_ARROW    = "|cffFFFFFF"   -- blanco        — flecha de submenú
local C_RESET    = "|r"

-- Nombre legible de cada submenú (para el área-trigger al entrar)
local MENU_TITLE = {
    [2] = "Classic Dungeons",
    [3] = "Burning Crusade Dungeons",
    [4] = "Wrath of the Lich King Dungeons",
    [5] = "Raid Teleports",
    [6] = "Eastern Kingdoms",
    [7] = "Kalimdor",
    [8] = "Outland",
    [9] = "Northrend",
}

-- =============================================================================
-- TABLA DE DESTINOS
-- Formato por entrada: {nombre, mapId, x, y, z, o, minLevel, faction}
--   faction: nil = todos, 0 = Alianza, 1 = Horda
-- =============================================================================

local DESTS = {}

-- ---- MENU_MAIN ---------------------------------------------------------------
DESTS[MENU_MAIN] = {
    [1]  = {"Stormwind",       0,   -8842.09,    626.358,   94.0867,  3.61363,  0, TEAM_ALLIANCE},
    [2]  = {"Orgrimmar",       1,    1601.08,  -4378.69,     9.9846,  2.14362,  0, TEAM_HORDE},
    [3]  = {"Darnassus",       1,    9869.91,   2493.58,  1315.88,    2.78897,  0, TEAM_ALLIANCE},
    [4]  = {"Ironforge",       0,   -4900.47,   -962.585,   501.455,  5.40538,  0, TEAM_ALLIANCE},
    [5]  = {"Exodar",          530, -3864.92, -11643.7,    -137.644,  5.50862,  0, TEAM_ALLIANCE},
    [6]  = {"Thunder Bluff",   1,   -1274.45,     71.8601,  128.159,  2.80623,  0, TEAM_HORDE},
    [7]  = {"Undercity",       0,    1633.75,    240.167,   -43.1034, 6.26128,  0, TEAM_HORDE},
    [8]  = {"Silvermoon City", 530,  9738.28,  -7454.19,    13.5605,  0.043914, 0, TEAM_HORDE},
    [9]  = {"Dalaran",         571,  5809.55,    503.975,   657.526,  2.38338,  0, nil},
    [10] = {"Shattrath",       530, -1887.62,   5359.09,   -12.4279,  4.40435,  0, nil},
    [11] = {"Booty Bay",       0,  -14281.9,    552.564,     8.90422, 0.860144, 0, nil},
    [12] = {"Gurubashi Arena", 0,  -13181.8,    339.356,    42.9805,  1.18013,  0, nil},
    [13] = {"GM Island",       1,   16222.0,  16265.0,      12.9469,  1.5708,   0, nil,  1},
    --                                                                    minGMRank ^  (1=Mod, 2=GM, 3=Admin)
}

-- ---- MENU_CLASSIC ------------------------------------------------------------
DESTS[MENU_CLASSIC] = {
    [0]  = {"Gnomeregan",        0,  -5163.54,    925.423,  257.181,  1.57423,  25, TEAM_ALLIANCE},
    [1]  = {"The Deadmines",     0, -11209.6,    1666.54,    24.6974, 1.42053,  17, TEAM_ALLIANCE},
    [2]  = {"The Stockade",      0,  -8799.15,    832.718,   97.6348, 6.04085,  22, TEAM_ALLIANCE},
    [3]  = {"Ragefire Chasm",    1,   1811.78,  -4410.5,    -18.4704, 5.20165,  15, TEAM_HORDE},
    [4]  = {"Razorfen Downs",    1,  -4657.3,   -2519.35,    81.0529, 4.54808,  34, TEAM_HORDE},
    [5]  = {"Razorfen Kraul",    1,  -4470.28,  -1677.77,    81.3925, 1.16302,  24, TEAM_HORDE},
    [6]  = {"Scarlet Monastery", 0,   2873.15,   -764.523,  160.332,  5.10447,  32, TEAM_HORDE},
    [7]  = {"Shadowfang Keep",   0,   -234.675,  1561.63,    76.8921, 1.24031,  18, TEAM_HORDE},
    [8]  = {"Wailing Caverns",   1,   -731.607, -2218.39,    17.0281, 2.78486,  17, TEAM_HORDE},
    [9]  = {"Blackfathom Deeps", 1,   4249.99,    740.102,  -25.671,  1.34062,  21, nil},
    [10] = {"Blackrock Depths",  0,  -7179.34,   -921.212,  165.821,  5.09599,  53, nil},
    [11] = {"Blackrock Spire",   0,  -7527.05,  -1226.77,   285.732,  5.29626,  57, nil},
    [12] = {"Dire Maul",         1,  -3520.14,   1119.38,   161.025,  4.70454,  55, nil},
    [13] = {"Maraudon",          1,  -1421.42,   2907.83,   137.415,  1.70718,  45, nil},
    [14] = {"Scholomance",       0,   1269.64,  -2556.21,    93.6088, 0.620623, 55, nil},
    [15] = {"Stratholme",        0,   3352.92,  -3379.03,   144.782,  6.25978,  55, nil},
    [16] = {"Sunken Temple",     0, -10177.9,   -3994.9,   -111.239,  6.01885,  47, nil},
    [17] = {"Uldaman",           0,  -6071.37,  -2955.16,   209.782,  0.015708, 37, nil},
    [18] = {"Zul'Farrak",        1,  -6801.19,  -2893.02,     9.00388,0.158639, 35, nil},
}

-- ---- MENU_BC -----------------------------------------------------------------
DESTS[MENU_BC] = {
    [0] = {"Auchindoun",         530, -3324.49,   4943.45, -101.239,  4.63901,  64, nil},
    [1] = {"Caverns of Time",    1,   -8369.65,  -4253.11, -204.272,  4.66289,  66, nil},
    [2] = {"Coilfang Reservoir", 530,   738.865,  6865.77,  -69.4659, 6.27655,  62, nil},
    [3] = {"Hellfire Citadel",   530,  -347.29,   3089.82,   21.394,  5.68114,  59, nil},
    [4] = {"Magisters' Terrace", 530, 12884.6,  -7317.69,   65.5023,  4.799,    70, nil},
    [5] = {"Tempest Keep",       530,  3100.48,   1536.49,  190.3,    4.62226,  70, nil},
}

-- ---- MENU_WRATH --------------------------------------------------------------
DESTS[MENU_WRATH] = {
    [0]  = {"Azjol-Nerub",           571, 3707.86,   2150.23,   36.76,    3.22,     73, nil},
    [1]  = {"Culling of Stratholme", 1,  -8756.39,  -4440.68, -199.489,  4.66289,  79, nil},
    [2]  = {"Trial of the Champion", 571, 8590.95,    791.792,  558.235,  3.13127,  79, nil},
    [3]  = {"Drak'Tharon Keep",      571, 4765.59,  -2038.24,  229.363,  0.887627, 74, nil},
    [4]  = {"Gundrak",               571, 6722.44,  -4640.67,  450.632,  3.91123,  71, nil},
    [5]  = {"ICC Dungeons",          571, 5643.16,   2028.81,  798.274,  4.60242,  79, nil},
    [6]  = {"The Nexus",             571, 3782.89,   6965.23,  105.088,  6.14194,  71, nil},
    [7]  = {"The Violet Hold",       571, 5693.08,    502.588,  652.672,  4.0229,   75, nil},
    [8]  = {"Halls of Lightning",    571, 9136.52,  -1311.81, 1066.29,   5.19113,  79, nil},
    [9]  = {"Halls of Stone",        571, 8922.12,  -1009.16, 1039.56,   1.57044,  77, nil},
    [10] = {"Utgarde Keep",          571, 1203.41,  -4868.59,   41.2486, 0.283237, 69, nil},
    [11] = {"Utgarde Pinnacle",      571, 1267.24,  -4857.3,   215.764,  3.22768,  75, nil},
}

-- ---- MENU_RAIDS --------------------------------------------------------------
DESTS[MENU_RAIDS] = {
    [0]  = {"Black Temple",         530, -3649.92,    317.469,   35.2827, 2.94285,  70, nil},
    [1]  = {"Blackwing Lair",       229,   152.451,   -474.881,  116.84,  0.001073, 60, nil},
    [2]  = {"Hyjal Summit",         1,   -8177.89,  -4181.23,  -167.552, 0.913338, 70, nil},
    [3]  = {"Serpentshrine Cavern", 530,   797.855,   6865.77,   -65.4165,0.005938, 70, nil},
    [4]  = {"Trial of the Crusader",571,  8515.61,    714.153,   558.248, 1.57753,  80, nil},
    [5]  = {"Gruul's Lair",         530,  3530.06,   5104.08,     3.50861,5.51117,  70, nil},
    [6]  = {"Magtheridon's Lair",   530,  -336.411,  3130.46,  -102.928, 5.20322,  70, nil},
    [7]  = {"Icecrown Citadel",     571,  5855.22,   2102.03,   635.991, 3.57899,  80, nil},
    [8]  = {"Karazhan",             0,  -11118.9,  -2010.33,    47.0819, 0.649895, 70, nil},
    [9]  = {"Molten Core",          230,  1126.64,   -459.94,  -102.535, 3.46095,  60, nil},
    [10] = {"Naxxramas",            571,  3668.72,  -1262.46,   243.622, 4.785,    80, nil},
    [11] = {"Onyxia's Lair",        1,   -4708.27,  -3727.64,   54.5589, 3.72786,  80, nil},
    [12] = {"Ruins of Ahn'Qiraj",   1,   -8409.82,   1499.06,   27.7179, 2.51868,  60, nil},
    [13] = {"Sunwell Plateau",      530, 12574.1,   -6774.81,   15.0904, 3.13788,  70, nil},
    [14] = {"The Eye",              530,  3088.49,   1381.57,   184.863, 4.61973,  67, nil},
    [15] = {"Temple of Ahn'Qiraj",  1,   -8240.09,   1991.32,  129.072, 0.941603, 60, nil},
    [16] = {"The Eye of Eternity",  571,  3784.17,   7028.84,  161.258,  5.79993,  80, nil},
    [17] = {"The Obsidian Sanctum", 571,  3472.43,    264.923, -120.146, 3.27923,  80, nil},
    [18] = {"Ulduar",               571,  9222.88,  -1113.59, 1216.12,   6.27549,  80, nil},
    [19] = {"Vault of Archavon",    571,  5453.72,   2840.79,   421.28,  0,        80, nil},
    [21] = {"Zul'Gurub",            0,  -11916.7,  -1215.72,   92.289,  4.72454,  57, nil},
    [22] = {"Zul'Aman",             530,  6851.78,  -7972.57,  179.242,  4.64691,  70, TEAM_HORDE},
}

-- ---- MENU_EK -----------------------------------------------------------------
DESTS[MENU_EK] = {
    [0]  = {"Elwynn Forest",       0,   -9449.06,     64.8392,  56.3581, 3.07047,  10, TEAM_ALLIANCE},
    [1]  = {"Eversong Woods",      530,  9024.37,  -6682.55,    16.8973, 3.14131,  10, TEAM_HORDE},
    [2]  = {"Dun Morogh",          0,   -5603.76,   -482.704,  396.98,   5.23499,  10, TEAM_ALLIANCE},
    [3]  = {"Tirisfal Glades",     0,    2274.95,    323.918,   34.1137, 4.24367,  10, TEAM_HORDE},
    [4]  = {"Ghostlands",          530,  7595.73,  -6819.6,     84.3718, 2.56561,  10, TEAM_HORDE},
    [5]  = {"Loch Modan",          0,   -5405.85,  -2894.15,  341.972,  5.48238,  10, TEAM_ALLIANCE},
    [6]  = {"Silverpine Forest",   0,     505.126,  1504.63,   124.808,  1.77987,  10, TEAM_HORDE},
    [7]  = {"Westfall",            0,  -10684.9,    1033.63,    32.5389, 6.07384,  10, TEAM_ALLIANCE},
    [8]  = {"Redridge Mountains",  0,   -9447.8,   -2270.85,   71.8224, 0.283853, 15, TEAM_ALLIANCE},
    [9]  = {"Duskwood",            0,  -10531.7,   -1281.91,   38.8647, 1.56959,  18, TEAM_ALLIANCE},
    [10] = {"Hillsbrad Foothills", 0,    -385.805,  -787.954,  54.6655, 1.03926,  20, nil},
    [11] = {"Wetlands",            0,   -3517.75,   -913.401,   8.86625,2.60705,  20, TEAM_ALLIANCE},
    [12] = {"Alterac Mountains",   0,     275.049,  -652.044,  130.296,  0.502032, 30, nil},
    [13] = {"Arathi Highlands",    0,   -1581.45,  -2704.06,   35.4168, 0.490373, 30, nil},
    [14] = {"Stranglethorn Vale",  0,  -11921.7,     -59.544,  39.7262, 3.73574,  30, nil},
    [15] = {"Badlands",            0,   -6782.56,  -3128.14,  240.48,   5.65912,  35, nil},
    [16] = {"Swamp of Sorrows",    0,  -10368.6,   -2731.3,    21.6537, 5.29238,  35, nil},
    [17] = {"The Hinterlands",     0,     112.406,  -3929.74,  136.358, 0.981903, 40, nil},
    [18] = {"Searing Gorge",       0,   -6686.33,  -1198.55,  240.027,  0.916887, 43, nil},
    [19] = {"The Blasted Lands",   0,  -11184.7,   -3019.31,    7.29238,3.20542,  45, nil},
    [20] = {"Burning Steppes",     0,   -7979.78,  -2105.72,  127.919,  5.10148,  50, nil},
    [21] = {"Western Plaguelands", 0,    1743.69,  -1723.86,   59.6648, 5.23722,  51, nil},
    [22] = {"Eastern Plaguelands", 0,    2280.64,  -5275.05,   82.0166, 4.7479,   53, nil},
    [23] = {"Isle of Quel'Danas",  530, 12806.5,   -6911.11,   41.1156, 2.22935,  70, nil},
}

-- ---- MENU_KALI ---------------------------------------------------------------
DESTS[MENU_KALI] = {
    [0]  = {"Azuremyst Isle",      530, -4192.62, -12576.7,    36.7598, 1.62813,  10, TEAM_ALLIANCE},
    [1]  = {"Teldrassil",          1,   9889.03,    915.869, 1307.43,   1.9336,   10, TEAM_ALLIANCE},
    [2]  = {"Durotar",             1,    228.978,  -4741.87,   10.1027, 0.416883, 10, TEAM_HORDE},
    [3]  = {"Mulgore",             1,  -2473.87,   -501.225,   -9.42465,0.6525,   10, TEAM_HORDE},
    [4]  = {"Bloodmyst Isle",      530, -2095.7,  -11841.1,    51.1557, 6.19288,  15, TEAM_ALLIANCE},
    [5]  = {"Darkshore",           1,   6463.25,    683.986,    8.92792, 4.33534,  10, TEAM_ALLIANCE},
    [6]  = {"The Barrens",         1,   -575.772, -2652.45,    95.6384, 0.006469, 10, TEAM_HORDE},
    [7]  = {"Stonetalon Mountains",1,   1574.89,   1031.57,   137.442,  3.8013,   15, nil},
    [8]  = {"Ashenvale Forest",    1,   1919.77,  -2169.68,    94.6729, 6.14177,  18, nil},
    [9]  = {"Thousand Needles",    1,  -5375.53,  -2509.2,    -40.432,  2.41885,  25, TEAM_HORDE},
    [10] = {"Desolace",            1,   -656.056,  1510.12,    88.3746, 3.29553,  30, nil},
    [11] = {"Dustwallow Marsh",    1,  -3350.12,  -3064.85,    33.0364, 5.12666,  35, nil},
    [12] = {"Feralas",             1,  -4808.31,   1040.51,   103.769,  2.90655,  40, nil},
    [13] = {"Tanaris Desert",      1,  -6940.91,  -3725.7,     48.9381, 3.11174,  40, nil},
    [14] = {"Azshara",             1,   3117.12,  -4387.97,    91.9059, 5.49897,  45, nil},
    [15] = {"Felwood",             1,   3898.8,   -1283.33,   220.519,  6.24307,  48, nil},
    [16] = {"Un'Goro Crater",      1,  -6291.55,  -1158.62,  -258.138,  0.457099, 48, nil},
    [17] = {"Silithus",            1,  -6815.25,    730.015,   40.9483, 2.39066,  55, nil},
    [18] = {"Winterspring",        1,   6658.57,  -4553.48,   718.019,  5.18088,  55, nil},
}

-- ---- MENU_OUTLAND ------------------------------------------------------------
DESTS[MENU_OUTLAND] = {
    [0] = {"Hellfire Peninsula",  530,  -207.335,  2035.92,   96.464,  1.59676,  58, nil},
    [1] = {"Zangarmarsh",         530,  -220.297,  5378.58,   23.3223, 1.61718,  60, nil},
    [2] = {"Terokkar Forest",     530, -2266.23,   4244.73,    1.47728,3.68426,  62, nil},
    [3] = {"Nagrand",             530, -1610.85,   7733.62,  -17.2773, 1.33522,  64, nil},
    [4] = {"Blade's Edge Mtns",   530,  2029.75,   6232.07,  133.495,  1.30395,  65, nil},
    [5] = {"Netherstorm",         530,  3271.2,    3811.61,   143.153, 3.44101,  67, nil},
    [6] = {"Shadowmoon Valley",   530, -3681.01,   2350.76,    76.587, 4.25995,  67, nil},
}

-- ---- MENU_NORTHREND ----------------------------------------------------------
DESTS[MENU_NORTHREND] = {
    [0] = {"Borean Tundra",       571, 2954.24,   5379.13,   60.4538, 2.55544,  68, nil},
    [1] = {"Howling Fjord",       571,  682.848,  -3978.3,   230.161,  1.54207,  68, nil},
    [2] = {"Dragonblight",        571, 2678.17,    891.826,    4.37494,0.101121, 71, nil},
    [3] = {"Grizzly Hills",       571, 4017.35,  -3403.85,   290,      5.35431,  73, nil},
    [4] = {"Zul'Drak",            571, 5560.23,  -3211.66,   371.709,  5.55055,  74, nil},
    [5] = {"Sholazar Basin",      571, 5614.67,   5818.86,   -69.722,  3.60807,  76, nil},
    [6] = {"Crystalsong Forest",  571, 5411.17,   -966.37,   167.082,  1.57167,  77, nil},
    [7] = {"Storm Peaks",         571, 6120.46,  -1013.89,   408.39,   5.12322,  77, nil},
    [8] = {"Icecrown",            571, 8323.28,   2763.5,    655.093,  2.87223,  77, nil},
    [9] = {"Wintergrasp",         571, 4522.23,   2828.01,   389.975,  0.215009, 77, nil},
}

-- =============================================================================
-- HELPERS
-- =============================================================================

-- Comprueba si un jugador cumple los requisitos de facción, nivel y rango GM
local function CanAccess(player, dest)
    local minLevel  = dest[7]
    local faction   = dest[8]  -- nil=todos, 0=Alianza, 1=Horda
    local minGMRank = dest[9]  -- nil=todos, 1+=solo GM (1=Mod, 2=GM, 3=Admin)

    if minLevel and player:GetLevel() < minLevel then
        return false
    end

    if faction ~= nil and player:GetTeam() ~= faction then
        return false
    end

    if minGMRank and player:GetGMRank() < minGMRank then
        return false
    end

    return true
end

-- Realiza el teleport y cierra el menú gossip
local function DoTeleport(player, dest)
    player:GossipComplete()
    local name   = dest[1]
    local mapId  = dest[2]
    local x      = dest[3]
    local y      = dest[4]
    local z      = dest[5]
    local o      = dest[6]
    player:Teleport(mapId, x, y, z, o)
    player:SendBroadcastMessage("|cff00ff96[Portal Master]|r Teleporting you to " .. name .. ".")
end

-- =============================================================================
-- MENÚ PRINCIPAL
-- =============================================================================

local function ShowMainMenu(player, creature)
    player:GossipClearMenu()

    local team = player:GetTeam()

    -- ── Capitales y lugares especiales (intid 1-12) ──────────────────────────
    local mainDests = DESTS[MENU_MAIN]
    for intid = 1, 12 do
        local dest = mainDests[intid]
        if dest and CanAccess(player, dest) then
            local faction = dest[8]
            local color
            if     faction == TEAM_ALLIANCE then color = C_ALLIANCE
            elseif faction == TEAM_HORDE    then color = C_HORDE
            else                                 color = C_NEUTRAL
            end
            local icon  = CITY_ICON[dest[1]] or TEX_PORTAL
            local label = icon .. "|cff000000" .. dest[1] .. C_RESET
            player:GossipMenuAddItem(10, label, MENU_MAIN, intid, false, "", 0)
        end
    end

    -- ── Navegación a continentes / zonas ─────────────────────────────────────
    player:GossipMenuAddItem(10, TEX_MAP .. "|cff000000" .. "Eastern Kingdoms"  .. C_RESET .. "  »", MENU_MAIN, INTID_NAV_EK,        false, "", 0)
    player:GossipMenuAddItem(10, TEX_MAP .. "|cff000000" .. "Kalimdor"          .. C_RESET .. "  »", MENU_MAIN, INTID_NAV_KALI,      false, "", 0)
    player:GossipMenuAddItem(10, TEX_MAP .. "|cff000000" .. "Outland"           .. C_RESET .. "  »", MENU_MAIN, INTID_NAV_OUTLAND,   false, "", 0)
    player:GossipMenuAddItem(10, TEX_MAP .. "|cff000000" .. "Northrend"         .. C_RESET .. "  »", MENU_MAIN, INTID_NAV_NORTHREND, false, "", 0)

    -- ── Navegación a mazmorras ────────────────────────────────────────────────
    player:GossipMenuAddItem(10, Tex("INV_Sword_04")                 .. "|cff000000" .. "Classic Dungeons"  .. C_RESET .. "  »", MENU_MAIN, INTID_NAV_CLASSIC, false, "", 0)
    player:GossipMenuAddItem(10, Tex("Spell_Shadow_DemonicTactics")  .. "|cff000000" .. "BC Dungeons"       .. C_RESET .. "  »", MENU_MAIN, INTID_NAV_BC,      false, "", 0)
    player:GossipMenuAddItem(10, Tex("Spell_Frost_FrostArmor02")     .. "|cff000000" .. "Wrath Dungeons"    .. C_RESET .. "  »", MENU_MAIN, INTID_NAV_WRATH,   false, "", 0)

    -- ── Raids ─────────────────────────────────────────────────────────────────
    player:GossipMenuAddItem(10, TEX_RAID .. "|cff000000" .. "Raid Teleports" .. C_RESET .. "  »", MENU_MAIN, INTID_NAV_RAIDS, false, "", 0)

    -- ── GM Island (solo visible para GM rank >= 1) ────────────────────────────
    local gmDest = mainDests[13]
    if gmDest and CanAccess(player, gmDest) then
        local icon  = CITY_ICON["GM Island"]
        local label = icon .. "|cff000000" .. "GM Island" .. C_RESET
        player:GossipMenuAddItem(10, label, MENU_MAIN, 13, false, "", 0)
    end

    player:GossipSendMenu(100, creature)
end

-- =============================================================================
-- SUBMENÚS (instancias, continentes)
-- =============================================================================

-- Devuelve el color de texto apropiado para un submenú dado
local function GetMenuColor(menuSender)
    if menuSender == MENU_RAIDS                          then return C_RAID
    elseif menuSender == MENU_CLASSIC
        or menuSender == MENU_BC
        or menuSender == MENU_WRATH                      then return C_DUNGEON
    else                                                      return C_ZONE
    end
end

-- Construye y envía un submenú filtrando por facción y nivel.
-- menuSender es el código de menú (MENU_CLASSIC, MENU_EK, etc.)
local function ShowSubMenu(player, creature, menuSender)
    player:GossipClearMenu()

    local dests = DESTS[menuSender]
    if not dests then
        ShowMainMenu(player, creature)
        return
    end

    -- Mostrar el nombre del submenú activo como mensaje de área
    local title = MENU_TITLE[menuSender]
    if title then
        player:SendAreaTriggerMessage("|cffFFD54F[Portal Master]|r  " .. title)
    end

    -- Color e ícono base para este menú
    local menuColor = GetMenuColor(menuSender)
    local menuIcon
    if menuSender == MENU_RAIDS then
        menuIcon = TEX_RAID
    elseif menuSender == MENU_CLASSIC or menuSender == MENU_BC or menuSender == MENU_WRATH then
        menuIcon = TEX_DUNGEON
    else
        menuIcon = TEX_MAP
    end

    -- Ordenar las claves ascendentemente
    local keys = {}
    for k in pairs(dests) do keys[#keys + 1] = k end
    table.sort(keys)

    local hasItems = false
    for _, intid in ipairs(keys) do
        local dest = dests[intid]
        if dest and CanAccess(player, dest) then
            local name   = dest[1]
            local minLvl = dest[7]
            local faction= dest[8]

            -- Color del nombre: facción > color de menú
            local nameColor
            if     faction == TEAM_ALLIANCE then nameColor = C_ALLIANCE
            elseif faction == TEAM_HORDE    then nameColor = C_HORDE
            else                                 nameColor = menuColor
            end

            -- Etiqueta: icono + "Nombre  (Lv 73+)"
            local icon  = CITY_ICON[name] or menuIcon
            local label = icon .. "|cff000000" .. name .. C_RESET
            if minLvl and minLvl > 0 then
                label = label .. "  " .. C_LEVEL .. "(Lv " .. minLvl .. "+)" .. C_RESET
            end

            player:GossipMenuAddItem(10, label, menuSender, intid, false, "", 0)
            hasItems = true
        end
    end

    if not hasItems then
        player:GossipMenuAddItem(0,
            C_LEVEL .. "(No destinations available for your faction/level)" .. C_RESET,
            menuSender, INTID_BACK, false, "", 0)
    end

    -- Botón Back
    player:GossipMenuAddItem(10,
        TEX_BACK .. "|cff000000" .. "<< Back to main menu" .. C_RESET,
        menuSender, INTID_BACK, false, "", 0)

    player:GossipSendMenu(100, creature)
end

-- =============================================================================
-- TABLA: intid de navegación → menuSender de destino
-- =============================================================================
local NAV_TO_MENU = {
    [INTID_NAV_CLASSIC]   = MENU_CLASSIC,
    [INTID_NAV_BC]        = MENU_BC,
    [INTID_NAV_WRATH]     = MENU_WRATH,
    [INTID_NAV_RAIDS]     = MENU_RAIDS,
    [INTID_NAV_EK]        = MENU_EK,
    [INTID_NAV_KALI]      = MENU_KALI,
    [INTID_NAV_OUTLAND]   = MENU_OUTLAND,
    [INTID_NAV_NORTHREND] = MENU_NORTHREND,
}

-- =============================================================================
-- CALLBACKS DE GOSSIP
-- =============================================================================

local function OnGossipHello(event, player, creature)
    ShowMainMenu(player, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code, menu_id)
    -- Volver al menú principal
    if intid == INTID_BACK then
        ShowMainMenu(player, creature)
        return
    end

    -- Navegación desde el menú principal a un submenú
    if sender == MENU_MAIN then
        local targetMenu = NAV_TO_MENU[intid]
        if targetMenu then
            ShowSubMenu(player, creature, targetMenu)
            return
        end

        -- Teleport desde el menú principal (intid 1-12)
        local dest = DESTS[MENU_MAIN][intid]
        if dest then
            if not CanAccess(player, dest) then
                player:GossipComplete()
                player:SendBroadcastMessage("|cffff4040[Portal Master]|r You do not meet the requirements for this destination.")
                return
            end
            DoTeleport(player, dest)
            return
        end

        -- intid desconocido en MENU_MAIN
        player:GossipComplete()
        return
    end

    -- Teleport desde cualquier submenú (sender == MENU_CLASSIC, MENU_EK, etc.)
    local menuDests = DESTS[sender]
    if menuDests then
        local dest = menuDests[intid]
        if dest then
            if not CanAccess(player, dest) then
                player:GossipComplete()
                player:SendBroadcastMessage("|cffff4040[Portal Master]|r You do not meet the requirements for this destination.")
                return
            end
            DoTeleport(player, dest)
            return
        end
    end

    -- Fallback: cerrar gossip
    player:GossipComplete()
end

-- =============================================================================
-- REGISTRO DE EVENTOS
-- =============================================================================

RegisterCreatureGossipEvent(NPC_ENTRY, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ENTRY, 2, OnGossipSelect)

print("[Portal Master] Script loaded — entry " .. NPC_ENTRY)

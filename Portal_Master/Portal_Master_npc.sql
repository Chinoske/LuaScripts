-- ============================================================================
-- Portal Master NPC — SQL de instalacion
-- ============================================================================
-- AzerothCore WotLK 3.3.5a
--
-- Ejecutar en acore_world:
--   mysql -u acore -p acore_world < Portal_Master_npc.sql
--
-- Despues (en la consola del worldserver):
--   .reload creature_template
--   .reload ale
--
-- NOTA: gossip, condiciones de faccion/nivel y teleports los maneja
--       Portal_Master.lua — no se necesitan gossip_menu, npc_text,
--       gossip_menu_option, conditions ni smart_scripts.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- LIMPIAR REGISTROS PREVIOS
-- ----------------------------------------------------------------------------
DELETE FROM `creature_template`       WHERE `entry`     = 190000;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 190000;
DELETE FROM `creature`                WHERE `id1`        = 190000;


-- ----------------------------------------------------------------------------
-- CREATURE TEMPLATE
--   entry    190000  — coincide con NPC_ENTRY en Portal_Master.lua
--   modelid  21572   — mago humano (modelo original de Rochet2)
--   faction  35      — amistoso con todos
--   npcflag  1       — gossip
--   rank     1       — Elite
--   type     7       — Humanoid
--   AIName   ''      — sin SmartAI; el Lua gestiona todo
-- ----------------------------------------------------------------------------
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
 `speed_walk`, `speed_run`, `unit_class`, `rank`, `family`, `type`,
 `RegenHealth`, `flags_extra`, `BaseAttackTime`, `RangeAttackTime`,
 `unit_flags`, `dynamicflags`, `ScriptName`)
VALUES
(190000, 'Portal Master', 'Teleporter', 71, 71, 35, 1,
 1.0, 1.14286, 1, 1, 0, 7,
 1, 2, 2000, 2000,
 0, 0, '');


-- ----------------------------------------------------------------------------
-- MODELO
--   DisplayID 21572 — mago humano masculino
-- ----------------------------------------------------------------------------
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(190000, 0, 21572, 1.0, 1);


-- ----------------------------------------------------------------------------
-- SPAWNS (12 ubicaciones — guids 5001001-5001012)
--   phaseMask 1  : fase normal
--   MovementType 0 : estatico
-- ----------------------------------------------------------------------------
INSERT INTO `creature`
(`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId`,
 `spawnMask`, `phaseMask`, `equipment_id`,
 `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `currentwaypoint`,
 `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`)
VALUES
-- Stormwind
(5001001, 190000, 0, 0,   0, 0, 0,   1, 1, 0,
 -8845.09,  624.828,   94.2999,  0.44062,  300, 0, 0,  1, 0,  0, 0, 0, 0),
-- Ironforge
(5001002, 190000, 0, 0,   0, 0, 0,   1, 1, 0,
 -4898.37, -965.118,  501.447,   2.25986,  300, 0, 0,  1, 0,  0, 0, 0, 0),
-- Undercity
(5001003, 190000, 0, 0,   0, 0, 0,   1, 1, 0,
  1637.21,  240.132,  -43.1034,  3.13147,  300, 0, 0,  1, 0,  0, 0, 0, 0),
-- Booty Bay
(5001004, 190000, 0, 0,   0, 0, 0,   1, 1, 0,
 -14279.8,  555.014,    8.90011, 3.97606,  300, 0, 0,  1, 0,  0, 0, 0, 0),
-- Orgrimmar
(5001005, 190000, 0, 0,   1, 0, 0,   1, 1, 0,
  1599.25, -4375.85,   10.0872,  5.23641,  300, 0, 0,  1, 0,  0, 0, 0, 0),
-- Thunder Bluff
(5001006, 190000, 0, 0,   1, 0, 0,   1, 1, 0,
 -1277.65,   72.9751, 128.742,   5.95567,  300, 0, 0,  1, 0,  0, 0, 0, 0),
-- Darnassus / Teldrassil
(5001007, 190000, 0, 0,   1, 0, 0,   1, 1, 0,
  9866.83, 2494.66,  1315.88,   5.94620,  300, 0, 0,  1, 0,  0, 0, 0, 0),
-- Exodar (map 530)
(5001008, 190000, 0, 0, 530, 0, 0,   1, 1, 0,
 -3862.69, -11645.8,  -137.629,  2.38273,  300, 0, 0,  1, 0,  0, 0, 0, 0),
-- Silvermoon City (map 530)
(5001009, 190000, 0, 0, 530, 0, 0,   1, 1, 0,
  9741.67, -7454.19,   13.5572,  3.14231,  300, 0, 0,  1, 0,  0, 0, 0, 0),
-- Shattrath (map 530)
(5001010, 190000, 0, 0, 530, 0, 0,   1, 1, 0,
 -1888.65,  5355.88,  -12.4279,  1.25883,  300, 0, 0,  1, 0,  0, 0, 0, 0),
-- Dalaran (map 571)
(5001011, 190000, 0, 0, 571, 0, 0,   1, 1, 0,
  5807.06,   506.244,  657.576,  5.54461,  300, 0, 0,  1, 0,  0, 0, 0, 0),
-- Gurubashi Arena
(5001012, 190000, 0, 0,   0, 0, 0,   1, 1, 0,
 -13180.5,   342.503,   43.1936, 4.32977,  300, 0, 0,  1, 0,  0, 0, 0, 0);


-- ============================================================================
-- VERIFICACION (copiar y pegar en el cliente MySQL si quieres confirmar)
-- ============================================================================
-- SELECT entry, name, subname FROM creature_template WHERE entry = 190000;
-- SELECT guid, id1, map, position_x, position_y FROM creature WHERE id1 = 190000;
--
-- Teleporte rapido en juego:
--   .go creature 5001001   -> Stormwind
--   .go creature 5001005   -> Orgrimmar
--   .go creature 5001011   -> Dalaran
-- ============================================================================

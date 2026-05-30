-- NPC Quest Complete DK — The Lich King
-- Base de datos: acore_world
-- AzerothCore WotLK 3.3.5a — Schema actualizado (sin columna `scale`, usa `CreatureImmunitiesId`)

DELETE FROM `creature_template` WHERE `entry`=200000;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(200000, 0, 0, 0, 0, 0, 'The Lich King', 'Completar misiones dk', NULL, 0, 83, 83, 2, 35, 1, 1, 1, 1, 1, 20, 3, 0, 35, 2000, 2000, 1, 1, 1, 768, 2048, 0, 0, 6, 36, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 2000, 1, 1, 1, 0, 0, 1, 0, 2, '', 12340);

DELETE FROM `creature_template_model` WHERE `CreatureID`=200000;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(200000, 0, 24191, 1, 1, 0);

DELETE FROM `creature` WHERE `id1`=200000;
INSERT INTO `creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(4000000, 200000, 0, 0, 609, 0, 0, 1, 1, 0, 2375.24, -5650.85, 426.127, 3.766, 300, 0, 0, 27890000, 0, 0, 1, 0, 0, '', 0, 0, 'NPC Completar misiones DK');
